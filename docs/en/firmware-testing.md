# Firmware build and QEMU/Renode smoke tests

[Documentation](index.md) · [Русский](../ru/firmware-testing.md) · [Environment](emulation.md)

The first firmware test adapts the author's F1 [02-semihosting example](../../tests/firmware/semihosting/README.md).
It is separate from the 115 configure scenarios: **72 builds, 78 QEMU runs and 78 Renode runs**:
twelve profiles plus one corrupted copy per tool pair; three xPack GCC versions × two CMake versions from the
[lockfile](../../ci/dependencies.lock.json), CubeF1 1.8.7, QEMU 11.0.0.
The Windows QEMU 11.1.0 installation was also checked locally; CI uses the pinned image.

## Contract

Builds must produce nonempty ELF/BIN/HEX/MAP/LSS. ELF inspection verifies ELF32 ARM,
Thumb reset/entry agreement, an aligned initial stack pointer in 20 KiB RAM, and
load segments within the F103C8 FLASH/RAM limits (64/20 KiB), including .data LMA.
Readelf output is retained. These checks do not establish general linker correctness.

| Profile | Expected execution |
| --- | --- |
| success | Compiler/target/machine/CPU output, TEST_RESULT=PASS, exit 0 |
| failure | Same startup output, TEST_RESULT=FAIL, exit 1 |
| hang | Startup output but no result marker, timeout after 5 seconds |
| bare / bareTemplate | Own startup, no CMSIS/HAL, TEST_RESULT=PASS, exit 0 |
| cmsis / cmsisTemplate | CMSIS startup, no HAL, TEST_RESULT=PASS, exit 0 |
| cmsisLibrary / cmsisEtl | C/C++ library and optional ETL, TEST_RESULT=PASS, exit 0 |
| arduinoString | Arduino String with own main/startup, TEST_RESULT=PASS, exit 0 |
| freertosTasks | Starter task, queue exchange, SysTick and semihosting, exit 0 |
| freertosQueue | FreeRTOS FIFO and Heap::4 before scheduler startup, TEST_RESULT=PASS, exit 0 |

Normal runs have a 15-second timeout. A hang before metadata is printed, a crash,
a missing marker, an unexpected exit code or conflicting markers fails the suite.
The intentional failure and timeout are passing *harness tests*, not ignored errors.
stdout/stderr, command lines, observed exits and emulator version are retained.
No GDB server or GUI is started. SYS_EXIT_EXTENDED uses the reason/status block;
SYS_WRITE0 emits output immediately. Compiler version is compared with the build manifest.
CMSIS Core/Device, HAL and framework versions are compared with the reviewed
expected-metadata.json baseline for the pinned dependencies.

## Running locally

Build the [compiler image](testing.md) and [emulator image](emulation.md) first.
The following shell commands use Linux paths; from PowerShell use the equivalent
absolute bind paths. The source mount is read only.

```sh
mkdir -p build/firmware-smoke build/firmware-qemu
docker run --rm --network none \
  -v "$PWD:/workspace:ro" -v "$PWD/build/firmware-smoke:/results" \
  stm32-yml-ci:local python3 /workspace/ci/firmware_matrix.py build --output /results
docker run --rm --network none -v "$PWD:/workspace:ro" -v "$PWD/build/firmware-qemu:/results" \
  stm32-yml-emulation:local python3 /workspace/ci/firmware_matrix.py run \
  --build /workspace/build/firmware-smoke --output /results
```

Use the already-built ELF files with local QEMU on Windows:

```powershell
python ci/firmware_matrix.py run --build build/firmware-smoke --output build/firmware-qemu-windows
python -m unittest discover -s tests -p "test_firmware*.py"
```

`--qemu` accepts an explicit executable. Builds use fresh directories and replace
the manifest at the start; a failed build cannot reuse a stale successful manifest.
The [workflow](../../.github/workflows/firmware.yml) builds both images and saves
artifacts/logs for 14 days. Both simulators use the same ELFs. No F1 peripheral or clock-model support
is inferred from running this ELF on the F205-based netduino2.

