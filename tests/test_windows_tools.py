"""TC-90: pinned Windows installer rejects corrupt archives and escaping paths."""
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'ci'))
import install_windows


class WindowsToolsTests(unittest.TestCase):
    def test_verified_extraction_and_rejections(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / 'ci').mkdir()
            cache = root / 'cache'
            cache.mkdir()
            archive = cache / 'tool.zip'
            def prepare(member, digest=None):
                with zipfile.ZipFile(archive, 'w') as zipped:
                    zipped.writestr(member, b'tool')
                lock = {'archives': [{'name': 'cmake', 'filename': 'tool.zip', 'url': 'unused',
                        'sha256': digest or hashlib.sha256(archive.read_bytes()).hexdigest()}]}
                (root / 'ci/windows.lock.json').write_text(json.dumps(lock), encoding='utf-8')
            with patch.object(install_windows, 'ROOT', root):
                prepare('distribution/bin/tool.exe', '0' * 64)
                with self.assertRaisesRegex(ValueError, 'SHA-256 mismatch'):
                    install_windows.install(root / 'bad-hash', cache)
                self.assertFalse((root / 'bad-hash/installed-lock.json').exists())
                prepare('distribution/../../escape')
                with self.assertRaisesRegex(ValueError, 'escapes destination'):
                    install_windows.install(root / 'bad-path', cache)
                self.assertFalse((root / 'escape').exists())
                prepare('distribution/bin/tool.exe')
                install_windows.install(root / 'good', cache)
                self.assertEqual((root / 'good/cmake/bin/tool.exe').read_bytes(), b'tool')
                self.assertTrue((root / 'good/installed-lock.json').is_file())


if __name__ == '__main__':
    unittest.main()
