"""Run the same smoke ELFs on a bounded Cortex-M3/RAM-stub Renode platform."""
from firmware_cases import BUILD_CASES, BUILD_ONLY_PROFILES, TARGETS, split_case
import argparse
import json
import os
import random
import re
from pathlib import Path
import shutil
import subprocess
import tempfile
import threading
import time
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
    if split_case(profile)[1] == 'hang':
        return guest is None and verdict(profile, None, True, output, gcc, 'renode')
    if not guest or guest.get('operation') != 0x20 or guest.get('reason') != 0x20026:
        return False
    return verdict(profile, guest.get('status'), False, output, gcc, 'renode')


PRIORITY_PROBE_WARNING = 'nvic: Trying to set the priority for interrupt 16 to 0xFF, but it should be maskable with 0xF0'


def process_completed(log, profile):
    warnings = [line.partition('[WARNING] ')[2] for line in log.splitlines() if '[WARNING]' in line]
    allowed = (not warnings or (split_case(profile)[1] == 'freertosTasks' and warnings == [PRIORITY_PROBE_WARNING]))
    return (log.splitlines().count('RENODE_RUN_COMPLETED') == 1 and allowed
            and not any(marker in log for marker in ('There was an error', '[ERROR]')))


CASE_TIMEOUT = 30  # host seconds without progress for one case (both modes)
CASE_END = 'RENODE_CASE_END='
CASE_MARKER = re.compile(CASE_END + r'\d+')
# Markers go through Renode's logger ('log' command), not 'echo', so they stay
# ordered with emulation messages. Log entries are whole lines, but direct console
# output ('echo', "Renode is quitting") can be split by one, e.g.
# "R<entry>\nenode is ...": embedded entries are moved to their own lines first.
LOG_ENTRY = re.compile(r'\d{2}:\d{2}:\d{2}\.\d+ \[(?:NOISY|DEBUG|INFO|WARNING|ERROR)\] ')
LOGGED_MARKER = re.compile(r'^\d{2}:\d{2}:\d{2}\.\d+ \[INFO\] Script: (RENODE_RUN_COMPLETED|RENODE_CASE_END=\d+)$')


def split_line(line):
    """Split direct console text from an embedded log entry; unwrap logged markers."""
    match = LOG_ENTRY.search(line)
    parts = [line[:match.start()], line[match.start():]] if match and match.start() else [line]
    return [marker.group(1) if (marker := LOGGED_MARKER.match(part)) else part for part in parts]


def split_log(text):
    return '\n'.join(part for line in text.splitlines() for part in split_line(line)) + '\n'


def prepare_case(root, build, output, case):
    """Validate one case and return its directory and Renode commands.

    The commands start with Clear, so every case gets a new machine: CPU, NVIC,
    SysTick, memories and the exit hook are recreated even inside one process.
    """
    profile = case['profile']
    target_name = split_case(profile)[0]
    target = TARGETS[target_name]
    flash_low, flash_size = target['flash']
    ram_low, ram_size = target['ram']
    directory = Path(tempfile.mkdtemp(prefix=profile.replace(':', '-') + '-', dir=output))
    directory.chmod(0o755)
    elf = (build / case['elf']).resolve()
    if not elf.is_relative_to(build) or not elf.is_file():
        raise ValueError('Invalid ELF path')
    trap = case['exit_trap']
    if not isinstance(trap, int) or trap % 2 or not flash_low <= trap < flash_low + flash_size:
        raise ValueError('Invalid exit trap address')
    hook = root / 'tests/firmware/renode/exit_hook.py'
    # Python repr quotes paths inside the Renode triple-quoted hook body.
    hook_code = (f'result_path = {(directory / "guest-exit.json").as_posix()!r}\n'
                 f'ram_low = {ram_low}\nram_high = {ram_low + ram_size - 8}\nexecfile({hook.as_posix()!r})')
    commands = [
        'Clear',
        f'mach create "{target_name}-smoke"',
        f'machine LoadPlatformDescription {resc_path(root / "tests/firmware/renode" / (target_name + "-smoke.repl"))}',
        f'sysbus.cpu.uart CreateFileBackend {resc_path(directory / "firmware.log")}',
        f'sysbus LoadELF {resc_path(elf)}',
        f'sysbus.cpu AddHook 0x{trap:X} """{hook_code}"""',
        'emulation RunFor "0.1"',
        'log "RENODE_RUN_COMPLETED"',
    ]
    return directory, commands


