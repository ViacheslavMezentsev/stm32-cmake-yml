/* Configure-only explicit linker script for STM32H563ZI with the ARMv8-M stack limit. */
MEMORY
{
  FLASH (rx) : ORIGIN = 0x08000000, LENGTH = 2048K
  RAM (xrw) : ORIGIN = 0x20000000, LENGTH = 640K
}
_estack = ORIGIN(RAM) + LENGTH(RAM);
_Min_Stack_Size = 0x400;
_sstack = _estack - _Min_Stack_Size;
SECTIONS { .text : { *(.text*) } > FLASH }
