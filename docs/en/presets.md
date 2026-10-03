# CMakePresets with project configuration

[Documentation](index.md) · [Русский](../ru/presets.md)

Documentation example for 0.10.0, based on an Arduino-backend project.
These three files illustrate integration into an existing firmware project;
they are not a standalone buildable firmware. Supply the toolchain, Arduino Core,
`Arduino/Core/CMakeLists.txt` wrapper, `app/CMakeLists.txt`, application sources
with their own `main()`, and suitable linker scripts. Product-specific settings
are omitted.

| Component | Responsibility |
| --- | --- |
| CMakePresets.json | Generator, build directory, Debug/Release, YAML file and profile selection |
| stm32_config.yml | MCU, backend, sources, libraries, linker script and artifacts |
| CMakeLists.txt | Toolchain before project(), framework integration, custom targets and extensions |
| Module CMakeLists.txt files | Library implementation, source selection and board-specific details |

```mermaid
flowchart TD
    P["CMakePresets.json: Debug-G474"] -->|"cache: STM32_YML_PROFILE=G474"| C["CMakeLists.txt"]
    Y["stm32_config.yml: profiles.G474"] --> R["prepare_project_data"]
    C --> R
    R --> J["project: name, languages, toolchain"]
    J --> S["setup_project"]
    M["Module CMakeLists.txt files and custom targets"] --> S
    S --> B["Generate → Build"]
```

## Three connected files

### CMakePresets.json

```json
{
  "version": 3,
  "cmakeMinimumRequired": {
    "major": 3,
    "minor": 21,
    "patch": 0
  },
  "configurePresets": [
    {
      "name": "base",
      "hidden": true,
      "generator": "Ninja",
      "binaryDir": "${sourceDir}/build/${presetName}",
      "cacheVariables": {
        "PROJECT_CONFIG_FILE": "${sourceDir}/stm32_config.yml",
        "CMAKE_EXPORT_COMPILE_COMMANDS": true
      }
    },
    {
      "name": "G431",
      "hidden": true,
      "inherits": "base",
      "cacheVariables": {
        "STM32_YML_PROFILE": "G431"
      }
    },
    {
      "name": "Debug-G431",
      "inherits": "G431",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Debug"
      }
    },
    {
      "name": "Release-G431",
      "inherits": "G431",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Release"
      }
    },
    {
      "name": "G474",
      "hidden": true,
      "inherits": "base",
      "cacheVariables": {
        "STM32_YML_PROFILE": "G474"
      }
    },
    {
      "name": "Debug-G474",
      "inherits": "G474",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Debug"
      }
    },
    {
      "name": "Release-G474",
      "inherits": "G474",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Release"
      }
    }
  ],
  "buildPresets": [
    {
      "name": "Debug-G431",
      "configurePreset": "Debug-G431"
    },
    {
      "name": "Release-G431",
      "configurePreset": "Release-G431"
    },
    {
      "name": "Debug-G474",
      "configurePreset": "Debug-G474"
    },
    {
      "name": "Release-G474",
      "configurePreset": "Release-G474"
    }
  ]
}
```

### stm32_config.yml

```yaml
# Excerpt: requires the project's toolchain, wrappers, sources and linker scripts.
project_name: example_board
toolchain_backend: arduino
languages: [C, CXX, ASM]
c_standard: 17
cpp_standard: 17
sources: [app]

profiles:
  G431:
    mcu: STM32G431CB
    linker_script: resources/STM32G431XX_FLASH.ld
    arduino:
      mcu_target: G431
  G474:
    mcu: STM32G474CE
    linker_script: resources/STM32G474XX_FLASH.ld
    arduino:
      mcu_target: G474

arduino:
  core_path: modules/Arduino_Core_STM32
  core_cmake_dir: Arduino/Core
  use_core_main: false

link_libraries: [Arduino::Core, AppSettings]
build_artifacts: [bin, hex, map]
```

### CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.21)