# Build-only firmware (tests/firmware/buildonly) on minimal H7/H5 models (TC-57).
# QEMU has no machine with these cores and FLASH at 0x08000000, so they run in
# Renode only. Expected lines are fixed per profile; h503 and h503bkp share the
# same code, and only the loaded backup SRAM word differs (TC-63).
BUILD_ONLY_MODELS = {
    'h7': ('h7-smoke.repl', 0x20000000, 0x2001FFF8, ['PROFILE=h7', 'CPUID=411FC27']),
    'h5': ('h5-smoke.repl', 0x20000000, 0x2009FFF8, ['PROFILE=h5', 'CPUID=411FD21']),
    'h503': ('h5-smoke.repl', 0x20000000, 0x20007FF8,
             ['PROFILE=h503', 'CPUID=411FD21', 'CRC_RESULT=PASS', 'BKPSRAM=00000000']),
    'h503bkp': ('h5-smoke.repl', 0x20000000, 0x20007FF8,
                ['PROFILE=h503', 'CPUID=411FD21', 'CRC_RESULT=PASS', 'BKPSRAM=B007B007']),
}


def run_build_only(renode, root, build, output, cases):
    """Run each build-only ELF in its own Renode process on its family model."""
    results = []
    for case in cases:
        profile = case['profile']
        model, ram_low, ram_high, expected = BUILD_ONLY_MODELS[profile]
        directory = Path(tempfile.mkdtemp(prefix='buildonly-' + profile + '-', dir=output))
        elf = (build / case['elf']).resolve()
        trap = case['exit_trap']
        if not elf.is_relative_to(build) or not elf.is_file():
            raise ValueError('Invalid ELF path')
        if not isinstance(trap, int) or trap % 2 or not 0x08000000 <= trap < 0x08200000:
            raise ValueError('Invalid exit trap address')
        hook = root / 'tests/firmware/renode/exit_hook.py'
        hook_code = (f'result_path = {(directory / "guest-exit.json").as_posix()!r}\n'
                     f'ram_low = {ram_low}\nram_high = {ram_high}\nexecfile({hook.as_posix()!r})')
        commands = [
            f'mach create "{profile}-smoke"',
            f'machine LoadPlatformDescription {resc_path(root / "tests/firmware/renode" / model)}',
            f'sysbus.cpu.uart CreateFileBackend {resc_path(directory / "firmware.log")}',
            f'sysbus LoadELF {resc_path(elf)}',
            f'sysbus.cpu AddHook 0x{trap:X} """{hook_code}"""',
            'emulation RunFor "0.1"',
            'log "RENODE_RUN_COMPLETED"',
            'quit',
        ]
        script = directory / 'run.resc'
        script.write_text('\n'.join(commands) + '\n', encoding='utf-8')
        command = renode_command(renode, directory / 'renode.config', script)
        started = time.monotonic()
        host_timeout = False
        try:
            process = subprocess.run(command, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                     stderr=subprocess.STDOUT, timeout=CASE_TIMEOUT)
            code, raw = process.returncode, process.stdout
        except subprocess.TimeoutExpired as error:
            host_timeout, code, raw = True, None, error.stdout or b''
        log = split_log(raw.decode('utf-8', errors='replace'))
        (directory / 'process.log').write_text(log, encoding='utf-8')
        firmware = directory / 'firmware.log'
        text = firmware.read_text(encoding='utf-8') if firmware.exists() else ''
        guest_path = directory / 'guest-exit.json'
        guest = json.loads(guest_path.read_text()) if guest_path.exists() else None
        lines = text.splitlines()
        completed = process_completed(log, profile)
        output_ok = ('SMOKE_BUILDONLY=1' in lines and 'TEST_RESULT=PASS' in lines
                     and all(any(line.startswith(item) for line in lines) for item in expected))
        passed = (not host_timeout and code == 0 and completed and output_ok and guest is not None
                  and guest.get('operation') == 0x20 and guest.get('reason') == 0x20026 and guest.get('status') == 0)
        results.append({'profile': profile, 'model': model, 'passed': passed, 'returncode': code,
                        'host_timeout': host_timeout, 'guest_exit': guest, 'completed': completed,
                        'output_ok': output_ok, 'expected_lines': expected,
                        'duration_seconds': round(time.monotonic() - started, 3), 'command': command})
    return results


