# Getting started

[Documentation](index.md) · [Русский](../ru/getting-started.md)

Requires CMake 3.19+, Arm GCC and Mike Farah yq. Python is used for CRC processing.
The framework is included in a consumer project, normally as a Git submodule.

## Layout

Keep application sources (for example Core/ and User/), CMakeLists.txt and
stm32_config.yml at the project level. Dependencies can live under modules/.
For multiple board revisions, keep each IOC, generated Core/ and optional linker
template in its own F411/ or G474/ directory. Profiles select the relevant files.
These names are examples; use paths that match your own repository.

## Connect the framework

```sh
git submodule add https://github.com/ObKo/stm32-cmake.git modules/stm32-cmake
git submodule add https://github.com/ViacheslavMezentsev/stm32-cmake-yml.git modules/stm32-cmake-yml
```

Consumer CMakeLists.txt:

```cmake
cmake_minimum_required(VERSION 3.19)
set(CMAKE_TOOLCHAIN_FILE
    "${CMAKE_CURRENT_SOURCE_DIR}/modules/stm32-cmake/cmake/stm32_gcc.cmake")
list(APPEND CMAKE_MODULE_PATH
    "${CMAKE_CURRENT_SOURCE_DIR}/modules/stm32-cmake-yml")
include(stm32_yml)
stm32_yml_prepare_project_data(PROJECT_NAME PROJECT_LANGUAGES)
project(${PROJECT_NAME} LANGUAGES ${PROJECT_LANGUAGES})
stm32_yml_setup_project(${PROJECT_NAME})
```

Create stm32_config.yml for your MCU and existing sources. Install the required
Cube dependencies and select the compiler/toolchain for your environment;
including this framework does not download every dependency automatically.
Arduino projects need their own toolchain and Core/library wrappers instead of
assuming the standard STM32 setup above covers them.

Next: [scenarios](scenarios.md), [option reference](reference/0.9.2/index.md),
[cache and bare metal](development.md).
