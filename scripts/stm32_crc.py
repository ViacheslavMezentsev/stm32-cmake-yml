# Расчёт CRC-32 аппаратного блока STM32 для внедрения в прошивку (ТЗ 4.15).
#
# Режимы (ТЗ 5.6.2):
#   stm32_crc.py <вход.bin> <выход.bin> [предел_байт]
#       CRC готового двоичного образа.
#   stm32_crc.py --elf <вход.elf> --flash <начало>:<длина> --exclude <секция>
#                [--image <образ.bin>] <выход.bin> [предел_байт]
#       Образ Flash строится из секций ELF с адресом загрузки в регионе FLASH
#       (ТЗ 4.15.9) и не раздувается секциями вне Flash.
#   stm32_crc.py --elf <вход.elf> --flash <начало>:<длина> --image <образ.bin>
#       Только образ Flash без расчёта CRC: BIN-артефакт (ТЗ 4.14.2).
#
# Выход — 4 байта CRC little-endian. Любой сбой завершает скрипт с ненулевым
# кодом и сообщением [CRC ERROR]; нулевая заглушка не записывается (ТЗ 4.15.7).
import argparse
import os
import struct
import sys

SHT_NULL = 0
SHT_NOBITS = 8
SHF_ALLOC = 0x2
PT_LOAD = 1


class CrcError(Exception):
    """Ошибка расчёта, прерывающая сборку."""


def stm32_crc32(data):
    """CRC-32 блока STM32 по умолчанию (ТЗ 4.15.3).

    Полином 0x04C11DB7, начальное значение 0xFFFFFFFF, 32-битные слова
    little-endian, без отражений и финального XOR; неполное последнее слово
    дополняется 0xFF, как незаписанная Flash.
    """
    crc = 0xFFFFFFFF
    for i in range(0, len(data), 4):
        chunk = data[i:i + 4]
        if len(chunk) < 4:
            chunk += b'\xFF' * (4 - len(chunk))
        crc ^= struct.unpack('<I', chunk)[0]
        for _ in range(32):
            if crc & 0x80000000:
                crc = ((crc << 1) ^ 0x04C11DB7) & 0xFFFFFFFF
            else:
                crc = (crc << 1) & 0xFFFFFFFF
    return crc


def flash_image(elf_path, origin, length, exclude):
    """Образ Flash из секций ELF (ТЗ 4.15.9).

    Берутся размещаемые секции с содержимым (все, кроме NULL и NOBITS), кроме
    исключённых, чей адрес загрузки лежит в [origin, origin + length). Образ
    начинается с наименьшего адреса загрузки и заканчивается концом последней
    секции; промежутки заполняются 0xFF. Результат совпадает с образом
    'objcopy -O binary --gap-fill 0xFF' для ELF без секций вне Flash.
    Возвращает (начальный адрес, образ, пропущенные секции).
    """
    with open(elf_path, 'rb') as stream:
        data = stream.read()
    if data[:4] != b'\x7fELF' or data[4] != 1 or data[5] != 1:
        raise CrcError(f"'{elf_path}' is not a 32-bit little-endian ELF file")
    phoff, shoff = struct.unpack_from('<II', data, 0x1C)
    phentsize, phnum, shentsize, shnum, shstrndx = struct.unpack_from('<HHHHH', data, 0x2A)
    segments = [struct.unpack_from('<8I', data, phoff + i * phentsize) for i in range(phnum)]
    sections = [struct.unpack_from('<10I', data, shoff + i * shentsize) for i in range(shnum)]
    names_offset = sections[shstrndx][4]

    def name_of(section):
        start = names_offset + section[0]
        return data[start:data.index(b'\0', start)].decode('ascii', 'replace')

    chunks, skipped = [], []
    for section in sections:
        _, kind, flags, address, offset, size = section[:6]
        name = name_of(section)
        if kind in (SHT_NULL, SHT_NOBITS) or not flags & SHF_ALLOC or size == 0 or name in exclude:
            continue
        # Адрес загрузки: по сегменту, в файловом диапазоне которого лежит секция.
        load = address
        for p_type, p_offset, _, p_paddr, p_filesz, _, _, _ in segments:
            if p_type == PT_LOAD and p_offset <= offset < p_offset + p_filesz:
                load = p_paddr + (offset - p_offset)
                break
        if origin <= load and load + size <= origin + length:
            chunks.append((load, data[offset:offset + size]))
        else:
            skipped.append((name, load, size))
    if not chunks:
        raise CrcError(f"No loadable sections inside FLASH 0x{origin:08X}+0x{length:X} in '{elf_path}'")
    start = min(load for load, _ in chunks)
    end = max(load + len(chunk) for load, chunk in chunks)
    image = bytearray(b'\xFF' * (end - start))
    for load, chunk in chunks:
        image[load - start:load - start + len(chunk)] = chunk
    return start, bytes(image), skipped


