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

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
arduino:
  core_cmake_dir: Arduino/Core
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_arduino.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.arduino-defaults`. [Test manifest](../../../../tests/cases.json).

<a id="arduino-mcu-target"></a>
## `arduino.mcu_target`

`CFG-ARDUINO-MCU-TARGET` · **Type:** string · **Default:** existing MCU_TARGET cache / warning

Passes a variant identifier to consumer wrappers via MCU_TARGET CACHE FORCE. The framework itself does not select a variant. If YAML omits it, existing MCU_TARGET is retained; if neither exists, a warning is emitted.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
arduino:
  mcu_target: F411
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_arduino.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.arduino-profile`. [Test manifest](../../../../tests/cases.json).

<a id="arduino-use-core-main"></a>
## `arduino.use_core_main`

`CFG-ARDUINO-USE-CORE-MAIN` · **Type:** boolean · **Default:** not set by framework

When present, exports USE_CORE_MAIN CACHE BOOL FORCE to the wrapper. Absence does not guarantee false: wrapper behavior and previous cache matter. Does not add a main file by itself.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
arduino:
  use_core_main: false
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_arduino.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.arduino-defaults`. [Test manifest](../../../../tests/cases.json).

<a id="arduino-libraries"></a>
## `arduino.libraries`

`CFG-ARDUINO-LIBRARIES` · **Type:** list of library directory names · **Default:** []

Looks for CMakeLists.txt under <core_path>/libraries/<name>. Absence warns; Arduino IDE availability does not guarantee a CMake wrapper. Discovered targets are not automatically linked to firmware.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
arduino:
  libraries: [Wire]
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_arduino.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.arduino-library-linked`, `configure.arduino-library-unlinked`, `configure.arduino-library-missing`, `configure.arduino-library-no-wrapper`, `configure.arduino-library-reconfigure`. [Test manifest](../../../../tests/cases.json).

<a id="arduino-custom-libraries"></a>
## `arduino.custom_libraries`

`CFG-ARDUINO-CUSTOM-LIBRARIES` · **Type:** list of relative directories · **Default:** []

Adds consumer CMakeLists.txt directories relative to the root. Absence warns. The project defines targets and their linkage. Arduino::Definitions propagates common defines and common/language compile_options; language compile_definitions_c/cxx are not copied into that interface.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
arduino:
  custom_libraries: [libraries/probe]
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_arduino.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.arduino-profile`, `configure.arduino-custom-chain`, `configure.arduino-custom-unlinked`, `configure.arduino-custom-missing`, `configure.arduino-custom-no-wrapper`, `configure.arduino-custom-reconfigure`. [Test manifest](../../../../tests/cases.json).
