# Changelog

[Русский](CHANGELOG.md) · **English** · [README](README.en.md)

All notable changes to this project are recorded in this file. The format is based
on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/). Codes `E001`…`E008` are
[errata](docs/en/errata/index.md) entries; spec items refer to the
[technical specification](docs/TECHNICAL_SPECIFICATION.md) (in Russian).

---

## [0.10.1] - 2026-10-03

- Fixed Git diagnostics for Windows 8.3 path aliases and added a regression. Host/Windows CI now print failure details in Actions while retaining blocking failures.

- Version diagnostics report each module’s own Git SHA and modified state; copies without Git do not inherit a project commit. Removed the YAML comparison checkmark and added checkout/submodule/worktree and bilingual regressions.

- Documented the CRC32 method, length field and CRC placement. Existing semihosting firmware checks length and zero residue in software; the host independently validates ELF/BIN. Build/run counts are unchanged and user linker layouts are not modified automatically.

- Localized CRC injection start/success and added JSONL diagnostics for objcopy failures with the section and cause. The script updates the ELF after calculation; failures stop post-build without reporting success.

- Source markers `[yml]`, `[ioc]`, `[auto]` now precede values in the final Configure report; message codes and JSONL argument order are unchanged.

- Added: `crc_method` / `crc.method` with `auto`; none, null and empty normalize to auto, unknown methods fail. Configure reports method, algorithm and section separately without claiming to validate placement.

- Added native Windows Configure/Build to Firmware with pinned tools. TC-44 remains partial: E010 (absolute sources on another drive) is covered by a regression, without changing behavior.

### Tests

- Added fast Windows/Linux Host CI with logs and path filters; fixed Windows portability of version tests. TC-44 remains partial due to E010.

### Fixed

- **E009:** CRC/BIN Python CLI writes stdout/stderr as UTF-8 regardless of the code page; import leaves streams unchanged. TC-88 covers CP1251/CP866, files/pipes, JSONL and CMake/Ninja POST_BUILD.

## [0.10.0] - 2026-10-02

### Added

- **Navigation and version boundaries:** README and status describe both Arduino modes and the current matrix; clarify QEMU/Renode families and the historical reference baseline.

- **Migration guide from 0.9.x** (spec 7.9): [migration steps](docs/en/migration-0.10.md), path comparison, code-based diagnostics and optional changes.

- **JSON Schema and a paired Presets + YAML example** (spec 5.1.4, 6.6.4): the reference index generates the schema; Docs checks consistency, fixture YAML/TOML and explicit negative expectations. Unknown keys and empty values remain allowed; Configure is unchanged. The bilingual example explains preset, YAML and custom CMake connections. [Schema](docs/en/schema.md) · [Example](docs/en/presets.md).

- **TOML and file discovery** (spec 3.1.5, 3.8): main files, includes and external profiles support `.toml`; YAML and TOML may be mixed. Without an explicit `PROJECT_CONFIG_FILE`, the only `stm32_config.yml`/`.yaml`/`.toml` is selected. Multiple candidates fail. An empty value restores discovery; discovered names are not cached. [Rules and old-cache migration](docs/en/reference/0.9.2/formats.md).

- **YAML `include` files** (spec 3.8): recursive object merging, list replacement and `_append`, with profile additions accumulated until activation. Include paths are relative to the declaring file; cycles and missing files report their chain. All files are Configure dependencies. `stm32_config.effective.json` records the tree before profiles, overrides, IOC and defaults. The `_append` suffix outside profiles is now reserved; the configuration root must be a single object. [Rules and limits](docs/en/reference/0.9.2/includes.md).

- **Message codes and language** (spec 4.16.5–4.16.10). Messages are printed by
  permanent `SCY-<I|W|E><number>` codes from the `cmake/stm32_yml_messages_catalog.cmake`
  catalog in Russian or English. `STM32_YML_LANG` (`auto`, `ru`, `en`) selects the
  language; `auto` uses the locale, on Windows the registry. `STM32_YML_MESSAGE_CODES=ON`
  shows the codes in the output. Every Configure message is written to
  `stm32_yml_messages.jsonl` in the build directory. The CRC script prints its build-time
  messages in the Configure language and writes them to `stm32_yml_build_messages.jsonl`.
  The codes are listed in the reference ([message codes](docs/en/reference/0.9.2/messages.md));
  the issue form asks for the message file.

