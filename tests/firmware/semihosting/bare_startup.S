/* Test-owned Cortex-M startup: no CMSIS, HAL or clock configuration.
   Thumb-1 instructions only, so the same file serves ARMv6-M (Cortex-M0)
   and ARMv7-M/ARMv7E-M targets; -mcpu comes from the profile options. */
.syntax unified
.thumb
.section .isr_vector,"a",%progbits
.global bare_vectors
bare_vectors:
.word _estack
.word Reset_Handler
.rept 14
.word Default_Handler
.endr
.section .text.Reset_Handler,"ax",%progbits
.global Reset_Handler
.type Reset_Handler,%function
.thumb_func
Reset_Handler:
    ldr r0, =_sidata
    ldr r1, =_sdata
    ldr r2, =_edata
1:  cmp r1, r2
    bhs 2f
    ldr r3, [r0]
    str r3, [r1]
    adds r0, r0, #4
    adds r1, r1, #4
    b 1b
2:  ldr r1, =_sbss
    ldr r2, =_ebss
    movs r3, #0
3:  cmp r1, r2
    bhs 4f
    str r3, [r1]
    adds r1, r1, #4
    b 3b
4:  bl __libc_init_array
    bl main
    b Default_Handler
.size Reset_Handler, .-Reset_Handler
.section .text.Default_Handler,"ax",%progbits
.type Default_Handler,%function
.thumb_func
Default_Handler:
    b Default_Handler
/* newlib's init-array helper expects _init with -nostartfiles. */
.global _init
.type _init,%function
.thumb_func
_init:
    bx lr