set(CMAKE_TOOLCHAIN_FILE
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/gcc-arm-none-eabi.cmake")
list(APPEND CMAKE_MODULE_PATH
    "${CMAKE_CURRENT_SOURCE_DIR}/modules/stm32-cmake-yml")
include(stm32_yml)

stm32_yml_prepare_project_data(PROJECT_NAME PROJECT_LANGUAGES)
project(${PROJECT_NAME} LANGUAGES ${PROJECT_LANGUAGES})

# Project-owned target referenced by YAML link_libraries.
add_library(AppSettings INTERFACE)
target_compile_definitions(AppSettings INTERFACE APP_PROTOCOL_VERSION=1)

stm32_yml_setup_project(${PROJECT_NAME})

# Optional project-specific targets and CTest registration go here.
```

## Connections to preserve

- `Debug-G474` names a CMake preset; `G474` names a YAML profile. Debug and Release
  presets share the same YAML profile. CMake `inherits` and framework `profiles`
  are independent mechanisms.
- `PROJECT_CONFIG_FILE` selects YAML explicitly; `STM32_YML_PROFILE` selects its
  profile. MCU and linker script remain in YAML, without duplication in presets.
- `CMAKE_BUILD_TYPE` selects the Ninja configuration. Common YAML settings may
  use `$<CONFIG:Debug>` and `$<CONFIG:Release>` expressions.
- Each preset has its own build directory and cache. A preset does not clear an
  existing cache. Clean the corresponding build directory or use a new one when
  changing toolchains.
- Here, `arduino.mcu_target` selects a configuration implemented by the project
  wrapper. The wrapper must support both values and supply the appropriate
  variant, startup, definitions and board flags. An MCU name alone does not
  replace this wrapper contract. Wrappers in 0.10.0 can use `Arduino::Platform`.
- `AppSettings` is created before `setup_project` because YAML references it.
  The included wrapper creates `Arduino::Core`. Custom CMake targets and modules
  remain integral parts of the project; YAML does not replace the CMake language.
- `use_core_main: false` requires an application-owned `main()` and the Arduino
  and hardware initialization needed by that application.

## Usage

From the root of the prepared project:

```sh
cmake --list-presets
cmake --preset Debug-G474
cmake --build --preset Debug-G474
cmake --preset Release-G431
cmake --build --preset Release-G431
```

Select the same Configure Preset in VS Code CMake Tools. Keep local xPack, Python,
GDB and hardware stand paths in the environment or a Git-ignored
`CMakeUserPresets.json`; compiler discovery is defined by the toolchain file.
Do not copy a Windows PATH with `;` separators into a shared Linux preset.

Hardware testing can use additional presets: a cache variable enables a project
CMake module that registers CTest tests, while `testPresets.configurePreset`
selects its build directory. A test preset does not create tests. Firmware
configuration still comes from YAML; stand configuration remains separate.

Preset format version 3 and minimum CMake 3.21 match the requirements for 0.10.0.
This is the CMake JSON format version, not the framework or YAML version.
Presets are not generated from YAML: the developer maintains both files.

Example files: [CMakePresets.json](../../examples/presets/CMakePresets.json), [stm32_config.yml](../../examples/presets/stm32_config.yml), [CMakeLists.txt](../../examples/presets/CMakeLists.txt).

See also: [Arduino](arduino.md), [JSON Schema](schema.md).

## TOML, include and separate profiles (0.10.2)

The additional [example](../../examples/presets/toml/CMakeLists.txt) uses the STM32
backend; the YAML/Arduino example above remains available. This is a
**Configure/Generate** example, not a ready firmware: `main.c` initializes nothing
and the HAL headers are configure-only placeholders. Before building, replace
those headers with complete CubeMX HAL configurations and provide application
code, clock initialization and handlers. CRC is disabled. The automatically
selected linker script uses stm32-cmake's standard heap/stack sizes; add a custom
`.ld.in` separately when needed.

| File | Purpose |
| --- | --- |
| [stm32_config.toml](../../examples/presets/toml/stm32_config.toml) | Shared settings and the G474RE base board |
| [config/F411.toml](../../examples/presets/toml/config/F411.toml) | Named F411 profile, its MCU, CubeF4 and complete HAL list |
| [config/G474.toml](../../examples/presets/toml/config/G474.toml) | Named G474 profile, its MCU, CubeG4 and complete HAL list |
| [CMakePresets.json](../../examples/presets/toml/CMakePresets.json) | Four presets, profile selection, Debug/Release and separate build directories |
| [CMakeLists.txt](../../examples/presets/toml/CMakeLists.txt) | Framework integration and space for project-owned targets |

Includes merge left to right, followed by the root file. Profile selection follows
merging; overrides follow the profile. Including `config/F411.toml` does not select
F411. With an empty `STM32_YML_PROFILE`, root G474 settings apply. Commenting out
`include` preserves the G474 base while removing named profiles. Clear a cached
profile explicitly with `-DSTM32_YML_PROFILE=` or use a fresh build directory.

Include paths are relative to their containing file. Configuration paths such as
`sources`, `include_directories` and `linker_script` remain project-relative; they
are not rebased to the profile file's directory. A normal list **replaces** the
previous list; `hal_components_append` would append to the base. F411 therefore
provides its complete `hal_components`, excluding G4 FDCAN. G474 also replaces
the list instead of duplicating existing entries. Profile names are `F411` and
`G474`; preset names are `f411ce-debug`, `f411ce-release`, `g474re-debug` and
`g474re-release`. Preset inheritance and configuration merging are independent.

Install CMake ≥ 3.21, Ninja, Python, yq and ARM GCC; provide stm32-cmake and
CubeF4 V1.28.3 / CubeG4 V1.6.3. `MODULES_DIR` points to the directory containing
stm32-cmake; `CMAKE_USER_HOME` points to the parent of `STM32Cube/Repository`.
The framework defaults to `modules/stm32-cmake-yml` within the example; override
`STM32_YML_FRAMEWORK_DIR` on the command line or in CMakeUserPresets.json.
The example does not download dependencies. From `examples/presets/toml`:

```sh
cmake --list-presets
cmake --preset g474re-debug -DSTM32_YML_FRAMEWORK_DIR=/path/to/stm32-cmake-yml
cmake --preset f411ce-release -DSTM32_YML_FRAMEWORK_DIR=/path/to/stm32-cmake-yml
```

For the base configuration with no selected profile, supply your toolchain path:

```sh
cmake -S . -B build/base -G Ninja -DCMAKE_BUILD_TYPE=Debug -DPROJECT_CONFIG_FILE=stm32_config.toml -DSTM32_YML_PROFILE= -DSTM32_YML_FRAMEWORK_DIR=/path/to/stm32-cmake-yml -DCMAKE_TOOLCHAIN_FILE=/path/to/stm32-cmake/cmake/stm32_gcc.cmake
```

Once complete firmware sources are provided, the build preset uses its matching
configure preset: `cmake --build --preset g474re-debug`. Select the same CMake Tools
preset in VS Code. This example registers no HIL tests. Future names `g474re-hil`,
`g474re-hil-host`, `g474re-hil-hw` and `g474re-hil-hw-remote` imply Debug and a
separately integrated project test module.

TC-97 reads these public files and checks the base, disabled include and four real
presets across the Configure matrix. The test copy only adds value/target observers
and redirects the build directory into an isolated folder. This does not validate
user firmware or HIL.
