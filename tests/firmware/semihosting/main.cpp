#include <stdio.h>
#include <stdarg.h>
#include <stdint.h>
#ifndef SMOKE_BARE
#include <stm32f1xx.h>
#include <core_cm3.h>
#endif
#include "version.h"
#include "build_metadata.h"
#ifdef SMOKE_LIBRARY
#include <smoke_library.h>
#include <string.h>
#if !defined(SMOKE_CXX_ONLY) || defined(SMOKE_C_ONLY) || defined(SMOKE_LIBRARY_PRIVATE)
#error Incorrect C++ language definitions or leaked PRIVATE library definition
#endif
#if defined(__EXCEPTIONS) || defined(__GXX_RTTI)
#error Missing executable C++ options
#endif
static volatile uint32_t library_input[] = {3, 1, 4, 1, 5};
#endif

extern "C" {
unsigned smoke_arduino_string(char*, unsigned);
volatile uint32_t smoke_data_probe = 0x12345678u;
volatile uint32_t smoke_bss_probe;
volatile uint32_t smoke_ctor_probe;
}
// Dedicated metadata word: the negative test changes only this unused payload.
__attribute__((section(".fw_version"), used)) static const uint32_t firmware_version = 0x00090200u;
extern "C" uint32_t __checksum_start[], __checksum_end[];
constexpr uint32_t crcStepWord(uint32_t crc, uint32_t word) {
    crc ^= word;
    for (int i = 0; i < 32; ++i)
        crc = (crc & 0x80000000u) ? (crc << 1) ^ 0x04C11DB7u : crc << 1;
    return crc;
}
static_assert(crcStepWord(0xFFFFFFFFu, 0x12345678u) == 0xDF8A8A2Bu);
static_assert(crcStepWord(0xFFFFFFFFu, 0) == 0xC704DD7Bu);
static_assert(crcStepWord(crcStepWord(0xFFFFFFFFu, 0x12345678u), 0x9ABCDEF0u) == 0x7D24A31Bu);

struct ConstructorProbe {
    ConstructorProbe() { smoke_ctor_probe = 0xC0DEC0DEu; }
};
static ConstructorProbe constructor_probe;

/**
 * @brief  Адрес регистра CPUID в блоке System Control Block (SCB).
 * @note   Этот адрес является стандартным для всех ядер Cortex-M.
 */
#define SCB_CPUID_ADDR ( 0xE000ED00UL )
#define SCB_CPUID      ( *( ( volatile const uint32_t* ) SCB_CPUID_ADDR ) )

/**
  * @brief  Код производителя ядра ARM Ltd.
  */
#define ARM_IMPLEMENTER_CODE (0x41UL)

/// Formatted output over the common semihosting transport.
// SYS_WRITE0 is supported by both pinned emulators. Formatting stays in newlib.
static void smoke_printf(const char* format, ...) {
    char buffer[512];
    va_list args;
    va_start(args, format);
    const int length = vsnprintf(buffer, sizeof(buffer), format, args);
    va_end(args);
    const char* message = (length < 0 || length >= (int)sizeof(buffer))
        ? "TRANSPORT_ERROR=format overflow\n" : buffer;
    register uint32_t operation __asm__("r0") = 4u;
    register const char* parameter __asm__("r1") = message;
    __asm__ volatile("bkpt 0xAB" : "+r"(operation), "+r"(parameter) : : "memory");
}

/// Обработчик прерывания SysTick.
#ifdef USE_HAL_DRIVER
extern "C" void SysTick_Handler( void )
{
    HAL_IncTick();
}
#endif

int counter = 0;

/**
 * @brief   Разбирает и выводит в консоль информацию из регистра CPUID.
 * @note    Не зависит от HAL. Может быть вызвана в любой момент.
 */
