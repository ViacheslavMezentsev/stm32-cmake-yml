"""TC-92: CRC injection lifecycle, localized records and post-build failure."""
import contextlib
import copy
import io
import json
import os
from pathlib import Path
import shutil
import struct
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

from test_firmware_crc_script import build_elf, SCRIPT, ROOT, SHT_PROGBITS, SHF_ALLOC
import stm32_crc
sys.path.insert(0, str(ROOT / 'ci'))
from messages_catalog import load


class InjectionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='crc injection ')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.elf = self.root / 'firmware image.elf'
        self.crc = self.root / 'checksum value.bin'
        self.messages = self.root / 'messages.json'
        self.log = self.root / 'stm32_yml_build_messages.jsonl'
        self.section = '.signature'
        build_elf(self.elf, [('.text', SHT_PROGBITS, SHF_ALLOC, 0x08000000,
                             struct.pack('<I', 0x12345678)),
                            (self.section, SHT_PROGBITS, SHF_ALLOC, 0x08000004, bytes(4))], [])
        previous = copy.deepcopy(stm32_crc.MESSAGES)
        self.addCleanup(lambda: stm32_crc.MESSAGES.update(previous))

    def language(self, lang):
        catalog = load(ROOT / 'cmake/stm32_yml_messages_catalog.cmake')
        self.messages.write_text(json.dumps({'lang': lang, 'codes': True,
            'messages': {k: v[lang] for k, v in catalog.items()}}, ensure_ascii=False), encoding='utf-8')
        self.log.write_text('', encoding='utf-8')

    def args(self, tool, limit='8'):
        return ['--messages', str(self.messages), '--elf', str(self.elf), '--flash',
                '0x08000000:8', '--exclude', self.section, '--objcopy', str(tool), str(self.crc), limit]

    def records(self):
        return [json.loads(line) for line in self.log.read_text(encoding='utf-8').splitlines()]

    def cli(self, tool, limit='8'):
        return subprocess.run([sys.executable, str(SCRIPT), *self.args(tool, limit)],
                              capture_output=True, env=dict(os.environ, PYTHONIOENCODING='cp866', PYTHONUTF8='0'))

    def test_success_records_and_argument_boundaries(self):
        for lang in ('ru', 'en'):
            with self.subTest(lang=lang):
                self.language(lang)
                tool = str(self.root / 'tool with spaces' / 'objcopy')
                with patch.object(stm32_crc.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0)) as run:
                    with contextlib.redirect_stdout(io.StringIO()) as out:
                        stm32_crc.run(self.args(tool))
                run.assert_called_once_with([tool, '--update-section',
                    f'{self.section}={self.crc}', str(self.elf)], capture_output=True)
                self.assertEqual(self.crc.read_bytes(), struct.pack('<I', 0xDF8A8A2B))
                records = self.records()
                self.assertEqual([r['code'] for r in records], ['SCY-I713', 'SCY-I709', 'SCY-I714'])
                self.assertEqual(records[0]['args'], [self.section])
                self.assertEqual(records[-1]['args'], [self.section])
                for record in records:
                    self.assertEqual(record['lang'], lang)
                    self.assertIn(record['text'], out.getvalue())
                    self.assertTrue(record['text'].startswith('[STM32 CRC32]'))

    def test_tool_failures_do_not_report_success_or_calculation_failure(self):
        for lang in ('ru', 'en'):
            for tool, error in ((sys.executable, 'SCY-E713'),
                                (self.root / 'missing objcopy', 'SCY-E714')):
                with self.subTest(lang=lang, error=error):
                    self.language(lang)
                    result = self.cli(tool)
                    self.assertNotEqual(result.returncode, 0)
                    records = self.records()
                    self.assertEqual([r['code'] for r in records], ['SCY-I713', 'SCY-I709', error])
                    self.assertIn(self.section, records[-1]['args'])
                    for line in records[-1]['text'].splitlines():
                        self.assertIn(line, result.stderr.decode('utf-8'))
                    self.assertNotIn('Traceback', result.stderr.decode('utf-8'))
                    self.assertEqual(self.crc.read_bytes(), struct.pack('<I', 0xDF8A8A2B))

    def test_success_keeps_external_tool_diagnostics(self):
        self.language('en')
        with patch.object(stm32_crc.subprocess, 'run',
                          return_value=subprocess.CompletedProcess([], 0, b'output', b'note')):
            with contextlib.redirect_stdout(io.StringIO()):
                stm32_crc.run(self.args('objcopy'))
        self.assertEqual([r['code'] for r in self.records()],
                         ['SCY-I713', 'SCY-I709', 'SCY-I715', 'SCY-I714'])
        self.assertEqual(self.records()[2]['args'], ['output\nnote'])

    def test_calculation_failure_never_launches_objcopy(self):
        self.language('en')
        result = self.cli(self.root / 'missing objcopy', '0')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual([r['code'] for r in self.records()], ['SCY-I713', 'SCY-E706', 'SCY-E708'])
        self.assertFalse(self.crc.exists())

    def test_injection_arguments_are_required(self):
        self.language('en')
        result = subprocess.run([sys.executable, str(SCRIPT), '--messages', str(self.messages),
                                 '--elf', str(self.elf), '--flash', '0x08000000:8',
                                 '--image', str(self.root / 'image.bin'), '--objcopy', sys.executable],
                                capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.records()[0]['code'], 'SCY-E715')
        self.assertFalse(self.crc.exists())

    @unittest.skipUnless(shutil.which('cmake') and shutil.which('ninja'), 'CMake and Ninja required')
    def test_cmake_postbuild_failure_stops_following_commands(self):
        self.language('ru')
        marker = self.root / 'should not exist'
        source = self.root / 'project'
        source.mkdir()
        values = [sys.executable, str(SCRIPT), *self.args(sys.executable)]
        command = ' '.join('"' + value.replace('\\', '/') + '"' for value in values)
        (source / 'CMakeLists.txt').write_text(
            'cmake_minimum_required(VERSION 3.21)\nproject(injection NONE)\n'
            'add_custom_target(probe ALL)\nadd_custom_command(TARGET probe POST_BUILD\n'
            'COMMAND ' + command + '\nCOMMAND "${CMAKE_COMMAND}" -E touch "' + marker.as_posix() + '"\nVERBATIM)\n', encoding='utf-8')
        build = self.root / 'build'
        subprocess.run(['cmake', '-S', str(source), '-B', str(build), '-G', 'Ninja'], check=True, capture_output=True)
        result = subprocess.run(['cmake', '--build', str(build)], capture_output=True,
                                env=dict(os.environ, PYTHONIOENCODING='cp866'))
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(marker.exists())
        self.assertEqual(self.records()[-1]['code'], 'SCY-E713')
        self.assertIn('[STM32 CRC32]', result.stdout.decode('utf-8'))


if __name__ == '__main__':
    unittest.main()
