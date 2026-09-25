# Firmware test groups

[Documentation](index.md) · [Русский](../ru/firmware-plan.md) · [Execution contract](firmware-testing.md)

The goal is to cover use cases with an observable contract on a selected model.
The 115 Configure cases are not 115 firmwares: malformed YAML, reconfiguration
and synthetic libraries do not need executable counterparts. Each new group gets
its own branch.

| Group | Contract | Starting point and boundary |
| --- | --- | --- |
| 1. Basic execution | Startup, .data/.bss, C++ construction, metadata, CRC, exit and hang | Adapted F1 `02-semihosting`: 18 builds, 24 QEMU + 24 Renode runs. Implemented in this branch. |
| 2. Build modes | Bare metal without CMSIS/HAL and with project-owned startup; CMSIS without HAL; explicit/template linker scripts; profiles on one MCU | Next branch. F1 `cmsis-02-semihosting` is a candidate; bare metal gets a separate minimal fixture. Specify vectors, stack, flags and HSI without PLL. |
| 3. Libraries and C/C++ runtime | Custom CMake modules, ETL, language flags; Arduino and RTOS in subsequent separate stages | F1 `etl-default` is a candidate. Start with algorithms without I/O; Arduino startup and RTOS tick need their own contracts. External FreeRTOS/E007 stays regression/errata only, without a fix. |
| 4. Cores and ABI | M0, M3, M4/FPU, M7; startup, instruction sets and soft/hard-float | Separate F0, F1, F3/F4/G4 and F7 checks. Use netduino2/netduinoplus2 only after confirming ISA and memory compatibility; a higher core does not prove a lower core works. Use an appropriate Renode model for other cases. |
| 5. Peripherals | GPIO, SysTick/timers, UART, then individual protocols | Start with `03-blink`, HSI without PLL; assert GPIO events and virtual time. Requires functional register/IRQ models. Memory stubs cannot establish peripheral behavior. External devices and electrical properties need hardware tests. |

Candidates come from [demo-stm32-cmake](https://github.com/ViacheslavMezentsev/demo-stm32-cmake),
primarily stm32f1xx and stm32f4xx. Naming an example schedules inspection; it does
not establish simulator compatibility of its current contents. Original local
projects remain read only.

## Admitting a scenario

1. Inspect CPU/ISA/FPU, VMA/LMA, reset/vectors and pre-main device accesses.
2. Classify it as build-only, runnable on a named model, or blocked with a reason.
   An unavailable model is not a passing test.
3. Build on GCC 14.2 / CMake 3.28 first; check ELF/BIN and expected output.
4. Add a contract-specific negative check and bounded execution time.
5. Expand to the six locked tool pairs and suitable simulators. Preserve commands,
   versions, metadata and exclusion reasons.

Cover different build mechanisms on one MCU before expanding cores. Compatibility
belongs to a firmware execution path, not an entire family name. Reports must
explicitly identify partial models. Incorporate the author's guidance before a
new group; the already selected semihosting firmware can be moved between
simulators without choosing the example again.
