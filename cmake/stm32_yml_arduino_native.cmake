# ==============================================================================
# Модуль: РЕЖИМ ARDUINO NATIVE (ТЗ 4.9.9–4.9.13, 4.9.18)
# ==============================================================================
# Цели Arduino_Core_STM32 подключаются напрямую из его CMake-файлов:
# environment, set_base_arduino_config, CMakeLists.txt variant, cores/arduino,
# libraries/SrcWrapper и библиотек arduino.libraries. Функции ядра set_board(),
# updatedb(), ensure_core_deps() и overall_settings() не вызываются: Configure
# не требует Python и сети и не меняет файлы ядра. Цели board и user_settings
# создаёт фреймворк.
# ==============================================================================

include_guard(GLOBAL)

# Цели ядра, которые создаёт режим native.
set(_STM32_YML_ARDUINO_NATIVE_TARGETS
    board user_settings base_config stm32_runtime
    core core_usage core_bin variant variant_usage variant_bin
    SrcWrapper SrcWrapper_usage SrcWrapper_bin)

# ==============================================================================
# @param TARGET_NAME  - Исполняемая цель проекта.
# @param CORE         - Абсолютный путь к Arduino_Core_STM32.
# ==============================================================================
function(stm32_yml_setup_arduino_native TARGET_NAME CORE)
    foreach(_name IN LISTS _STM32_YML_ARDUINO_NATIVE_TARGETS)
        if(TARGET ${_name})
            stm32_yml_msg(E510 "${_name}")
        endif()
    endforeach()
    # Ключи режима wrappers (ТЗ 4.9.2, 4.9.4) в режиме native не действуют.
    foreach(_key IN ITEMS core_cmake_dir mcu_target)
        if(NOT "${arduino_${_key}}" STREQUAL "")
            stm32_yml_msg(W506 "arduino.${_key}")
        endif()
    endforeach()

    # Плата (ТЗ 4.9.10): по умолчанию auto; неудача — ошибка.
    set(_requested "${arduino_board}")
    if(_requested STREQUAL "")
        set(_requested auto)
    endif()
    if(NOT EXISTS "${CORE}/cmake/boards_db.cmake")
        stm32_yml_msg(E509 "${CORE}/cmake/boards_db.cmake")
    endif()
    stm32_yml_arduino_select_board("${CORE}" "${_requested}" _board _candidates)
    if(_board STREQUAL "")
        stm32_yml_msg(E504 "${MCU}" "${_candidates}")
    endif()

    # CMSIS (ТЗ 4.9.14): ядро берёт заголовки из ${CMSIS6_PATH}/CMSIS/Core/Include.
    stm32_yml_arduino_find_cmsis(_cmsis _cmsis_source _places)
    if(_cmsis_source STREQUAL "")
        stm32_yml_msg(E506 "${_places}")
    endif()

    stm32_yml_arduino_load_board("${CORE}" "${_board}")
    stm32_yml_msg(I509 "${_board}" "${_requested}")

    # Цель board — копия цели платы с вариантами по умолчанию. Скрипт
    # компоновщика (--default-script) подставляет модуль linker (ТЗ 4.9.11).
    add_library(board INTERFACE)
    foreach(_property IN ITEMS INTERFACE_COMPILE_OPTIONS INTERFACE_COMPILE_DEFINITIONS
            INTERFACE_INCLUDE_DIRECTORIES INTERFACE_LINK_LIBRARIES)
        get_target_property(_value ${_board} ${_property})
        if(_value)
            set_property(TARGET board PROPERTY ${_property} "${_value}")
        endif()
    endforeach()
    get_target_property(_link_options ${_board} INTERFACE_LINK_OPTIONS)
    set(_default_script "")
    set(_options "")
    foreach(_option IN LISTS _link_options)
        if(_option MATCHES "^LINKER:--default-script=(.*)$")
            set(_default_script "${CMAKE_MATCH_1}")
        else()
            list(APPEND _options "${_option}")
        endif()
    endforeach()
    set_property(TARGET board PROPERTY INTERFACE_LINK_OPTIONS "${_options}")
    set_property(GLOBAL PROPERTY _STM32_YML_ARDUINO_VARIANT_SCRIPT "${_default_script}")
    set_property(GLOBAL PROPERTY _STM32_YML_ARDUINO_FLASH_SIZE "${ARDUINO_FLASH_SIZE}")
    set_property(GLOBAL PROPERTY _STM32_YML_ARDUINO_NATIVE TRUE)
    set(ARDUINO_BOARD "${_board}" CACHE STRING "Плата Arduino / Arduino board ID." FORCE)
    set(ARDUINO_VARIANT_PATH "${ARDUINO_VARIANT_PATH}" CACHE PATH
        "Каталог variant выбранной платы Arduino / variant directory of the Arduino board." FORCE)

    # user_settings (ТЗ 4.9.12): настройки overall_settings() ядра (-Os,
    # newlib-nano), затем флаги YAML — они могут переопределить оптимизацию.
    add_library(user_settings INTERFACE)
    target_compile_options(user_settings INTERFACE -Os)
    target_link_options(user_settings INTERFACE --specs=nano.specs)
    if(compile_definitions)
        target_compile_definitions(user_settings INTERFACE ${compile_definitions})
    endif()
    if(compile_options)
        target_compile_options(user_settings INTERFACE ${compile_options})
    endif()
    foreach(_language IN ITEMS C CXX)
        string(TOLOWER "${_language}" _suffix)
        if(compile_definitions_${_suffix})
            target_compile_definitions(user_settings INTERFACE
                $<$<COMPILE_LANGUAGE:${_language}>:${compile_definitions_${_suffix}}>)
        endif()
        if(compile_options_${_suffix})
            target_compile_options(user_settings INTERFACE
                $<$<COMPILE_LANGUAGE:${_language}>:${compile_options_${_suffix}}>)
        endif()
    endforeach()
    if(_cmsis_source STREQUAL "external")
        # Путь CMSIS ядра указывает на несуществующий каталог: заголовки даёт проект.
        set(CMSIS6_PATH "${CMAKE_BINARY_DIR}/stm32_yml_cmsis_external")
        stm32_yml_arduino_attach_cmsis(user_settings "" external)
    else()
        set(CMSIS6_PATH "${_cmsis}")
        stm32_yml_msg(I514 "${_cmsis}" "${_cmsis_source}")
    endif()

    # Данные и цели ядра. environment задаёт BUILD_CORE_PATH, BUILD_LIB_PATH и
    # другие пути; set_base_arduino_config создаёт base_config и stm32_runtime.
    include("${CORE}/cmake/environment.cmake")
    include("${CORE}/cmake/set_base_arduino_config.cmake")
    stm32_yml_add_subdirectory("${ARDUINO_VARIANT_PATH}")
    stm32_yml_add_subdirectory("${CORE}/cores/arduino")
    stm32_yml_add_subdirectory("${CORE}/libraries/SrcWrapper")
    foreach(_lib IN LISTS arduino_libraries)
        if(_lib STREQUAL "SrcWrapper")
            continue()
        endif()
        set(_lib_dir "${CORE}/libraries/${_lib}")
        if(EXISTS "${_lib_dir}/CMakeLists.txt")
            stm32_yml_msg(I506 "${_lib}")
            stm32_yml_add_subdirectory("${_lib_dir}")
        else()
            stm32_yml_msg(W503 "${_lib}" "${_lib_dir}")
        endif()
    endforeach()

    # main() ядра или проекта (ТЗ 4.9.18).
    set(_use_core_main TRUE)
    if(DEFINED arduino_use_core_main AND NOT "${arduino_use_core_main}" STREQUAL "")
        set(_use_core_main ${arduino_use_core_main})
    endif()
    if(_use_core_main)
        stm32_yml_msg(I519)
    else()
        get_target_property(_sources core_bin SOURCES)
        list(FILTER _sources EXCLUDE REGEX "(^|/)main\\.cpp$")
        set_property(TARGET core_bin PROPERTY SOURCES "${_sources}")
        # _write из Print.cpp иначе не извлекается из libcore_bin.a (п. 10.3.10).
        target_link_options(${TARGET_NAME} PRIVATE "LINKER:--undefined=_write")
        stm32_yml_msg(I520)
    endif()

    target_link_libraries(${TARGET_NAME} PRIVATE stm32_runtime)
endfunction()

# ==============================================================================
# Скрипт компоновщика режима native (ТЗ 4.9.11): шаблон или явный скрипт
# заменяет --default-script цели board; без них — скрипт variant платы.
#
# @param TARGET_NAME  - Исполняемая цель.
# @param SCRIPT       - Путь скрипта; пусто — скрипт variant.
# @param OUT_SCRIPT   - Переменная для фактического скрипта.
# ==============================================================================
function(stm32_yml_arduino_native_linker_script TARGET_NAME SCRIPT OUT_SCRIPT)
    if(SCRIPT STREQUAL "")
        get_property(SCRIPT GLOBAL PROPERTY _STM32_YML_ARDUINO_VARIANT_SCRIPT)
        stm32_yml_msg(I521 "${SCRIPT}")
    endif()
    target_link_options(board INTERFACE "LINKER:--default-script=${SCRIPT}")
    set_property(TARGET ${TARGET_NAME} APPEND PROPERTY LINK_DEPENDS "${SCRIPT}")
    set(${OUT_SCRIPT} "${SCRIPT}" PARENT_SCOPE)
endfunction()