def case_result(case, directory, code, log, host_timeout, duration, command, gcc):
    """Classify one case from its own Renode log segment and output files."""
    profile = case['profile']
    (directory / 'process.log').write_text(log, encoding='utf-8')
    output = (directory / 'firmware.log').read_text(encoding='utf-8') if (directory / 'firmware.log').exists() else ''
    guest_path = directory / 'guest-exit.json'
    guest = json.loads(guest_path.read_text()) if guest_path.exists() else None
    completed = process_completed(log, profile)
    passed = classify(profile, code, host_timeout, completed, guest, output, case['metadata'], gcc)
    return {'profile': profile, 'passed': passed, 'returncode': code,
            'host_timeout': host_timeout, 'virtual_budget_seconds': 0.1,
            'duration_seconds': duration,
            'guest_exit': guest, 'completed': completed,
            'metadata_ok': metadata_matches(output, case['metadata']),
            'warnings': [line for line in log.splitlines() if '[WARNING]' in line],
            'expected_metadata': case['metadata'], 'command': command}


# Renode fills the remaining defaults. Synchronous logging keeps every entry:
# asynchronous entries still queued at Clear or quit can be dropped, losing a
# marker or, worse, an [ERROR] line. Collapsing would hide repeated warnings.
RENODE_CONFIG = '[general]\nuse-synchronous-logging = True\ncollapse-repeated-log-entries = False\n'


def renode_command(renode, config, script):
    config.write_text(RENODE_CONFIG, encoding='utf-8')
    return [renode, '--disable-gui', '--console', '--plain', '--config', str(config), '--execute', 'include ' + resc_path(script)]


def run_process_mode(renode, root, build, output, cases, gcc):
    """Diagnostic mode: one fresh Renode process per case."""
    results = []
    for case in cases:
        directory, commands = prepare_case(root, build, output, case)
        script = directory / 'run.resc'
        script.write_text('\n'.join(commands + ['quit']) + '\n', encoding='utf-8')
        command = renode_command(renode, directory / 'renode.config', script)
        started = time.monotonic()
        host_timeout = False
        try:
            process = subprocess.run(command, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                     stderr=subprocess.STDOUT, timeout=CASE_TIMEOUT)
            code, raw = process.returncode, process.stdout
        except subprocess.TimeoutExpired as error:
            host_timeout, code, raw = True, None, error.stdout or b''
        log = split_log(raw.decode('utf-8', errors='replace'))
        results.append(case_result(case, directory, code, log, host_timeout,
                                   round(time.monotonic() - started, 3), command, gcc))
    return results


