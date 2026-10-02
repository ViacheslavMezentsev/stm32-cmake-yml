"""Fast native host checks (spec 8.5.9); not the full TC-44 job."""
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import sys
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]
PATTERNS = ('test_crc_encoding.py', 'test_crc_injection.py', 'test_firmware_crc_script.py', 'test_component_versions.py', 'test_windows_tools.py')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    report = {'status': 'failed', 'platform': sys.platform, 'python': sys.version,
              'patterns': PATTERNS, 'tools': {}}
    started = time.monotonic()
    try:
        for tool in ('cmake', 'ninja', 'git'):
            path = shutil.which(tool)
            if not path:
                raise RuntimeError(f'Required tool missing: {tool}')
            result = subprocess.run([path, '--version'], capture_output=True, check=True, timeout=30)
            report['tools'][tool] = result.stdout.decode('utf-8').strip()
        loader = unittest.TestLoader()
        suite = unittest.TestSuite()
        for pattern in PATTERNS:
            selected = loader.discover(str(ROOT / 'tests'), pattern=pattern)
            if not selected.countTestCases():
                raise RuntimeError(f'No tests found: {pattern}')
            suite.addTests(selected)
        with (args.output / 'tests.log').open('w', encoding='utf-8') as log:
            result = unittest.TextTestRunner(stream=log, verbosity=2).run(suite)
        report.update(tests=result.testsRun, failures=len(result.failures), errors=len(result.errors),
                      skipped=len(result.skipped), expected_failures=len(result.expectedFailures))
        if result.wasSuccessful() and result.testsRun and not result.skipped and not result.expectedFailures:
            report['status'] = 'passed'
    except (OSError, RuntimeError, subprocess.SubprocessError, UnicodeError) as error:
        report['error'] = str(error)
    finally:
        report['duration_seconds'] = round(time.monotonic() - started, 3)
        (args.output / 'summary.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(f"Host checks: {report['status']}; see {args.output}")
    return 0 if report['status'] == 'passed' else 1


if __name__ == '__main__':
    raise SystemExit(main())
