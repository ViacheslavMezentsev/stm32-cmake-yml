# Test environment

[Русский](../ru/testing.md)

Testing uses an isolated Linux environment and CTest configuration fixtures.
Existing `include(stm32_yml)` projects do not need any changes. The suite invokes
the framework from the current checkout and checks Configure/Generate results;
it does not build firmware.

## Contents

| Component | Pinned versions |
| --- | --- |
| Platform | Linux amd64, Ubuntu 24.04 by image digest |
| Ubuntu packages | Ubuntu repositories; installed versions recorded in the image |
| xPack Arm GCC | 13.3.1-1.1, 14.2.1-1.1, 15.2.1-1.1 |
| CMake | 3.19.8 (minimum compatibility), 3.28.3 (reference environment) |
| Ninja / Mike Farah yq | 1.12.1 / 4.44.3 |
| stm32-cmake | Commit recorded in the lockfile |
| STM32Cube | F1 1.8.7, F4 1.28.3, G4 1.6.3 |
| Arduino Core STM32 / ETL | 2.12.0 / 20.47.1 |

[dependencies.lock.json](../../ci/dependencies.lock.json) records archive SHA-256
checksums and source commits. Selected Cube submodules (CMSIS device, HAL and
FreeRTOS where it is a submodule) use the gitlinks of those commits, never remote
branch heads. BSP and unrelated middleware submodules are not initialized.
Git metadata and licenses are retained for inspection. The image records Ubuntu
package versions in `/opt/stm32-yml-ci/packages.txt`.

QEMU **11.0.0**, built from source, and Renode are planned for the later emulation
stage; neither is installed in this image. Arduino projects still need their own
CMake core/library wrappers. The image does not contain a copy of stm32-cmake-yml.

## Build and verify

Requires Docker with Linux containers. Run from the repository root in either
PowerShell or a Linux shell:

```sh
docker build --platform linux/amd64 -f ci/docker/Dockerfile -t stm32-yml-ci:local .
docker run --rm --network none stm32-yml-ci:local
```

The initial build downloads three toolchains and Cube sources: allow several GB
of disk space and time for downloads. Subsequent builds reuse Docker layers.
The Dockerfile-specific ignore file sends only environment inputs to Docker.
Archives are verified before extraction. Installation failure stops the build.

The default command checks tool versions, YAML conversion, pinned source commits
and required dependency files. It then configures a tiny C/C++/ASM project with
each of the six GCC/CMake pairs and verifies that Ninja files were generated.
CMake performs its own compiler checks, but no `cmake --build` is invoked.
This verifies environment readiness, **not** framework behavior, firmware
linking, CRC correctness or MCU peripheral simulation. Verification works offline.

## Select tools and use the checkout

Defaults: GCC `14.2.1-1.1`, CMake `3.28.3`. `GCC_VERSION` and `CMAKE_VERSION` select
installed versions; unsupported or empty values fail immediately.

```sh
docker run --rm --network none -e GCC_VERSION=13.3.1-1.1 -e CMAKE_VERSION=3.19.8 stm32-yml-ci:local cmake --version
docker run --rm --network none -e GCC_VERSION=15.2.1-1.1 stm32-yml-ci:local arm-none-eabi-gcc --version
```

Open a shell with the current checkout mounted read-only. Use `/tmp/build/...`
for outputs, or mount a separate writable directory. Linux:

```sh
docker run --rm -it --network none --mount "type=bind,source=$(pwd),target=/workspace,readonly" stm32-yml-ci:local bash
```

PowerShell:

```powershell
docker run --rm -it --network none --mount "type=bind,source=$($PWD.Path),target=/workspace,readonly" stm32-yml-ci:local bash
```

Inside the container:

- Toolchain: `$STM32_TOOLCHAIN_PATH` (also selected on `PATH`).
- stm32-cmake: `/opt/modules/stm32-cmake`.
- Cube: `/opt/STM32Cube/Repository/STM32Cube_FW_<family>_V<version>`;
  `CMAKE_USER_HOME=/opt` enables the framework's existing lookup.
