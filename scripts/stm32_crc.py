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
# кодом и сообщением об ошибке; нулевая заглушка не записывается (ТЗ 4.15.7).
#
# Сообщения (ТЗ 4.16.11): --messages <stm32_yml_build_messages.json> — тексты
# кодов 7xx на языке Configure; каждое сообщение дописывается строкой JSON в
# stm32_yml_build_messages.jsonl рядом с этим файлом. Без --messages выводятся
# английские тексты FALLBACK, совпадающие с каталогом (проверка L1).
import argparse
import json
import os
import re
import struct
import sys

# Английские тексты каталога cmake/stm32_yml_messages_catalog.cmake для запуска
# без --messages; ci/check_messages.py сверяет их с каталогом.
FALLBACK = {
    'I707': "{1} Skipped {2}: load address 0x{3} ({4} bytes) is outside FLASH",
    'I708': "{1} Written {2}: {3} bytes from 0x{4}",
    'I709': "[STM32 CRC32] Calculated: 0x{1} (Size: {2} bytes from 0x{3})",
    'I710': "[STM32 CRC32] Calculated: 0x{1} (Size: {2} bytes)",
    'E702': "'{1}' is not a 32-bit little-endian ELF file",
    'E703': "No loadable sections inside FLASH 0x{1}+0x{2} in '{3}'",
    'E704': "Invalid number '{1}' in {2}",
    'E705': "Invalid --flash value '{1}', expected <origin>:<length>",
    'E706': "CRC image is larger than the FLASH limit: {1} > {2} bytes. "
            "Check 'flash_size' and the FLASH region of the linker script.",
    'E707': "Pass <output.bin> for the CRC or --image for the FLASH image",
    'E708': "Build failed: CRC was not calculated.",
    'E709': "Input file '{1}' not found.",
    'E710': "Usage: stm32_crc.py <input.bin> <output.bin> [limit] | "
            "--elf <input.elf> --flash <origin>:<length> --exclude <section> <output.bin> [limit]",
    'E711': "I/O error: {1}",
}
PARAM = re.compile(r"\{(\d+)\}")
MESSAGES = {'lang': 'en', 'codes': False, 'texts': {}, 'log': None}


def load_messages(path):
    """Тексты и настройки вывода, записанные Configure (ТЗ 4.16.11)."""
    with open(path, encoding='utf-8') as stream:
        data = json.load(stream)
    MESSAGES.update(lang=data.get('lang', 'en'), codes=bool(data.get('codes')),
                    texts=data.get('messages', {}),
                    log=os.path.join(os.path.dirname(os.path.abspath(path)), 'stm32_yml_build_messages.jsonl'))


def render(code, args):
    """Текст по коду: подстановка {n} за один проход, как stm32_yml_msg."""
    text = MESSAGES['texts'].get(code) or FALLBACK[code]
    def value(match):
        number = int(match.group(1))
        return args[number - 1] if 1 <= number <= len(args) else match.group(0)
    return PARAM.sub(value, text)


def emit(code, *args, stream=None):
    """Выводит сообщение и дописывает запись в файл сообщений сборки."""
    args = [str(arg) for arg in args]
    text = render(code, args)
    level = {'I': 'STATUS', 'W': 'WARNING', 'E': 'FATAL_ERROR'}[code[0]]
    if MESSAGES['log']:
        record = {'code': f'SCY-{code}', 'level': level, 'lang': MESSAGES['lang'], 'args': args, 'text': text}
        with open(MESSAGES['log'], 'a', encoding='utf-8') as log:
            log.write(json.dumps(record, ensure_ascii=False) + '\n')
    shown = text
    if MESSAGES['codes']:
        shown = '\n'.join(f'[SCY-{code}] {line}' for line in text.split('\n'))
    print(shown, file=stream or (sys.stderr if code[0] == 'E' else sys.stdout), flush=True)

SHT_NULL = 0
SHT_NOBITS = 8
SHF_ALLOC = 0x2
PT_LOAD = 1


class CrcError(Exception):
    """Ошибка расчёта, прерывающая сборку: код каталога и аргументы."""

    def __init__(self, code, *args):
        super().__init__(render(code, [str(arg) for arg in args]))
        self.code, self.args_list = code, args


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
        raise CrcError('E702', elf_path)
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
        raise CrcError('E703', f"{origin:08X}", f"{length:X}", elf_path)
    start = min(load for load, _ in chunks)
    end = max(load + len(chunk) for load, chunk in chunks)
    image = bytearray(b'\xFF' * (end - start))
    for load, chunk in chunks:
        image[load - start:load - start + len(chunk)] = chunk
    return start, bytes(image), skipped


def parse_int(text, where):
    try:
        return int(text, 0)
    except ValueError:
        raise CrcError('E704', text, where) from None


def parse_flash(text):
    origin, sep, length = text.partition(':')
    if not sep:
        raise CrcError('E705', text)
    return parse_int(origin, '--flash'), parse_int(length, '--flash')


def check_limit(size, limit):
    if limit is not None and size > limit:
        raise CrcError('E706', f"{size:,}", f"{limit:,}")


def write_crc(path, data):
    crc = stm32_crc32(data)
    with open(path, 'wb') as stream:
        stream.write(struct.pack('<I', crc))
    return crc


def run(argv):
    if '--messages' in argv:
        index = argv.index('--messages')
        load_messages(argv[index + 1])
        argv = argv[:index] + argv[index + 2:]
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
            raise CrcError('E707')
        if not os.path.exists(args.elf):
            raise CrcError('E709', args.elf)
        origin, length = parse_flash(args.flash)
        limit = parse_int(args.limit, 'limit') if args.limit is not None else None
        start, image, skipped = flash_image(args.elf, origin, length, set(args.exclude))
        tag = '[STM32 CRC32]' if args.output else '[STM32 BIN]'
        for name, load, size in skipped:
            emit('I707', tag, name, f"{load:08X}", size)
        check_limit(len(image), limit)
        if args.image:
            with open(args.image, 'wb') as stream:
                stream.write(image)
        if args.output is None:
            emit('I708', tag, args.image, len(image), f"{start:08X}")
            return
        crc = write_crc(args.output, image)
        emit('I709', f"{crc:08X}", len(image), f"{start:08X}")
        return

    if len(argv) not in (2, 3):
        raise CrcError('E710')
    input_bin, output_bin = argv[0], argv[1]
    if not os.path.exists(input_bin):
        raise CrcError('E709', input_bin)
    limit = parse_int(argv[2], 'limit') if len(argv) == 3 else None
    with open(input_bin, 'rb') as stream:
        data = stream.read()
    check_limit(len(data), limit)
    crc = write_crc(output_bin, data)
    emit('I710', f"{crc:08X}", len(data))


def main():
    try:
        run(sys.argv[1:])
    except CrcError as error:
        emit(error.code, *error.args_list)
        emit('E708')
        sys.exit(1)
    except OSError as error:
        emit('E711', error)
        emit('E708')
        sys.exit(1)


if __name__ == '__main__':
    main()
