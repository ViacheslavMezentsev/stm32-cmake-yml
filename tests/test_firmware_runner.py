"""Ensure guest failures, crashes and timeouts cannot masquerade as passing tests."""
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'ci'))
from run_qemu_smoke import verdict, metadata_matches

HEADER = 'BUILD_TARGET=STM32F103C8T6\nEMULATOR_MACHINE=netduino2\n  Compiler:    GCC 14.2.1\n0xC23 -> Cortex-M3\n'


class VerdictTests(unittest.TestCase):
    def test_crc_corruption_requires_dedicated_exit(self):
        output = HEADER + 'TEST_RESULT=FAIL'
        self.assertTrue(verdict('crc-corrupt', 3, False, output, '14.2.1'))
        for code in (0, 1, 2, -6):
            self.assertFalse(verdict('crc-corrupt', code, False, output, '14.2.1'))
        self.assertFalse(verdict('crc-corrupt', None, True, output, '14.2.1'))

    def test_metadata_requires_all_fields_and_exact_values(self):
        expected = {'PROFILE': 'success', 'BSS_INIT': '00000000'}
        self.assertTrue(metadata_matches('PROFILE=success\nBSS_INIT=00000000\n', expected))
        for output in ('PROFILE=success', 'PROFILE=failure\nBSS_INIT=00000000',
                       'PROFILE=success\nBSS_INIT=DEADBEEF',
                       'PROFILE=success\nBSS_INIT=00000000\nPROFILE=success'):
            self.assertFalse(metadata_matches(output, expected))
        self.assertFalse(metadata_matches('', {}))

    def test_success_requires_marker_and_exit_zero(self):
        self.assertTrue(verdict('success', 0, False, HEADER + 'TEST_RESULT=PASS\n', '14.2.1'))
        for code, timeout, output in [(0, False, HEADER), (1, False, HEADER + 'TEST_RESULT=PASS'),
                                      (None, True, HEADER + 'TEST_RESULT=PASS')]:
            self.assertFalse(verdict('success', code, timeout, output, '14.2.1'))

    def test_guest_failure_is_not_an_arbitrary_crash(self):
        self.assertTrue(verdict('failure', 1, False, HEADER + 'TEST_RESULT=FAIL', '14.2.1'))
        for code in (0, -6, 2):
            self.assertFalse(verdict('failure', code, False, HEADER + 'TEST_RESULT=FAIL', '14.2.1'))
        self.assertFalse(verdict('failure', 1, False, HEADER, '14.2.1'))

    def test_timeout_requires_reaching_firmware(self):
        self.assertTrue(verdict('hang', None, True, HEADER, '14.2.1'))
        self.assertFalse(verdict('hang', None, True, '', '14.2.1'))
        self.assertFalse(verdict('hang', 0, False, HEADER, '14.2.1'))
        self.assertFalse(verdict('hang', None, True, HEADER + 'TEST_RESULT=PASS', '14.2.1'))

    def test_metadata_and_result_are_unambiguous(self):
        good = HEADER + 'TEST_RESULT=PASS'
        self.assertFalse(verdict('success', 0, False, good, '15.2.1'))
        self.assertFalse(verdict('success', 0, False, good.replace('Cortex-M3', 'Cortex-M4'), '14.2.1'))
        self.assertFalse(verdict('success', 0, False, good + '\nTEST_RESULT=FAIL', '14.2.1'))


if __name__ == '__main__':
    unittest.main()
