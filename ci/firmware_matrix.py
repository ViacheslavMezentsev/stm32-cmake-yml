"""Build or run the locked firmware toolchain matrix in separate containers."""
import argparse
import itertools
import json
import os
from pathlib import Path
import subprocess
import sys


def pairs(lock):
    for key in ('gcc_versions', 'cmake_versions'):
        versions = lock[key]
        if not versions or len(set(versions)) != len(versions):
            raise ValueError(f'Empty or duplicate {key}')
    return list(itertools.product(lock['gcc_versions'], lock['cmake_versions']))


def verify_build(report, gcc, cmake):
    if report['status'] != 'passed' or sorted(c['profile'] for c in report['cases']) != ['failure', 'hang', 'success']:
        raise ValueError('Missing or failed build profiles')
    if report['gcc'] != gcc.split('-')[0] or report['cmake'] != 'cmake version ' + cmake:
        raise ValueError('Actual compiler/CMake versions do not match selected pair')


def verify_matrix(report, combinations):
    actual = [(item['gcc'], item['cmake']) for item in report['pairs']]
    if (report['status'] != 'passed' or report['phase'] != 'build'
            or len(actual) != len(combinations) or set(actual) != set(combinations)
            or any(item['status'] != 'passed' or item['profiles'] != 3 for item in report['pairs'])):
        raise ValueError('Expected a complete successful build matrix matching the current lockfile')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('phase', choices=('build', 'run'))
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--build', type=Path, help='Matrix build root, required for run')
    parser.add_argument('--qemu', default='qemu-system-arm')
    parser.add_argument('--emulator', choices=('qemu', 'renode'), default='qemu')
    parser.add_argument('--renode', default='renode')
    args = parser.parse_args()
    if args.phase == 'run' and args.build is None:
        parser.error('--build is required for run')
    if args.phase == 'run' and args.build.resolve() == args.output.resolve():
        parser.error('Build and run output directories must be different')
    root = Path(__file__).resolve().parent.parent
    lock = json.loads((root / 'ci/dependencies.lock.json').read_text(encoding='utf-8'))
    combinations = pairs(lock)
    args.output.mkdir(parents=True, exist_ok=True)
    output = args.output.resolve()
    summary = {'status': 'failed', 'phase': args.phase, 'expected_pairs': len(combinations), 'emulator': args.emulator if args.phase == 'run' else None, 'pairs': []}
    destination = output / 'matrix-summary.json'
    destination.write_text(json.dumps(summary) + '\n')
    if args.phase == 'run':
        try:
            verify_matrix(json.loads((args.build / 'matrix-summary.json').read_text(encoding='utf-8')), combinations)
        except (OSError, ValueError, KeyError) as error:
            summary['error'] = str(error)
            destination.write_text(json.dumps(summary, indent=2) + '\n', encoding='utf-8')
            print(summary['error'], file=sys.stderr)
            return 1
    for gcc, cmake in combinations:
        name = f'gcc-{gcc}_cmake-{cmake}'
        directory = output / name
        directory.mkdir(exist_ok=True)
        item = {'gcc': gcc, 'cmake': cmake, 'status': 'failed', 'profiles': 0}
        try:
            env = dict(os.environ, GCC_VERSION=gcc, CMAKE_VERSION=cmake)
            if args.phase == 'build':
                command = ['/usr/local/bin/stm32-yml-env', 'python3', str(root / 'ci/build_firmware_smoke.py'), '--output', str(directory)]
            else:
                build = args.build.resolve() / name
                verify_build(json.loads((build / 'build-summary.json').read_text(encoding='utf-8')), gcc, cmake)
                command = [sys.executable, str(root / f'ci/run_{args.emulator}_smoke.py'), '--build', str(build),
                           '--output', str(directory), '--' + args.emulator, getattr(args, args.emulator)]
            with (directory / 'matrix-driver.log').open('w', encoding='utf-8') as log:
                result = subprocess.run(command, env=env, stdout=log, stderr=subprocess.STDOUT, timeout=1200)
            item['returncode'] = result.returncode
            if result.returncode:
                raise ValueError(f'{args.phase} returned {result.returncode}; see matrix-driver.log')
            filename = 'build-summary.json' if args.phase == 'build' else f'{args.emulator}-summary.json'
            report = json.loads((directory / filename).read_text(encoding='utf-8'))
            if args.phase == 'build':
                verify_build(report, gcc, cmake)
            elif report['status'] != 'passed' or sorted(c['profile'] for c in report['cases']) != ['crc-corrupt', 'failure', 'hang', 'success'] or not all(c['passed'] for c in report['cases']):
                raise ValueError(f'Missing or failed {args.emulator} profiles')
            item.update(status='passed', profiles=3)
            if args.phase == 'run':
                item['executions'] = len(report['cases'])
        except (OSError, ValueError, KeyError, subprocess.SubprocessError) as error:
            item['error'] = str(error)
        summary['pairs'].append(item)
        destination.write_text(json.dumps(summary, indent=2) + '\n', encoding='utf-8')
        print(f'{args.phase}: {name}: {item["status"]}', flush=True)
    summary['status'] = 'passed' if all(p['status'] == 'passed' for p in summary['pairs']) else 'failed'
    destination.write_text(json.dumps(summary, indent=2) + '\n', encoding='utf-8')
    return 0 if summary['status'] == 'passed' else 1


if __name__ == '__main__':
    raise SystemExit(main())
