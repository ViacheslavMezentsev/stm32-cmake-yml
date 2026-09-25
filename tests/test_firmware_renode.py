"""Renode process success must not masquerade as firmware success."""
import os
from pathlib import Path
import stat
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'ci'))
import run_renode_smoke
from run_renode_smoke import classify, resc_path, process_completed, split_line, split_log, PRIORITY_PROBE_WARNING

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

    def test_only_single_known_priority_probe_warning_is_allowed_for_tasks(self):
        warning = '[WARNING] ' + PRIORITY_PROBE_WARNING + '\n'
        completed = 'RENODE_RUN_COMPLETED\n'
        self.assertTrue(process_completed(completed, 'freertosTasks'))
        self.assertTrue(process_completed(warning + completed, 'freertosTasks'))
        self.assertFalse(process_completed(warning + completed, 'success'))
        for bad in (warning * 2 + completed, warning.replace('0xFF', '0x80') + completed,
                    warning + '[ERROR] cpu fault\n' + completed, warning,
                    '[WARNING] unmapped register\n' + completed):
            self.assertFalse(process_completed(bad, 'freertosTasks'))

    def test_paths_escape_spaces_and_reject_script_breaks(self):
        self.assertIn('path\\ with\\ spaces', resc_path(Path('path with spaces')))
        with self.assertRaises(ValueError):
            resc_path(Path('bad\npath'))

    def test_logged_markers_survive_interleaved_console_output(self):
        entry = '02:21:10.0472 [INFO] Script: RENODE_RUN_COMPLETED'
        self.assertEqual(split_line('R' + entry), ['R', 'RENODE_RUN_COMPLETED'])
        self.assertEqual(split_line('enode is qui02:21:01.7712 [INFO] Script: RENODE_CASE_END=12'),
                         ['enode is qui', 'RENODE_CASE_END=12'])
        self.assertEqual(split_line('x02:21:01.7 [ERROR] cpu fault'), ['x', '02:21:01.7 [ERROR] cpu fault'])
        # Only exact logged markers are unwrapped; echoed or foreign text is left as is.
        self.assertEqual(split_line('02:21:10.0472 [INFO] Script: RENODE_RUN_COMPLETED!'),
                         ['02:21:10.0472 [INFO] Script: RENODE_RUN_COMPLETED!'])
        self.assertTrue(process_completed(split_log('R' + entry + '\nenode is quitting\n'), 'success'))


FAKE_RENODE = """#!/usr/bin/env python3
import os, re, sys, time
if '--version' in sys.argv:
    print('Renode, fake'); sys.exit(0)
script = sys.argv[sys.argv.index('--execute') + 1].split('@', 1)[1].replace('\\\\ ', ' ')
index = 0
for line in open(script):
    marker = re.match(r'log "(RENODE_[A-Z_]+(?:=(\\d+))?)"', line)
    if not marker:
        continue
    case = index
    if marker.group(2) is not None:
        index += 1
    if str(case) == os.environ.get('FAKE_SKIP'):
        continue
    if str(case) == os.environ.get('FAKE_HANG'):
        time.sleep(30)
    print('R' if case % 2 else '', end='')
    print('00:00:00.0000 [INFO] Script: ' + marker.group(1), flush=True)
print('Renode is quitting')
"""


@unittest.skipUnless(os.name == "posix", "fake Renode is a POSIX script")
class RenodeBatchTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        base = Path(self.temp.name)
        self.renode = base / 'renode'
        self.renode.write_text(FAKE_RENODE)
        self.renode.chmod(self.renode.stat().st_mode | stat.S_IEXEC)
        self.build = base / 'build'
        self.build.mkdir()
        self.output = base / 'out'
        self.output.mkdir()
        self.root = Path(__file__).resolve().parents[1]
        self.cases = []
        for number in range(3):
            (self.build / f'{number}.elf').write_bytes(b'')
            self.cases.append({'profile': 'hang', 'elf': f'{number}.elf', 'exit_trap': 0x08000100, 'metadata': {}})
        self.addCleanup(self.temp.cleanup)
        self.addCleanup(os.environ.pop, 'FAKE_SKIP', None)
        self.addCleanup(os.environ.pop, 'FAKE_HANG', None)

    def run_batch(self):
        return run_renode_smoke.run_batch_mode(str(self.renode), self.root, self.build, self.output, self.cases, '14.2.1')

    def test_each_case_gets_its_own_completed_segment_and_config(self):
        results = self.run_batch()
        self.assertEqual([r['completed'] for r in results], [True, True, True])
        self.assertTrue(all(r['duration_seconds'] is not None for r in results))
        config = (self.output / 'renode.config').read_text()
        self.assertIn('use-synchronous-logging = True', config)
        self.assertIn('collapse-repeated-log-entries = False', config)
        self.assertIn('Clear', (self.output / 'batch.resc').read_text())

    def test_missing_marker_fails_only_that_case(self):
        os.environ['FAKE_SKIP'] = '1'
        results = self.run_batch()
        self.assertEqual([r['completed'] for r in results], [True, False, True])
        self.assertFalse(results[1]['passed'])

    def test_stalled_case_is_a_host_timeout_for_it_and_later_cases(self):
        os.environ['FAKE_HANG'] = '1'
        original = run_renode_smoke.CASE_TIMEOUT
        run_renode_smoke.CASE_TIMEOUT = 1
        self.addCleanup(setattr, run_renode_smoke, 'CASE_TIMEOUT', original)
        results = self.run_batch()
        self.assertEqual([r['host_timeout'] for r in results], [False, True, True])
        self.assertTrue(all(not r['passed'] for r in results))


if __name__ == '__main__':
    unittest.main()
