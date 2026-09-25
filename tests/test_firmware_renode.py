"""Renode process success must not masquerade as firmware success."""
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'ci'))
from run_renode_smoke import classify, resc_path

HEADER = 'BUILD_TARGET=STM32F103C8T6\nTEST_PLATFORM=cortex-m3-smoke\nCompiler:    GCC 14.2.1\n0xC23 -> Cortex-M3\nPROFILE=success\n'


class RenodeTests(unittest.TestCase):
    def check(self, profile='success', host=0, timeout=False, completed=True, guest=None, text='TEST_RESULT=PASS'):
        return classify(profile, host, timeout, completed, guest, HEADER + text,
                        {'PROFILE': 'success'}, '14.2.1')

    def test_exit_requires_real_guest_reason_and_status(self):
        good = {'operation': 0x20, 'reason': 0x20026, 'status': 0}
        self.assertTrue(self.check(guest=good))
        for guest in (None, {}, dict(good, status=1), dict(good, reason=0), dict(good, operation=0)):
            self.assertFalse(self.check(guest=guest))
        for code in (1, -6):
            self.assertFalse(self.check(host=code, guest=good))
        self.assertFalse(self.check(timeout=True, guest=good))
        self.assertFalse(self.check(completed=False, guest=good))
        self.assertFalse(self.check(guest=good, text='TRANSPORT_ERROR=overflow\nTEST_RESULT=PASS'))

    def test_negative_exits_are_distinct(self):
        for profile, code in [('failure', 1), ('crc-corrupt', 3)]:
            guest = {'operation': 0x20, 'reason': 0x20026, 'status': code}
            self.assertTrue(self.check(profile=profile, guest=guest, text='TEST_RESULT=FAIL'))
            self.assertFalse(self.check(profile=profile, guest=dict(guest, status=2), text='TEST_RESULT=FAIL'))

    def test_hang_requires_completed_virtual_budget_not_host_timeout(self):
        self.assertTrue(self.check(profile='hang', text=''))
        self.assertFalse(self.check(profile='hang', timeout=True, text=''))
        self.assertFalse(self.check(profile='hang', completed=False, text=''))
        self.assertFalse(self.check(profile='hang', text='TEST_RESULT=PASS'))

    def test_paths_escape_spaces_and_reject_script_breaks(self):
        self.assertIn('path\\ with\\ spaces', resc_path(Path('path with spaces')))
        with self.assertRaises(ValueError):
            resc_path(Path('bad\npath'))


if __name__ == '__main__':
    unittest.main()
