# Arduino backend

[Documentation](../../index.md) → [Reference 0.9.2](index.md) → Arduino backend · [Русский](../../../ru/reference/0.9.2/arduino.md)

Shared rules: [semantics](semantics.md). Baseline: `f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0`. Introduction history before 0.9.2 is not established; presence is confirmed in this baseline. Unless stated otherwise, configuration happens at Configure/Generate and actual commands execute at Build/Post-build.

<a id="arduino-core-path"></a>
## `arduino.core_path`

`CFG-ARDUINO-CORE-PATH` · **Type:** string: relative directory · **Default:** required for arduino

Root-relative Arduino_Core_STM32 directory; missing value/directory fails. Exported as ARDUINO_CORE_DIR. The core is not downloaded or automatically built in full.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
arduino:
  core_path: modules/Arduino_Core_STM32
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_arduino.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.arduino-defaults`, `configure.arduino-missing-core`. [Test manifest](../../../../tests/cases.json).

<a id="arduino-core-cmake-dir"></a>
## `arduino.core_cmake_dir`

`CFG-ARDUINO-CORE-CMAKE-DIR` · **Type:** string: relative directory · **Default:** Arduino/Core

Root-relative consumer CMake wrapper directory. Its CMakeLists.txt is added with add_subdirectory; absence warns. The wrapper creates required targets, then selected by link_libraries.

**Change in 0.10.0** (spec 4.6.8): the build directory of an added directory is its path from the project root; a directory outside the project uses `_deps/<path without leading ..>` (for example, `../modules/etl` → `build/_deps/modules/etl`); clashing paths get a `-<4 SHA-1 characters>` suffix. The former `external_*`, `arduino_lib_*`, `arduino_custom_*` and `arduino_core` names are gone; after upgrading from 0.9.x build in a clean directory.

**Change in 0.10.0** (spec 4.9.4): applies only in the `wrappers` mode; in `native` it warns with `SCY-W506`.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
arduino:
  core_cmake_dir: Arduino/Core
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_arduino.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.arduino-defaults`, `configure.arduino-native-wrapper-keys`. [Test manifest](../../../../tests/cases.json).

<a id="arduino-mcu-target"></a>
## `arduino.mcu_target`

`CFG-ARDUINO-MCU-TARGET` · **Type:** string · **Default:** existing MCU_TARGET cache / warning

Passes a variant identifier to consumer wrappers via MCU_TARGET CACHE FORCE. The framework itself does not select a variant. If YAML omits it, existing MCU_TARGET is retained; if neither exists, a warning is emitted.

**Change in 0.10.0** (spec 4.9.2): applies only in the `wrappers` mode; in `native` it warns with `SCY-W506`. Without the key and with `Arduino::Platform` created there is no `SCY-W501` warning: wrappers based on it do not use `MCU_TARGET`.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
arduino:
  mcu_target: F411
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_arduino.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.arduino-profile`, `configure.arduino-native-wrapper-keys`, `configure.arduino-mcu-target-platform`, `configure.arduino-mcu-target-missing`. [Test manifest](../../../../tests/cases.json).

<a id="arduino-use-core-main"></a>
## `arduino.use_core_main`

`CFG-ARDUINO-USE-CORE-MAIN` · **Type:** boolean · **Default:** not set by framework

When present, exports USE_CORE_MAIN CACHE BOOL FORCE to the wrapper. Absence does not guarantee false: wrapper behavior and previous cache matter. Does not add a main file by itself.

**Change in 0.10.0** (spec 4.9.18): in the `native` mode the default is `true`: the core `main()` (`initVariant()`, `setup()`, `loop()`), the `premain()` constructor calls `init()` (`SCY-I519`). With `false` the framework drops `main.cpp` from `core_bin` and adds `--undefined=_write` (`SCY-I520`); the project `main()` calls `init()` and `initVariant()`, on Cortex-M7 also the `premain()` settings (NVIC priority grouping, caches). A project `main()` with `true` gives the link error `undefined reference to '_write'` or an image without `premain()`.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
arduino:
  use_core_main: false
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_arduino.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.arduino-defaults`, `configure.arduino-native-core-main`, `configure.arduino-native-own-main`. [Test manifest](../../../../tests/cases.json).

<a id="arduino-libraries"></a>
## `arduino.libraries`

`CFG-ARDUINO-LIBRARIES` · **Type:** list of library directory names · **Default:** []

Looks for CMakeLists.txt under <core_path>/libraries/<name>. Absence warns; Arduino IDE availability does not guarantee a CMake wrapper. Discovered targets are not automatically linked to firmware.

**Change in 0.10.0** (spec 4.6.8): the build directory of an added directory is its path from the project root; a directory outside the project uses `_deps/<path without leading ..>` (for example, `../modules/etl` → `build/_deps/modules/etl`); clashing paths get a `-<4 SHA-1 characters>` suffix. The former `external_*`, `arduino_lib_*`, `arduino_custom_*` and `arduino_core` names are gone; after upgrading from 0.9.x build in a clean directory.