- **Component versions** (spec 4.2.6, 4.2.7). After the version lines the log prints the
  versions of CMake, yq, stm32-cmake or Arduino Core STM32 and, after `project()`, the
  compiler. An unknown version prints "version unknown" without a warning.
- **Error for a missing STM32Cube version** (spec 4.7.2). A `cubefw_package: Vx.y.z` that is
  not in the repository fails Configure with `SCY-E415` naming the version, family and path
  instead of a `find_package` failure inside stm32-cmake.
- **`system_library: none`** (spec 4.10.2) explicitly disables the system library without
  a warning.
- **`Arduino::Options` and `Arduino::Platform` targets in the `wrappers` mode** (spec 4.9.8,
  4.9.10, 4.9.14–4.9.16). The `arduino.integration` key (`wrappers` by default, as in 0.9.3).
  `Arduino::Options` holds common and language `compile_options`; `Arduino::Platform` holds
  the core and FPU flags, board definitions and include directories and CMSIS, so a core
  wrapper linked to it does not depend on the MCU family. The board is `arduino.board` or is
  selected by `mcu` (`STM32F103C8T6` → `GENERIC_F103C8TX`) from the core `boards_db.cmake`
  without Python; CMSIS is `arduino.cmsis_path`, a search of the Arduino IDE, the core download
  cache and STM32Cube, or `external` with `arduino.cmsis_target`. If the board or CMSIS cannot
  be found with defaults, `Arduino::Platform` is not created and older configurations work as
  before.
- **Arduino `native` mode** (spec 4.9.9–4.9.13, 4.9.18): `arduino.integration: native`
  adds the Arduino_Core_STM32 CMake files directly, without project wrappers, Python or
  network; the board is selected by `mcu`, YAML flags reach the core and the project through
  `user_settings` (`-Os` and newlib-nano by default), a `.ld.in` template or `linker_script`
  replaces the board variant script, `arduino.libraries` are added by the core's own
  `CMakeLists.txt`, `arduino.use_core_main: false` allows an own `main()`. Firmware of the
  mode is built in the L4 matrix for every target; emulator runs follow the RCC/PWR models.
- **Arduino backend guide** (spec 4.9.17, `docs/en/arduino.md`): choosing the mode, core and
  library wrapper templates on `Arduino::Platform`, a `native` example, an own `main()`, the
  minimal CMSIS Core set for `external`.

### Changed

- **Configuration extensions:** only lowercase `.yml`, `.yaml`, `.toml` are accepted. Other extensions now produce `SCY-E015` instead of implicit yq parser selection.

- **Configure CI:** three parallel GCC jobs, cached environment layers, packed diagnostics and a final completeness check for all six tool pairs. The test set is unchanged; Firmware remains manual at stage boundaries and runs on tags.

- **Minimum CMake is 3.21** (spec 2.5.1). `stm32_yml.cmake` and the test projects require
  `cmake_minimum_required(VERSION 3.21)`; the check matrix is CMake 3.21.7 and 3.28.3
  instead of 3.19.8 and 3.28.3. Projects on CMake 3.19–3.20 must upgrade.
- **Build directories of added directories** (spec 4.6.8). A directory from `sources`,
  `arduino.libraries`, `arduino.custom_libraries` and the Arduino core wrapper are built in
  `build/<path from the project root>`; out-of-tree directories in
  `build/_deps/<path without leading ..>` (`../modules/etl` → `build/_deps/modules/etl`);
  clashing paths get a `-<4 SHA-1 characters>` suffix. The former `external_*`,
  `arduino_lib_*`, `arduino_custom_*` and `arduino_core` directories are no longer created.
  **After upgrading, build in a clean build directory.** A `_deps/…` project directory with
  out-of-tree directories present fails with `SCY-E302`.
