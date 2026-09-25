"""Badge labels must reflect conclusions and publishers must preserve siblings."""
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'ci'))
from workflow_badges import endpoint
from publish_firmware_badge import publish_files


class StatusBadgeTests(unittest.TestCase):
    def test_success_failure_and_non_results_are_distinct(self):
        for conclusion, message in [('success', 'PASS'), ('failure', 'FAIL'),
                                    ('timed_out', 'FAIL'), ('cancelled', 'CANCEL'),
                                    ('skipped', 'SKIP'), ('neutral', 'N/A')]:
            run = {'conclusion': conclusion, 'html_url': 'https://example.test/run', 'head_sha': 'abc'}
            badge = endpoint('Configure', run)
            self.assertEqual(badge['message'], message)
            if message == 'PASS':
                self.assertEqual(badge['color'], '238636')
        self.assertEqual(endpoint('Docs', None)['message'], 'N/A')

    def test_publishing_preserves_other_badges(self):
        previous = ('100644 blob old-count\tcounts.json\n'
                    '100644 blob old-status\tconfigure-status.json\n'
                    '100644 blob old-report\tfirmware.json')
        with patch('publish_firmware_badge.git', side_effect=[
                'parent\trefs/heads/ci-badges', '', 'parent', previous,
                'new-status', 'tree', 'commit', '']) as git:
            publish_files(Path('unused'), ['configure-status.json'], 'Update')
        tree_input = git.call_args_list[5].kwargs['text']
        self.assertIn('old-count\tcounts.json\n', tree_input)
        self.assertIn('old-report\tfirmware.json\n', tree_input)
        self.assertIn('new-status\tconfigure-status.json\n', tree_input)
        self.assertNotIn('old-status', tree_input)
        self.assertEqual(git.call_args_list[-1].args, ('push', 'origin', 'commit:refs/heads/ci-badges'))


if __name__ == '__main__':
    unittest.main()
