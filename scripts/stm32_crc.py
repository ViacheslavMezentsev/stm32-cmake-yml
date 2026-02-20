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

def main():
    if len(sys.argv) != 3:
        print("Usage: python stm32_crc.py <input_no_crc.bin> <output_crc_value.bin>")
        sys.exit(1)

    input_bin = sys.argv[1]
    output_crc_bin = sys.argv[2]

    if not os.path.exists(input_bin):
        print(f"Error: Input file {input_bin} not found.")
        sys.exit(1)

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
        print(f"CRC Script Error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()