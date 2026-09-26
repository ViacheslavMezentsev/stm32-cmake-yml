"""Only complete matching reports may advertise confirmed firmware counts."""
import copy
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
import xml.etree.ElementTree as ET

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'ci'))
from firmware_cases import BUILD_CASES, BUILD_ONLY_PROFILES, ENABLED_TARGETS, case_name, run_cases
from firmware_badge import collect, svg, main
from publish_firmware_badge import publish


class BadgeTests(unittest.TestCase):
    def setUp(self):
        self.lock = {'gcc_versions': ['14.2.1-1.1'], 'cmake_versions': ['3.28.3']}
        pair = {'gcc': '14.2.1-1.1', 'cmake': '3.28.3', 'status': 'passed', 'profiles': len(BUILD_CASES)}
        build = {'status': 'passed', 'phase': 'build', 'pairs': [pair]}
        run = dict(build, phase='run')
        cases = [{'profile': p, 'metadata': {'PROFILE': p}} for p in BUILD_CASES]
        negatives = [{'profile': case_name(t, 'crc-corrupt'), 'metadata': {'PROFILE': 'success', 'CRC_RESULT': 'FAIL'}}
                     for t in ENABLED_TARGETS]
        compiled = {'status': 'passed', 'gcc': '14.2.1', 'cmake': 'cmake version 3.28.3',
                    'git_revision': 'abc', 'git_dirty': '0', 'cases': cases, 'crc_negatives': negatives,
                    'build_only': [{'profile': p, 'status': 'build-only'} for p in BUILD_ONLY_PROFILES],
                    'crc_limit_negative': {'status': 'failed-as-expected'}}
        executed = {'status': 'passed', 'cases': [dict(profile=c['profile'], passed=True,
                    metadata_ok=True, expected_metadata=c['metadata']) for c in cases + negatives
                    if c['profile'] in run_cases('qemu')]}
        self.reports = [build, run, compiled, executed]

    def count(self, reports):
        with patch('firmware_badge.read', side_effect=reports):
            return collect(Path('build'), Path('run'), self.lock, 'abc')

    def test_counts_builds_separately_from_negative_checks(self):
        result = self.count(self.reports)
        builds = len(BUILD_CASES) + len(BUILD_ONLY_PROFILES)
        checks = len(run_cases('qemu'))
        self.assertEqual((result['builds'], result['checks']), (builds, checks))
        badge = ET.fromstring(svg(result))
        self.assertEqual(badge.attrib['aria-label'], f"Builds (Checks): {result['builds']} ({result['checks']})")
        self.assertFalse(badge.findall('.//{http://www.w3.org/2000/svg}image'))
        self.assertTrue(all('rx' not in r.attrib for r in badge.findall('{http://www.w3.org/2000/svg}rect')))
        self.assertIn(f'{builds} ({checks})', svg(result))

    def test_renode_counts_build_only_runs(self):
        reports = copy.deepcopy(self.reports)
        expected = {c['profile']: c['metadata'] for c in reports[2]['cases'] + reports[2]['crc_negatives']}
        reports[3]['cases'] = [dict(profile=p, passed=True, metadata_ok=True, expected_metadata=expected[p])
                               for p in run_cases('renode')]
        reports[3]['build_only'] = [{'profile': p, 'passed': True} for p in BUILD_ONLY_PROFILES]
        with patch('firmware_badge.read', side_effect=reports):
            result = collect(Path('build'), Path('run'), self.lock, 'abc', 'renode')
        self.assertEqual(result['checks'], len(run_cases('renode')) + len(BUILD_ONLY_PROFILES))
        for change in ('missing', 'failed'):
            reports = copy.deepcopy(self.reports)
            reports[3]['build_only'] = [{'profile': p, 'passed': True} for p in BUILD_ONLY_PROFILES]
            if change == 'missing': reports[3]['build_only'].pop()
            if change == 'failed': reports[3]['build_only'][0]['passed'] = False
            with self.subTest(change=change), self.assertRaises(ValueError), \
                    patch('firmware_badge.read', side_effect=reports):
                collect(Path('build'), Path('run'), self.lock, 'abc', 'renode')

    def test_rejects_failed_missing_duplicate_or_stale_results(self):
        for change in ('failed', 'missing', 'duplicate', 'stale', 'dirty', 'metadata', 'matrix', 'buildonly'):
            reports = copy.deepcopy(self.reports)
            if change == 'failed': reports[3]['cases'][0]['passed'] = False
            if change == 'missing': reports[3]['cases'].pop()
            if change == 'duplicate': reports[3]['cases'][1] = reports[3]['cases'][0]
            if change == 'stale': reports[2]['git_revision'] = 'old'
            if change == 'dirty': reports[2]['git_dirty'] = '1'
            if change == 'metadata': reports[3]['cases'][0]['expected_metadata'] = {}
            if change == 'matrix': reports[1]['pairs'] = []
            if change == 'buildonly': reports[2]['build_only'].pop()
            with self.subTest(change=change), self.assertRaises(ValueError):
                self.count(reports)

    def test_old_run_cannot_replace_main_badge(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)
            (path / 'firmware.json').write_text(json.dumps({'revision': 'old'}))
            with patch('publish_firmware_badge.git', return_value='new\trefs/heads/main') as git:
                publish(path, 'old')
                self.assertEqual(git.call_count, 1)

    def test_combined_badge_does_not_double_count_builds(self):
        with tempfile.TemporaryDirectory() as directory:
            argv = ['badge', '--build', 'build', '--run', 'qemu', '--renode-run', 'renode',
                    '--output', directory, '--revision', 'abc', '--run-url', 'https://example.invalid/run']
            results = [{'builds': 72, 'checks': 78, 'emulator': e, 'revision': 'abc'} for e in ('QEMU', 'Renode')]
            with patch.object(sys, 'argv', argv), patch('firmware_badge.read', return_value=self.lock), \
                    patch('firmware_badge.collect', side_effect=results):
                main()
            report = json.loads((Path(directory) / 'firmware.json').read_text())
            self.assertEqual((report['builds'], report['checks']), (72, 156))
            self.assertEqual(report['checks_by_emulator'], {'QEMU': 78, 'Renode': 78})
            ET.fromstring((Path(directory) / 'firmware.svg').read_text())
            endpoint = json.loads((Path(directory) / 'counts.json').read_text())
            self.assertEqual(endpoint['message'], '72 (156)')
            self.assertEqual(endpoint['color'], '238636')


if __name__ == '__main__':
    unittest.main()
