"""Host failures must be visible in Actions, not only in uploaded files."""
import contextlib
import io
import json
from pathlib import Path
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'ci'))
import run_host_checks


class HostDiagnosticsTests(unittest.TestCase):
    def test_failed_test_is_printed_and_remains_blocking(self):
        def fail():
            raise AssertionError('host diagnostic sentinel')

        def discover(*args, **kwargs):
            return unittest.TestSuite([unittest.FunctionTestCase(fail)])

        with tempfile.TemporaryDirectory() as directory:
            output = io.StringIO()
            with patch.object(sys, 'argv', ['run_host_checks', '--output', directory]), \
                    patch.object(run_host_checks.shutil, 'which', return_value='tool'), \
                    patch.object(run_host_checks.subprocess, 'run', return_value=SimpleNamespace(stdout=b'version')), \
                    patch.object(unittest.TestLoader, 'discover', side_effect=discover), \
                    contextlib.redirect_stdout(output):
                self.assertEqual(run_host_checks.main(), 1)
            self.assertIn('AssertionError: host diagnostic sentinel', output.getvalue())
            self.assertIn('Traceback', output.getvalue())
            report = json.loads((Path(directory) / 'summary.json').read_text(encoding='utf-8'))
            self.assertEqual(report['status'], 'failed')
            self.assertEqual(report['failures'], len(run_host_checks.PATTERNS))
            self.assertIn('host diagnostic sentinel', (Path(directory) / 'tests.log').read_text(encoding='utf-8'))


if __name__ == '__main__':
    unittest.main()
