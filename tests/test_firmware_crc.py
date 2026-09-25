"""CRC vectors and rejection of broken load layouts/artifacts."""
from pathlib import Path
import struct
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'ci'))
from firmware_crc import crc32_words, inspect_crc


class CrcTests(unittest.TestCase):
    def test_vectors_and_alignment(self):
        for words, expected in [([0x12345678], 0xDF8A8A2B), ([0], 0xC704DD7B),
                                ([0x12345678, 0x9ABCDEF0], 0x7D24A31B)]:
            self.assertEqual(crc32_words(struct.pack('<' + 'I' * len(words), *words)), expected)
        with self.assertRaises(ValueError):
            crc32_words(b'abc')

    def test_layout_and_artifact_rejections(self):
        start = 0x08000000
        payload = struct.pack('<3I', 0x12345678, 0xDEADBEEF, 0x00090200)
        image = payload + struct.pack('<I', crc32_words(payload))
        data = bytearray(512)
        struct.pack_into('<I', data, 28, 52)
        struct.pack_into('<I', data, 32, 320)
        struct.pack_into('<5H', data, 42, 32, 3, 40, 4, 0)
        for i, (vaddr, paddr, offset, size) in enumerate([
                (start, start, 160, 4), (0x20000000, start + 4, 164, 4),
                (start + 8, start + 8, 168, 8)]):
            struct.pack_into('<8I', data, 52 + i * 32, 1, offset, vaddr, paddr, size, size, 0, 4)
        data[160:176] = image
        names = b'\0.checksum\0.fw_version\0.data\0'
        data[240:240 + len(names)] = names
        for i, (name, address, offset, size) in enumerate([
                (0, 0, 240, len(names)), (1, start + 12, 172, 4),
                (11, start + 8, 168, 4), (23, 0x20000000, 164, 4)]):
            struct.pack_into('<10I', data, 320 + i * 40, name, 1, 2, address, offset, size, 0, 0, 4, 0)
        with tempfile.TemporaryDirectory() as directory:
            elf = Path(directory) / 'fixture.elf'
            elf.write_bytes(data)
            elf.with_suffix('.bin').write_bytes(image)
            metadata, corrupted, negative = inspect_crc(elf)
            self.assertEqual(metadata['CRC_RESULT'], 'PASS')
            self.assertEqual(negative['CRC_RESULT'], 'FAIL')
            self.assertNotEqual(metadata['CRC_COMPUTED'], negative['CRC_COMPUTED'])
            self.assertEqual(sum(a != b for a, b in zip(data, corrupted)), 1)
            elf.write_bytes(corrupted)
            with self.assertRaisesRegex(ValueError, 'Injected ELF CRC'):
                inspect_crc(elf)
            elf.write_bytes(data)
            elf.with_suffix('.bin').write_bytes(image[:-1] + b'\0')
            with self.assertRaisesRegex(ValueError, 'BIN differs'):
                inspect_crc(elf)
            elf.with_suffix('.bin').write_bytes(image)
            for paddr in (start + 9, start + 7, start + 16):
                broken = bytearray(data)
                struct.pack_into('<I', broken, 52 + 2 * 32 + 12, paddr)
                elf.write_bytes(broken)
                with self.assertRaises(ValueError):
                    inspect_crc(elf)


if __name__ == '__main__':
    unittest.main()
