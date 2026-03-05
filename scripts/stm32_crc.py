# Этот скрипт реализует стандартный алгоритм аппаратного CRC32 STM32 (MPEG-2 style).
import sys
import struct
import os

def stm32_crc32(data):
    """
    Эмуляция аппаратного CRC32 STM32 (Poly 0x04C11DB7, Init 0xFFFFFFFF, Input/Output not reflected).
    STM32 читает данные словами по 32 бита (Little Endian в памяти, но регистр CRC работает со словами).
    """
    crc = 0xFFFFFFFF

    # Обрабатываем данные по 4 байта (1 слово)
    for i in range(0, len(data), 4):
        chunk = data[i:i+4]
        # Если в конце меньше 4 байт, дополняем 0xFF (стандартное поведение заполнения Flash)
        if len(chunk) < 4:
            chunk += b'\xFF' * (4 - len(chunk))

        # STM32 (Little Endian) читает слово из памяти. Преобразуем bytes -> uint32
        val = struct.unpack('<I', chunk)[0]

        # Эмуляция регистра CRC
        xbit = 0x80000000
        poly = 0x04C11DB7
        crc = crc ^ val
        for _ in range(32):
            if crc & xbit:
                crc = (crc << 1) ^ poly
            else:
                crc <<= 1
            crc &= 0xFFFFFFFF

    return crc

def graceful_exit(message, output_bin_path=None):
    """
    Завершение без прерывания сборки CMake/Ninja.
    Печатает предупреждение, записывает нулевой CRC (заглушку),
    чтобы следующая команда objcopy не упала из-за отсутствия файла.
    """
    print(f"\n[CRC WARNING] {message}")
    print("[CRC WARNING] Checksum calculation skipped. Firmware will contain 0x00000000.")
    if output_bin_path is not None:
        print(f"[CRC WARNING] Stub CRC file written to: {output_bin_path}")
    print()

    if output_bin_path is not None:
        try:
            # Записываем нулевой CRC (4 байта), чтобы сборка продолжилась
            with open(output_bin_path, 'wb') as f:
                f.write(struct.pack('<I', 0))
        except Exception:
            pass # Игнорируем ошибки при попытке создать заглушку

    # Возвращаем 0, чтобы Ninja считал шаг успешным
    sys.exit(0)

def main():
    # Проверка минимального количества аргументов
    if len(sys.argv) < 3:
        graceful_exit("Invalid arguments. Usage: python stm32_crc.py <input.bin> <output.bin> [max_flash_size]")

    input_bin = sys.argv[1]
    output_crc_bin = sys.argv[2]

    # Проверка существования входного файла
    if not os.path.exists(input_bin):
        graceful_exit(f"Input file '{input_bin}' not found.", output_crc_bin)

    # Защита от дурака: проверка на гигантский бинарный файл (проблема gap-fill)
    if len(sys.argv) >= 4:
        try:
            max_flash_size = int(sys.argv[3])
            file_size = os.path.getsize(input_bin)

            if file_size > max_flash_size:
                # Типичная причина на H5/H7: секции DTCM, ITCM или SRAM, начинающиеся
                # с адреса 0x00000000, из-за gap-fill раздувают бинарный образ.
                # Решение: убедитесь, что в скрипте компоновщика такие секции расположены
                # только во внутренней RAM и не попадают в образ Flash. В postbuild.cmake
                # команда objcopy использует --remove-section для их исключения.
                msg = (
                    f"Intermediate binary '{input_bin}' is abnormally large!\n"
                    f"[CRC WARNING]   Actual size : {file_size:,} bytes"
                    f" ({file_size / 1024:.1f} KiB / {file_size / 1024 / 1024:.2f} MiB)\n"
                    f"[CRC WARNING]   Max Flash   : {max_flash_size:,} bytes"
                    f" ({max_flash_size / 1024:.1f} KiB / {max_flash_size / 1024 / 1024:.2f} MiB)\n"
                    f"[CRC WARNING]   Likely cause: a section (e.g. DTCM/ITCM on H5/H7) starts at\n"
                    f"[CRC WARNING]                 address 0x00000000 and triggers gap-fill.\n"
                    f"[CRC WARNING]   Fix hint    : add --remove-section=<section> to the objcopy\n"
                    f"[CRC WARNING]                 call in stm32_yml_postbuild.cmake, or check\n"
                    f"[CRC WARNING]                 your linker script for DTCM/ITCM placement."
                )
                graceful_exit(msg, output_crc_bin)
        except ValueError:
            pass # Если третий аргумент по какой-то причине не число, просто игнорируем проверку

    # Основной блок расчета контрольной суммы
    try:
        with open(input_bin, 'rb') as f:
            data = f.read()

        # Выравнивание длины данных на 4 байта (заполнение 0xFF)
        # Это важно, так как HAL_CRC_Calculate работает словами
        remainder = len(data) % 4
        if remainder != 0:
            data += b'\xFF' * (4 - remainder)

        # Расчет CRC
        crc_val = stm32_crc32(data)
        print(f"[STM32 CRC32] Calculated: 0x{crc_val:08X} (Size: {len(data)} bytes)")

        # Запись результата в файл (4 байта, Little Endian, чтобы лечь в память МК)
        with open(output_crc_bin, 'wb') as f:
            f.write(struct.pack('<I', crc_val))

    except Exception as e:
        # Перехват любых неожиданных ошибок Python
        graceful_exit(f"Unexpected Python error: {str(e)}", output_crc_bin)

if __name__ == '__main__':
    main()
