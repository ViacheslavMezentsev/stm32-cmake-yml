# Test environment

[Русский](../ru/testing.md)

Testing uses an isolated Linux environment with pinned versions. Existing
`include(stm32_yml)` projects do not need any changes. The tests invoke the
framework from the current checkout. This page describes the test levels, the
compiler environment and the configure scenarios; firmware builds and runs are on
the [firmware tests](firmware-testing.md) page.

## Test levels and where to find them

Checks are split into six levels (spec 8.1, appendix F). Numbers are for a full run
on three GCC × two CMake versions.

| Level | What it checks | Where in the tree | How to run | Size |
| --- | --- | --- | --- | --- |
| L0 | Environment readiness: tool versions, sources from the lockfile, Configure/Generate of a small project; QEMU, Renode and machines | `ci/docker/verify.py`, `ci/emulation/check.py` | `docker run --rm --network none stm32-yml-ci:local`; `python ci/emulation/check.py` | 6 pairs; 2 emulators |
| L1 | Documentation: links, bilingual `CFG-*` cards, errata, option-to-test mappings | `ci/check_reference.py`, `docs/reference-index.json` | `python ci/check_reference.py` | 55 cards, 8 errata, 75 pages |
| L2 | CI script logic: QEMU/Renode runners, CRC, matrix, badges | `tests/test_firmware*.py`, `ci/emulation/test_check.py` | `python -m unittest discover -s tests -p "test_firmware*.py"` | 42 tests |
| L3 | Framework behaviour at Configure/Generate | `tests/cases.json`, `tests/run_case.py`, `tests/CMakeLists.txt`, `tests/fixtures/project/` | `python ci/run_configure_tests.py --output <dir>` (in the image) | 139 scenarios × 6 = 834 |
| L4 | Firmware builds; ELF, layout, CRC and metadata checks | `tests/firmware/semihosting/`, `tests/firmware/buildonly/`, `ci/build_firmware_smoke.py`, `ci/firmware_cases.py` | `python ci/firmware_matrix.py build --output <dir>` | 570 builds |
| L5 | Firmware execution in emulators | `ci/run_qemu_smoke.py`, `ci/run_renode_smoke.py`, `tests/firmware/renode/` | `python ci/firmware_matrix.py run [--emulator renode] --build <builds> --output <logs>` | 336 QEMU, 612 Renode runs |

```text
ci/
├── docker/                    # L0: compiler image, installer and verify.py
├── emulation/                 # L0: QEMU/Renode image, check.py and its test
├── dependencies.lock.json     # Pinned versions and SHA-256
├── check_reference.py         # L1
├── run_configure_tests.py     # L3: CTest on every GCC/CMake pair
├── firmware_cases.py          # L4–L5: targets, profiles, emulators
├── build_firmware_smoke.py    # L4: build and checks for one pair
├── firmware_matrix.py         # L4–L5: every pair in a separate process
├── run_qemu_smoke.py          # L5: QEMU
├── run_renode_smoke.py        # L5: Renode
└── firmware_badge.py          # Builds (Checks) counter
tests/
├── cases.json                 # L3: scenario descriptions
├── run_case.py                # L3: runs one scenario
├── fixtures/project/          # L3: test project, scenario YAML and IOC files
├── toolchains/                # L3: Arduino toolchain file
├── test_firmware*.py          # L2
└── firmware/
    ├── semihosting/           # L4–L5: firmware with 13 profiles; targets/ — F0, F4, G4, F7
    ├── buildonly/             # L4–L5: H7/H5 and the H503 CRC image
    └── renode/                # L5: *.repl models and exit_hook.py
.github/workflows/             # CI: environment, configure, firmware, emulation, documentation, badges
```

