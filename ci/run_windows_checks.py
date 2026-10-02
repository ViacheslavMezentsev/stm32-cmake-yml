"""TC-44: pinned native Windows Configure subset and minimal firmware build."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--tools', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--external-root', type=Path, default=Path(tempfile.gettempdir()))
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    output, tools = args.output.resolve(), args.tools.resolve()
    report = {'status': 'failed', 'cases': [], 'versions': {},
              'tc44_complete': False, 'known_limitations': ['E010']}
    start = time.monotonic()
    try:
        if os.name != 'nt':
            raise ValueError('Windows is required')
        lock = json.loads((ROOT / 'ci/windows.lock.json').read_text(encoding='utf-8'))
        installed = json.loads((tools / 'installed-lock.json').read_text(encoding='utf-8'))
        if lock != installed:
            raise ValueError('Installed lock does not match the repository')
        env = dict(os.environ, PYTHONIOENCODING='utf-8', MODULES_DIR=str(tools / 'modules'), CMAKE_USER_HOME=str(tools / 'no-cube'))
        env['PATH'] = os.pathsep.join(str(tools / p) for p in ('cmake/bin', 'gcc/bin', 'ninja', 'yq')) + os.pathsep + env['PATH']
        cmake = tools / 'cmake/bin/cmake.exe'
        for name, executable, argument, expected in (
            ('cmake', cmake, '--version', 'cmake version ' + lock['cmake']),
            ('gcc', tools / 'gcc/bin/arm-none-eabi-gcc.exe', '-dumpfullversion', '14.2.1'),
            ('yq', tools / 'yq/yq.exe', '--version', 'v4.44.3'),
            ('ninja', tools / 'ninja/ninja.exe', '--version', '1.12.1')):
            text = subprocess.check_output([str(executable), argument], env=env, timeout=30).decode('utf-8').strip()
            if expected not in text:
                raise ValueError(f'Wrong {name}: {text}')
            report['versions'][name] = text
        cases = [c for c in json.loads((ROOT / 'tests/cases.json').read_text(encoding='utf-8')) if c.get('windows')]
        required = {'minimal', 'ioc_backslash', 'crlf', 'external_drive', 'registry_lang', 'build'}
        if not required <= {k for c in cases for k,v in c['windows'].items() if v}:
            raise ValueError('Incomplete TC-44 selection')
        with tempfile.TemporaryDirectory(prefix='stm32-windows-', dir=args.external_root) as external:
            if Path(external).drive.lower() == output.drive.lower():
                raise ValueError('Select --external-root on a different drive from --output')
            for case in cases:
                name = case['name']
                command = [sys.executable, str(ROOT / 'tests/run_case.py'), '--case', name,
                           '--cmake', str(cmake), '--framework', str(ROOT), '--work-dir', str(output / 'cases'),
                           '--windows', '--external-root', external]
                with (output / (name + '.log')).open('wb') as log:
                    run = subprocess.run(command, env=env, stdout=log, stderr=subprocess.STDOUT, timeout=420)
                report['cases'].append({'name': name, 'returncode': run.returncode, 'checks': case['windows']})
                print(f"{name}: {run.returncode}", flush=True)
        # Includes independent version-source probes and mandatory UTF-8 POST_BUILD.
        with (output / 'host.log').open('wb') as log:
            host = subprocess.run([sys.executable, str(ROOT / 'ci/run_host_checks.py'), '--output', str(output / 'host')],
                                  env=env, stdout=log, stderr=subprocess.STDOUT, timeout=180)
        report['host_returncode'] = host.returncode
        if host.returncode:
            print((output / 'host.log').read_text(encoding='utf-8', errors='replace'), flush=True)
        if host.returncode == 0 and all(c['returncode'] == 0 for c in report['cases']):
            report['status'] = 'passed'
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        report['error'] = str(error)
        print(f'Windows check error: {error}', flush=True)
    finally:
        report['duration_seconds'] = round(time.monotonic() - start, 3)
        (output / 'summary.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(f"Windows checks: {report['status']}; TC-44 incomplete (E010)")
    return 0 if report['status'] == 'passed' else 1


if __name__ == '__main__':
    raise SystemExit(main())
