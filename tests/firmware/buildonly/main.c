/* Minimal CMSIS firmware for families without the F103 smoke model.
 *
 * Built on every tool pair (spec 8.8.5, TC-57) and run in a minimal Renode
 * platform (tests/firmware/renode/<family>-smoke.repl): CPU, NVIC, memories and
 * RAM stubs for the registers SystemInit touches. Output goes through ARM
 * semihosting SYS_WRITE0, the result through SYS_EXIT_EXTENDED at
 * smoke_exit_trap, the same protocol as the F103 semihosting firmware.
 */
#include <stdint.h>
#if defined(STM32H7)
#include "stm32h7xx.h"
#elif defined(STM32H5)
#include "stm32h5xx.h"
#endif

volatile uint32_t smoke_counter = 0x12345678u;

#if defined(SMOKE_BKPSRAM)
/* Initialized data outside FLASH: must not enter the CRC image (spec 4.15.9). */
__attribute__((section(".bkpsram"), used)) volatile uint32_t smoke_boot_marker = 0xB007B007u;
#endif

static void smoke_write(const char* text)
{
    register uint32_t operation __asm__("r0") = 4u; /* SYS_WRITE0 */
    register const char* parameter __asm__("r1") = text;
    __asm__ volatile("bkpt 0xAB" : "+r"(operation), "+r"(parameter) : : "memory");
}

static void smoke_hex(const char* key, uint32_t value)
{
    static const char digits[] = "0123456789ABCDEF";
    char line[48];
    unsigned position = 0;
    while (*key && position < 30) {
        line[position++] = *key++;
    }
    line[position++] = '=';
    for (int shift = 28; shift >= 0; shift -= 4) {
        line[position++] = digits[(value >> shift) & 0xFu];
    }
    line[position++] = '\n';
    line[position] = '\0';
    smoke_write(line);
}

/* ARM SYS_EXIT_EXTENDED: reason ADP_Stopped_ApplicationExit + status. */
__attribute__((noreturn, noinline)) static void smoke_exit(uint32_t status)
{
    const uint32_t arguments[2] = {0x20026u, status};
    register uint32_t operation __asm__("r0") = 0x20u;
    register const uint32_t* parameter __asm__("r1") = arguments;
    __asm__ volatile(".global smoke_exit_trap\nsmoke_exit_trap:\nbkpt 0xAB" : "+r"(operation), "+r"(parameter) : : "memory");
    for (;;) {
    }
}

#if defined(SMOKE_CRC)
extern const uint32_t __checksum_start[];
extern const uint32_t __checksum_end[];

/* STM32 CRC-32 (spec 4.15.3) over the FLASH image up to .checksum. */
static uint32_t smoke_crc(const uint32_t* begin, const uint32_t* end)
{
    uint32_t crc = 0xFFFFFFFFu;
    for (const uint32_t* word = begin; word < end; ++word) {
        crc ^= *word;
        for (int bit = 0; bit < 32; ++bit) {
            crc = (crc & 0x80000000u) ? (crc << 1) ^ 0x04C11DB7u : crc << 1;
        }
    }
    return crc;
}
#endif

int main(void)
{
    int passed = 1;
    smoke_write("SMOKE_BUILDONLY=1\n");
    smoke_write("PROFILE=" SMOKE_PROFILE "\n");
    smoke_hex("CPUID", SCB->CPUID);
    /* Initialized .data copied by the startup code. */
    if (smoke_counter != 0x12345678u) {
        passed = 0;
    }
    smoke_counter++;
    smoke_hex("DATA", smoke_counter);
#if defined(SMOKE_CRC)
    const uint32_t stored = *__checksum_end;
    const uint32_t computed = smoke_crc(__checksum_start, __checksum_end);
    smoke_hex("CRC_STORED", stored);
    smoke_hex("CRC_COMPUTED", computed);
    smoke_write(stored == computed ? "CRC_RESULT=PASS\n" : "CRC_RESULT=FAIL\n");
    passed = passed && stored == computed;
#endif
#if defined(SMOKE_CRC)
    /* Same code in h503 and h503bkp, so their FLASH images and CRC are equal
       (TC-63); the runner expects B007B007 only when .bkpsram was loaded. */
    smoke_hex("BKPSRAM", *(volatile const uint32_t*)0x40036400u);
#endif
    smoke_write(passed ? "TEST_RESULT=PASS\n" : "TEST_RESULT=FAIL\n");
    smoke_exit(passed ? 0u : 1u);
}