def run_batch_mode(renode, root, build, output, cases, gcc):
    """Run every case in one Renode process; Clear recreates the machine per case.

    Output is split by per-case end markers. A case that does not reach its
    marker within CASE_TIMEOUT host seconds stops the process; it and all later
    cases fail as host timeouts, and a non-zero exit fails every case.
    """
    prepared = [prepare_case(root, build, output, case) for case in cases]
    lines = []
    for index, (_, commands) in enumerate(prepared):
        lines += commands + [f'log "{CASE_END}{index}"']
    script = output / 'batch.resc'
    script.write_text('\n'.join(lines + ['quit']) + '\n', encoding='utf-8')
    command = renode_command(renode, output / 'renode.config', script)
    segments, ends, current, raw_lines = [], [], [], []
    progress = threading.Event()
    started = time.monotonic()
    # Closed stdin: after a script error Renode exits instead of waiting at the prompt.
    process = subprocess.Popen(command, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

    def reader():
        try:
            for raw in process.stdout:
                raw_lines.append(raw)
                for line in split_line(raw.decode('utf-8', errors='replace').rstrip('\r\n')):
                    index = int(line[len(CASE_END):]) if CASE_MARKER.fullmatch(line) else -1
                    if index >= len(segments):
                        # A skipped marker leaves empty segments: only those cases fail.
                        while len(segments) < index:
                            segments.append('')
                            ends.append(None)
                        segments.append('\n'.join(current) + '\n')
                        ends.append(time.monotonic())
                        current.clear()
                        progress.set()
                    else:
                        current.append(line)
        finally:
            progress.set()  # EOF: wake the watchdog immediately

    thread = threading.Thread(target=reader, daemon=True)
    thread.start()
    host_timeout = False
    while thread.is_alive():
        if not progress.wait(CASE_TIMEOUT) and thread.is_alive():
            host_timeout = True
            process.kill()
            break
        progress.clear()
    thread.join(10)
    try:
        code = None if host_timeout else process.wait(CASE_TIMEOUT)
    except subprocess.TimeoutExpired:
        process.kill()
        code = None
    (output / 'process.log').write_bytes(b''.join(raw_lines))
    results = []
    previous = started
    for index, (case, (directory, _)) in enumerate(zip(cases, prepared)):
        if index < len(segments) and ends[index] is None:
            log, duration, timed_out = '', None, False
        elif index < len(segments):
            log, duration, timed_out = segments[index], round(ends[index] - previous, 3), False
            previous = ends[index]
        else:
            # Unfinished output belongs to the first case without an end marker.
            log = '\n'.join(current) + '\n' if index == len(segments) else ''
            duration, timed_out = None, host_timeout
        results.append(case_result(case, directory, code, log, timed_out, duration, command, gcc))
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--renode', default=os.environ.get('RENODE_BINARY', 'renode'))
    parser.add_argument('--mode', choices=('batch', 'process'), default='batch',
                        help='batch: one Renode process, Clear between cases; process: one process per case')
    parser.add_argument('--shuffle', type=int, metavar='SEED',
                        help='Run cases in a seeded random order to check order independence')
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    report = {'status': 'failed', 'model': '<target>-smoke', 'exit_adapter': 'SYS_EXIT_EXTENDED hook',
              'mode': args.mode, 'shuffle_seed': args.shuffle, 'cases': []}
    root = Path(__file__).resolve().parent.parent
    started = time.monotonic()
    try:
        build = args.build.resolve()
        output = args.output.resolve()
        manifest = json.loads((build / 'build-summary.json').read_text(encoding='utf-8'))
        if manifest['status'] != 'passed' or sorted(c['profile'] for c in manifest['cases']) != sorted(BUILD_CASES):
            raise ValueError('Expected complete successful build')
        if not manifest.get('crc_negatives'):
            raise ValueError('Missing CRC negative images')
        renode = shutil.which(args.renode)
        if not renode and args.renode == 'renode' and os.name == 'nt':
            renode = str(Path(os.environ.get('ProgramFiles', 'C:/Program Files')) / 'Renode/renode.exe')
        if not renode or not Path(renode).is_file():
            raise ValueError('Renode executable not found')
        report['renode'] = subprocess.check_output([renode, '--version'], text=True, timeout=30).strip()
        cases = manifest['cases'] + manifest['crc_negatives']
        if args.shuffle is not None:
            random.Random(args.shuffle).shuffle(cases)
        run = run_batch_mode if args.mode == 'batch' else run_process_mode
        report['cases'] = run(renode, root, build, output, cases, manifest['gcc'])
        if sorted(c['profile'] for c in manifest['build_only']) != sorted(BUILD_ONLY_PROFILES):
            raise ValueError('Expected complete build-only firmware')
        report['build_only'] = run_build_only(renode, root, build, output, manifest['build_only'])
        for case in report['cases'] + report['build_only']:
            print(f'{"PASS" if case["passed"] else "FAIL"}: {case["profile"]}; guest={case["guest_exit"]}; '
                  f'host={case["returncode"]}', flush=True)
        report['status'] = ('passed' if report['cases'] and all(c['passed'] for c in report['cases'] + report['build_only'])
                            else 'failed')
    except (OSError, ValueError, KeyError, subprocess.SubprocessError) as error:
        report['error'] = str(error)
    report['duration_seconds'] = round(time.monotonic() - started, 3)
    (args.output / 'renode-summary.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    return 0 if report['status'] == 'passed' else 1


if __name__ == '__main__':
    raise SystemExit(main())
