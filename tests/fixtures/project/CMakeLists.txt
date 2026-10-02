cmake_minimum_required(VERSION 3.21)
include("${STM32_YML_FRAMEWORK_DIR}/stm32_yml.cmake")
# Test-only message codes 9xx before project() (spec 4.16.5, 4.16.10; TC-74, TC-75).
if(STM32_YML_TEST_MESSAGES)
    include("${CMAKE_CURRENT_SOURCE_DIR}/test_messages.cmake")
endif()
stm32_yml_prepare_project_data(PROJECT_NAME PROJECT_LANGUAGES)
project(${PROJECT_NAME} LANGUAGES ${PROJECT_LANGUAGES})
# TC-79: artifacts are built without the stm32-cmake stm32_generate_* functions.
if(STM32_YML_TEST_NO_GENERATE)
    foreach(KIND IN ITEMS binary hex srec)
        cmake_language(EVAL CODE "function(stm32_generate_${KIND}_file)
            message(FATAL_ERROR \"stm32_generate_${KIND}_file must not be used\")
        endfunction()")
    endforeach()
endif()
stm32_yml_setup_project(${PROJECT_NAME})
# TC-71: an INTERFACE CMSIS target defined after the framework call.
if(STM32_YML_TEST_CMSIS_TARGET)
    add_library(ProjectCmsis INTERFACE)
endif()
# TC-79: target properties set after the framework call (spec 4.14.4).
if(DEFINED STM32_YML_TEST_OUTPUT_NAME)
    set_target_properties(${PROJECT_NAME} PROPERTIES OUTPUT_NAME "${STM32_YML_TEST_OUTPUT_NAME}")
endif()
if(DEFINED STM32_YML_TEST_OUTPUT_DIR)
    set_target_properties(${PROJECT_NAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${STM32_YML_TEST_OUTPUT_DIR}")
endif()

# Observe public configuration and target properties without changing the target.
file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/observed")
foreach(KEY IN ITEMS PROJECT_NAME MCU STM32_YML_PROFILE heap_size stack_size CMAKE_VERBOSE_MAKEFILE
        crc_enable crc_method use_cmsis use_hal toolchain_backend arduino_mcu_target
        MCU_TARGET USE_CORE_MAIN CMAKE_C_STANDARD CMAKE_CXX_STANDARD
        cubefw_package use_freertos include_directories
        freertos_version freertos_components cmsis_rtos_api custom_probe_key)
    file(WRITE "${CMAKE_BINARY_DIR}/observed/${KEY}.txt" "${${KEY}}")
endforeach()
foreach(KEY IN ITEMS SOURCES COMPILE_DEFINITIONS COMPILE_OPTIONS LINK_OPTIONS LINK_LIBRARIES C_CPPCHECK CXX_CPPCHECK)
    get_target_property(VALUE ${PROJECT_NAME} ${KEY})
    file(WRITE "${CMAKE_BINARY_DIR}/observed/${KEY}.txt" "${VALUE}")
endforeach()
# Arduino interface targets (spec 4.9.3, 4.9.15; TC-72).
set(ARDUINO_TARGETS "")
foreach(TARGET_NAME IN ITEMS ArduinoDefinitions ArduinoOptions ArduinoPlatform board user_settings)
    if(TARGET ${TARGET_NAME})
        if(TARGET_NAME MATCHES "^Arduino")
            list(APPEND ARDUINO_TARGETS ${TARGET_NAME})
        endif()
        foreach(KEY IN ITEMS INTERFACE_COMPILE_DEFINITIONS INTERFACE_COMPILE_OPTIONS
                INTERFACE_INCLUDE_DIRECTORIES INTERFACE_LINK_OPTIONS INTERFACE_LINK_LIBRARIES)
            get_target_property(VALUE ${TARGET_NAME} ${KEY})
            file(WRITE "${CMAKE_BINARY_DIR}/observed/${TARGET_NAME}.${KEY}.txt" "${VALUE}")
        endforeach()
    endif()
endforeach()
file(WRITE "${CMAKE_BINARY_DIR}/observed/ARDUINO_TARGETS.txt" "${ARDUINO_TARGETS}")
