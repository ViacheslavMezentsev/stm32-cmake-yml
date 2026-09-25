cmake_minimum_required(VERSION 3.19)
include("${STM32_YML_FRAMEWORK_DIR}/stm32_yml.cmake")
stm32_yml_prepare_project_data(PROJECT_NAME PROJECT_LANGUAGES)
project(${PROJECT_NAME} LANGUAGES ${PROJECT_LANGUAGES})
stm32_yml_setup_project(${PROJECT_NAME})

# Observe public configuration and target properties without changing the target.
file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/observed")
foreach(KEY IN ITEMS PROJECT_NAME MCU STM32_YML_PROFILE heap_size stack_size
        crc_enable use_cmsis use_hal toolchain_backend arduino_mcu_target
        MCU_TARGET USE_CORE_MAIN CMAKE_C_STANDARD CMAKE_CXX_STANDARD
        cubefw_package use_freertos include_directories
        freertos_version freertos_components cmsis_rtos_api)
    file(WRITE "${CMAKE_BINARY_DIR}/observed/${KEY}.txt" "${${KEY}}")
endforeach()
foreach(KEY IN ITEMS SOURCES COMPILE_DEFINITIONS COMPILE_OPTIONS LINK_OPTIONS LINK_LIBRARIES C_CPPCHECK CXX_CPPCHECK)
    get_target_property(VALUE ${PROJECT_NAME} ${KEY})
    file(WRITE "${CMAKE_BINARY_DIR}/observed/${KEY}.txt" "${VALUE}")
endforeach()