- **Artifact names and directory** (spec 4.14.2, 4.14.4). `bin`, `hex`, `srec`, `lss` and
  `map` are named after the final ELF name (`OUTPUT_NAME`, `OUTPUT_NAME_<CONFIG>`,
  `<CONFIG>_POSTFIX`) and placed in the ELF directory, including target properties set after
  the framework call; the framework builds `hex` and `srec` itself with `objcopy`, the
  `stm32_generate_*` functions are not needed. For a target in the top directory without
  `OUTPUT_NAME` and `RUNTIME_OUTPUT_DIRECTORY` and a single-config generator the paths are
  unchanged. Changed:
  - with `OUTPUT_NAME`, the `lss` and `map` names (formerly the target name);
  - with `OUTPUT_NAME` set after the framework call, the names of all artifacts;
  - with `RUNTIME_OUTPUT_DIRECTORY` or a target in a subdirectory under Ninja, the `map`
    location (formerly the build directory or the build root);
  - with Ninja Multi-Config, the location of all artifacts (formerly without the
    configuration subdirectory).

  Replace references to these files in your scripts with a path from the ELF:
  `$<TARGET_FILE_DIR:app>/$<TARGET_FILE_BASE_NAME:app>.hex`. To keep the former location, copy
  after the build:
  `add_custom_command(TARGET app POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy_if_different "$<TARGET_FILE_DIR:app>/$<TARGET_FILE_BASE_NAME:app>.map" "${CMAKE_BINARY_DIR}/app.map")`.
- **Output language.** Without a Russian locale (including Docker and CI) catalog
  messages are printed in English, for example "stm32-cmake-yml version: …". For Russian
  output use `-DSTM32_YML_LANG=ru`. Scripts that parse the log should use the codes from
  `stm32_yml_messages.jsonl` rather than the text.
- **The `arduino.mcu_target` warning** (`SCY-W501`) appears only if `Arduino::Platform` is
  not created: wrappers based on it do not need `MCU_TARGET`.
- **`mcu_core` hint.** The dual-core error suggests one core (`mcu_core: M7`) instead of
  the `M7;M4` list.
- **Unknown enumerated value.** The end of the warning is capitalized:
  "Применяется '…'" / "Значение не используется" in Russian.
- **The `[CRC ERROR]` label of the CRC script** is replaced by catalog texts: the error and
  the line "Build failed: CRC was not calculated." (`SCY-E708`). Scripts that looked for the
  label in the log should check the code in `stm32_yml_build_messages.jsonl`.
- **English lines in the Russian output.** The READONLY linker script lines are
  translated into Russian.

---

## [0.9.3] - 2026-09-27

### Added

- **`srec` artifact.** `build_artifacts: [srec]` produces a Motorola S-record file
  through `stm32_generate_srec_file`.
- **Configure re-runs when inputs change.** Changing the YAML, IOC or
  `profiles_file` re-runs Configure on the next build.
- **Inline profiles warning.** With `profiles_file` set, an inline `profiles:`
  section is still unused, and a warning now lists its profiles.
- **Unapplied heap/stack warning.** Explicit `heap_size`/`stack_size` values are not
  applied with the stm32-cmake or an explicit `linker_script`, and Configure says so.
- **`_sstack` warning.** Configure warns when the startup sets MSPLIM from
  `_sstack` (CubeH5 1.7.0) and the linker script does not define the symbol.
- **Documentation.** Bilingual `CFG-*` option reference with 0.9.3 change notes,
  errata E001–E008, guides for scenarios, sources, modules, diagnostics and
  development modes, and the technical specification
  (`docs/TECHNICAL_SPECIFICATION.md`). The AI-agent skills in `skills/` follow the
  reference.
- **Tests and CI.** A Docker environment with pinned tools and STM32Cube packages;
  139 Configure scenarios on six GCC/CMake pairs; a firmware matrix for
  STM32F103C8T6, STM32F030R8T6, STM32F411CEU6, STM32F401CCU6, STM32G431CBU6,
  STM32G474CEU6, STM32F746ZGT6 and H7/H5 running in QEMU and Renode; result badges.
  Contents and commands: [Testing](docs/en/testing.md).

### Changed

- **A CRC failure fails the build (E006).** A CRC calculation failure now fails the
  build with `[CRC ERROR]` instead of writing a zero stub. `crc_enable: true` with
  the stm32-cmake-generated linker script is a Configure error; a template or
  explicit script without the `crc_section_name` section warns.
  **Compatibility:** builds that used to pass with a `0x00000000` stub now fail;
  CRC projects without a `.ld.in` template or explicit script must add one or
  disable CRC.
