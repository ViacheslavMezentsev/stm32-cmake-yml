# Firmware test groups

[Documentation](index.md) · [Русский](../ru/firmware-plan.md) · [Execution contract](firmware-testing.md)

The goal is to cover use cases with an observable contract on a selected model.
The 171 Configure cases are not 171 firmwares: malformed YAML, reconfiguration
and synthetic libraries do not need executable counterparts. Each new group gets
its own branch.

| Group | Contract | Starting point and boundary |
| --- | --- | --- |
| 1. Basic execution | Startup, .data/.bss, C++ construction, metadata, CRC, exit and hang | Adapted F1 `02-semihosting`: 18 builds, 24 QEMU + 24 Renode runs. Merged into main (`493771d`). |
| 2. Build modes | Bare metal without CMSIS/HAL and with project-owned startup; CMSIS without HAL; explicit/template linker scripts; profiles on one MCU | Merged into main `ba9bde7`: four extra profiles, own bare startup and shared runtime assertions. Total: 42 builds and 48 checks per simulator. No new clock/peripheral configuration. |
| 3. Libraries and C/C++ runtime | Custom CMake modules, ETL, language flags; Arduino and RTOS in subsequent separate stages | Merged into main `a53f809`: mixed C/C++ library and ETL vector/string without I/O; total 54 builds / 120 simulator checks. E008 fixed in 0.9.3 (`d8708b4`), workaround removed; full Arduino startup remains a separate contract; FreeRTOS stages are described below. External FreeRTOS (E007) is fixed in 0.9.3 and exercised by the `freertosExternal` profile. |
| 4. Cores and ABI | M0, M3, M4/FPU, M7; startup, instruction sets and soft/hard-float | Done in 0.9.3 (spec 8.8.8, TC-67): every profile for F0 (M0), F1 (M3), F4 and G4 (M4F, hard float), F7 (M7F); QEMU `netduino2`/`netduinoplus2` for F0, F1, F4, Renode for all — [emulators per family](emulation.md#emulators-per-family). Running M0 code on an M3 in QEMU does not prove M0 compatibility; Renode checks it. F3 is not in the matrix. |
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

Arduino String with own main is merged into main (`5743602`): 60 total builds / 132 simulator checks. Full Arduino startup remains a separate stage; RTOS stages are described below.

Merged into main (`4109bc8`), `codex/firmware-freertos-queue`: queues and Heap::4 before scheduler startup, 66 total builds / 144 checks.

Merged into main (`f16eb09`), `codex/firmware-freertos-tasks`: starter creates receiver and sender then deletes itself; queue exchange, SysTick wakeup without HAL and semihosting from a task. Total: 72 builds / 156 checks.

## Optimistic size estimate

This estimate predates group 4 and is kept as a guide. The actual 0.9.3 matrix is
already larger: 13 profiles per target plus 4 H7/H5 profiles give 570 builds and 948
simulator runs, 66 of them corrupted ELF copies ([firmware testing](firmware-testing.md)).

A planning target, not verified coverage: **50–60 distinct firmware profiles,
300–360 builds and roughly 500–650 simulator executions** across six GCC/CMake
pairs. This estimates representative coverage of existing configuration
mechanisms, not every possible combination of YAML values (an unbounded set).

One possible upper-target breakdown:

| Group | Profiles in the estimate |
| --- | ---: |
| Profiles implemented at the time of the estimate, including FreeRTOS tasks | 12 |
| Additional IOC/profile, linking, runtime and library variants | 12 |
| Additional Arduino/RTOS APIs and integration variants | 10 |
| Additional F0/F3/F4/F7/G4, startup and ABI/FPU variants | 18 |
| Limited GPIO/UART/timer scenarios | 8 |
| **Total** | **60** |

If 42 profiles can run on both simulators and 18 on one, the result would be
**360 builds and 624 checks**: `(42 × 2 + 18) × 6 + 12`. The final 12 are the
corrupted-ELF runs at the time of the estimate. This illustrative allocation requires model audits;
an incompatible model reduces execution counts rather than creating a false pass.

Configure is separate: the current 171 scenarios give 1026 checks, including
22 expected-error scenarios and 26 multistep scenarios. They do not need to
become 171 distinct firmwares. Keeping that suite, the example above would total
**about 1458 Configure + simulator checks**, besides 360 builds and script/docs
checks. The Builds (Checks) badge counts only the firmware matrix.