## Matrix isolation and compatibility

The matrix is read from the shared dependency lockfile, not duplicated in YAML.
Images are built once; tool pairs run sequentially with separate build/log paths.
Actual GCC/CMake versions and all twelve profiles are checked for each pair.
Failures do not stop collection of other pair results, but the matrix exits nonzero
if any pair fails. Run selection uses the current lockfile rather than accepting
whatever manifests happen to exist. Aggregate reports are matrix-summary.json;
individual reports remain build-summary.json and qemu-summary.json.

The fixture uses C11 and C++17. CMake 3.19 rejects C_STANDARD=17 even with a
compiler that supports C17: CMake added that value in 3.21. The source C files do
not need C17. This is a fixture compatibility adjustment, not a framework change.
To run just one pair, the original build_firmware_smoke.py/run_qemu_smoke.py remain
available with a dedicated output directory.

## Metadata and initial memory state

Each profile prints PROFILE, CMAKE, FRAMEWORK, GIT_REVISION and GIT_DIRTY.
The header is generated from the actual CMake configuration; the builder records
Git HEAD and whether the working tree has changes. HEAD plus a dirty flag is not
a content hash of uncommitted changes. Date/time fields remain diagnostic only.
A missing field, wrong value or duplicate metadata field fails the run, including
the intentional failure and timeout profiles. Older build manifests without
metadata must be rebuilt.

Three volatile four-byte probes are checked at entry to main, before HAL setup:
initialized .data = 0x12345678, .bss = 0, and a C++ constructor-written value =
0xC0DEC0DE. A mismatch exits with code 2 before normal success/failure/hang behavior.
The builder verifies D/B symbol types and sizes using nm and records their addresses;
the runner compares those addresses with values printed by the firmware. Runtime
values are also checked independently against the reviewed baseline.

This observes initial memory state and constructor execution. Zero .bss alone does
not prove that the startup clearing loop executed: emulator RAM may start zeroed.
A development negative check modified only the .data probe's load bytes in a copy
of one ELF: the guest printed FAIL and exited 2, and the runner rejected it. That
extra .data corruption experiment is not part of the recurring CI matrix. The original demo remains read only.

## CRC of the loaded firmware

The test-local STM32F103C8_FLASH.ld keeps .data's FLASH load image and a four-byte
.fw_version record before .checksum. The record contains 0x00090200 (fixture
format for 0.9.2); it is retained by KEEP. This fixed 64/20 KiB layout is not a
general-purpose linker template. Existing startup, heap and stack symbols remain.

The framework injects STM32_HW_DEFAULT CRC. An independent host calculation and
the firmware's C++ calculation use polynomial 0x04C11DB7, initial 0xFFFFFFFF,
little-endian 32-bit words, no reflection and no final XOR. Three supplied vectors
are checked in Python and by static_assert. The range starts at 0x08000000 and
ends just before the checksum word; all bounds are word-aligned.

The builder rejects gaps/overlaps in FLASH load segments, a checksum that is not
last, misplaced .data/.fw_version, incorrect injected CRC and BIN/ELF differences.
The guest prints CRC_START, CRC_END, CRC_STORED, CRC_COMPUTED and CRC_RESULT;
all five fields must match the host manifest exactly, even for failure/hang.

For each tool pair, a copy of success ELF has one bit changed in .fw_version.
Code, startup data and the injected CRC remain unchanged. The derived negative case,
crc-corrupt, must report CRC_RESULT=FAIL and TEST_RESULT=FAIL and exit 3. A crash
or timeout cannot pass this case. This adds six runs without extra compilations:
72 builds, 78 runs per simulator. Reports distinguish twelve profiles from thirteen executions.

This verifies software CRC over loaded FLASH on netduino2, not the STM32 CRC
peripheral. E004 (algorithm selection) and E006 (post-build error handling) remain
open and unchanged. Old manifests must be rebuilt to include CRC expectations.