**Change in 0.10.0** (spec 4.9.13): in the `native` mode libraries are added by their core `CMakeLists.txt` and linked through `link_libraries` by core target names (`Wire`); `SrcWrapper` is always added. Libraries needing extra core dependencies (USBDevice, VirtIO, CMSIS_DSP) are not supported.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
arduino:
  libraries: [Wire]
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_arduino.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.arduino-library-linked`, `configure.arduino-library-unlinked`, `configure.arduino-library-missing`, `configure.arduino-library-no-wrapper`, `configure.arduino-library-reconfigure`, `configure.arduino-native-own-main`, `configure.arduino-native-missing-library`. [Test manifest](../../../../tests/cases.json).

<a id="arduino-custom-libraries"></a>
## `arduino.custom_libraries`

`CFG-ARDUINO-CUSTOM-LIBRARIES` · **Type:** list of relative directories · **Default:** []

Adds consumer CMakeLists.txt directories relative to the root. Absence warns. The project defines targets and their linkage. Arduino::Definitions propagates common defines and common/language compile_options; language compile_definitions_c/cxx are not copied into that interface.

**Change in 0.10.0** (spec 4.6.8): the build directory of an added directory is its path from the project root; a directory outside the project uses `_deps/<path without leading ..>` (for example, `../modules/etl` → `build/_deps/modules/etl`); clashing paths get a `-<4 SHA-1 characters>` suffix. The former `external_*`, `arduino_lib_*`, `arduino_custom_*` and `arduino_core` names are gone; after upgrading from 0.9.x build in a clean directory.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
arduino:
  custom_libraries: [libraries/probe]
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_arduino.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.arduino-profile`, `configure.arduino-custom-chain`, `configure.arduino-custom-unlinked`, `configure.arduino-custom-missing`, `configure.arduino-custom-no-wrapper`, `configure.arduino-custom-reconfigure`. [Test manifest](../../../../tests/cases.json).

<a id="arduino-integration"></a>
## `arduino.integration`

`CFG-ARDUINO-INTEGRATION` · **Type:** string: wrappers · **Default:** wrappers

Arduino backend mode (spec 4.9.8). An empty or missing value means `wrappers`, the 0.9.3 behaviour: project wrappers add the core and libraries. An unknown value warns with `SCY-W005` and uses `wrappers`. The mode is logged (`SCY-I508`).

**New in 0.10.0** (spec 4.9.8–4.9.16).

The `native` value (spec 4.9.9–4.9.13): the framework adds the core CMake files from `arduino.core_path` directly — `environment`, `set_base_arduino_config`, the selected board variant, `cores/arduino`, `libraries/SrcWrapper` and the `arduino.libraries` libraries; `set_board()`, `updatedb()`, `ensure_core_deps()` and `overall_settings()` are not called, Python and network are not needed, core files are not changed. The `board` target is a copy of the board target with the serial `generic`, USB `none`, VirtIO `disable` variants; the `user_settings` target holds `-Os`, `--specs=nano.specs`, then common and language `compile_definitions`/`compile_options` from YAML (not added to the executable directly). The executable links `stm32_runtime`. A `.ld.in` template or an explicit `linker_script` replaces `--default-script` of `board`; without them the variant script is used (`SCY-I521`, heap/stack do not apply). A project target named like a core target (`core`, `board`, `user_settings` and others) fails with `SCY-E510`. `Arduino::Definitions`, `Arduino::Options` and `Arduino::Platform` exist only in `wrappers`.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
arduino:
  integration: wrappers
```

[Implementation](../../../../cmake/stm32_yml_arduino.cmake) · [Index](index.md)

**Checks:** `configure.arduino-integration-wrappers`, `configure.arduino-integration-unknown`, `configure.arduino-defaults`, `configure.arduino-integration-native`, `configure.arduino-native-core-main`, `configure.arduino-native-variant-script`, `configure.arduino-native-explicit-script`, `configure.arduino-native-target-clash`. [Test manifest](../../../../tests/cases.json).

<a id="arduino-board"></a>
## `arduino.board`

`CFG-ARDUINO-BOARD` · **Type:** string: board ID / auto · **Default:** auto when mcu is set

A board from the core `boards.txt` (spec 4.9.10, 4.9.16). With `auto` the ID is built from `mcu`: `GENERIC_` + seven characters of the name without `STM32` + `X` (`STM32F103C8T6` → `GENERIC_F103C8TX`); if there is none, the single ID with a one-letter suffix (`GENERIC_U575ZITXQ`). Board data is read from that board's block of the core `cmake/boards_db.cmake` without `updatedb()` and Python. The selected board is logged (`SCY-I509`), its variant goes to the `ARDUINO_VARIANT_PATH` cache entry and the ID to `ARDUINO_BOARD`. If neither `arduino.board` nor `arduino.cmsis_path` is set and no board can be selected (a short MCU name, no `mcu` or no board database), `Arduino::Platform` is not created and a message is printed (`SCY-I510`, `SCY-I511`, `SCY-I517`), so 0.9.3 configurations keep working. With an explicit value: an unknown ID fails with `SCY-E503`, a failed `auto` with `SCY-E504` listing candidates, an unrecognized block with `SCY-E509`, a project target named like the board with `SCY-E508`.

**New in 0.10.0** (spec 4.9.8–4.9.16).

In the `native` mode the default is `auto`; a failed selection fails with `SCY-E504` for any value.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
arduino:
  board: GENERIC_F103C8TX
```

