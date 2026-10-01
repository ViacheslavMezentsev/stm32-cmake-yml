# Arduino backend: wrappers and native modes

[Documentation](index.md) · [Русский](../ru/arduino.md)

With `toolchain_backend: arduino` firmware is built with [Arduino_Core_STM32](https://github.com/stm32duino/Arduino_Core_STM32)
(version 2.12.0 is checked). The core is added in one of two modes, the
`arduino.integration` key (spec 4.9.8). The modes are independent: keys of one do not
affect the other.

| | `wrappers` (default) | `native` |
| --- | --- | --- |
| Who builds the core | project CMake wrappers (`arduino.core_cmake_dir`, `arduino.custom_libraries`) | the core's own CMake files |
| Board flags | the `Arduino::Platform` target or by hand in the wrapper | the core `board` target, created by the framework |
| YAML flags | the executable and `Arduino::Definitions`/`Arduino::Options` | through `user_settings`, to both the core and the project |
| Core libraries | own wrappers (template below) | `arduino.libraries` with their `CMakeLists.txt` |
| Linker script | a `.ld.in` template or `linker_script` (required) | a template, `linker_script` or the board variant script |
| When to choose | modified copies of the core or libraries, a special core build | an unmodified core, few own CMake files |

Common keys: `arduino.core_path` (the core path), `arduino.board` (board, spec 4.9.10),
`arduino.cmsis_path` and `arduino.cmsis_target` (CMSIS, spec 4.9.14),
`arduino.use_core_main`. The exact meaning of each key is in the
[reference](reference/0.9.2/arduino.md).

## Board and CMSIS

The board is set by `arduino.board`, an ID from the core `boards.txt`, or selected by
`mcu` (`auto`): `GENERIC_` + seven characters of the name without `STM32` + `X`
(`STM32F103C8T6` → `GENERIC_F103C8TX`), otherwise the single ID with a one-letter suffix
(`STM32U575ZIT6Q` → `GENERIC_U575ZITXQ`). `auto` needs the full MCU name: `STM32G431CB` is
too short, use `STM32G431CBU6` or `board: GENERIC_G431CBUX`. Board data is read from the
core `cmake/boards_db.cmake` without Python or network.

CMSIS Core is searched in this order: `arduino.cmsis_path`; the Arduino IDE
(`%LOCALAPPDATA%\Arduino15`, `~/.arduino15`, `~/Library/Arduino15`, directory
`packages/STMicroelectronics/tools/CMSIS/<version>`); the core download cache
(`~/.Arduino_Core_STM32_dl/*/dist/CMSIS6`); `Drivers` of the family STM32Cube package
(CMSIS 5 instead of CMSIS 6 expected by the core; the checked families build). The
source is printed in the Configure log.

## Wrappers mode

The 0.9.3 behaviour is kept: the framework creates `Arduino::Definitions`, adds the core
wrapper from `arduino.core_cmake_dir` (`Arduino/Core` by default) and the
`arduino.custom_libraries` directories; the executable links what `link_libraries`
lists. Since 0.10.0 there are two more interface targets:

- `Arduino::Options` — common and language `compile_options`;
- `Arduino::Platform` — core and FPU flags, definitions and include directories of the
  selected board (`system/<family>`, HAL drivers, CMSIS device, variant), the
  `cores/arduino` and `SrcWrapper` directories, CMSIS Core. Board linker options are not
  included: the framework sets the linker script in this mode. The
  `ARDUINO_VARIANT_PATH` cache entry is the variant directory, `ARDUINO_BOARD` the board.

`Arduino::Platform` is created when the board and CMSIS are found. If that is not
possible with defaults (a short MCU name, no CMSIS), the target is not created and the
reason is logged: 0.9.3 wrappers that do not use it work as before.

A wrapper linked to `Arduino::Platform` does not depend on the MCU family: the same
`CMakeLists.txt` builds the core for F103 and G431. The templates below were checked by
building firmware for `STM32F103C8T6` and `STM32G431CBU6` (GCC 14.2.1, CMake 3.21.7);
copy them into the project and adjust as needed.

`stm32_config.yml`:

```yaml
toolchain_backend: arduino
mcu: STM32F103C8T6
languages: [C, CXX, ASM]
sources: [sketch.cpp]
compile_options: [Os]
link_options: [specs=nano.specs]
linker_directives: [--gc-sections]
linker_script_dir: linker          # STM32F103C8_FLASH.ld.in template
arduino:
  core_path: modules/Arduino_Core_STM32
  custom_libraries: [Arduino/libraries/Wire]
link_libraries: [Arduino::Wire, Arduino::Core]
```

`Arduino/Core/CMakeLists.txt`, the core wrapper:

```cmake
# Arduino core wrapper for the wrappers mode (spec 4.9.15, 4.9.17).
# Family-independent: Arduino::Platform supplies the board flags, definitions
# and include directories.
set(_core "${ARDUINO_CORE_DIR}/cores/arduino")
set(_wrapper "${ARDUINO_CORE_DIR}/libraries/SrcWrapper/src")
file(GLOB _sources CONFIGURE_DEPENDS
    "${_core}/*.c" "${_core}/*.cpp" "${_core}/avr/*.c" "${_core}/stm32/*.c" "${_core}/stm32/*.S"
    "${_wrapper}/*.c" "${_wrapper}/*.cpp" "${_wrapper}/stm32/*.c" "${_wrapper}/stm32/*.cpp"
    "${_wrapper}/HAL/*.c" "${_wrapper}/LL/*.c"
    "${ARDUINO_VARIANT_PATH}/*.c" "${ARDUINO_VARIANT_PATH}/*.cpp")
if(DEFINED USE_CORE_MAIN AND NOT USE_CORE_MAIN)
    # Project main(): the core main.cpp is not compiled.
    list(FILTER _sources EXCLUDE REGEX "/cores/arduino/main\\.cpp$")
endif()
# OBJECT, not STATIC: core interrupt handlers reach the image even without
# explicit references (otherwise the weak startup stubs remain).
add_library(ArduinoCore OBJECT ${_sources})
add_library(Arduino::Core ALIAS ArduinoCore)
target_link_libraries(ArduinoCore PUBLIC Arduino::Platform Arduino::Definitions)
```

`Arduino/libraries/Wire/CMakeLists.txt`, a core library wrapper:

```cmake
# Wrapper of the core Wire library for the wrappers mode (spec 4.9.17).
set(_lib "${ARDUINO_CORE_DIR}/libraries/Wire/src")
add_library(ArduinoWire OBJECT "${_lib}/Wire.cpp" "${_lib}/utility/twi.c")
add_library(Arduino::Wire ALIAS ArduinoWire)
target_include_directories(ArduinoWire PUBLIC "${_lib}" "${_lib}/utility")
target_link_libraries(ArduinoWire PUBLIC Arduino::Core)
```

Object files of an OBJECT library reach only a target linked to it directly, so
`link_libraries` lists both `Arduino::Wire` and `Arduino::Core`. Core and FPU flags reach
the executable through the `PUBLIC` link to `Arduino::Platform`: `-mcpu`, `-mfpu`,
`-mfloat-abi` and board definitions are not needed in YAML.

## Native mode

```yaml
toolchain_backend: arduino
mcu: STM32F103C8T6
languages: [C, CXX, ASM]
sources: [sketch.cpp]
arduino:
  integration: native
  core_path: modules/Arduino_Core_STM32
  libraries: [Wire]               # SrcWrapper is always added
link_libraries: [Wire]            # core target names
```

The framework adds `cmake/environment.cmake`, `cmake/set_base_arduino_config.cmake`, the
board variant, `cores/arduino`, `libraries/SrcWrapper` and the `arduino.libraries`
libraries (spec 4.9.9). The core functions `set_board()`, `updatedb()`,
`ensure_core_deps()` and `overall_settings()` are not called: Configure needs no Python
or network and does not change core files. The framework creates:

- `board` — the board target with the serial `generic`, USB `none`, VirtIO `disable`
  variants;
- `user_settings` — `-Os` and `--specs=nano.specs`, then common and language
  `compile_definitions` and `compile_options` from YAML. Both the core files and the
  project get them; `-O2` in YAML overrides `-Os`.

The executable links the core `stm32_runtime` automatically. Linker script: a `.ld.in`
template (heap/stack sizes, CRC section) or `linker_script` replaces the board
`--default-script`; without them the board variant script is used and heap/stack do not
apply. The core also passes `system/ldscript.ld`, which adds a `.noinit` section after
`.bss` through `INSERT`; if your script has such a section, remove one of them. Project
targets must not be named like core targets (`core`, `variant`, `board`, `base_config`,
`user_settings`, `SrcWrapper`, `stm32_runtime`). `arduino.core_cmake_dir` and
`arduino.mcu_target` do not apply in this mode. Core libraries that need extra
dependencies (USBDevice, VirtIO, CMSIS_DSP) are not supported in 0.10.0.

### Own main()

`arduino.use_core_main` (spec 4.9.18) selects whose `main()` is used.

- `true` (default in `native`): the core `main()` (`cores/arduino/main.cpp`) calls
  `initVariant()`, then `setup()` and `loop()` in a loop; the `premain()` constructor
  calls `init()` before `main()`, sets the NVIC priority grouping and enables the caches
  on Cortex-M7. The project defines `setup()` and `loop()`.
- `false`: the framework drops `main.cpp` from the core `core_bin` target and adds
  `--undefined=_write`. The project defines `main()` and does what `premain()` did:

```cpp
#include <Arduino.h>

int main(void) {
#ifdef NVIC_PRIORITYGROUP_4
    HAL_NVIC_SetPriorityGrouping(NVIC_PRIORITYGROUP_4);  // as the core premain() (FreeRTOS)
#endif
#if (__CORTEX_M == 0x07U)
    SCB_EnableICache();  // Cortex-M7 caches, as the core premain()
    SCB_EnableDCache();
#endif
    init();          // HAL, SysTick, clocks (the board SystemClock_Config)
    initVariant();   // board setup
    for (;;) {
        // application
    }
}
```

The core `premain()` is a constructor with priority 101: it runs before C++ static
objects. Without it `init()` runs later, from `main()`, so global objects whose
constructors use HAL must be created after `init()`.

Signs of a mistake: a project `main()` with `use_core_main: true` gives the link error
`undefined reference to '_write'` (or, with another library order, an image without
`premain()` where `init()` is never called); `use_core_main: false` without `init()`
leaves clocks and SysTick unconfigured, and `delay()` and `millis()` do not work.

## CMSIS from the project (external)

`arduino.cmsis_path: external` — the framework adds no CMSIS paths. With
`arduino.cmsis_target` the project target is linked to `Arduino::Platform` (`wrappers`)
or `user_settings` (`native`); the target may be defined after the framework call:

```cmake
stm32_yml_setup_project(${PROJECT_NAME})
add_library(ProjectCmsis INTERFACE)
target_include_directories(ProjectCmsis INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/third_party/CMSIS/Core/Include")
```

```yaml
arduino:
  cmsis_path: external
  cmsis_target: ProjectCmsis
```

For the F0, F1, F4, G4 and F7 boards of the check matrix 12 CMSIS Core 6 files
(`CMSIS/Core/Include/…`) are enough: `cmsis_compiler.h`, `cmsis_gcc.h`,
`cmsis_version.h`, `core_cm0.h`, `core_cm3.h`, `core_cm4.h`, `core_cm7.h`, `core_cm33.h`,
`m-profile/cmsis_gcc_m.h`, `m-profile/armv7m_mpu.h`, `m-profile/armv8m_mpu.h`,
`m-profile/armv7m_cachel1.h`. With this set the `native` mode builds firmware for
`STM32F103C8T6`, `STM32F030R8T6`, `STM32F411CEU6`, `STM32G474CEU6` and `STM32F746ZGT6`.
For other cores (M0+, M23, M55 and others) add the matching `core_*.h`.

## Checks

The modes are checked by the L3 `arduino-*` cases ([testing](testing.md)); `native`
firmware is built for every L4 matrix target ([firmware](firmware-testing.md)); emulator
runs of `native` firmware come with the RCC/PWR models.
