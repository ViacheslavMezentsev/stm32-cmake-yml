# Standalone library modules

[Documentation](index.md) · [Русский](../ru/modules.md)

Unlike [main-target sources](simple-sources.md), a STATIC library has its own
compile properties. Creating its target does not link the application to it.

## Minimal integration

```yaml
sources: [main.c, Modules/Sensor]
link_libraries: [App::Sensor]
```

```cmake
# Modules/Sensor/CMakeLists.txt
add_library(sensor STATIC Src/sensor.c)
add_library(App::Sensor ALIAS sensor)
target_include_directories(sensor PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/Inc")
target_compile_definitions(sensor PRIVATE SENSOR_INTERNAL=1)
```

Files must exist. A sources directory invokes add_subdirectory; link_libraries
connects the main target to the library. Target and directory names need not match.
The standard backend's custom_libraries refers to existing library file paths,
not a substitute for adding a CMake directory. See [reference](reference/0.9.2/sources.md).

## Shared and private settings

YAML compile_options/compile_definitions are PRIVATE executable settings. They
are not passed backwards through an executable-to-library dependency. Shared
settings can be expressed explicitly through an INTERFACE target:

```cmake
add_library(app_settings INTERFACE)
target_compile_definitions(app_settings INTERFACE APP_SETTING=1)
target_compile_options(app_settings INTERFACE
    "$<$<COMPILE_LANGUAGE:C>:-Wstrict-prototypes>"
    "$<$<COMPILE_LANGUAGE:CXX>:-fno-exceptions>")
target_link_libraries(sensor PRIVATE app_settings)
```

Also add app_settings to YAML link_libraries if the application needs those
settings. Align CPU/Thumb/FPU/float ABI with the toolchain for every object; these
fragments do not specify complete MCU settings. Do not copy MCU-specific values
between families without checking them.

PUBLIC library includes/definitions affect the library and its consumers;
PRIVATE compile properties stay with the library. A STATIC library's PRIVATE
link dependency can still be required at final link time. CMAKE_C_STANDARD and
CMAKE_CXX_STANDARD initialize properties at target creation, not through permanent
inheritance from the executable. Consistent target-specific settings are allowed.

The standard backend reads sources before setup_frameworks. Do not inspect
CMSIS/HAL/FreeRTOS target properties before creation; ensure required targets
exist by Generate. Use actual component names from the installed package.
Inspect INTERFACE_SOURCES before spreading startup targets across libraries.
Arduino uses separate integration; these scenarios do not test its wrappers.

## Evidence

| Scenario | Configure/Generate checks |
| --- | --- |
| `module-explicit-link` | YAML links the application's module ALIAS; PUBLIC include/define reaches the application, PRIVATE define does not; shared INTERFACE settings reach both targets; language flags stay separate. |
| `module-not-auto-linked` | The directory creates a library, but without link_libraries its PUBLIC define/include does not reach the application. Executable YAML flags do not appear in library commands. |
| `module-missing-target` | An unknown :: target fails Generate with the expected diagnostic. |

[Fixture](../../tests/fixtures/project/Module/CMakeLists.txt) · [Manifest](../../tests/cases.json)

Checks cover source ownership, compile_commands.json, C11/C++17 settings in the
selected environment and target linkage. They create no archives or ELF files.
Symbol resolution, ABI correctness, archive extraction order and execution remain
unverified. A plain name without :: may denote an external library; successful
Generate does not establish its availability. These tests promise no new MCU or startup support.

Dependency semantics: [CMake 3.19 target_link_libraries](https://cmake.org/cmake/help/v3.19/command/target_link_libraries.html).
[Agent skill](../../skills/stm32-module-creator/SKILL.md).