[Implementation](../../../../cmake/stm32_yml_arduino_board.cmake) · [Index](index.md)

**Checks:** `configure.arduino-platform-arduino15`, `configure.arduino-board-explicit`, `configure.arduino-board-unknown`, `configure.arduino-board-short-mcu`, `configure.arduino-board-auto-explicit`, `configure.arduino-board-suffix`, `configure.arduino-board-ambiguous`, `configure.arduino-board-malformed`, `configure.arduino-board-target-clash`, `configure.arduino-platform-no-mcu`, `configure.arduino-native-explicit-board`, `configure.arduino-native-short-mcu`. [Test manifest](../../../../tests/cases.json).

<a id="arduino-cmsis-path"></a>
## `arduino.cmsis_path`

`CFG-ARDUINO-CMSIS-PATH` · **Type:** string: directory / external · **Default:** search

The CMSIS source for `Arduino::Platform` (spec 4.9.14). A path from the project root or absolute: a directory with `CMSIS/Core/Include/cmsis_version.h`, otherwise `SCY-E505`. Without a value the search order is: the Arduino IDE (`<Arduino15>/packages/STMicroelectronics/tools/CMSIS/<version>`, the newest version; `<Arduino15>` is `%LOCALAPPDATA%\Arduino15`, `~/.arduino15`, `~/Library/Arduino15`), the core download cache (`~/.Arduino_Core_STM32_dl/*/dist/CMSIS6`), `Drivers` of the family STM32Cube package — a local `Drivers/`, an explicit `cubefw_package` or the newest package in `$CMAKE_USER_HOME/STM32Cube/Repository` (CMSIS 5 instead of CMSIS 6: warning `SCY-W505` with an explicit `arduino.board`, otherwise message `SCY-I518`). The source found is logged (`SCY-I514`). Nothing found: with defaults, message `SCY-I512` without `Arduino::Platform`; with an explicit `arduino.board`, `SCY-E506` listing the places. `external`: the framework adds no CMSIS paths, see `arduino.cmsis_target`.

**New in 0.10.0** (spec 4.9.8–4.9.16).

In the `native` mode CMSIS is required: the path goes to the core as `CMSIS6_PATH`; not found — `SCY-E506`; with `external` the `arduino.cmsis_target` target is linked to `user_settings`.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
arduino:
  cmsis_path: modules/CMSIS_6
```

[Implementation](../../../../cmake/stm32_yml_arduino_board.cmake) · [Index](index.md)

**Checks:** `configure.arduino-platform-arduino15`, `configure.arduino-platform-dl-cache`, `configure.arduino-platform-cube`, `configure.arduino-platform-cube-explicit`, `configure.arduino-platform-no-cmsis`, `configure.arduino-platform-no-cmsis-explicit`, `configure.arduino-cmsis-path`, `configure.arduino-cmsis-path-invalid`, `configure.arduino-cmsis-external`, `configure.arduino-native-no-cmsis`, `configure.arduino-native-cmsis-external`. [Test manifest](../../../../tests/cases.json).

<a id="arduino-cmsis-target"></a>
## `arduino.cmsis_target`

`CFG-ARDUINO-CMSIS-TARGET` · **Type:** string: target · **Default:** not set

The project INTERFACE target with CMSIS for `arduino.cmsis_path: external` (spec 4.9.14): linked to `Arduino::Platform` (`SCY-I515`). The target may be defined after the framework call; if it does not exist at the end of `CMakeLists.txt`, `SCY-E507`. Without `cmsis_target` a message says that the project supplies CMSIS (`SCY-I516`). The minimal CMSIS Core file set is in the [Arduino backend guide](../../arduino.md).

**New in 0.10.0** (spec 4.9.8–4.9.16).

In the `native` mode the target is linked to `user_settings`.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
arduino:
  cmsis_path: external
  cmsis_target: ProjectCmsis
```

[Implementation](../../../../cmake/stm32_yml_arduino_board.cmake) · [Index](index.md)

**Checks:** `configure.arduino-cmsis-external-target`, `configure.arduino-cmsis-external-missing`, `configure.arduino-cmsis-external`, `configure.arduino-native-cmsis-external`. [Test manifest](../../../../tests/cases.json).
