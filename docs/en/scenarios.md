# Usage scenarios

[Documentation](index.md) · [Русский](../ru/scenarios.md)

These YAML fragments illustrate configuration, not complete or validated firmware.
Supply existing source paths, dependencies and any required startup/linker files.
See [reference](reference/0.9.2/index.md) and [errata](errata/index.md) for contracts.

## CubeMX IOC

```yaml
stm32_cmake_yml_version: 0.9.2
ioc_file: my_project.ioc
build_artifacts: [bin, hex, map]
crc_enable: true
```

IOC provides supported fields such as MCU and memory sizes; specify source paths
and missing values yourself. Parsing IOC does not generate startup code or clocks.
CRC also needs a suitable linker section and tools; Configure does not validate it.

## Manual configuration

```yaml
stm32_cmake_yml_version: 0.9.2
mcu: STM32F411CEU6
heap_size: 512
stack_size: 1K
sources: [Core, User]
hal_components: [GPIO, UART, DMA, TIMEx]
use_freertos: true
freertos_components: [ARM_CM4F, "Heap::4"]
```

Adapt components and FreeRTOS port to the actual MCU and dependency versions.
Source directories need the consumer CMake integration described in the reference.

## Board profiles

One configuration selects different inputs for separate build directories:

```yaml
profiles:
  F411:
    mcu: STM32F411CEU6
    ioc_file: project_F411.ioc
    linker_script_dir: F411
    sources_append: [F411/Core]
  G474:
    mcu: STM32G474RETx
    ioc_file: project_G474.ioc
    linker_script_dir: G474
    sources_append: [G474/Core]
    hal_components_append: [FDCAN]
```

```sh
cmake -DSTM32_YML_PROFILE=F411 -B build/F411 -S .
cmake -DSTM32_YML_PROFILE=G474 -B build/G474 -S .
```

The project must select the appropriate toolchain. These commands configure only.
Profile names must not contain underscores.

## Arduino Core STM32

```yaml
toolchain_backend: arduino
mcu: STM32G474RET6
arduino:
  core_path: modules/Arduino_Core_STM32
  core_cmake_dir: Arduino/Core
  mcu_target: G474
  use_core_main: false
custom_libraries: [Arduino/libraries/SrcWrapper, Arduino/libraries/Wire, UserApp]
link_libraries: [UserApp, Arduino::SrcWrapper, Arduino::Core, STM32::Nano]
linker_script: auto
crc_enable: true
compile_definitions: [STM32G474xx, USE_HAL_DRIVER]
compile_options_cxx: [fno-exceptions, fno-rtti]
```

Core and library CMake wrappers belong to the consumer. Ensure the named targets
exist; automatic linker selection needs a matching file/template for this backend.

## Scalar overrides

```sh
cmake -S . -B build/G474 -DSTM32_YML_PROFILE=G474 -DSTM32_YML_OVERRIDE_heap_size=8K
```

Nonempty scalar overrides take precedence over profiles. An empty value is ignored;
omitting a previous -D does not remove its cached value. See [development](development.md).
