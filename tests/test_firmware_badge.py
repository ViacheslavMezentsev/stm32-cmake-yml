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
from firmware_cases import BUILD_PROFILES
from firmware_badge import collect, svg, main
from publish_firmware_badge import publish


class BadgeTests(unittest.TestCase):
    def setUp(self):
        self.lock = {'gcc_versions': ['14.2.1-1.1'], 'cmake_versions': ['3.28.3']}
        pair = {'gcc': '14.2.1-1.1', 'cmake': '3.28.3', 'status': 'passed', 'profiles': len(BUILD_PROFILES)}
        build = {'status': 'passed', 'phase': 'build', 'pairs': [pair]}
        run = dict(build, phase='run')
        cases = [{'profile': p, 'metadata': {'PROFILE': p}} for p in BUILD_PROFILES]
        negative = {'profile': 'crc-corrupt', 'metadata': {'PROFILE': 'success', 'CRC_RESULT': 'FAIL'}}
        compiled = {'status': 'passed', 'gcc': '14.2.1', 'cmake': 'cmake version 3.28.3',
                    'git_revision': 'abc', 'git_dirty': '0', 'cases': cases, 'crc_negative': negative}
        executed = {'status': 'passed', 'cases': [dict(profile=c['profile'], passed=True,
                    metadata_ok=True, expected_metadata=c['metadata']) for c in cases + [negative]]}
        self.reports = [build, run, compiled, executed]

    def count(self, reports):
        with patch('firmware_badge.read', side_effect=reports):
            return collect(Path('build'), Path('run'), self.lock, 'abc')

    def test_counts_builds_separately_from_negative_checks(self):
        result = self.count(self.reports)
        self.assertEqual((result['builds'], result['checks']), (len(BUILD_PROFILES), len(BUILD_PROFILES) + 1))
        ET.fromstring(svg(result))
        self.assertIn(f'{len(BUILD_PROFILES)} builds / {len(BUILD_PROFILES) + 1} checks', svg(result))

    def test_rejects_failed_missing_duplicate_or_stale_results(self):
        for change in ('failed', 'missing', 'duplicate', 'stale', 'dirty', 'metadata', 'matrix'):
            reports = copy.deepcopy(self.reports)
            if change == 'failed': reports[3]['cases'][0]['passed'] = False
            if change == 'missing': reports[3]['cases'].pop()
            if change == 'duplicate': reports[3]['cases'][1] = reports[3]['cases'][0]
            if change == 'stale': reports[2]['git_revision'] = 'old'
            if change == 'dirty': reports[2]['git_dirty'] = '1'
            if change == 'metadata': reports[3]['cases'][0]['expected_metadata'] = {}
            if change == 'matrix': reports[1]['pairs'] = []
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
            results = [{'builds': 54, 'checks': 60, 'emulator': e, 'revision': 'abc'} for e in ('QEMU', 'Renode')]
            with patch.object(sys, 'argv', argv), patch('firmware_badge.read', return_value=self.lock), \
                    patch('firmware_badge.collect', side_effect=results):
                main()
            report = json.loads((Path(directory) / 'firmware.json').read_text())
            self.assertEqual((report['builds'], report['checks']), (54, 120))
            self.assertEqual(report['checks_by_emulator'], {'QEMU': 60, 'Renode': 60})
            ET.fromstring((Path(directory) / 'firmware.svg').read_text())


if __name__ == '__main__':
    unittest.main()