void print_cpu_id( void )
{
    uint32_t cpuid_val = SCB_CPUID;

    // --- Извлекаем поля из 32-битного значения ---

    // Поле Implementer: [31:24]
    uint8_t implementer = ( cpuid_val >> 24 ) & 0xFF;

    // Поле Variant: [23:20]
    uint8_t variant = ( cpuid_val >> 20 ) & 0x0F;

    // Поле Constant/Architecture: [19:16]
    // 0xF для архитектуры ARMv7-M
    uint8_t architecture = ( cpuid_val >> 16 ) & 0x0F;

    // Поле Part Number: [15:4]
    uint16_t part_no = ( cpuid_val >> 4 ) & 0xFFF;

    // Поле Revision: [3:0]
    uint8_t revision = cpuid_val & 0x0F;

    // --- Выводим информацию ---

    smoke_printf( "--- CPUID Register Analysis (Value: 0x%08lX) ---\n", cpuid_val );

    // 1. Implementer (Производитель ядра)
    smoke_printf( "  Implementer [31:24]: 0x%02X -> ", implementer );
    if ( implementer == 0x41 )
    {
        smoke_printf( "ARM Ltd. ('A')\n" );
    } else if ( implementer == 0x51 )
    {
        smoke_printf( "QEMU ('Q')\n" );
    } else
    {
        smoke_printf( "Unknown\n" );
    }

    // 2. Variant (Ревизия ядра)
    smoke_printf( "  Variant     [23:20]: 0x%X   -> r%dp\n", variant, variant );

    // 3. Architecture (Архитектура)
    smoke_printf( "  Architecture[19:16]: 0x%X   -> ", architecture );

    if ( architecture == 0xF )
    {
        smoke_printf( "ARMv7-M Architecture\n" );
    }
    else if ( architecture == 0xC )
    {
        smoke_printf( "ARMv6-M Architecture\n" );
    }
    else
    {
        smoke_printf( "Unknown Architecture\n" );
    }

    // 4. Part Number (Модель ядра)
    smoke_printf( "  Part Number [15:4]:  0x%03X -> ", part_no );

    switch ( part_no )
    {
        case 0xC20:
            smoke_printf( "Cortex-M0\n" );
            break;
        case 0xC60:
            smoke_printf( "Cortex-M0+\n" );
            break;
        case 0xC21:
            smoke_printf( "Cortex-M1\n" );
            break;
        case 0xC23:
            smoke_printf( "Cortex-M3\n" );
            break;
        case 0xC24:
            smoke_printf( "Cortex-M4\n" );
            break;
        case 0xC27:
            smoke_printf( "Cortex-M7\n" );
            break;
        case 0xD20:
            smoke_printf( "Cortex-M23\n" );
            break;
        case 0xD21:
            smoke_printf( "Cortex-M33\n" );
            break;
        default:
            smoke_printf( "Unknown Core\n" );
            break;
    }

    // 5. Revision (Патч ревизии)
    smoke_printf( "  Revision    [3:0]:   0x%X   -> p%d\n", revision, revision );

    smoke_printf( "-------------------------------------------------------\n" );
}

