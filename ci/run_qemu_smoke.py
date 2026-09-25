"""Run previously built semihosting fixtures; distinguish guest failure and timeout."""
from firmware_cases import BUILD_PROFILES, RUN_PROFILES, PASS_PROFILES
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import time


def metadata_matches(output, expected):
    # Each field must appear exactly once; conflicting duplicate values fail.
    fields = {}
    for line in output.splitlines():
        key, separator, value = line.strip().partition('=')
        if separator and key in expected:
            if key in fields:
                return False
            fields[key] = value
    return bool(expected) and fields == expected


def verdict(profile, code, timed_out, output, gcc):
    if profile not in RUN_PROFILES or 'TRANSPORT_ERROR=' in output:
        return False
    lines = {line.strip() for line in output.splitlines()}
    if not {'BUILD_TARGET=STM32F103C8T6', 'TEST_PLATFORM=cortex-m3-smoke'} <= lines:
        return False
    if f'Compiler:    GCC {gcc}' not in lines or '0xC23 -> Cortex-M3' not in output:
        return False
    if profile == 'hang':
        return timed_out and not ({'TEST_RESULT=PASS', 'TEST_RESULT=FAIL'} & lines)
    if profile == 'crc-corrupt':
        return not timed_out and code == 3 and 'TEST_RESULT=FAIL' in lines and 'TEST_RESULT=PASS' not in lines
    marker = 'TEST_RESULT=PASS' if profile in PASS_PROFILES else 'TEST_RESULT=FAIL'
    opposite = 'TEST_RESULT=FAIL' if profile in PASS_PROFILES else 'TEST_RESULT=PASS'
    return not timed_out and code == (0 if profile in PASS_PROFILES else 1) and marker in lines and opposite not in lines


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--qemu', default='qemu-system-arm')
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    report = {'status': 'failed', 'cases': []}
    try:
        build = args.build.resolve()
        manifest = json.loads((build / 'build-summary.json').read_text(encoding='utf-8'))
        if manifest['status'] != 'passed' or sorted(c['profile'] for c in manifest['cases']) != sorted(BUILD_PROFILES):
            raise ValueError('Expected successful build manifest with all expected profiles')
        qemu = shutil.which(args.qemu)
        if not qemu:
            raise ValueError(f'QEMU not found: {args.qemu}')
        report['qemu'] = subprocess.check_output([qemu, '--version'], text=True, timeout=30).strip()
        if manifest['crc_negative']['profile'] != 'crc-corrupt':
            raise ValueError('Missing CRC negative image')
        for case in manifest['cases'] + [manifest['crc_negative']]:
            profile = case['profile']
            elf = (build / case['elf']).resolve()
            if not elf.is_relative_to(build) or not elf.is_file():
                raise ValueError(f'Invalid ELF path: {elf}')
            command = [qemu, '-M', 'netduino2', '-nographic', '-monitor', 'none', '-serial', 'none',
                       '-no-reboot', '-semihosting-config', 'enable=on,target=native', '-kernel', str(elf)]
            started = time.monotonic()
            timeout_seconds = 2 if profile == 'hang' else 15
            timed_out = False
            try:
                process = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                         timeout=timeout_seconds)
                code, raw = process.returncode, process.stdout
            except subprocess.TimeoutExpired as error:
                timed_out, code, raw = True, None, error.stdout or b''
            output = raw.decode('utf-8', errors='replace')
            (args.output / (profile + '.log')).write_text(output, encoding='utf-8')
            metadata_ok = metadata_matches(output, case['metadata'])
            passed = metadata_ok and verdict(profile, code, timed_out, output, manifest['gcc'])
            report['cases'].append({'profile': profile, 'passed': passed, 'returncode': code,
                                    'timeout': timed_out, 'metadata_ok': metadata_ok,
                                    'timeout_seconds': timeout_seconds, 'duration_seconds': round(time.monotonic() - started, 3),
                                    'expected_metadata': case['metadata'], 'command': command})
            print(f'{"PASS" if passed else "FAIL"}: {profile}; exit={code}; timeout={timed_out}', flush=True)
        report['status'] = 'passed' if all(c['passed'] for c in report['cases']) else 'failed'
    except (OSError, ValueError, KeyError, subprocess.SubprocessError) as error:
        report['error'] = str(error)
    (args.output / 'qemu-summary.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    return 0 if report['status'] == 'passed' else 1


if __name__ == '__main__':
    raise SystemExit(main())