- **Heap/stack format check.** `heap_size` and `stack_size` are validated on every
  Configure: integer bytes or an integer with upper-case `K`/`M`.
  **Compatibility:** values such as `1k` or `0x200` used to be ignored silently
  without a template and are now a Configure error.
- **CRC image and BIN from FLASH sections.** The intermediate CRC image and the
  `bin` artifact are built from ELF sections loaded into the linker-script `FLASH`
  region instead of `objcopy --gap-fill`. A section outside Flash (for example in
  STM32H5 backup SRAM) no longer inflates the files to hundreds of megabytes; the
  H5 CRC limitation is gone. Images, CRC and BIN of ordinary projects are unchanged.
- **Only `profiles:` from `profiles_file`.** Other keys of the external file no
  longer replace the base value for `_append`.
- **Unknown enumerated values.** `toolchain_backend`, `system_library`,
  `cmsis_rtos_api`, `freertos_version`, `crc_algorithm` and `build_artifacts`
  elements warn with the known values, and the default behaviour applies:
  `external` for `freertos_version`, as in 0.9.2, and `STM32_HW_DEFAULT` for
  `crc_algorithm` (E004). Empty values are not checked.
- **Version banner.** The `Framework :` and `Config :` lines are replaced with
  "stm32-cmake-yml версия: …" and "Версия в конфигурации: …". The warning calls
  `stm32_cmake_yml_version` a recommended parameter; the "What's new in 0.9" help
  is removed.
- **Early component checks.** Missing `hal_components` and `freertos_components`
  entries and a missing CMSIS-RTOS wrapper fail Configure with the component name
  instead of failing Generate.
- **IOC FreeRTOS port table.** C0, U0, H5, L5, U5, WL and the H7/WL cores are
  added; an unknown family warns.
- **Linker-script RAM check.** CCRAM, RAM_SHARE and the MCU core are included; the
  stm32-cmake script is reported as not checked.
- **`hal_conf.h` hint.** Names the actual HAL configuration file.

### Fixed

- **Derived values after a profile switch (E001).** Switching profiles in one build
  directory refreshes the MCU and the heap/stack sizes of the local linker template;
  old values no longer stay in `CMakeCache.txt`. Use `STM32_YML_OVERRIDE_mcu`,
  `STM32_YML_OVERRIDE_heap_size` and `STM32_YML_OVERRIDE_stack_size` for explicit
  overrides.
- **Profile list from `profiles_file` (E002).** `STM32_YML_PROFILE=list` reads
  `profiles_file` as profile selection does.
- **Profile-only keys (E008).** Keys set only in a profile or through
  `STM32_YML_OVERRIDE_*` are applied without a root declaration, including
  `compile_options_c`/`_cxx`, `compile_definitions_c`/`_cxx` and project-specific
  keys.
- **Incomplete IOC.** An IOC without a project name, `HeapSize` or `StackSize` gets
  the manual-mode values `auto`, 512 and 1024 instead of empty values.
- **MCU core.** The core follows the stm32-cmake list: selected automatically for
  single-core MCUs (every H7 gets `M7`), required for dual-core ones, and a value
  outside the list is an error listing the cores. The core reaches the CMSIS-RTOS
  wrapper and the RAM/Flash sizes.
- **`freertos_version: external` (E007).** FreeRTOS is found in `FREERTOS_PATH`
  (Cube tree or FreeRTOS-Kernel), and the `FreeRTOS::<port>` targets are used. When
  stm32-cmake omits the port's `portasm.c` (`ARM_CM0` in FreeRTOS-Kernel 11), the
  framework adds it to the port target.

---

## [0.9.2] - 2026-09-19

### Changed

- **Cleanup after earlier patches.** Removed the unused `_STM32_YML_LIST_PARAMS`
  list and a duplicated `.ioc` parser header, restored the
  `stm32_yml_ensure_default_value` documentation, aligned the
  `stm32_yml_setup_system_libraries` indentation, removed a repeated reference RAM
  size calculation and an ap-patch fragment from the user manual.
- **Quoted `system_library` comparison.** The parameter is optional, and without
  quotes CMake compared the variable name with a string.

### Fixed

