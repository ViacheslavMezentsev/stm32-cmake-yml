"""TC-83: versions of stm32-cmake and Arduino Core STM32 (spec 4.2.6, 4.2.7).

The CMake functions run in script mode (cmake -P) on temporary directories:
a git clone with a tag, a clone without tags (shallow), a copy without .git,
and a directory without version data.
"""
from pathlib import Path
import os
import json
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

    def version(self, function, directory, options=(), env=None):
        script = self.dir / 'probe.cmake'
        script.write_text('cmake_minimum_required(VERSION 3.21)\n'
                          f'include("{ROOT.as_posix()}/cmake/stm32_yml_versions.cmake")\n'
                          f'{function}("{directory.as_posix()}" _v)\nmessage("RESULT=[${{_v}}]")\n', encoding='utf-8')
        result = subprocess.run([CMAKE, *options, '-P', str(script)], capture_output=True, text=True, check=True, env=env)
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
        commit = subprocess.check_output([GIT, '-C', str(directory), 'rev-parse', '--short=7', 'HEAD'], text=True).strip()
        return directory, commit

    CHANGELOG = '# Change log\n\n## v2.1.0 (2021/08/09)\n\n## v2.0 (2020/11/01)\n'

    def test_stm32_cmake_tag(self):
        directory, _ = self.repo('tagged', {'CHANGELOG.md': self.CHANGELOG}, tag='v2.2.0')
        self.assertEqual(self.version('stm32_yml_stm32_cmake_version', directory), 'v2.2.0')

    def test_stm32_cmake_without_tags(self):
        directory, commit = self.repo('untagged', {'CHANGELOG.md': self.CHANGELOG})
        self.assertEqual(self.version('stm32_yml_stm32_cmake_version', directory), 'v2.1.0+')

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


    def test_git_identity_clean_modified_staged_untracked_and_ignored(self):
        directory, sha = self.repo('module', {'file': 'original', '.gitignore': '*.ignored\n'})
        suffix = lambda: self.version('_stm32_yml_git_suffix', directory)
        self.assertEqual(suffix(), f' (commit: {sha})')
        (directory / 'build.ignored').write_text('ignored')
        self.assertEqual(suffix(), f' (commit: {sha})')
        (directory / 'file').write_text('modified')
        self.assertEqual(suffix(), f' (commit: {sha}, modified)')
        git(directory, 'add', 'file')
        self.assertEqual(suffix(), f' (commit: {sha}, modified)')
        git(directory, 'reset', '--hard', 'HEAD')  # Only the temporary fixture.
        (directory / 'new.txt').write_text('untracked')
        self.assertEqual(suffix(), f' (commit: {sha}, modified)')

    def test_git_identity_path_alias(self):
        directory, sha = self.repo('long module name', {'file': 'original'})
        aliases = [directory / '..' / directory.name]
        if os.name == 'nt':
            import ctypes
            buffer = ctypes.create_unicode_buffer(32768)
            size = ctypes.windll.kernel32.GetShortPathNameW(str(directory), buffer, len(buffer))
            self.assertTrue(0 < size < len(buffer))
            # On volumes without 8.3 names this is the original spelling.
            aliases.append(Path(buffer.value))
        for alias in aliases:
            with self.subTest(path=str(alias)):
                self.assertEqual(self.version('_stm32_yml_git_suffix', alias), f' (commit: {sha})')

    def test_separate_modules_and_inherited_git_environment(self):
        first, sha1 = self.repo('framework module', {'framework': 'one'})
        second, sha2 = self.repo('backend module', {'backend': 'two'})
        self.assertNotEqual(sha1, sha2)
        env = dict(os.environ, GIT_DIR=str(first / '.git'), GIT_WORK_TREE=str(first))
        self.assertEqual(self.version('_stm32_yml_git_suffix', second, env=env), f' (commit: {sha2})')
        self.assertEqual(self.version('_stm32_yml_git_suffix', first), f' (commit: {sha1})')

    def test_copy_inside_foreign_repository_has_no_identity(self):
        parent, _ = self.repo('parent', {'project': 'one'})
        copied = parent / 'copied module'
        copied.mkdir()
        (copied / 'CHANGELOG.md').write_text(self.CHANGELOG)
        self.assertEqual(self.version('_stm32_yml_git_suffix', copied), '')
        self.assertEqual(self.version('stm32_yml_stm32_cmake_version', copied), 'v2.1.0+')

    def test_missing_git_broken_metadata_and_unborn_repository(self):
        directory, _ = self.repo('no git program', {'CHANGELOG.md': self.CHANGELOG})
        disabled = ('-DCMAKE_DISABLE_FIND_PACKAGE_Git=TRUE',)
        self.assertEqual(self.version('_stm32_yml_git_suffix', directory, disabled), '')
        self.assertEqual(self.version('stm32_yml_stm32_cmake_version', directory, disabled), 'v2.1.0+')
        broken = self.dir / 'broken'
        broken.mkdir()
        (broken / '.git').write_text('gitdir: does-not-exist\n')
        self.assertEqual(self.version('_stm32_yml_git_suffix', broken), '')
        unborn = self.dir / 'unborn'
        unborn.mkdir()
        git(unborn, 'init', '-q')
        self.assertEqual(self.version('_stm32_yml_git_suffix', unborn), '')

    def test_worktree_ignores_changes_in_other_worktree(self):
        original, sha = self.repo('original', {'file': 'original'}, tag='v2.2.0')
        worktree = self.dir / 'linked worktree'
        git(original, 'worktree', 'add', '--detach', str(worktree), 'HEAD')
        self.assertTrue((worktree / '.git').is_file())
        (original / 'file').write_text('unrelated change')
        self.assertEqual(self.version('_stm32_yml_git_suffix', worktree), f' (commit: {sha})')
        self.assertEqual(self.version('stm32_yml_stm32_cmake_version', worktree), 'v2.2.0')
        (worktree / 'file').write_text('local change')
        self.assertEqual(self.version('_stm32_yml_git_suffix', worktree), f' (commit: {sha}, modified)')

    def test_submodule_ignores_parent_changes(self):
        upstream, sha = self.repo('upstream module', {'file': 'original'})
        parent, _ = self.repo('superproject', {'project': 'one'})
        git(parent, '-c', 'protocol.file.allow=always', 'submodule', 'add', str(upstream), 'module')
        module = parent / 'module'
        self.assertTrue((module / '.git').is_file())
        (parent / 'project').write_text('parent-only change')
        self.assertEqual(self.version('_stm32_yml_git_suffix', module), f' (commit: {sha})')
        (module / 'file').write_text('module change')
        self.assertEqual(self.version('_stm32_yml_git_suffix', module), f' (commit: {sha}, modified)')

    def test_bilingual_version_messages_keep_package_and_commit_separate(self):
        framework, first = self.repo('framework', {'file': 'framework'})
        backend, second = self.repo('backend', {'CHANGELOG.md': self.CHANGELOG})
        (framework / 'file').write_text('modified framework')
        for lang, matched, unknown in [('ru', '(совпадают)', 'версия не определена'),
                                       ('en', '(match)', 'version unknown')]:
            script = self.dir / 'messages.cmake'
            script.write_text(f'''cmake_minimum_required(VERSION 3.21)
include("{ROOT.as_posix()}/cmake/stm32_yml_messages.cmake")
include("{ROOT.as_posix()}/cmake/stm32_yml_versions.cmake")
_stm32_yml_git_suffix("{framework.as_posix()}" _framework)
stm32_yml_msg(I001 "0.10.1" "${{_framework}}")
stm32_yml_msg(I003 "0.10.1")
_stm32_yml_git_suffix("{backend.as_posix()}" _backend)
stm32_yml_stm32_cmake_version("{backend.as_posix()}" _version)
_stm32_yml_print_version("stm32-cmake" "${{_version}}" "${{_backend}}")
_stm32_yml_print_version("unknown-module" "" "${{_backend}}")
_stm32_yml_print_version("copied-module" "0.10.1")
''', encoding='utf-8')
            result = subprocess.run([CMAKE, f'-DSTM32_YML_LANG={lang}', '-P', str(script)],
                                    cwd=self.dir, capture_output=True, encoding='utf-8')
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            records = [json.loads(line) for line in (self.dir / 'stm32_yml_messages.jsonl').read_text(encoding='utf-8').splitlines()]
            by_code = {r['code']: r for r in records if r['code'] in ('SCY-I001', 'SCY-I003', 'SCY-I044')}
            self.assertEqual(by_code['SCY-I001']['args'], ['0.10.1', f' (commit: {first}, modified)'])
            self.assertEqual(by_code['SCY-I001']['text'], f'stm32-cmake-yml: 0.10.1 (commit: {first}, modified)')
            self.assertTrue(by_code['SCY-I003']['text'].endswith(f'0.10.1 {matched}'))
            self.assertIn(f'{unknown} (commit: {second})', by_code['SCY-I044']['text'])
            self.assertIn(f'stm32-cmake: v2.1.0+ (commit: {second})', result.stdout)
            self.assertIn('copied-module: 0.10.1', result.stdout)
            self.assertNotIn('✓', result.stdout)


if __name__ == '__main__':
    unittest.main()
