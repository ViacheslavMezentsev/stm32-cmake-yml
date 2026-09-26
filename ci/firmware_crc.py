"""Inspect the fixture's CRC layout without relying on the post-build CRC script."""
import struct


def crc32_words(data):
    if len(data) % 4:
        raise ValueError('CRC input must contain whole words')
    crc = 0xFFFFFFFF
    for (word,) in struct.iter_unpack('<I', data):
        crc ^= word
        for _ in range(32):
            crc = ((crc << 1) ^ (0x04C11DB7 if crc & 0x80000000 else 0)) & 0xFFFFFFFF
    return crc


def inspect_crc(elf, flash_end=0x08010000):
    data = elf.read_bytes()
    shoff = struct.unpack_from('<I', data, 32)[0]
    shsize, shcount, names_index = struct.unpack_from('<HHH', data, 46)
    headers = [struct.unpack_from('<10I', data, shoff + i * shsize) for i in range(shcount)]
    names_header = headers[names_index]
    names = data[names_header[4]:names_header[4] + names_header[5]]
    sections = {names[h[0]:].split(b'\0', 1)[0].decode(): h for h in headers}
    checksum, version, ram = (sections[key] for key in ('.checksum', '.fw_version', '.data'))
    start, end = 0x08000000, checksum[3]
    if checksum[5] != 4 or version[5] != 4 or end % 4 or not start < end < flash_end:
        raise ValueError('Invalid checksum/version section bounds')
    image = bytearray(end + 4 - start)
    covered = bytearray(len(image))
    phoff = struct.unpack_from('<I', data, 28)[0]
    phsize, phcount = struct.unpack_from('<HH', data, 42)
    ram_covered = False
    for i in range(phcount):
        kind, offset, vaddr, paddr, filesz, _, _, _ = struct.unpack_from('<8I', data, phoff + i * phsize)
        if kind != 1 or not filesz:
            continue
        if not start <= paddr < paddr + filesz <= end + 4:
            raise ValueError('Checksum is not last in FLASH load image')
        low, high = paddr - start, paddr - start + filesz
        if any(covered[low:high]):
            raise ValueError('Overlapping FLASH load segments')
        image[low:high] = data[offset:offset + filesz]
        covered[low:high] = b'\1' * filesz
        if vaddr <= ram[3] and ram[3] + ram[5] <= vaddr + filesz:
            ram_covered = paddr + ram[3] - vaddr + ram[5] <= version[3]
    if not all(covered) or not ram_covered or version[3] + 4 != end:
        raise ValueError('CRC range has gaps or does not include .data then .fw_version')
    stored = struct.unpack_from('<I', image, end - start)[0]
    computed = crc32_words(image[:-4])
    if stored != computed:
        raise ValueError('Injected ELF CRC does not match FLASH load bytes')
    # BIN is generated after injection and must represent the same load image.
    if elf.with_suffix('.bin').read_bytes() != image:
        raise ValueError('BIN differs from injected ELF load image')
    metadata = {'CRC_START': f'{start:08X}', 'CRC_END': f'{end:08X}',
                'CRC_STORED': f'{stored:08X}', 'CRC_COMPUTED': f'{computed:08X}', 'CRC_RESULT': 'PASS'}
    corrupted = bytearray(data)
    corrupted[version[4]] ^= 1
    image[version[3] - start] ^= 1
    negative = dict(metadata, CRC_COMPUTED=f'{crc32_words(image[:-4]):08X}', CRC_RESULT='FAIL')
    return metadata, corrupted, negative