## Renode and a shared ELF

The fixture uses vsnprintf + SYS_WRITE0 instead of newlib SYS_WRITE/initialise_monitor_handles:
the pinned Renode 1.16.1 lacks the full set of those semihosting operations. This
changes test transport, not framework behavior. TEST_PLATFORM=cortex-m3-smoke replaces
the hardcoded EMULATOR_MACHINE=netduino2 line; the runner records the actual model
in its command and report.

[f103-smoke.repl](../../tests/firmware/renode/f103-smoke.repl) supplies Cortex-M3, NVIC,
64 KiB FLASH and 20 KiB RAM. RCC and the FLASH controller are memory stubs for the
selected HAL_Init path, without PLL or peripheral validation. The stock Renode F103
platform is not used: its broad memory ranges and online SVD are unnecessary here.

Renode handles SYS_WRITE0 natively. The [exit adapter](../../tests/firmware/renode/exit_hook.py)
hooks the exported smoke_exit_trap, reads R0/R1 and the reason/status block in RAM,
and halts the CPU. It does not supply expected results. Required values are operation
0x20, reason 0x20026 and status 0/1/3 for success/failure/crc-corrupt respectively.
The Renode process normally returns 0 for all three, which is insufficient to pass.

Each case gets 0.1 seconds of virtual time and a 30-second host deadline. Hang needs
complete expected output, no guest exit and completion of the virtual budget.
A host timeout always fails. Renode errors/warnings, incomplete scripts, wrong
metadata and output-buffer overflow fail the check. The sole exception is the exact
freertosTasks priority-probe warning documented below and retained in the report.
Artifacts include run.resc,
process.log, firmware.log, guest-exit.json (when reached) and renode-summary.json.
No downloads, GUI or GDB are needed.

```powershell
python ci/firmware_matrix.py run --emulator renode --build build/firmware-smoke --output build/firmware-renode
```

For one pair: `python ci/run_renode_smoke.py --build <pair-directory> --output <logs>`.
Use `--renode "C:/Program Files/Renode/renode.exe"` if needed; standard Windows
installation paths are discovered automatically. In the container, use the same
matrix runner and bind mounts as QEMU with `--emulator renode`. Rebuild old
ELFs/manifests: the smoke_exit_trap symbol address is now required.