void print_firmware_info( void )
{
    // Блок вывода версий.
    smoke_printf( "--- Firmware build information ------------------------\n" );

    // 1. Версия компилятора GCC.
    smoke_printf( "  Compiler:    GCC %d.%d.%d\n", __GNUC__, __GNUC_MINOR__, __GNUC_PATCHLEVEL__ );

#ifndef SMOKE_BARE
    // 2. Версия CMSIS Core.
    // Эти макросы определены в файле 'core_cm3.h' (или аналогичном для вашего ядра).
    smoke_printf( "  CMSIS Core:  v%d.%d\n", __CM3_CMSIS_VERSION_MAIN, __CM3_CMSIS_VERSION_SUB );

    // 3. Версия CMSIS Device (специфично для вендора, в нашем случае ST).
    // Эти макросы определены в файле 'stm32f1xx.h'.
    smoke_printf( "  CMSIS Device:  v%d.%d.%d\n",
            __STM32F1_CMSIS_VERSION_MAIN,
            __STM32F1_CMSIS_VERSION_SUB1,
            __STM32F1_CMSIS_VERSION_SUB2 );

#endif
#ifdef USE_HAL_DRIVER
    // 4. Версия библиотеки HAL.
    // Этот макрос определен в 'stm32f1xx_hal.h'.
    uint32_t hal_version = HAL_GetHalVersion();
    uint8_t hal_major = ( hal_version >> 24 ) & 0xFF;
    uint8_t hal_minor = ( hal_version >> 16 ) & 0xFF;
    uint8_t hal_patch = ( hal_version >> 8 ) & 0xFF;
    // uint8_t hal_rc = hal_version & 0xFF; // Ревизия (обычно 0)

    smoke_printf( "  STM32Cube HAL: v%d.%d.%d\n", hal_major, hal_minor, hal_patch );

    if ( 0 )
    {
        // 5. Уникальный ID устройства (если нужно).
        // Это не версия, но очень полезно для идентификации.
        uint32_t uid_word0 = HAL_GetUIDw0();
        uint32_t uid_word1 = HAL_GetUIDw1();
        uint32_t uid_word2 = HAL_GetUIDw2();

        smoke_printf( "  Device UID:    %08lX%08lX%08lX\n", uid_word2, uid_word1, uid_word0 );
    }

#endif
    // 6. Дата и время сборки (стандартные макросы препроцессора).
    smoke_printf( "  Build Date:    %s\n", __DATE__ );
    smoke_printf( "  Build Time:    %s\n", __TIME__ );

    smoke_printf( "  Version: %u.%u.%u.%u (%02u.%02u.%02u %02u:%02u:%02u)\n",
            Version.Major, Version.Minor, Version.Build, Version.Revision,
            DAY, MON, YEAR, HOUR, MIN, SEC );

    smoke_printf( "--------------------------------------------------\n" );
}

/**
 * \brief   Точка входа в программу.
 *
 */
// ARM SYS_EXIT_EXTENDED: reason + application status, both 32-bit words.
[[noreturn]] __attribute__((noinline)) static void smoke_exit(uint32_t status)
{
    const uint32_t arguments[2] = {0x20026u, status};
    register uint32_t operation __asm__("r0") = 0x20u;
    register const uint32_t* parameter __asm__("r1") = arguments;
    __asm__ volatile(".global smoke_exit_trap\nsmoke_exit_trap:\nbkpt 0xAB" : "+r"(operation), "+r"(parameter) : : "memory");
    while (1) { __asm__ volatile("nop"); }
}

