"""Run the same smoke ELFs on a bounded Cortex-M3/RAM-stub Renode platform."""
from firmware_cases import BUILD_PROFILES
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
from run_qemu_smoke import metadata_matches, verdict


def resc_path(path):
    value = path.resolve().as_posix()
    if any(c in value for c in ('"', '\n', '\r')):
        raise ValueError('Unsupported Renode script path')
    return '@' + value.replace(' ', '\\ ')


def classify(profile, process_code, host_timeout, completed, guest, output, expected, gcc):
    # A wall-clock timeout, parser error or missing end-of-script marker always fails.
    if host_timeout or process_code != 0 or not completed or 'TRANSPORT_ERROR=' in output:
        return False
    if not metadata_matches(output, expected):
        return False
    if profile == 'hang':
        return guest is None and verdict(profile, None, True, output, gcc)
    if not guest or guest.get('operation') != 0x20 or guest.get('reason') != 0x20026:
        return False
    return verdict(profile, guest.get('status'), False, output, gcc)


PRIORITY_PROBE_WARNING = 'nvic: Trying to set the priority for interrupt 16 to 0xFF, but it should be maskable with 0xF0'


def process_completed(log, profile):
    warnings = [line.partition('[WARNING] ')[2] for line in log.splitlines() if '[WARNING]' in line]
    allowed = (not warnings or (profile == 'freertosTasks' and warnings == [PRIORITY_PROBE_WARNING]))
    return (log.splitlines().count('RENODE_RUN_COMPLETED') == 1 and allowed
            and not any(marker in log for marker in ('There was an error', '[ERROR]')))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--renode', default=os.environ.get('RENODE_BINARY', 'renode'))
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    report = {'status': 'failed', 'model': 'f103-smoke', 'exit_adapter': 'SYS_EXIT_EXTENDED hook', 'cases': []}
    root = Path(__file__).resolve().parent.parent
    try:
        build = args.build.resolve()
        manifest = json.loads((build / 'build-summary.json').read_text(encoding='utf-8'))
        if manifest['status'] != 'passed' or sorted(c['profile'] for c in manifest['cases']) != sorted(BUILD_PROFILES):
            raise ValueError('Expected complete successful build')
        if manifest['crc_negative']['profile'] != 'crc-corrupt':
            raise ValueError('Missing CRC negative image')
        renode = shutil.which(args.renode)
        if not renode and args.renode == 'renode' and os.name == 'nt':
            renode = str(Path(os.environ.get('ProgramFiles', 'C:/Program Files')) / 'Renode/renode.exe')
        if not renode or not Path(renode).is_file():
            raise ValueError('Renode executable not found')
        report['renode'] = subprocess.check_output([renode, '--version'], text=True, timeout=30).strip()
        for case in manifest['cases'] + [manifest['crc_negative']]:
            profile = case['profile']
            directory = Path(tempfile.mkdtemp(prefix=profile + '-', dir=args.output.resolve()))
            directory.chmod(0o755)
            elf = (build / case['elf']).resolve()
            if not elf.is_relative_to(build) or not elf.is_file():
                raise ValueError('Invalid ELF path')
            trap = case['exit_trap']
            if not isinstance(trap, int) or trap % 2 or not 0x08000000 <= trap < 0x08010000:
                raise ValueError('Invalid exit trap address')
            hook = root / 'tests/firmware/renode/exit_hook.py'
            guest_path = directory / 'guest-exit.json'
            # Python repr quotes paths inside the Renode triple-quoted hook body.
            hook_code = f'result_path = {guest_path.as_posix()!r}\nexecfile({hook.as_posix()!r})'
            script = directory / 'run.resc'
            script.write_text(f'''mach create "f103-smoke"
machine LoadPlatformDescription {resc_path(root / 'tests/firmware/renode/f103-smoke.repl')}
sysbus.cpu.uart CreateFileBackend {resc_path(directory / 'firmware.log')}
sysbus LoadELF {resc_path(elf)}
sysbus.cpu AddHook 0x{trap:X} """{hook_code}"""
emulation RunFor "0.1"
echo "RENODE_RUN_COMPLETED"
quit
''', encoding='utf-8')
            command = [renode, '--disable-gui', '--console', '--plain', '--config', str(directory / 'renode.config'), '--execute', 'include ' + resc_path(script)]
            host_timeout = False
            try:
                process = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=30)
                code, raw = process.returncode, process.stdout
            except subprocess.TimeoutExpired as error:
                host_timeout, code, raw = True, None, error.stdout or b''
            log = raw.decode('utf-8', errors='replace')
            (directory / 'process.log').write_text(log, encoding='utf-8')
            output = (directory / 'firmware.log').read_text(encoding='utf-8') if (directory / 'firmware.log').exists() else ''
            guest = json.loads(guest_path.read_text()) if guest_path.exists() else None
            completed = process_completed(log, profile)
            passed = classify(profile, code, host_timeout, completed, guest, output, case['metadata'], manifest['gcc'])
            report['cases'].append({'profile': profile, 'passed': passed, 'returncode': code,
                                    'host_timeout': host_timeout, 'virtual_budget_seconds': 0.1,
                                    'guest_exit': guest, 'completed': completed,
                                    'metadata_ok': metadata_matches(output, case['metadata']),
                                    'warnings': [line for line in log.splitlines() if '[WARNING]' in line],
                                    'expected_metadata': case['metadata'], 'command': command})
            print(f'{"PASS" if passed else "FAIL"}: {profile}; guest={guest}; host={code}', flush=True)
        report['status'] = 'passed' if all(c['passed'] for c in report['cases']) else 'failed'
    except (OSError, ValueError, KeyError, subprocess.SubprocessError) as error:
        report['error'] = str(error)
    (args.output / 'renode-summary.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    return 0 if report['status'] == 'passed' else 1


if __name__ == '__main__':
    raise SystemExit(main())
