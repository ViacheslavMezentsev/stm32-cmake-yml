# Reference 0.9.2

[Documentation](../../index.md) → Reference 0.9.2 · [Русский](../../../ru/reference/0.9.2/index.md)

Baseline: `f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0`. [Semantics and version boundary](semantics.md) · [Errata](../../errata/index.md) · [Testing](../../testing.md).

## By topic

- [Project and version](project.md)
- [Sources and libraries](sources.md)
- [Compilation](compiler.md)
- [CMSIS, HAL and FreeRTOS](frameworks.md)
- [Linking and memory](linker.md)
- [Profiles](profiles.md)
- [Arduino backend](arduino.md)
- [Artifacts and CRC](postbuild.md)
- [Diagnostics](diagnostics.md)

## Alphabetical YAML option index

| YAML | Contract |
| --- | --- |
| [`arduino.core_cmake_dir`](arduino.md#arduino-core-cmake-dir) | `CFG-ARDUINO-CORE-CMAKE-DIR` |
| [`arduino.core_path`](arduino.md#arduino-core-path) | `CFG-ARDUINO-CORE-PATH` |
| [`arduino.custom_libraries`](arduino.md#arduino-custom-libraries) | `CFG-ARDUINO-CUSTOM-LIBRARIES` |
| [`arduino.libraries`](arduino.md#arduino-libraries) | `CFG-ARDUINO-LIBRARIES` |
| [`arduino.mcu_target`](arduino.md#arduino-mcu-target) | `CFG-ARDUINO-MCU-TARGET` |
| [`arduino.use_core_main`](arduino.md#arduino-use-core-main) | `CFG-ARDUINO-USE-CORE-MAIN` |
| [`build_artifacts`](postbuild.md#build-artifacts) | `CFG-BUILD-ARTIFACTS` |
| [`c_standard`](compiler.md#c-standard) | `CFG-C-STANDARD` |
| [`cmsis_rtos_api`](frameworks.md#cmsis-rtos-api) | `CFG-CMSIS-RTOS-API` |
| [`compile_definitions`](compiler.md#compile-definitions) | `CFG-COMPILE-DEFINITIONS` |
| [`compile_definitions_c`](compiler.md#compile-definitions-c) | `CFG-COMPILE-DEFINITIONS-C` |
| [`compile_definitions_cxx`](compiler.md#compile-definitions-cxx) | `CFG-COMPILE-DEFINITIONS-CXX` |
| [`compile_options`](compiler.md#compile-options) | `CFG-COMPILE-OPTIONS` |
| [`compile_options_c`](compiler.md#compile-options-c) | `CFG-COMPILE-OPTIONS-C` |
| [`compile_options_cxx`](compiler.md#compile-options-cxx) | `CFG-COMPILE-OPTIONS-CXX` |
| [`cpp_standard`](compiler.md#cpp-standard) | `CFG-CPP-STANDARD` |
| [`cppcheck_args`](diagnostics.md#cppcheck-args) | `CFG-CPPCHECK-ARGS` |
| [`cppcheck_enable`](diagnostics.md#cppcheck-enable) | `CFG-CPPCHECK-ENABLE` |
| [`cppcheck_ignores`](diagnostics.md#cppcheck-ignores) | `CFG-CPPCHECK-IGNORES` |
| [`crc_algorithm`](postbuild.md#crc-algorithm) | `CFG-CRC-ALGORITHM` |
| [`crc_enable`](postbuild.md#crc-enable) | `CFG-CRC-ENABLE` |
| [`crc_section_name`](postbuild.md#crc-section-name) | `CFG-CRC-SECTION-NAME` |
| [`cubefw_package`](frameworks.md#cubefw-package) | `CFG-CUBEFW-PACKAGE` |
| [`custom_libraries`](sources.md#custom-libraries) | `CFG-CUSTOM-LIBRARIES` |
| [`flash_size`](postbuild.md#flash-size) | `CFG-FLASH-SIZE` |
| [`freertos_components`](frameworks.md#freertos-components) | `CFG-FREERTOS-COMPONENTS` |
| [`freertos_version`](frameworks.md#freertos-version) | `CFG-FREERTOS-VERSION` |
| [`hal_components`](frameworks.md#hal-components) | `CFG-HAL-COMPONENTS` |
| [`heap_size`](linker.md#heap-size) | `CFG-HEAP-SIZE` |
| [`include_directories`](sources.md#include-directories) | `CFG-INCLUDE-DIRECTORIES` |
| [`ioc_file`](project.md#ioc-file) | `CFG-IOC-FILE` |
| [`languages`](project.md#languages) | `CFG-LANGUAGES` |
| [`link_libraries`](sources.md#link-libraries) | `CFG-LINK-LIBRARIES` |
| [`link_options`](linker.md#link-options) | `CFG-LINK-OPTIONS` |
| [`linker_directives`](linker.md#linker-directives) | `CFG-LINKER-DIRECTIVES` |
| [`linker_script`](linker.md#linker-script) | `CFG-LINKER-SCRIPT` |
| [`linker_script_dir`](linker.md#linker-script-dir) | `CFG-LINKER-SCRIPT-DIR` |
| [`log_target_properties`](diagnostics.md#log-target-properties) | `CFG-LOG-TARGET-PROPERTIES` |
| [`mcu`](project.md#mcu) | `CFG-MCU` |
| [`mcu_core`](project.md#mcu-core) | `CFG-MCU-CORE` |
| [`profiles`](profiles.md#profiles) | `CFG-PROFILES` |
| [`profiles_file`](profiles.md#profiles-file) | `CFG-PROFILES-FILE` |
| [`project_name`](project.md#project-name) | `CFG-PROJECT-NAME` |
| [`sources`](sources.md#sources) | `CFG-SOURCES` |
| [`stack_size`](linker.md#stack-size) | `CFG-STACK-SIZE` |
| [`stm32_cmake_yml_version`](project.md#stm32-cmake-yml-version) | `CFG-STM32-CMAKE-YML-VERSION` |
| [`stm32_cmake_yml_version_check`](project.md#stm32-cmake-yml-version-check) | `CFG-STM32-CMAKE-YML-VERSION-CHECK` |
| [`system_library`](linker.md#system-library) | `CFG-SYSTEM-LIBRARY` |
| [`toolchain_backend`](project.md#toolchain-backend) | `CFG-TOOLCHAIN-BACKEND` |
| [`use_cmsis`](frameworks.md#use-cmsis) | `CFG-USE-CMSIS` |
| [`use_freertos`](frameworks.md#use-freertos) | `CFG-USE-FREERTOS` |
| [`use_hal`](frameworks.md#use-hal) | `CFG-USE-HAL` |
| [`use_newlib_nano`](linker.md#use-newlib-nano) | `CFG-USE-NEWLIB-NANO` |
| [`validate_linker_script`](diagnostics.md#validate-linker-script) | `CFG-VALIDATE-LINKER-SCRIPT` |
| [`verbose_build`](diagnostics.md#verbose-build) | `CFG-VERBOSE-BUILD` |

[CMake/environment controls](semantics.md) are not YAML keys. The [tool index](../../../reference-index.json) maps options, pages, tests and errata.
