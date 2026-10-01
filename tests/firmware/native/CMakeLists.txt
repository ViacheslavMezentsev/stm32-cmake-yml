# Arduino native mode firmware (spec 4.9.9-4.9.13, 4.9.18; TC-73, TC-85):
# built and inspected on every tool pair; runs in emulators come with RCC/PWR
# models (TC-86, after 0.10.0).
cmake_minimum_required(VERSION 3.21)
if(NOT STM32_YML_FRAMEWORK_DIR)
    message(FATAL_ERROR "Pass STM32_YML_FRAMEWORK_DIR and CMAKE_TOOLCHAIN_FILE")
endif()
list(APPEND CMAKE_MODULE_PATH "${STM32_YML_FRAMEWORK_DIR}")
include(stm32_yml)
stm32_yml_prepare_project_data(PROJECT_NAME PROJECT_LANGUAGES)
project(${PROJECT_NAME} LANGUAGES ${PROJECT_LANGUAGES})
stm32_yml_setup_project(${PROJECT_NAME})
set_target_properties(${PROJECT_NAME} PROPERTIES SUFFIX ".elf")