- **Flag normalization with a separate argument.** The token after options such as
  `--param`, `-include`, `-isystem`, `-Xlinker` got a leading dash:
  `"--param max-inline-insns-single=500"` became
  `--param -max-inline-insns-single=500`, which the compiler rejected.
  `stm32_yml_normalize_flags` recognizes these options and passes the value
  unchanged. The flag and value can be one string or two list elements.
- **Control flow in the `.ioc` parser.** Post-processing that chooses between
  `FirmwarePackage` and `CustomerFirmwarePackage` was nested in the
  `ProjectManager.LibraryCopy` branch inside the loop and read variables written
  with `PARENT_SCOPE`. Values now accumulate in local variables, post-processing and
  export run after the loop, and the `CustomerFirmwarePackage` priority works.
- **`_append` with a replacement in the same profile.** When a profile set both `X`
  and `X_append`, the addition was appended to the root YAML list instead of the
  profile list.
- **`-DSTM32_YML_PROFILE=list` without an `mcu` key.** A profile is detected by any
  of its keys, not only `mcu`; the result is deduplicated.
- **FreeRTOS source label.** The label in the final parameter table was empty:
  `_src_freertos_flag` was never computed.
- **`project_name` comparison.** The unquoted `if(${project_name} ...)` broke CMake
  syntax when the `.ioc` had no `ProjectManager.ProjectName`.
- **`M` suffix in the reference RAM size.** Diagnostics handled only `K`, and
  `math(EXPR)` failed on values such as `1M` (H7, F7).
- **Directory outside the project tree.** `add_subdirectory` was called without an
  explicit binary directory, and a path such as `../shared` failed to configure.
- **Arduino library binary directories.** The name came from the last path segment,
  so `Arduino/libraries/Cli` and `Components/Cli` collided. The whole relative path
  is used now; the first build after the update is a full rebuild.

---

## [0.9.1] - 2026-09-13

### Added

- **FLASH size detection (`flash_size: auto`).** The postbuild module reads the
  linker script to find the FLASH size. This restored CRC32 injection for the
  Arduino backend without an explicit size.
- **System libraries for every backend.** `use_newlib_nano` and `system_library`
  moved to `stm32_yml_setup_system_libraries` and work with the Arduino backend too.

### Changed

- **Linker script for Arduino.** Uses `target_link_options` and the `LINK_DEPENDS`
  property; the dependency on the `stm32_add_linker_script` macro is gone.
- **Configure output for Arduino.** Messages about searching `ioc_file`,
  `use_cmsis`, `use_hal`, `use_freertos` and `mcu_core` are removed.
- **CRC parameters in the log.** `crc_section_name` and `crc_algorithm` are
  initialized and printed only with `crc_enable: true`.

### Fixed

- **Passing `use_core_main`.** `arduino.use_core_main` did not reach the Arduino
  core; the value is now written to `CMakeCache.txt`.
- **Path to `stm32_crc.py`.** `CMAKE_CURRENT_FUNCTION_LIST_DIR` is used, so the
  script is found wherever the framework is located.
- **Diagnostics for Arduino.** The `hal_conf.h` search and the RAM check
  (`stm32_get_memory_info`) are disabled for the Arduino backend: without the
  stm32-cmake macros they caused a fatal configuration error.
- **False CRC warnings.** The Python and `objcopy` checks run only with
  `CRC_POSSIBLE`.

---

## [0.9.0] - 2026-07-30

### Added

- **Build profiles (`profiles:`).** A `stm32_config.yml` section for several board
  or MCU revisions in one project. A profile is selected with
  `-DSTM32_YML_PROFILE=<name>` and overrides the base values. Lists support
  replacement (key without a suffix) and addition (`_append` suffix). Profiles can
  live in an external file set by `profiles_file:`.
- **`-DSTM32_YML_OVERRIDE_*` overrides.** Any scalar parameter can be overridden with
  a CMake cache variable without editing the configuration; overrides apply on top
  of the profile.
- **Arduino Core STM32 backend (`toolchain_backend: arduino`).** HAL/CMSIS are not
  added through stm32-cmake. The `arduino:` section sets the core path, standard and
  custom libraries, the board variant and `use_core_main`. The framework creates the
  `Arduino::Definitions` INTERFACE target and calls `add_subdirectory` for the core
  and libraries.
