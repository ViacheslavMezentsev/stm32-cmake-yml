# Firmware build and QEMU smoke tests

[Documentation](index.md) · [Русский](../ru/firmware-testing.md) · [Environment](emulation.md)

The first firmware test adapts the author's F1 [02-semihosting example](../../tests/firmware/semihosting/README.md).
It is separate from the 115 configure scenarios: **three builds and three QEMU runs**,
on one tool pair (xPack GCC 14.2.1-1.1 / CMake 3.28.3), CubeF1 1.8.7, QEMU 11.0.0.
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

Normal runs have a 15-second timeout. A hang before metadata is printed, a crash,
a missing marker, an unexpected exit code or conflicting markers fails the suite.
The intentional failure and timeout are passing *harness tests*, not ignored errors.
stdout/stderr, command lines, observed exits and emulator version are retained.
No GDB server or GUI is started. SYS_EXIT_EXTENDED uses the reason/status block;
stdio is flushed before exit. Compiler version is compared with the build manifest.
Other library versions are diagnostic output at this stage.

## Running locally

Build the [compiler image](testing.md) and [emulator image](emulation.md) first.
The following shell commands use Linux paths; from PowerShell use the equivalent
absolute bind paths. The source mount is read only.

```sh
mkdir -p build/firmware-smoke build/firmware-qemu
docker run --rm --network none -e GCC_VERSION=14.2.1-1.1 -e CMAKE_VERSION=3.28.3 \
  -v "$PWD:/workspace:ro" -v "$PWD/build/firmware-smoke:/results" \
  stm32-yml-ci:local python3 /workspace/ci/build_firmware_smoke.py --output /results
docker run --rm --network none -v "$PWD:/workspace:ro" -v "$PWD/build/firmware-qemu:/results" \
  stm32-yml-emulation:local python3 /workspace/ci/run_qemu_smoke.py \
  --build /workspace/build/firmware-smoke --output /results
```

Use the already-built ELF files with local QEMU on Windows:

```powershell
python ci/run_qemu_smoke.py --build build/firmware-smoke --output build/firmware-qemu-windows
python -m unittest discover -s tests -p test_firmware_runner.py
```

`--qemu` accepts an explicit executable. Builds use fresh directories and replace
the manifest at the start; a failed build cannot reuse a stale successful manifest.
The [workflow](../../.github/workflows/firmware.yml) builds both images and saves
artifacts/logs for 14 days. The compiler matrix, runtime .data/.bss checks, CRC and
Renode execution remain subsequent steps. No F1 peripheral or clock-model support
is inferred from running this ELF on the F205-based netduino2.