- Arduino Core: `/opt/Arduino_Core_STM32/2.12.0`.
- ETL: `/opt/etl/20.47.1`.
- Framework under test: `/workspace`, supplied by the caller.

Use separate build directories per project/profile/GCC/CMake/build type.
Preserve the selected environment when launching commands (use `bash`, not a
login shell which can reset `PATH`). The same Docker commands work in the VS Code
terminal. Interactive debugging and VS Code launch configurations come later.

## Updates and CI

The environment workflow builds the image and verifies it without network access.
The separate `Configure tests` workflow runs on every pull request, pushes to
`main`, and manual dispatch. It builds the image once and tests all six tool pairs
in one job, continuing after a failing pair. Neither workflow publishes images
or builds firmware. Keeping this check unconditional also makes it suitable as
a required PR check without path-filtered runs remaining pending.

Update versions and hashes together in the lockfile, review upstream sources,
then rebuild and verify. When changing Ubuntu, also update the Dockerfile digest
to match the lockfile. CMake 3.28.3 is a fixed reference, not a claim to be the
latest CMake. Runtime libraries and Python packages follow Ubuntu updates;
this image freezes the testing tools and source dependencies, not every OS
package or the resulting image bytes. Ubuntu snapshots are not required.

## Framework configuration tests

[tests/cases.json](../../tests/cases.json) defines 36 scenarios, run with each of
the three GCC and two CMake versions from the lockfile: **216 case executions**.
Four scenarios perform three consecutive configurations in the same build tree.

| Area | Checks |
| --- | --- |
| Defaults and dependencies | F411 (BlackPill) and F103 (BluePill), actual CMSIS/HAL targets, default heap/stack, C/C++ standards |
| Profiles on the same MCU | List replacement, append, replacement followed by append, sources, external profiles, scalar override priority |
| IOC and YAML precedence | STM32F103C8T6, IOC-derived defaults, YAML/profile/override precedence, missing IOC |
| Bare metal | No CMSIS/HAL/FreeRTOS, unavailable Cube repository, explicit CPU flags and local linker template |
| YAML values | Unquoted scalars, `false`, zero heap, null/empty defaults, empty list replacement and append |
| Reconfiguration | Profile source/definition replacement and reset, persistent overrides and explicit cache removal with `-U` |
| Profile regressions | External profile listing, generated heap/stack updates, MCU and compiler defines after switching profiles |
| Language flags | Normalization and isolation of C and C++ flags/definitions in `compile_commands.json` |
| Linker | Explicit `.ld`, template discovery in `linker_script_dir`, heap/stack substitutions, READONLY and checksum section preservation |
| CRC | Presence/absence of the generated post-build command, section and Flash-size arguments |
| Arduino | Consumer-owned core/custom-library wrappers, profile parameters, shared compile definitions, `use_core_main: false` |
| Diagnostics | Missing/malformed YAML, missing linker/core, invalid memory size, HAL without CMSIS, profile listing and unknown-profile warning |

These are small **configure-only fixtures**, not ready-to-flash board examples.
The Arduino wrapper references a real pinned core source but does not describe a
complete board/variant. Its toolchain supplies the size helper required by the
current framework, following the consumer toolchain pattern. The synthetic
linker template tests substitutions and section preservation, not memory layout
correctness. CRC execution, firmware linking, peripherals, QEMU and Renode are
outside this stage. Compiler detection may compile CMake's own probes.

Positive cases require successful CMake exit, generated Ninja/cache/compilation
database files, and matching configuration or target properties. Negative cases
require both failure and a specific diagnostic, so an unrelated compiler failure
cannot count as success. Current compatibility behavior is preserved: an unknown
profile warns and continues; `STM32_YML_PROFILE=list` prints names and exits with
an error. Each case starts with a fresh cache; multi-step cases deliberately
reuse it and verify every step. Omitting a `-D` argument does not remove it from
CMakeCache: use `-USTM32_YML_OVERRIDE_stack_size` to remove an override, or
`-DSTM32_YML_PROFILE=` to return to the base configuration.

