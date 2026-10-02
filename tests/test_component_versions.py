"""TC-83: versions of stm32-cmake and Arduino Core STM32 (spec 4.2.6, 4.2.7).

The CMake functions run in script mode (cmake -P) on temporary directories:
a git clone with a tag, a clone without tags (shallow), a copy without .git,
and a directory without version data.
"""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
CMAKE = shutil.which('cmake')
GIT = shutil.which('git')


def git(directory, *args):
    subprocess.run([GIT, '-C', str(directory), *args], check=True, capture_output=True,
                   env=dict(os.environ, GIT_AUTHOR_NAME='t', GIT_AUTHOR_EMAIL='t@t',
                            GIT_COMMITTER_NAME='t', GIT_COMMITTER_EMAIL='t@t',
                            GIT_CONFIG_NOSYSTEM='1', GIT_CONFIG_GLOBAL=os.devnull))


@unittest.skipUnless(CMAKE and GIT, 'cmake and git are required')
class ComponentVersionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='component versions ')
        self.addCleanup(self.temp.cleanup)
        self.dir = Path(self.temp.name)

    def version(self, function, directory):
        script = self.dir / 'probe.cmake'
        script.write_text(f'include("{ROOT.as_posix()}/cmake/stm32_yml_versions.cmake")\n'
                          f'{function}("{directory.as_posix()}" _v)\nmessage("RESULT=[${{_v}}]")\n', encoding='utf-8')
        result = subprocess.run([CMAKE, '-P', str(script)], capture_output=True, text=True, check=True)
        return result.stderr.split('RESULT=[', 1)[1].split(']', 1)[0]

    def repo(self, name, files, tag=None):
        directory = self.dir / name
        directory.mkdir()
        for filename, text in files.items():
            (directory / filename).write_text(text, encoding='utf-8')
        git(directory, 'init', '-q')
        git(directory, 'add', '.')
        git(directory, 'commit', '-q', '-m', 'init')
        if tag:
            git(directory, 'tag', tag)
        commit = subprocess.check_output([GIT, '-C', str(directory), 'rev-parse', '--short', 'HEAD'], text=True).strip()
        return directory, commit

    CHANGELOG = '# Change log\n\n## v2.1.0 (2021/08/09)\n\n## v2.0 (2020/11/01)\n'

    def test_stm32_cmake_tag(self):
        directory, _ = self.repo('tagged', {'CHANGELOG.md': self.CHANGELOG}, tag='v2.2.0')
        self.assertEqual(self.version('stm32_yml_stm32_cmake_version', directory), 'v2.2.0')

    def test_stm32_cmake_without_tags(self):
        directory, commit = self.repo('untagged', {'CHANGELOG.md': self.CHANGELOG})
        self.assertEqual(self.version('stm32_yml_stm32_cmake_version', directory), f'v2.1.0+ ({commit})')

    def test_stm32_cmake_without_git(self):
        directory = self.dir / 'copy'
        directory.mkdir()
        (directory / 'CHANGELOG.md').write_text(self.CHANGELOG, encoding='utf-8')
        self.assertEqual(self.version('stm32_yml_stm32_cmake_version', directory), 'v2.1.0+')

    def test_unknown_versions_are_empty(self):
        (self.dir / 'empty').mkdir()
        self.assertEqual(self.version('stm32_yml_stm32_cmake_version', self.dir / 'empty'), '')
        self.assertEqual(self.version('stm32_yml_stm32_cmake_version', self.dir / 'missing'), '')
        self.assertEqual(self.version('stm32_yml_arduino_core_version', self.dir / 'missing'), '')

    def test_arduino_core(self):
        directory, commit = self.repo('core', {'platform.txt': 'name=STM32\nversion=2.12.0\n'})
        self.assertEqual(self.version('stm32_yml_arduino_core_version', directory), f'2.12.0 ({commit})')
        copied = self.dir / 'core copy'
        shutil.copytree(directory, copied, ignore=shutil.ignore_patterns('.git'))
        self.assertEqual(self.version('stm32_yml_arduino_core_version', copied), '2.12.0')


if __name__ == '__main__':
    unittest.main()
