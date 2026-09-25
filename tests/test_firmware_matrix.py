"""Matrix discovery and tool selection must not silently omit or reuse pairs."""
import copy
import json
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'ci'))
from firmware_cases import BUILD_PROFILES
from firmware_matrix import pairs, verify_build, verify_matrix


class MatrixTests(unittest.TestCase):
    def test_stale_or_partial_build_matrix_is_rejected(self):
        good = {'status': 'passed', 'phase': 'build', 'pairs': [
            {'gcc': '14', 'cmake': '3', 'status': 'passed', 'profiles': len(BUILD_PROFILES)}]}
        verify_matrix(good, [('14', '3')])
        for key, value in [('status', 'failed'), ('phase', 'run'), ('pairs', [])]:
            bad = copy.deepcopy(good)
            bad[key] = value
            with self.assertRaises(ValueError):
                verify_matrix(bad, [('14', '3')])
        with self.assertRaises(ValueError):
            verify_matrix(good, [('15', '3')])

    def test_every_locked_combination_is_unique(self):
        lock = json.loads((Path(__file__).resolve().parents[1] / 'ci/dependencies.lock.json').read_text())
        actual = pairs(lock)
        self.assertEqual(len(actual), len(lock['gcc_versions']) * len(lock['cmake_versions']))
        self.assertEqual(len(set(actual)), len(actual))

    def test_empty_and_duplicate_lists_fail(self):
        for versions in ([], ['13', '13']):
            with self.assertRaises(ValueError):
                pairs({'gcc_versions': versions, 'cmake_versions': ['3.19.8']})

    def test_wrong_tools_and_incomplete_profiles_fail(self):
        good = {'status': 'passed', 'gcc': '14.2.1', 'cmake': 'cmake version 3.19.8',
                'cases': [{'profile': p} for p in BUILD_PROFILES]}
        verify_build(good, '14.2.1-1.1', '3.19.8')
        for key, value in [('gcc', '13.3.1'), ('cmake', 'cmake version 3.28.3'),
                           ('status', 'failed'), ('cases', []), ('cases', [{'profile': p} for p in BUILD_PROFILES[:-2]]), ('cases', [{'profile': p} for p in ('success', 'failure', 'hang')]),
                           ('cases', [{'profile': 'success'}] * 3)]:
            report = copy.deepcopy(good)
            report[key] = value
            with self.assertRaises(ValueError):
                verify_build(report, '14.2.1-1.1', '3.19.8')


if __name__ == '__main__':
    unittest.main()
