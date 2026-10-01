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
