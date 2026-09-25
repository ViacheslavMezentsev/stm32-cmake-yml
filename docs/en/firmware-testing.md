# Firmware build and QEMU smoke tests

[Documentation](index.md) · [Русский](../ru/firmware-testing.md) · [Environment](emulation.md)

The first firmware test adapts the author's F1 [02-semihosting example](../../tests/firmware/semihosting/README.md).
It is separate from the 115 configure scenarios: **18 builds and 18 QEMU runs**:
three profiles × three xPack GCC versions × two CMake versions from the
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

Normal runs have a 15-second timeout. A hang before metadata is printed, a crash,
a missing marker, an unexpected exit code or conflicting markers fails the suite.
The intentional failure and timeout are passing *harness tests*, not ignored errors.
stdout/stderr, command lines, observed exits and emulator version are retained.
No GDB server or GUI is started. SYS_EXIT_EXTENDED uses the reason/status block;
stdio is flushed before exit. Compiler version is compared with the build manifest.
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
artifacts/logs for 14 days. CRC and Renode execution remain subsequent steps. No F1 peripheral or clock-model support
is inferred from running this ELF on the F205-based netduino2.

## Matrix isolation and compatibility

The matrix is read from the shared dependency lockfile, not duplicated in YAML.
Images are built once; tool pairs run sequentially with separate build/log paths.
Actual GCC/CMake versions and all three profiles are checked for each pair.
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
extra corruption experiment is not part of the recurring 18-run CI matrix; CRC
coverage is still separate future work. The original demo remains read only.
