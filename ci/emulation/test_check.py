"""Regressions for false-positive environment checks; no emulator required."""
import unittest
from unittest.mock import patch
import subprocess
import check


class CheckTests(unittest.TestCase):
    def test_local_newer_but_ci_exact(self):
        output = 'QEMU emulator version 11.1.0 (custom build)'
        self.assertEqual(check.version(output, 'qemu', '11.0.0', False), '11.1.0')
        with self.assertRaises(ValueError):
            check.version(output, 'qemu', '11.0.0', True)

    def test_old_and_unrecognized_versions(self):
        for output in ('QEMU emulator version 9.2.0', 'other program 11.0.0'):
            with self.assertRaises(ValueError):
                check.version(output, 'qemu', '11.0.0', False)

    def test_renode_build_suffix(self):
        self.assertEqual(check.version('Renode v1.16.1.19220', 'renode', '1.16.1', True), '1.16.1')

    def test_machine_names_are_exact(self):
        with self.assertRaises(ValueError):
            check.machines('netduinoplus2 description', ['netduino2'])
        self.assertEqual(check.machines('netduino2 description', ['netduino2']), ['netduino2'])

    def test_invalid_override_does_not_fall_back(self):
        with patch('check.shutil.which', return_value=__file__):
            with self.assertRaises(ValueError):
                check.executable('/nonexistent/emulator', 'qemu-system-arm')

    def test_errors_and_timeouts_are_not_success(self):
        with patch('check.subprocess.run', return_value=subprocess.CompletedProcess([], 1, '', 'broken')):
            with self.assertRaisesRegex(ValueError, 'broken'):
                check.run('fake', '--version')
        with patch('check.subprocess.run', side_effect=subprocess.TimeoutExpired('fake', 30)):
            with self.assertRaises(subprocess.TimeoutExpired):
                check.run('fake', '--version')


if __name__ == '__main__':
    unittest.main()
