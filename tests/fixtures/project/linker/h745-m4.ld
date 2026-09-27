/* Configure-only explicit linker script for the STM32H745 Cortex-M4 core. */
MEMORY
{
  FLASH (rx) : ORIGIN = 0x08100000, LENGTH = 1024K
  RAM (xrw) : ORIGIN = 0x10000000, LENGTH = 288K
}
SECTIONS
{
  .text : { *(.text*) } > FLASH
  .checksum : { KEEP(*(.checksum)) } > FLASH
}
