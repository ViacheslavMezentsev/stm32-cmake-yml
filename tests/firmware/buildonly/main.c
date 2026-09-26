/* Minimal build-only firmware: CMSIS startup/system, no HAL, no simulator. */
#if defined(STM32H7)
#include "stm32h7xx.h"
#elif defined(STM32H5)
#include "stm32h5xx.h"
#endif

volatile uint32_t smoke_counter = 0x12345678u;

#if defined(SMOKE_BKPSRAM)
/* Initialized data outside FLASH: must not enter the CRC image (spec 4.15.9). */
__attribute__((section(".bkpsram"), used)) uint32_t smoke_boot_marker = 0xB007B007u;
#endif

int main(void)
{
    for (;;) {
        smoke_counter++;
    }
}