int main()
{
    const uint32_t initial_data = smoke_data_probe;
    const uint32_t initial_bss = smoke_bss_probe;
    const uint32_t initial_ctor = smoke_ctor_probe;

    // Инициализация библиотеки HAL.
#ifdef USE_HAL_DRIVER
    HAL_Init();
#endif

    print_firmware_info();

    print_cpu_id();

    smoke_printf("BUILD_TARGET=%s\n", SMOKE_MCU);
    smoke_printf("PROFILE=%s\nCMAKE=%s\nFRAMEWORK=%s\n", SMOKE_PROFILE, SMOKE_CMAKE, SMOKE_FRAMEWORK);
    smoke_printf("GIT_REVISION=%s\nGIT_DIRTY=%s\n", SMOKE_GIT, SMOKE_DIRTY);
#ifndef SMOKE_BARE
    smoke_printf("CMSIS_CORE=%u.%u\n", __CM3_CMSIS_VERSION_MAIN, __CM3_CMSIS_VERSION_SUB);
    smoke_printf("CMSIS_DEVICE=%u.%u.%u\n", __STM32F1_CMSIS_VERSION_MAIN,
           __STM32F1_CMSIS_VERSION_SUB1, __STM32F1_CMSIS_VERSION_SUB2);
#else
    smoke_printf("CMSIS_CORE=none\nCMSIS_DEVICE=none\n");
#endif
#ifdef USE_HAL_DRIVER
    const uint32_t hal_version = HAL_GetHalVersion();
    smoke_printf("HAL_VERSION=%lu.%lu.%lu\n", (hal_version >> 24) & 255u,
           (hal_version >> 16) & 255u, (hal_version >> 8) & 255u);
#else
    smoke_printf("HAL_VERSION=none\n");
#endif
    extern uint32_t _Min_Heap_Size[], _Min_Stack_Size[];
    smoke_printf("HEAP_SIZE=%lu\nSTACK_SIZE=%lu\n", (uint32_t)_Min_Heap_Size, (uint32_t)_Min_Stack_Size);
    smoke_printf("DATA_INIT=%08lX\nBSS_INIT=%08lX\nCTOR_INIT=%08lX\n", initial_data, initial_bss, initial_ctor);
    smoke_printf("DATA_ADDRESS=%08lX\nBSS_ADDRESS=%08lX\nCTOR_ADDRESS=%08lX\n",
           (uint32_t)&smoke_data_probe, (uint32_t)&smoke_bss_probe, (uint32_t)&smoke_ctor_probe);
    smoke_printf("TEST_PLATFORM=cortex-m3-smoke\n");

    if (initial_data != 0x12345678u || initial_bss != 0 || initial_ctor != 0xC0DEC0DEu) {
        smoke_printf("TEST_RESULT=FAIL\n");

        smoke_exit(2);
    }
    uint32_t crc = 0xFFFFFFFFu;
    // Volatile FLASH reads prevent folding the image into compile-time constants.
    for (uintptr_t address = (uintptr_t)__checksum_start; address < (uintptr_t)__checksum_end; address += 4)
        crc = crcStepWord(crc, *(volatile const uint32_t*)address);
    const uint32_t stored = *(volatile const uint32_t*)__checksum_end;
    smoke_printf("CRC_START=%08lX\nCRC_END=%08lX\nCRC_STORED=%08lX\nCRC_COMPUTED=%08lX\n",
           (uint32_t)__checksum_start, (uint32_t)__checksum_end, stored, crc);
    smoke_printf("CRC_RESULT=%s\n", crc == stored ? "PASS" : "FAIL");
    if (crc != stored) {
        smoke_printf("TEST_RESULT=FAIL\n");

        smoke_exit(3);
    }

#ifdef SMOKE_LIBRARY
    const uint32_t library_result = smoke_transform(library_input, 5);
    const uint32_t language_result = smoke_language();
    smoke_printf("LIB_RESULT=%lu\nC_LANGUAGE=%lu\n", library_result, language_result);
    if (library_result != 123u || language_result != 11u) {
        smoke_printf("TEST_RESULT=FAIL\n");
        smoke_exit(4);
    }
#ifdef SMOKE_ETL
    const uint32_t etl_result = smoke_etl(library_input, 5);
    smoke_printf("ETL_RESULT=%lu\nETL_TEXT=%s\nETL_VERSION=%s\n",
                 etl_result, smoke_etl_text(), smoke_etl_version());
    if (etl_result != 14u || strcmp(smoke_etl_text(), "etl:14") != 0) {
        smoke_printf("TEST_RESULT=FAIL\n");
        smoke_exit(4);
    }
#endif
#endif
#ifdef SMOKE_ARDUINO
    char arduino_text[32] = {};
    const unsigned arduino_length = smoke_arduino_string(arduino_text, sizeof(arduino_text));
    smoke_printf("ARDUINO_TEXT=%s\nARDUINO_LENGTH=%u\n", arduino_text, arduino_length);
    if (arduino_length != 9u) {
        smoke_printf("TEST_RESULT=FAIL\n");
        smoke_exit(5);
    }
#endif
#if defined(SMOKE_HANG)
    while (1) { __asm__ volatile("nop"); }
#elif defined(SMOKE_FAIL)
    smoke_printf("TEST_RESULT=FAIL\n");

    smoke_exit(1);
#else
    smoke_printf("TEST_RESULT=PASS\n");

    smoke_exit(0);
#endif
}