- **`linker_script_dir` parameter.** The directory searched for the `.ld.in`
  template and an explicit `.ld` script, at the root or in a profile. Without it the
  project root is searched, as before.
- **`cmake/stm32_yml_profiles.cmake` module.** Loads and applies profiles, the
  `_append` semantics, overrides and the profile list
  (`-DSTM32_YML_PROFILE=list`).
- **`cmake/stm32_yml_arduino.cmake` module.** Sets up the Arduino backend: checks
  `core_path`, creates `Arduino::Definitions`, adds the core and libraries.

### Changed

- **Configuration priority.** Defaults → `ioc_file` → base YAML → profile →
  overrides.
- **`toolchain_backend` initialization.** Done at the start of
  `stm32_yml_setup_project()` before `stm32_get_chip_info` and `add_executable`;
  duplicate `ensure_default_value` calls are removed.
- **`stm32_get_chip_info` call.** Made only for the stm32-cmake backend, where the
  `stm32_gcc.cmake` toolchain is available.
- **Linker template search.** A loop over directories (`linker_script_dir` first,
  then the project root) replaced three separate `if(NOT EXISTS ...)` blocks; the
  same logic applies to an explicit script.
- **Version mismatch message.** Lists what is new in 0.9 and states backward
  compatibility.
- **Framework version.** `STM32_CMAKE_YML_VERSION` is `0.9` instead of `0.8`.
  **Compatibility:** 0.9 changes are backward compatible; a project with
  `stm32_cmake_yml_version: "0.8"` builds unchanged with an informational warning.

---

## [0.8.0] - 2026-05-01

### Added

- **Separate C and C++ flags.** `compile_options_c`, `compile_options_cxx`,
  `compile_definitions_c` and `compile_definitions_cxx` are passed through
  `$<COMPILE_LANGUAGE:C>` and `$<COMPILE_LANGUAGE:CXX>`. The shared
  `compile_options` and `compile_definitions` are kept.
- **Flag normalization `stm32_yml_normalize_flags`.** A string with spaces is split
  into flags (`"-Wall -Wextra"` → two elements), a missing dash is added
  (`Wall` → `-Wall`), and `$<...>` generator expressions are left unchanged.
  `compile_definitions` use the `NO_AUTO_DASH` mode.
- **YAML over `.ioc`.** `stm32_config.yml` parameters override CubeMX `.ioc` values
  without editing the `.ioc`.

### Changed

- **Template search with `linker_script: auto`.** Three name variants (for
  `STM32H723VGT6`): `STM32H723VG_FLASH.ld.in` (exact match),
  `STM32H723XG_FLASH.ld.in` (package replaced with X, as in CubeMX) and
  `STM32H723XX_FLASH.ld.in` (generic). The output `.ld` name comes from the MCU type
  (`H723VG`), not from `MCU_TYPE` (`H723xx`).
- **MCU type for the template search.** Taken from the full MCU name
  (`string(SUBSTRING "${MCU}" 5 6 ...)`), not from `stm32_get_chip_info`.
- **Linker-script RAM check.** Sums all `(xrw)` or `(rw)` regions of the `MEMORY{}`
  block except `ORIGIN = 0x00000000` (ITCMRAM); works for H7 with several regions.
  Prints a comparison with the stm32-cmake data instead of `FATAL_ERROR`.

---

## [0.7.1] - 2026-03-15

### Fixed

- **`crc_enable: false` did not disable CRC.** `string(JSON GET)` returns booleans
  in upper case (`FALSE`/`TRUE`), while normalization compared with lower case.
  Normalization is added when parsing JSON (`stm32_yml_utils.cmake`), before
  `PARENT_SCOPE` (`stm32_yml_config.cmake`) and at the point of use
  (`stm32_yml_postbuild.cmake`). Updating from affected versions needs a clean
  reconfigure (delete `build/` or `CMakeCache.txt`).

---

## [0.7.0] - 2026-02-20

### Added

- **CRC diagnostics.** CRC32 injection prints the section address, data size and
  the computed value.
- **Unified messages.** `message(STATUS ...)` prefixes are unified, and
  informational messages are separated from warnings.
- **`CustomerFirmwarePackage`.** Custom firmware packages can be used alongside
  standard STM32Cube ones.