def parse_int(text, what):
    try:
        return int(text, 0)
    except ValueError:
        raise CrcError(f"Invalid {what}: '{text}'") from None


def parse_flash(text):
    origin, sep, length = text.partition(':')
    if not sep:
        raise CrcError(f"Invalid --flash value '{text}', expected <origin>:<length>")
    return parse_int(origin, 'FLASH origin'), parse_int(length, 'FLASH length')


def check_limit(size, limit):
    if limit is not None and size > limit:
        raise CrcError(
            f"CRC image is larger than the FLASH limit: {size:,} > {limit:,} bytes.\n"
            f"[CRC ERROR]   Check 'flash_size' and the FLASH region of the linker script.")


def write_crc(path, data):
    crc = stm32_crc32(data)
    with open(path, 'wb') as stream:
        stream.write(struct.pack('<I', crc))
    return crc


def run(argv):
    if argv and argv[0] == '--elf':
        parser = argparse.ArgumentParser(prog='stm32_crc.py')
        parser.add_argument('--elf', required=True)
        parser.add_argument('--flash', required=True, type=str)
        parser.add_argument('--exclude', action='append', default=[])
        parser.add_argument('--image')
        parser.add_argument('output', nargs='?')
        parser.add_argument('limit', nargs='?')
        args = parser.parse_args(argv)
        if args.output is None and not args.image:
            raise CrcError('Pass <output.bin> for the CRC or --image for the FLASH image')
        if not os.path.exists(args.elf):
            raise CrcError(f"Input file '{args.elf}' not found.")
        origin, length = parse_flash(args.flash)
        limit = parse_int(args.limit, 'FLASH limit') if args.limit is not None else None
        start, image, skipped = flash_image(args.elf, origin, length, set(args.exclude))
        tag = '[STM32 CRC32]' if args.output else '[STM32 BIN]'
        for name, load, size in skipped:
            print(f"{tag} Skipped {name}: load address 0x{load:08X} ({size} bytes) is outside FLASH")
        check_limit(len(image), limit)
        if args.image:
            with open(args.image, 'wb') as stream:
                stream.write(image)
        if args.output is None:
            print(f"{tag} Written {args.image}: {len(image)} bytes from 0x{start:08X}")
            return
        crc = write_crc(args.output, image)
        print(f"[STM32 CRC32] Calculated: 0x{crc:08X} (Size: {len(image)} bytes from 0x{start:08X})")
        return

    if len(argv) not in (2, 3):
        raise CrcError("Usage: stm32_crc.py <input.bin> <output.bin> [limit] | "
                       "--elf <input.elf> --flash <origin>:<length> --exclude <section> <output.bin> [limit]")
    input_bin, output_bin = argv[0], argv[1]
    if not os.path.exists(input_bin):
        raise CrcError(f"Input file '{input_bin}' not found.")
    limit = parse_int(argv[2], 'FLASH limit') if len(argv) == 3 else None
    with open(input_bin, 'rb') as stream:
        data = stream.read()
    check_limit(len(data), limit)
    crc = write_crc(output_bin, data)
    print(f"[STM32 CRC32] Calculated: 0x{crc:08X} (Size: {len(data)} bytes)")


def main():
    try:
        run(sys.argv[1:])
    except (CrcError, OSError) as error:
        print(f"\n[CRC ERROR] {error}\n[CRC ERROR] Build failed: CRC was not calculated.", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