Regression cases also check external profile listing and changing memory sizes
or MCU in the same build tree. `MCU`, `HEAP_SIZE` and `STACK_SIZE` are derived
cache entries and now follow the resolved configuration on every configure
(`HEAP_SIZE`/`STACK_SIZE` when generating a local template). To override them,
use the configuration inputs `-DSTM32_YML_OVERRIDE_mcu=...`,
`-DSTM32_YML_OVERRIDE_heap_size=...`, `-DSTM32_YML_OVERRIDE_stack_size=...`.
Direct `-DMCU`, `-DHEAP_SIZE` or `-DSTACK_SIZE` values no longer take precedence
over the resolved YAML configuration. Changing the compiler/toolchain still
requires a separate build directory.

### F1 fixture provenance and future simulation

The reduced [bluepill-hsi.ioc](../../tests/fixtures/project/bluepill-hsi.ioc)
uses the ProjectManager keys found in the author's
[03-blink example](https://github.com/ViacheslavMezentsev/demo-stm32-cmake/blob/0eaf00af7378ba93d74205d60fc98493b6632f2a/stm32f1xx/03-blink/03-blink.ioc).
That example uses `STM32F103C8Tx` (the parser strips the trailing `x`); the test
YAML also exercises the full `STM32F103C8T6` name. The source example uses
HSE/PLL at 72 MHz. The reduced fixture instead declares HSI at 8 MHz and no PLL
selection, and uses Cube F1 1.8.7 from the environment lockfile. It is not a
complete CubeMX project and has not been regenerated in CubeMX. This tests
configuration parsing, not clocks: the framework does not generate or execute
`SystemClock_Config`. Later firmware fixtures must explicitly implement HSI
with PLL disabled and verify that in the simulator.

The author's `stm32f1xx/02-semihosting/.vscode/tasks.json` launches QEMU with
`-semihosting`; retain that option when designing the later semihosting tests.
These examples are references, not dependencies downloaded by this suite.
YAML scalars such as MCU names, paths and `1K` remain unquoted. Quote values
when YAML syntax or preserving a string type requires it.

Run the full matrix from the repository root after building the image above.
PowerShell (also works in the VS Code terminal):

```powershell
New-Item -ItemType Directory -Force build/configure-tests | Out-Null
docker run --rm --network none --mount "type=bind,source=$($PWD.Path),target=/workspace,readonly" --mount "type=bind,source=$($PWD.Path)/build/configure-tests,target=/results" stm32-yml-ci:local python3 /workspace/ci/run_configure_tests.py --output /results
```

Linux:

```sh
mkdir -p build/configure-tests
docker run --rm --network none --user "$(id -u):$(id -g)" --mount "type=bind,source=$PWD,target=/workspace,readonly" --mount "type=bind,source=$PWD/build/configure-tests,target=/results" stm32-yml-ci:local python3 /workspace/ci/run_configure_tests.py --output /results
```

For one tool pair, start the container shell with those two mounts and optional
`-e GCC_VERSION=... -e CMAKE_VERSION=...`, then run:

```sh
cmake -S /workspace/tests -B /results/single -G Ninja
cd /results/single
ctest --output-on-failure -j 4
ctest --output-on-failure -R '^configure.profile-'
```

Use a separate `single` directory for each tool pair. The `cd` form is compatible
with CMake 3.19. No root `CMakeLists.txt` or consumer-facing presets are added;
the test entry point is `tests/`.

The matrix writes `summary.json`, CTest logs, source copies and generated files.
Each case has `step-N/configure.log` and snapshots of the cache, Ninja file,
compilation database, linker scripts and observed properties for every step.
Repeated runs retain separate case directories for diagnosis; they consume disk
space until you remove the generated output. GitHub uploads selected diagnostic
files as `configure-diagnostics` for 14 days, including when tests fail. Core
symlinks and dependency source trees are excluded from this artifact.

To add a scenario, extend `tests/cases.json` and, if needed, the fixture files.
Keep assertions about externally observable results; do not copy framework
logic into the tests. Add a regression case before changing that behavior in
a later PR. Existing test names should remain unique.
