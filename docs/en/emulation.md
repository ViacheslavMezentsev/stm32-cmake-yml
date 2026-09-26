# Emulation environment

[Documentation](index.md) · [Русский](../ru/emulation.md) · [Roadmap](../../TODO.md)

This first stage checks executable availability, versions and QEMU machines only.
It does not build/load firmware or validate semihosting, CRC or peripherals.
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

## Next stages

Steps 1–4 are implemented in the [firmware suite](firmware-testing.md): 18 builds and 24 QEMU and 24 Renode runs. [Further groups](firmware-plan.md).

1. Agree the first known-working example with the author; build ELF and inspect
   sections, vectors and stack. Then expand to three GCC and two CMake versions.
2. QEMU early startup without PLL/peripheral initialization, semihosting, success,
   intentional failure and a hanging test terminated by a timeout.
3. Compare profile/MCU/GCC/Git/library metadata with expectations; check .data/.bss
   initialization. Report the build MCU separately from the emulator model.
4. CRC: .checksum after all FLASH load sections, including the .data load image;
   identical range/fill bytes, software calculation and an intentionally corrupted
   image. Discuss E004/E006 and framework changes separately.
5. Repeat in Renode and validate termination semantics; a runner/Robot Framework
   adapter may translate the guest result into the process result if needed.
6. Expand bare metal/CMSIS/HAL/Arduino scenarios and add VS Code debug launches.

Each run needs isolated logs, a timeout and a mandatory final marker. Never hide
errors/timeouts with `|| true`. Check model CPU, FPU and memory-map compatibility;
a memory-backed peripheral stub does not validate device behavior. Resolve ELF/BIN
loading and FLASH gap differences before CRC. CI must not wait for GDB; isolate
debug ports and processes. SYS_WRITE0 is verified on the pinned versions; Renode SYS_EXIT_EXTENDED
uses an explicit test adapter.

A separate [first build and QEMU test](firmware-testing.md) is now implemented.
