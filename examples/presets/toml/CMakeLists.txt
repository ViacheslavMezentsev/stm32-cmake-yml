cmake_minimum_required(VERSION 3.21)

# Dependencies are supplied by the developer; no automatic download.
set(STM32_YML_FRAMEWORK_DIR "${CMAKE_CURRENT_SOURCE_DIR}/modules/stm32-cmake-yml"
    CACHE PATH "stm32-cmake-yml checkout")
include("${STM32_YML_FRAMEWORK_DIR}/stm32_yml.cmake")
stm32_yml_prepare_project_data(PROJECT_NAME PROJECT_LANGUAGES)
project(${PROJECT_NAME} LANGUAGES ${PROJECT_LANGUAGES})

# Project-owned targets may be added here before setup_project().
stm32_yml_setup_project(${PROJECT_NAME})
