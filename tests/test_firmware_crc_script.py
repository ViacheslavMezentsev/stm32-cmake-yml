"""Post-build CRC script: vectors, failures and the FLASH image built from ELF sections.

Spec: 4.15.3 (algorithm, appendix B vectors), 4.15.7 (failure breaks the build,
no zero stub), 4.15.9 (image from sections loaded into FLASH), 5.6.2 (interface).
Test cases TC-43, TC-63 (host part).
"""
from pathlib import Path
import struct
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'scripts/stm32_crc.py'
sys.path.insert(0, str(ROOT / 'scripts'))
from stm32_crc import flash_image, stm32_crc32  # noqa: E402

SHT_PROGBITS, SHT_STRTAB, SHT_NOBITS, SHT_INIT_ARRAY = 1, 3, 8, 14
SHF_WRITE, SHF_ALLOC, SHF_EXEC = 1, 2, 4


def build_elf(path, sections, segments):
    """Write a minimal ELF32 ARM file.

    sections: (name, type, flags, address, bytes or size for NOBITS).
    segments: (section name, physical address) PT_LOAD entries.
    """
    names = b'\0'
    name_offsets = {}
    for name, *_ in sections + [('.shstrtab',)]:
        name_offsets[name] = len(names)
        names += name.encode() + b'\0'
    body = bytearray()
    offsets = {}
    data_start = 52 + 32 * len(segments)
    for name, kind, _, _, content in sections:
        offsets[name] = data_start + len(body)
        if kind != SHT_NOBITS:
            body += content
    strtab_offset = data_start + len(body)
    body += names
    while len(body) % 4:
        body += b'\0'
    shoff = data_start + len(body)
    headers = [bytes(40)]
    for name, kind, flags, address, content in sections:
        size = content if kind == SHT_NOBITS else len(content)
        headers.append(struct.pack('<10I', name_offsets[name], kind, flags, address,
                                   offsets[name], size, 0, 0, 4, 0))
    headers.append(struct.pack('<10I', name_offsets['.shstrtab'], SHT_STRTAB, 0, 0,
                               strtab_offset, len(names), 0, 0, 1, 0))
    program = b''
    by_name = {name: (address, content) for name, _, _, address, content in sections}
    for name, physical in segments:
        address, content = by_name[name]
        program += struct.pack('<8I', 1, offsets[name], address, physical, len(content),
                               len(content), 6, 4)
    ident = b'\x7fELF' + bytes([1, 1, 1]) + bytes(9)
    header = ident + struct.pack('<HHIIIIIHHHHHH', 2, 40, 1, 0x08000001, 52, shoff, 0x05000000,
                                 52, 32, len(segments), 40, len(headers), len(headers) - 1)
    Path(path).write_bytes(header + program + bytes(body) + b''.join(headers))


def run_script(*args):
    return subprocess.run([sys.executable, str(SCRIPT), *map(str, args)],
                          capture_output=True, text=True, encoding='utf-8')


class CrcVectorsTests(unittest.TestCase):
    def test_appendix_b_vectors(self):
        self.assertEqual(stm32_crc32(struct.pack('<I', 0x12345678)), 0xDF8A8A2B)
        self.assertEqual(stm32_crc32(struct.pack('<I', 0x00000000)), 0xC704DD7B)
        self.assertEqual(stm32_crc32(struct.pack('<II', 0x12345678, 0x9ABCDEF0)), 0x7D24A31B)
        # A partial last word is padded with 0xFF like erased FLASH.
        self.assertEqual(stm32_crc32(bytes([1, 2, 3])), 0xEE3E0B31)
        self.assertEqual(stm32_crc32(bytes([1, 2, 3])), stm32_crc32(bytes([1, 2, 3, 0xFF])))


class BinaryModeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.dir = Path(self.temp.name)

    def test_success_writes_little_endian_crc(self):
        (self.dir / 'in.bin').write_bytes(struct.pack('<I', 0x12345678))
        result = run_script(self.dir / 'in.bin', self.dir / 'out.bin', 4)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.dir / 'out.bin').read_bytes(), struct.pack('<I', 0xDF8A8A2B))

    def test_failures_break_the_build_without_stub(self):
        (self.dir / 'big.bin').write_bytes(bytes(8))
        for args in ((self.dir / 'missing.bin', self.dir / 'out.bin'),
                     (self.dir / 'big.bin', self.dir / 'out.bin', 4),
                     (self.dir / 'big.bin', self.dir / 'out.bin', 'not-a-number'),
                     (self.dir / 'big.bin',)):
            result = run_script(*args)
            self.assertNotEqual(result.returncode, 0, args)
            self.assertIn('[CRC ERROR]', result.stderr)
            self.assertFalse((self.dir / 'out.bin').exists(), 'zero stub must not be written')


class ElfModeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.dir = Path(self.temp.name)
        self.elf = self.dir / 'fw.elf'
        build_elf(self.elf, [
            ('.isr_vector', SHT_PROGBITS, SHF_ALLOC, 0x08000000, bytes(range(8))),
            ('.init_array', SHT_INIT_ARRAY, SHF_ALLOC | SHF_WRITE, 0x08000010, b'\x11\x22\x33\x44'),
            ('.data', SHT_PROGBITS, SHF_ALLOC | SHF_WRITE, 0x20000000, b'\xAA\xBB\xCC\xDD'),
            ('.checksum', SHT_PROGBITS, SHF_ALLOC | SHF_WRITE, 0x08000018, bytes(4)),
            ('.bkpsram', SHT_PROGBITS, SHF_ALLOC | SHF_WRITE, 0x40036400, b'\x07\xB0\x07\xB0'),
            ('.bss', SHT_NOBITS, SHF_ALLOC | SHF_WRITE, 0x20000004, 16),
            ('.comment', SHT_PROGBITS, 0, 0, b'GCC\0'),
        ], [('.data', 0x08000014), ('.bkpsram', 0x40036400)])
        # FLASH image: vectors, 0xFF gap, .init_array, .data load image; .checksum excluded.
        self.expected = bytes(range(8)) + b'\xFF' * 8 + b'\x11\x22\x33\x44' + b'\xAA\xBB\xCC\xDD'

    def test_image_contains_only_sections_loaded_into_flash(self):
        start, image, skipped = flash_image(self.elf, 0x08000000, 0x20000, {'.checksum'})
        self.assertEqual(start, 0x08000000)
        self.assertEqual(image, self.expected)
        self.assertEqual([name for name, _, _ in skipped], ['.bkpsram'])

    def test_command_line_writes_crc_and_image(self):
        result = run_script('--elf', self.elf, '--flash', '0x08000000:131072', '--exclude', '.checksum',
                            '--image', self.dir / 'image.bin', self.dir / 'crc.bin', 131072)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.dir / 'image.bin').read_bytes(), self.expected)
        self.assertEqual((self.dir / 'crc.bin').read_bytes(), struct.pack('<I', stm32_crc32(self.expected)))
        self.assertIn('Skipped .bkpsram: load address 0x40036400', result.stdout)

    def test_elf_failures_break_the_build(self):
        (self.dir / 'text.elf').write_text('not an ELF file')
        for args in (('--elf', self.dir / 'missing.elf', '--flash', '0x08000000:1024'),
                     ('--elf', self.dir / 'text.elf', '--flash', '0x08000000:1024'),
                     ('--elf', self.elf, '--flash', '0x08000000'),
                     ('--elf', self.elf, '--flash', '0x09000000:1024'),
                     ('--elf', self.elf, '--flash', '0x08000000:131072', '--exclude', '.checksum')):
            limit = ['16'] if args[-1] == '.checksum' else []
            result = run_script(*args, self.dir / 'crc.bin', *limit)
            self.assertNotEqual(result.returncode, 0, args)
            self.assertIn('[CRC ERROR]', result.stderr)
            self.assertFalse((self.dir / 'crc.bin').exists())


if __name__ == '__main__':
    unittest.main()