Limitation source: [Renode 1.16.1 Arm.cs](https://github.com/renode/renode-infrastructure/blob/add012af003a0f620d3da52828262676f374d121/src/Emulator/Cores/Arm/Arm.cs).
Further scenarios: [five test groups](firmware-plan.md).

## Build modes and linker templates

The four additional profiles share the same F103C8 fixture and output protocol.
`bare` and `bareTemplate` replace sources with `bare_startup.S` and `main.cpp`;
they explicitly supply Cortex-M3/Thumb/soft-float flags and `-nostartfiles`.
The test-owned assembly provides core vectors, copies .data, clears .bss and calls
`__libc_init_array` before main. It does not include device IRQ handlers or a clock
initialization routine. This is a minimal CPU test, not a board startup template.
`cmsis` and `cmsisTemplate` retain the CMSIS device startup and the existing
SystemInit source, with HAL disabled. No new profile configures PLL or peripherals.
The inspected `cmsis-02-semihosting` example supplied the own-startup use case;
its GPIO/SysTick/HSE path was not imported.

Explicit `.ld` profiles reserve 512 bytes for heap and 1K for stack. The `Template`
profiles select `linker_script: auto`, discover `STM32F103C8_FLASH.ld.in` and
substitute heap=0 and stack=2K. The builder compares absolute linker symbols with
these expectations and the firmware prints their values. Reservations are not a
measurement of maximum stack usage or a proof that every application can use zero heap.
CRC remains after all FLASH load data, including .data and .fw_version.

`compile_commands.json` is checked for source selection: bare mode has only its
two project-owned sources and no CMSIS/HAL paths; CMSIS mode must include the ST
startup and exclude HAL sources. Absent libraries print `none` in metadata.
The shared profile list in `ci/firmware_cases.py` prevents old three-profile reports
from satisfying the expanded matrix. Unknown runtime profiles fail validation.

## User libraries and ETL

`cmsisLibrary` adds the `Library` source directory (its own CMakeLists.txt) and
links `Smoke::Library` through `link_libraries`. The mixed C/C++ static library
exports its include path and PUBLIC definition; PRIVATE definitions remain local.
Its CPU and language options are set explicitly because executable PRIVATE flags
do not propagate to separately compiled targets. Compile-time guards check the
C/C++ definitions and C++ no-exceptions/no-RTTI settings. ELF symbol inspection
requires the C function, C++ wrapper and executable C probe to survive linking.

Runtime volatile input `[3, 1, 4, 1, 5]` gives weighted sum 46 in C and XOR 0x55
in C++, producing `LIB_RESULT=123`; `C_LANGUAGE=11` confirms the executable's C
translation unit was called. Wrong results exit with status 4 and fail the run.
`cmsisEtl` also uses ETL vector push/pop and string operations, requiring sum 14,
text `etl:14`, and the version from ETL's header. Both profiles retain startup,
metadata and CRC checks and use CMSIS without HAL.

ETL 20.47.1 comes from the existing pinned lockfile; the builder passes its include
path to the test module. No new dependency download is added. The inspected
`etl-default` example's HSE setup and endless loop are not imported. This tests
the selected bounded container operations, not ETL's entire API or heap behavior.
The framework has not gained an ETL-specific configuration option.

The build exposed [E008](errata/E008.md): language keys declared only inside a
profile do not reach the executable. The fixture declares empty root lists as a
verified workaround; six configure-only probes preserve the known deviation.
These probes do not add firmware builds or simulator checks to the badge.

## Arduino String with a project-owned main

The author approved this first Arduino stage: software components and own main;
the default Arduino init/setup/loop, clock setup and SysTick remain separate work.
`arduinoString` selects the actual Arduino backend and `use_core_main: false`.
The consumer-owned `ArduinoString/CMakeLists.txt` builds pinned Core STM32 2.12.0
WString.cpp and itoa.c as Arduino::Core, with Arduino::Definitions usage requirements.
No Core sources are copied or mocked. Only the selected String components are
compiled, not the complete Arduino board core or SrcWrapper/HAL.

The toolchain is independent of stm32-cmake, reusing the existing consumer test
toolchain and adding real BIN/HEX helpers. Cortex-M3, Thumb, soft-float, nano/nosys
specs, `-nostartfiles` and `--gc-sections` are explicit. `use_newlib_nano: false`
disables the framework's STM32::Nano target; nano is selected by compiler/linker
specs instead. Direct SYS_WRITE0/SYS_EXIT_EXTENDED does not use nosys file I/O.
Unused floating-point String methods requiring dtostrf are discarded; float
formatting is outside this scenario. The builder supplies core_path relative to
the source directory, as required by this backend.

The existing test-owned startup initializes data, BSS and constructors. A bounded
512-byte `_sbrk` heap services real String allocations without semihosting heap
queries; this is a single-threaded test allocator, not an Arduino runtime replacement.
The test exercises reserve, integer construction, concatenation, copy, replace,
lowercasing, search, substring and toInt. It requires `ARDUINO_TEXT=arm32:123` and
`ARDUINO_LENGTH=9`; the runner checks both values. Failed internal checks or an
incorrect length terminate the firmware with status 5. Selected allocation failures
are also detected by these assertions; exhaustive heap exhaustion is not tested.
Existing FLASH CRC and metadata checks still apply. CMSIS/HAL fields are `none`.

This tests a narrow Arduino software path on netduino2 and the same Renode memory
model. It does not validate an F411 board, Arduino.h, Print, GPIO, Serial or timing.
The mcu_gcs_board configuration was inspected read-only for the wrapper/own-main
pattern; its F411 variant and device drivers were not imported.

## FreeRTOS: queues and memory before the scheduler

`freertosQueue` uses kernel V10.3.1 from pinned CubeF1, ARM_CM3 and Heap::4,
CMSIS startup without HAL and `cmsis_rtos_api: none`. Checks cover a two-item FIFO
(17 and 29), full/empty queue rejection with zero wait, allocation alignment,
oversized allocation rejection, and free memory recovery after freeing a block
and deleting the queue. Expected fields are RTOS_RESULT=46, RTOS_HEAP=restored
and RTOS_SCHEDULER=not-started. A failed check or configASSERT exits with status 6;
a hang is not accepted.

The FreeRTOS heap is a separate 4096-byte BSS array, independent of the newlib
`heap_size: 512` reservation. compile_commands must contain the kernel, port and
heap_4 sources. Scheduling, tasks, context switching, tick and CMSIS-RTOS are not
covered. Real port critical sections execute; SysTick is not started.
External FreeRTOS/E007 remains a separate regression without a fix.

## FreeRTOS: starter task and inter-task exchange

`freertosTasks` starts FreeRTOS without HAL or CMSIS-RTOS wrappers. A priority-2
starter creates two length-1 queues and two priority-1 tasks, then deletes itself
with vTaskDelete(NULL). The receiver waits for a request. The sender delays for
two ticks, sends 17 and waits for reply 46 (the receiver adds 29).
Queue waits are bounded to 1000 ticks. The receiver deletes itself; the sender
checks the reply, tick advancement and scheduler state, prints
`RTOS_TASK_MESSAGE=hello from sender` through SYS_WRITE0, then exits the simulator
through SYS_EXIT_EXTENDED. Only one task prints.

FreeRTOS owns Cortex-M3 SysTick. No additional TIM is needed: HAL_Init/HAL_IncTick
are not called and there is no separate HAL time base. The test overrides the
standard weak vPortSetupTimerInterrupt hook with CMSIS SysTick_Config: reload,
clear CURRENT, then enable. This avoids the observed Renode 1.16.1 first-tick
delay with the original port CURRENT-before-reload ordering; neither the kernel
nor the framework is changed. FreeRTOSConfig.h connects
the real port SVC/PendSV/SysTick handlers; the builder verifies their ELF vector
addresses. Renode SysTick runs at 8 MHz, matching configCPU_CLOCK_HZ. QEMU netduino2
still models F205, so the test checks logical tick progress rather than actual
F103 HSI frequency accuracy. Renode keeps its 0.1-second virtual budget; no
RCC/PLL/TIM hardware models are added. A lost tick fails the test.

This profile reserves an 8192-byte FreeRTOS BSS heap, including task stacks:
256 words each for starter/receiver and 512 for sender with formatted output.
The system stack_size remains 1K; the idle task and internal structures also fit
inside the heap. Long-running load, timing accuracy, FreeRTOS software timers and
HAL/RTOS coexistence are outside this test. configASSERT exits with status 6;
unexpected scheduler startup return is also an error.

The port requires 16-byte .text alignment. Test .ld/.ld.in files now explicitly
include padding up to that boundary inside .isr_vector. Previously the ELF gap
contained zeros while the CRC command used --gap-fill 0xFF; the independent CRC
check detected this discrepancy. The framework algorithm is unchanged: the test
image contract requires identical contiguous ELF/BIN FLASH bytes, with CRC after
all FLASH load sections.

FreeRTOS probes the priority mask by writing 0xFF to the priority of IRQ 16.
Renode warns that the value should be masked with 0xF0. The runner permits exactly
one occurrence of this exact warning only for freertosTasks, retaining it in the
report. Other warnings, duplicate probe warnings, errors or missing guest exit
still fail. configASSERT remains enabled.