Details: configure scenarios — [below](#framework-configuration-tests), firmware —
[firmware tests](firmware-testing.md), emulators per family and their specifics —
[emulation environment](emulation.md).

## Contents

| Component | Pinned versions |
| --- | --- |
| Platform | Linux amd64, Ubuntu 24.04 by image digest |
| Ubuntu packages | Ubuntu repositories; installed versions recorded in the image |
| xPack Arm GCC | 13.3.1-1.1, 14.2.1-1.1, 15.2.1-1.1 |
| CMake | 3.21.7 (minimum supported version since 0.10.0), 3.28.3 (reference environment) |
| Ninja / Mike Farah yq | 1.12.1 / 4.44.3 |
| stm32-cmake | Commit recorded in the lockfile |
| STM32Cube | F0 1.11.6, F1 1.8.7, F3 1.11.5, F4 1.28.3, F7 1.17.3, G4 1.6.3, H5 1.7.0, H7 1.13.0 |
| FreeRTOS-Kernel | 11.3.1 (`/opt/FreeRTOS-Kernel/11.3.1`, for `freertos_version: external`) |
| Arduino Core STM32 / ETL | 2.12.0 / 20.47.1 |

[dependencies.lock.json](../../ci/dependencies.lock.json) records archive SHA-256
checksums and source commits. Selected Cube submodules (CMSIS device, HAL and
FreeRTOS where it is a submodule) use the gitlinks of those commits, never remote
branch heads. BSP and unrelated middleware submodules are not initialized.
Cube `Projects` and `Utilities` example directories are not downloaded: a partial
clone (`--filter=blob:none`) and sparse checkout driven by the lock file's
`sparse_exclude` shrink Cube from 3.9 to 1.3 GB. Archives and sources install
in 4 parallel threads; each item's log is printed as one block.
Git metadata and licenses are retained for inspection. The image records Ubuntu
package versions in `/opt/stm32-yml-ci/packages.txt`.

QEMU **11.0.0** (prebuilt from source, [tools/qemu](../../tools/qemu/README.md)) and Renode
are part of the separate emulation image ([ci/emulation](../../ci/emulation/Dockerfile)); neither is installed in this image. Arduino projects still need their own
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
docker run --rm --network none -e GCC_VERSION=13.3.1-1.1 -e CMAKE_VERSION=3.21.7 stm32-yml-ci:local cmake --version
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
The separate `Configure tests` workflow runs on pushes to `main` and working branches (`claude/**`, `codex/**`, `gemini/**`, `dev/**`), and manual dispatch. It builds the image once and tests all six tool pairs
in one job, continuing after a failing pair. Neither workflow publishes images
or builds firmware. Configure skips only pushes without inputs: Markdown,
`docs/reference-index.json`, `.github/FUNDING.yml`, `.github/ISSUE_TEMPLATE/`,
`LICENSE`. Firmware runs manually and on `v*` tags — [GitHub checks](maintenance.md#github-checks).

Update versions and hashes together in the lockfile, review upstream sources,
then rebuild and verify. When changing Ubuntu, also update the Dockerfile digest
to match the lockfile. CMake 3.28.3 is a fixed reference, not a claim to be the
latest CMake. Runtime libraries and Python packages follow Ubuntu updates;
this image freezes the testing tools and source dependencies, not every OS
package or the resulting image bytes. Ubuntu snapshots are not required.

## Framework configuration tests

[tests/cases.json](../../tests/cases.json) defines 167 scenarios, run with each of
the three GCC and two CMake versions from the lockfile: **1002 case executions**.
Twenty-seven scenarios perform two to thirteen consecutive configurations in the same build tree.

| Area | Checks |
| --- | --- |
| Defaults and dependencies | F411 (BlackPill) and F103 (BluePill), actual CMSIS/HAL targets, default heap/stack, C/C++ standards |
| Profiles on the same MCU | List replacement, append, replacement followed by append, sources, external profiles (the `profiles:` section only), profile-only and override-only keys without root declarations, scalar override priority |
| IOC and YAML precedence | STM32F103C8T6, IOC-derived defaults, YAML/profile/override precedence, manual-mode values for an incomplete IOC, missing IOC |
| Bare metal | No CMSIS/HAL/FreeRTOS, unavailable Cube repository, explicit CPU flags and local linker template |
| YAML values | Unquoted scalars, `false`, zero heap, null/empty defaults, empty list replacement and append |
| Reconfiguration | Profile source/definition replacement and reset, persistent overrides and explicit cache removal with `-U`, Configure re-run after YAML, IOC and profile-file changes |
| Profile regressions | External profile listing, generated heap/stack updates, MCU and compiler defines after switching profiles |
| Language flags | Normalization and isolation of C and C++ flags/definitions in `compile_commands.json` |
| Linker | Explicit `.ld`, template discovery in `linker_script_dir`, heap/stack substitutions, size format in every mode, warning for unapplied heap/stack, READONLY and checksum section preservation |
| CRC | Presence/absence of the generated post-build command, section and Flash-size arguments |
| Arduino | Consumer-owned core/custom-library wrappers, profile parameters, shared compile definitions, `use_core_main: false` |
| Diagnostics | Missing/malformed YAML, missing linker/core, invalid memory size, HAL without CMSIS, profile listing and unknown-profile warning, warnings for unknown enumerated values and none for empty values |

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

Use a separate `single` directory for each tool pair. The `cd` form works with
every CMake version of the matrix. No root `CMakeLists.txt` or consumer-facing presets are added;
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
a later change. Existing test names should remain unique.

### Profile boundaries and empty overrides

Three additional multi-step scenarios check isolation of valid `Rev`/`RevB` names
through sources, definitions and linker sizes; a nonempty override returning to
the profile value with `-DSTM32_YML_OVERRIDE_stack_size=`; and resetting/reapplying
an external profile without stale definitions. An empty override is ignored,
not interpreted as zero. Underscores in profile names remain outside the contract.
Framework code was not changed for these checks.

The VS Code cache-deletion workflow and bare-metal startup responsibilities
are described in [development](development.md).

### Source integration

Three new cases check a source directory with CMakeLists, shared target ownership
of nested C/C++ and root C, include paths and language-specific flags in
compile_commands.json. A missing file warns; a directory without CMakeLists fails
Configure. [Guide and coverage limits](simple-sources.md).

Checks run without PRs on pushes to working branches (`claude/**`, `codex/**`,
`gemini/**`, `dev/**`) and main; branches are merged by fast-forward. [Merge workflow](maintenance.md#branches-without-pull-requests).

### Library modules

Three scenarios cover explicit STATIC-library linkage, no automatic linkage from
sources alone, and an unknown ALIAS error. They inspect C/C++ commands, PUBLIC/PRIVATE
compile properties and INTERFACE settings without running the linker. [Guide](modules.md).

### Diagnostics

Three cases check log_target_properties/validate_linker_script toggling in one
cache, nonfatal RAM mismatch, a warning for unrecognized RAM and a missing
hal_conf error. [Diagnostic limits](troubleshooting.md).

### YAML version diagnostics

Eight `version-*` cases cover matching, missing, empty, older and newer versions, disabling comparison at the YAML root, and comparison before profiles/overrides. Every case must complete Configure/Generate successfully; warnings are not failures. This checks 0.9.2 diagnostics, not compatibility with future configuration versions. No firmware is built.

The `versions-stm32-cmake` and `versions-arduino` cases check the "Component versions"
block (spec 4.2.6, 4.2.7, TC-83): CMake, yq, stm32-cmake or Arduino Core STM32, and the
compiler; in `arduino-missing-core` the core version is unknown. The values depend on the
environment (in the CI image git may refuse repositories owned by another user), so the
versions themselves are checked by L2 `tests/test_component_versions.py` on temporary
directories: a tag, a clone without tags, a copy without `.git`, a missing directory.

### Other configuration checks

- `verbose-build` (TC-41) switches `verbose_build` in one build tree: `CMAKE_VERBOSE_MAKEFILE`
  becomes `ON`, then `OFF`.
- `yq-missing` (TC-42) runs Configure with a `PATH` without yq: `SCY-E003` before `project()`.
- `unknown-keys-no-warning` (TC-42): unknown top-level keys and nested sections are exported
  without warnings (the `no_warnings` case key); `toolchain_backend` defaults to `stm32-cmake`.
- `cubefw-*` (TC-45) check the STM32Cube package choice: local `Drivers/` (the `local_drivers`
  case key links a pinned package), the latest repository version, an explicit version, a
  missing version (`SCY-E415`) and a missing repository (`SCY-E401`).
- `build-dirs-*` (TC-78) check build directories per spec 4.6.8: a project directory
  (`Module`), `../modules/etl` → `_deps/modules/etl`, the clashing keys `../modules/etl` and
  `../../modules/etl` and the nested `../a/x`, `../a/x/y` with a SHA-1 suffix, `../a/xy`
  without one, and `SCY-E302` for the `_deps/local` project directory. The `extra_dirs` case
  key copies `tests/fixtures/outside-module` into and outside the project; `binary_dirs`
  checks build directories (`{h:<path>}` is 4 SHA-1 characters). `arduino-library-linked` and
  `arduino-custom-chain` check the build directories of the Arduino core wrapper and libraries.

### Messages, codes and language

Framework messages are printed by codes from `cmake/stm32_yml_messages_catalog.cmake`
(spec 4.16.5–4.16.13). L3 cases run in English: `tests/run_case.py` passes
`-DSTM32_YML_LANG=en` unless a case sets `lang`. Every step checks
`stm32_yml_messages.jsonl`: the code is in the catalog, the level matches the code class,
the text matches the catalog and the text itself is in the output. Case keys:
`messages` (a code and optionally its arguments), `messages_absent`, `message_lang`,
`message_codes`, and `error` as `{"code": …}` — the last message before the failure.

Thirteen `messages-*` cases cover the language from `STM32_YML_LANG` and the locale
(`LC_ALL`, `LC_MESSAGES`, `LANG`, skipping `C` and `POSIX`), the `rus`/`eng` synonyms, an
unknown value, Russian text when English is missing, the `[SCY-…]` prefix with
`STM32_YML_MESSAGE_CODES=ON`, records up to `FATAL_ERROR` with arguments containing `;`,
quotes and `\`, and recreation of the file on every Configure. For them the fixture loads
test-only 9xx codes from `tests/fixtures/project/test_messages.cmake`
(`-DSTM32_YML_TEST_MESSAGES=ON`). `ci/check_messages.py` (L1) checks the catalog and
sources; its tests are in `tests/test_check_messages.py`. It also compares the English
`FALLBACK` texts of `scripts/stm32_crc.py` with the catalog and the
[message code](reference/0.9.2/messages.md) pages built by `ci/messages_reference.py`.

Every L3 step also checks `stm32_yml_build_messages.json`: the 7xx texts in the Configure
language for the CRC script, and an empty `stm32_yml_build_messages.jsonl`. The script's
build-time messages in Russian and English, codes in the output and file records are
checked by `tests/test_firmware_crc_script.py` (L2, TC-77); in L4 the build failure on the
FLASH limit is detected by the `SCY-E706` and `SCY-E708` codes in the build message file.

### STM32Cube FreeRTOS

Nine `freertos-*` cases use the real pinned CubeF4 and stm32-cmake packages in the container. Minimal YAML checks ARM_CM4F, Heap::4/Heap::2, Timers, EventGroups, StreamBuffer, and no wrapper / CMSIS-RTOS v1 / v2 through LINK_LIBRARIES and successful Ninja generation. The `gcs` profile reflects settings from the author's supplied `mcu_gcs_web_board`; `demo` reflects `demo-stm32-cmake/stm32f4xx/ethernet-rndis-nicokorn`. Both source projects were inspected read-only; their networking sources are neither copied nor built.

Separate cases cover no port, multiple ports and an unknown component. Disabled FreeRTOS must ignore even an invalid component list. `freertos-required-package` blocks find_package with `CMAKE_DISABLE_FIND_PACKAGE_FreeRTOS=TRUE` and expects the required dependency to fail; this is a controlled unavailable-package simulation, not a physically damaged Cube installation.

Without IOC, default `freertos_version` is checked through the selected Cube target namespace; omitting `cmsis_rtos_api` adds no wrapper. External FreeRTOS and IOC inference are not covered by this group. The fixture deliberately has no FreeRTOSConfig.h: Configure/Generate does not validate its contents or prove scheduler, interrupt-handler, heap or firmware correctness. Building requires application settings and an agreed scenario.

### IOC-derived FreeRTOS

Seven `freertos-ioc-*` cases extend the manual configuration group above. Reduced IOC files contain a FREERTOS marker and CMSIS-RTOS selection; tests check automatic ARM_CM3/Heap::4/v1 for F1 and ARM_CM4F/Heap::4/v2 for F4. F4 markers follow the author's supplied `mcu_gcs_web_board`; F1 is a synthetic variation using the same field format. These are parser inputs, not complete CubeMX projects or an HSI clock implementation.

YAML and profiles can replace components with Heap::2 and the API with none. Empty use_freertos, freertos_version, cmsis_rtos_api and component lists fall back to IOC/automatic values. An override of false suppresses IOC activation. `freertos-ioc-reconfigure` checks enabled → disabled by profile → enabled across Configure runs sharing a cache; it supplements the usual clean-cache reconfiguration workflow.

Assertions cover exported values, direct target dependencies and successful Generate. Other families and external FreeRTOS are covered by the cases below; port/core compatibility, task execution and clock setup are not tested here. No firmware is built.

### External FreeRTOS

`freertos_version: external` ([E007](errata/E007.md) is fixed on the 0.9.3 branch) is checked on two layouts. `freertos-external-cmake` and `freertos-external-env` take the CubeF4 FreeRTOS tree through `-DFREERTOS_PATH` and the environment; `freertos-external-kernel` uses FreeRTOS-Kernel 11.3.1 with `cmsis_rtos_api: none` and `v2`. The expected targets are `FreeRTOS::<port>` and `FreeRTOS::<component>` without the `FreeRTOS::STM32::F4` namespace. Negative cases: no `FREERTOS_PATH`, the `ARM_CM7_MPU` port that FreeRTOS-Kernel lacks, and an unknown component. The CMSIS-RTOS v2 wrapper with FreeRTOS-Kernel 11.3.1 and CubeF1 was also built manually (the `freertosQueue` firmware with the FreeRTOSConfig.h options the wrapper requires); running such firmware was not checked.

### MCU core, H7 and H5

`h7-single-core-default` checks that the single-core STM32H743ZI gets core M7 and the `CMSIS::STM32::H743ZI::M7`, `HAL::STM32::H7::M7::*` targets. `h7-dual-core` checks STM32H745ZI: no core is an error listing the cores; M7 and M4 select that core's targets, and for M4 the RAM total and the CRC Flash limit follow the core (288K, 1024K). `mcu-core-invalid` checks a core outside the list and a core for F4. `h7-freertos-cube` checks CubeH7 FreeRTOS with the v2 wrapper in the M7 namespace. `h5-cmsis-hal-freertos-external` checks H5: CMSIS/HAL, FreeRTOS-Kernel with the `ARM_CM33_NTZ` port, the v2 wrapper refusal (CubeH5 has no FreeRTOS) and CRC with a template. `hal-missing-component` expects a Configure error before Generate.

### FreeRTOS port from an IOC

`freertos-ioc-port-table` checks the port table in thirteen steps for F1, F4, G0, C0, U0, H5, L5, U5, WL (M4, M0PLUS), WB and H7 (M7, M4): an override replaces the MCU and FreeRTOS-Kernel is used as external, so those families' Cube packages are not needed. `freertos-ioc-port-unknown-family` checks the warning and `ARM_CM4F` for a family outside the table.

### Additional F0, F3, F7 and G4 families

| Family | MCU | IOC-derived FreeRTOS | Checks |
| --- | --- | --- | --- |
| F0 | STM32F030R8 | ARM_CM0, Heap::4, v1 | CMSIS/HAL, LL profile, bare metal, IOC RTOS |
| F3 | STM32F303VC | ARM_CM4F, Heap::4, v1 | CMSIS/HAL, IOC RTOS |
| F7 | STM32F746NG | ARM_CM7, Heap::4, v1 | CMSIS/HAL, IOC RTOS |
| G4 | STM32G431CB | ARM_CM4F, Heap::4, v1 | CMSIS/HAL, IOC RTOS |

Ten cases check real imported targets and cortex-m0/m4/m7 flags in compile_commands.json. F0 bare metal sets explicit CPU flags and checks absence of CMSIS/HAL/FreeRTOS dependencies. These are Configure/Generate checks, not compilation or proof that RTOS fits and runs on the selected device.

F0, F7 and G4 MCUs follow local demos `stm32f0xx/03-blink`, `stm32f7xx/03-blink` and `stm32g4xx/03-blink`; F3 uses a synthetic F303VC case. Reduced IOC fixtures add FreeRTOS/v1 markers. Full demo IOC files are not copied; the HSI field does not generate a clock implementation. Minimal HAL headers are for configuration only.

CubeF0/F3/F7 are pinned by commit in the lockfile; CubeG4 was already pinned. Only CMSIS device/HAL submodules are initialized, plus FreeRTOS for F0. Selected F3/F7 packages contain FreeRTOS in the parent repository. BSP and unrelated submodules are not initialized. The parent repository is fetched as a partial clone with sparse checkout that omits `Projects` and `Utilities`.

### System libraries and linker options

Five `system-*` cases check NoSys + Nano, Semihosting + Nano, both settings disabled, custom link_options/linker_directives, and profile transitions NoSys → Semihosting → no system library. Assertions cover direct target dependencies, transitive specs in generated Ninja LINK_FLAGS, and removal of stale flags after repeated Configure.

`link_options: [nostartfiles, "-Wl,--cref"]` becomes driver options `-nostartfiles` and `-Wl,--cref`; `linker_directives: [--print-memory-usage]` uses LINKER to generate `-Wl,--print-memory-usage`. These three flags must not appear in compile_commands.json. The test project has one executable, so the checker requires exactly one LINK_FLAGS line. It checks the current Ninja generator, not every CMake generator format.

The fixture uses bare metal without CMSIS/HAL. Specs are supplied by the pinned xPack/upstream; tests do not invoke the linker or establish syscall, printf/float or semihosting execution behavior. Real test firmware builds and runs are described in [firmware testing](firmware-testing.md).

### Cppcheck configuration

Five `cppcheck-*` cases check C_CPPCHECK/CXX_CPPCHECK values and the `--cppcheck=` Ninja rule: defaults, custom arguments and exclusions, empty-list fallback, unavailable executable, and enabled → disabled → enabled with different settings while reusing the cache.

Positive cases explicitly set CPPCHECK_EXECUTABLE to `/usr/bin/false`, a test command path, **not an analyzer**. Configure/Generate does not execute it. These cases check integration generation, not real Cppcheck discovery in PATH, execution, version compatibility, suppression parsing by the analyzer or analysis results. The unavailable case uses normal find_program in the pinned image without Cppcheck and requires a warning with successful Generate.

Nonempty cppcheck_args replace default arguments. Nonempty cppcheck_ignores replace default exclusions; `Vendor SDK`, containing a space, remains one CMake property argument. Empty lists restore defaults rather than removing all arguments/exclusions. Exact values are asserted for both languages. No firmware is compiled and no static analysis is executed.

CMake 3.21 stores the command in `CMakeFiles/rules.ninja`, while 3.28 stores it in `build.ninja`; the check considers both files.

### Post-build artifact selection

Six `artifacts-*` cases check commands declared during Configure/Generate: omitted setting, `[bin, hex, map, lss]`, map only, an empty list, an unknown item alongside bin, and shared-cache profile transitions all formats → bin → empty. CRC is disabled so its intermediate BIN commands cannot be mistaken for artifact selection.

Assertions cover objcopy binary/ihex, objdump -h -S and output filenames in Ninja POST_BUILD; map checks both LINK_OPTIONS and the generated linker flag. The primary ELF target and size-reporting command remain with an empty list. Unknown items add no conversion; supported bin still adds its command. Profile transitions must remove commands from the previous selection.

Tests also assert that no ELF/BIN/HEX/MAP/LSS output has been created in the build directory: conversion and linking are never executed. These cases do not prove file-format, listing, memory-size or CRC correctness, and do not cover the Arduino backend.

### Custom library paths

Five `custom-library-*` cases check custom_libraries relative to the project root, warning and skipping a missing file, profile `_append`, replacement/clearing on repeated Configure, and combination with `link_libraries: [m]`. Assertions cover exact LINK_LIBRARIES order and generated Ninja arguments, including `prebuilt/vendor sdk/libbeta.a`, a path containing a space. The plain name m becomes -lm, but its existence and symbol resolution are not checked at this stage.

The two `.a` files in [prebuilt](../../tests/fixtures/project/prebuilt/README.md) contain only the standard ar header, with no object members or ABI. They are path-handling input fixtures; no compiler or archiver was invoked to create them. The linker is not executed either. Tests do not establish MCU suitability, ABI compatibility or symbol resolution. Arduino custom-library semantics are separate and are not covered by these cases.

### Arduino library discovery

Five `arduino-library-*` cases check a library with a CMake wrapper, explicit linkage versus adding a target alone, warnings for a missing directory or CMakeLists.txt, and profile transitions selected → empty → selected without linkage. Checks inspect LINK_LIBRARIES, compile commands, propagation of a public definition, and removal of the library source after clearing the list.

The [synthetic core layout](../../tests/fixtures/project/arduino-library-core/README.md) uses test-owned library wrappers and the pinned core source through a symlink. It does not establish support for native Arduino library wrappers: for example, EEPROM and IWatchdog in pinned Core 2.12.0 require CMake 3.21. Since 0.10.0 the framework minimum is 3.21 as well (3.19 before); dependencies may impose higher requirements. Consumer wrappers connected through `arduino.custom_libraries` are a separate path and can have different requirements. No firmware is built.

### Consumer Arduino wrappers

Five `arduino-custom-*` cases exercise `arduino.custom_libraries` with an empty `arduino.libraries` list. Two consumer OBJECT libraries form a public dependency chain through Arduino::Definitions and Arduino::Core. Both wrapper directories end in `driver`, so successful generation also checks distinct binary directories for different relative paths (not arbitrary path-sanitization collisions).

Assertions cover owning targets, transitive definitions/includes, separate C/C++ flags, absence of automatic linkage, warnings for missing directories/CMakeLists.txt, and selected → empty → unlinked profile transitions. The wrappers are synthetic, inspired by a consumer pattern with Core/SrcWrapper/peripheral libraries; they do not implement or validate SPI, Wire or HAL. Compilation, object inclusion at link time and firmware execution remain outside this suite.

[QEMU/Renode environment and firmware roadmap](emulation.md).
