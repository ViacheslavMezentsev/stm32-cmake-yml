# Emulation environment

[Documentation](index.md) · [Русский](../ru/emulation.md) · [Roadmap](../../TODO.md)

The environment check `ci/emulation/check.py` covers executable availability, versions and
QEMU machines. It does not build or run firmware; the [firmware tests](firmware-testing.md) do.
Environment checks are not included in the configure-test count on the [status page](status.md).

## Local checks

From the repository root:

```powershell
python ci/emulation/check.py --output build/emulation/environment.json
python ci/emulation/check.py --qemu "C:/path/qemu-system-arm.exe" --renode "C:/Program Files/Renode/renode.exe"
python -m unittest discover -s ci/emulation -p test_check.py
```

On Windows, `scoop install qemu` is convenient; for exactly 11.0.0 use the
[20260422 installer](https://qemu.weilnetz.de/w64/2026/qemu-w64-setup-20260422.exe)
([details](../../tools/qemu/README.md)).

Resolution order: CLI option → QEMU_BINARY/RENODE_BINARY → PATH. On Windows,
Renode also falls back to Program Files/Renode. An invalid explicit path fails
instead of silently selecting another installation. Arguments bypass the shell;
paths with spaces work. Each command has a 30-second timeout. Launch errors,
version mismatches and missing machines produce a nonzero exit and JSON error.
The checker does not install software.

Local releases at least as new as the lock are accepted, without claiming that
all newer versions are compatible. Full version output, including build ID, is
recorded. --locked requires the same release number; container binary provenance
is additionally controlled by archive SHA-256 verification.

## Linux CI

```sh
docker build --platform linux/amd64 -f ci/emulation/Dockerfile -t stm32-yml-emulation:local .
docker run --rm --network none stm32-yml-emulation:local
```

The [lockfile](../../ci/emulation/versions.lock.json) pins QEMU 11.0.0 and Renode
1.16.1. QEMU is not compiled during the image build: it comes from the prebuilt
[tools/qemu](../../tools/qemu/README.md) archive (arm-softmmu without a GUI, built
from the official release archive; both SHA-256 values are pinned). Renode uses
the portable .NET archive. Required machines are netduino2 and
netduinoplus2. Ubuntu is pinned by digest; OS packages receive updates and their
versions are recorded in /opt/emulation/packages.txt. The image is not claimed
to be bit-reproducible. The build context is the repository root; `.dockerignore`
excludes `.git` and `build`.

The [workflow](../../.github/workflows/emulation.yml) builds a separate image,
checks it offline and uploads logs, JSON and installed package versions. Compiler
infrastructure remains separate. Building the image requires network access and
may take several minutes. Official sources: [QEMU](https://download.qemu.org/),
[Renode 1.16.1](https://github.com/renode/renode/releases/tag/v1.16.1).

## Emulators per family

Every target runs all 13 profiles of the test firmware and a corrupted copy
(spec 8.8.8, TC-67); H7 and H5 use separate minimal firmware (TC-57). The target
list is `TARGETS` in [ci/firmware_cases.py](../../ci/firmware_cases.py), the Renode
models are in `tests/firmware/renode/`.

| Family | MCU | Core | QEMU | Renode | Why |
| --- | --- | --- | --- | --- | --- |
| F1 | STM32F103C8T6 | Cortex-M3 | `netduino2` (STM32F205) | `f103-smoke` | Reference target; core and memory map match |
| F0 | STM32F030R8T6 | Cortex-M0 | `netduino2` (M3 core) | `f030-smoke` (`cortex-m0`) | QEMU has no M0 machine with Flash at `0x08000000`; Thumb-1 code runs on the M3, only Renode checks the M0 core |
| F4 | STM32F411CEU6, STM32F401CCU6 | Cortex-M4F | `netduinoplus2` (STM32F405) | `f4-smoke` (`cortex-m4`) | The machine's FLASH and SRAM cover both targets |
| G4 | STM32G431CBU6, STM32G474CEU6 | Cortex-M4F | — | `g4-smoke` (`cortex-m4`) | QEMU has no G4 machine |
| F7 | STM32F746ZGT6 | Cortex-M7F | — | `f7-smoke` (`cortex-m7`) | QEMU has no Cortex-M7 machine with Flash at `0x08000000` |
| H7 | STM32H743ZI | Cortex-M7 | — | `h7-smoke` | Same; `h7` firmware only |
| H5 | STM32H563ZI, STM32H503CB | Cortex-M33 | — | `h5-smoke` | QEMU has no M33 machine with Flash at `0x08000000` |

The models check the core, FPU, NVIC/SysTick and memory map, not peripherals:
RCC and the FLASH controller are RAM stubs, and HAL_Init takes the path without PLL.

## QEMU specifics

- **Command.** `qemu-system-arm -M <machine> -nographic -monitor none -serial none
  -no-reboot -semihosting-config enable=on,target=native -kernel <elf>`
  ([run_qemu_smoke.py](../../ci/run_qemu_smoke.py)). `target=native` makes QEMU
  handle semihosting itself, without GDB; `-no-reboot` ends the process on a guest
  reset; `-serial none` and `-monitor none` leave only semihosting output on stdout.
- **Exit.** SYS_EXIT_EXTENDED is supported: the QEMU exit code equals the guest
  status (0, 1, or 3 for crc-corrupt).
- **Timeouts.** 15 s per run, 2 s for the `hang` profile; a timeout of any other
  profile is a failure.
- **Machine core, not the MCU.** CPUID reports the machine core: Cortex-M3 for F030
  on `netduino2`. The runner compares the core line with the target's `qemu_part`,
  and Renode with `renode_part`.
- **Peripherals.** The machines model STM32F205/F405, not the built MCU; the
  `TEST_PLATFORM` line (for example `cortex-m4-smoke`) names the test platform, not a board.
- **Windows.** QEMU 11.1.0 was also checked locally; CI uses 11.0.0 from
  [tools/qemu](../../tools/qemu/README.md).

## Renode specifics

- **Command.** `renode --disable-gui --console --plain --config renode.config
  --execute "include <script>.resc"` ([run_renode_smoke.py](../../ci/run_renode_smoke.py)).
  `renode.config` sets `use-synchronous-logging = True` and
  `collapse-repeated-log-entries = False`: the 1.16.1 asynchronous logger lost
  entries before `Clear`. Case markers are written with `log`, not `echo`.
- **Batch mode.** All cases of one GCC/CMake pair run in one process; `Clear`
  recreates the machine before each case. `--renode-mode process` runs one process
  per case for diagnostics, `--renode-shuffle <seed>` shuffles the order.
- **Semihosting.** `UART.SemihostingUart` handles SYS_WRITE0. SYS_EXIT_EXTENDED and
  newlib SYS_WRITE are not supported, so the firmware prints through `vsnprintf` +
  SYS_WRITE0, and [exit_hook.py](../../tests/firmware/renode/exit_hook.py)
  (`sysbus.cpu AddHook` on `smoke_exit_trap`) reads R0/R1 and the status block from
  target RAM and halts the CPU.
- **Time.** `emulation RunFor "0.1"` gives 0.1 s of virtual time per case and 30 s
  on the host. `hang` needs the full output without a guest exit.
- **Core type.** `cpuType: "cortex-m4f"` in Renode 1.16.1 reports a Cortex-M7 CPUID
  (0x411FC272), so the F4 and G4 models use `cortex-m4`; it has an FPU, as the
  hard-float profiles and FreeRTOS `ARM_CM4F` confirm.
- **NVIC.** `priorityMask: 0xC0` for Cortex-M0 (2 priority bits), `0xF0` for the
  other cores (4 bits). FreeRTOS writes 0xFF to the IRQ 16 priority at startup, and
  Renode warns about the mask; the runner allows exactly one such warning, only in
  `freertosTasks`.
- **SysTick.** `systickFrequency`: 8 MHz for F0/F1, 16 MHz for F4/G4/F7, 32 MHz for
  H5, 64 MHz for H7; the frequency is not checked. After VAL = 0 is written, Renode
  reloads the counter from the previous LOAD (0xFFFFFF after reset). The fixture
  overrides the weak `vPortSetupTimerInterrupt` (LOAD, then VAL, then enable), and
  for the FreeRTOS V10.0.1 `ARM_CM0` port without that hook it writes LOAD before
  starting the scheduler; otherwise the first tick comes after about 2 s.
- **Models.** Stock Renode platforms are not used: their broad memory map and online
  SVD download are unnecessary. A model is `CPU.CortexM`, NVIC,
  `Memory.MappedMemory` for FLASH/SRAM and RAM stubs for the registers that
  SystemInit/HAL_Init touch.

Protocol and report details: [firmware tests](firmware-testing.md); scenario
groups: [plan](firmware-plan.md).
