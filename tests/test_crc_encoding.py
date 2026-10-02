"""TC-88: CLI UTF-8 bytes regardless of the host code page (spec 4.16.15)."""
import json
import os
from pathlib import Path
import shutil
import struct
import subprocess
import sys
import tempfile
import unittest

from test_firmware_crc_script import build_elf, SHT_PROGBITS, SHF_ALLOC, SCRIPT


class EncodingTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / 'данные с пробелами'
        self.root.mkdir()
        self.input = self.root / 'вход.bin'
        self.input.write_bytes(struct.pack('<I', 0x12345678))
        self.output = self.root / 'выход.bin'
        self.messages = self.root / 'messages.json'
        self.messages.write_text(json.dumps({'lang': 'ru', 'codes': True, 'messages': {
            'I710': '[STM32 CRC32] Рассчитано: 0x{1} (размер: {2})',
            'I708': '{1} Записан {2}: {3} байт от 0x{4}',
            'E709': "Файл '{1}' не найден.",
            'E708': 'Сборка прервана: CRC не рассчитан.'}}, ensure_ascii=False), encoding='utf-8')

    def env(self, encoding):
        env = dict(os.environ, PYTHONUTF8='0')
        env.pop('PYTHONIOENCODING', None)
        if encoding:
            env['PYTHONIOENCODING'] = encoding
        return env

    def command(self, *args):
        return [sys.executable, str(SCRIPT), '--messages', str(self.messages), *map(str, args)]

    def test_pipe_and_file_bytes(self):
        for encoding in (None, 'cp1251', 'cp866', 'utf-8'):
            for redirected in (False, True):
                for failure in (False, True):
                    with self.subTest(encoding=encoding, file=redirected, failure=failure):
                        source = self.root / 'нет.bin' if failure else self.input
                        command = self.command(source, self.output)
                        if redirected:
                            with tempfile.TemporaryFile() as out, tempfile.TemporaryFile() as err:
                                result = subprocess.run(command, env=self.env(encoding), stdout=out, stderr=err)
                                out.seek(0); err.seek(0)
                                stdout, stderr = out.read(), err.read()
                        else:
                            result = subprocess.run(command, env=self.env(encoding), capture_output=True)
                            stdout, stderr = result.stdout, result.stderr
                        self.assertEqual(result.returncode, 1 if failure else 0)
                        if failure:
                            self.assertEqual(stdout, b'')
                            self.assertEqual(stderr.decode('utf-8').splitlines(), [
                                f"[SCY-E709] Файл '{source}' не найден.",
                                '[SCY-E708] Сборка прервана: CRC не рассчитан.'])
                        else:
                            self.assertEqual(stderr, b'')
                            self.assertEqual(stdout.decode('utf-8').splitlines(), [
                                '[SCY-I710] [STM32 CRC32] Рассчитано: 0xDF8A8A2B (размер: 4)'])
                            self.assertEqual(self.output.read_bytes(), struct.pack('<I', 0xDF8A8A2B))
        records = [json.loads(line) for line in (self.root / 'stm32_yml_build_messages.jsonl').read_bytes().decode('utf-8').splitlines()]
        self.assertEqual(len(records), 24)
        self.assertTrue(all(r['lang'] == 'ru' for r in records))
        self.assertEqual(records[0]['text'], '[STM32 CRC32] Рассчитано: 0xDF8A8A2B (размер: 4)')

    def test_bin_stdout(self):
        elf = self.root / 'образ.elf'
        build_elf(elf, [('.text', SHT_PROGBITS, SHF_ALLOC, 0x08000000, self.input.read_bytes())], [])
        for encoding in ('cp1251', 'cp866'):
            result = subprocess.run(self.command('--elf', elf, '--flash', '0x08000000:1024', '--image', self.output),
                                    env=self.env(encoding), capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout.decode('utf-8').splitlines(), [
                f'[SCY-I708] [STM32 BIN] Записан {self.output}: 4 байт от 0x08000000'])
            self.assertEqual(self.output.read_bytes(), self.input.read_bytes())

    def test_import_preserves_streams(self):
        code = ('import sys, io; sys.path.insert(0, sys.argv[1]); '
                'before=(sys.stdout, sys.stderr, sys.stdout.encoding, sys.stderr.encoding); '
                'import stm32_crc; '
                'assert before == (sys.stdout, sys.stderr, sys.stdout.encoding, sys.stderr.encoding); '
                'sys.stdout=io.StringIO(); sys.stderr=None; '
                'before=(sys.stdout, sys.stderr); stm32_crc.configure_output(); '
                'assert before == (sys.stdout, sys.stderr)')
        result = subprocess.run([sys.executable, '-c', code, str(SCRIPT.parent)], env=self.env('cp866'), capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    @unittest.skipUnless(shutil.which('cmake') and shutil.which('ninja'), 'CMake and Ninja required')
    def test_cmake_post_build(self):
        # A custom target avoids needing a host compiler or any STM32 dependencies.
        source = self.root / 'cmake'
        source.mkdir()
        args = ' '.join(f'"{str(a).replace(chr(92), "/")}"' for a in self.command(self.input, self.output))
        (source / 'CMakeLists.txt').write_text('cmake_minimum_required(VERSION 3.21)\nproject(encoding NONE)\n'
            'add_custom_target(probe ALL)\nadd_custom_command(TARGET probe POST_BUILD COMMAND ' + args + ' VERBATIM)\n', encoding='utf-8')
        build = self.root / 'build'
        configured = subprocess.run(['cmake', '-S', str(source), '-B', str(build), '-G', 'Ninja'], capture_output=True)
        self.assertEqual(configured.returncode, 0, configured.stderr)
        for encoding in ('cp1251', 'cp866'):
            result = subprocess.run(['cmake', '--build', str(build)], env=self.env(encoding), capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('[SCY-I710] [STM32 CRC32] Рассчитано: 0xDF8A8A2B (размер: 4)', result.stdout.decode('utf-8'))


if __name__ == '__main__':
    unittest.main()
