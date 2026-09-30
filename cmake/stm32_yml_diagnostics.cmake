# ==============================================================================
# Модуль: ДИАГНОСТИКА И САНИТАРНЫЕ ПРОВЕРКИ
# ==============================================================================
# Отвечает за проверку корректности конфигурации (наличие hal_conf.h,
# проверка размера RAM в .ld скрипте) и вывод отладочной информации.
# ==============================================================================

function(stm32_yml_run_diagnostics TARGET_NAME)

    # =======================================================================
    # 1. ОТЛАДОЧНЫЙ ВЫВОД СВОЙСТВ ЦЕЛИ
    # =======================================================================
    stm32_yml_ensure_default_value(log_target_properties "false")

    # Безопасный фолбек для локальной области видимости CMake
    if(NOT DEFINED log_target_properties OR "${log_target_properties}" STREQUAL "")
        set(log_target_properties "false")
    endif()

    if(log_target_properties)
        # --- Вывод свойств для финальной цели ---
        get_target_property(COMPILE_OPTIONS ${TARGET_NAME} COMPILE_OPTIONS)
        get_target_property(COMPILE_DEFINITIONS ${TARGET_NAME} COMPILE_DEFINITIONS)
        get_target_property(INCLUDE_DIRECTORIES ${TARGET_NAME} INCLUDE_DIRECTORIES)
        get_target_property(LINK_OPTIONS ${TARGET_NAME} LINK_OPTIONS)
        get_target_property(LINK_LIBRARIES ${TARGET_NAME} LINK_LIBRARIES)

        stm32_yml_msg(I801 "${TARGET_NAME}")

        string(REPLACE ";" " \n    " COMPILE_OPTIONS_FORMATTED "${COMPILE_OPTIONS}")
        string(REPLACE ";" " \n    " COMPILE_DEFINITIONS_FORMATTED "${COMPILE_DEFINITIONS}")
        string(REPLACE ";" " \n    " INCLUDE_DIRECTORIES_FORMATTED "${INCLUDE_DIRECTORIES}")
        string(REPLACE ";" " \n    " LINK_OPTIONS_FORMATTED "${LINK_OPTIONS}")
        string(REPLACE ";" " \n    " LINK_LIBRARIES_FORMATTED "${LINK_LIBRARIES}")

        stm32_yml_msg(I802 "${COMPILE_OPTIONS_FORMATTED}")
        stm32_yml_msg(I803 "${COMPILE_DEFINITIONS_FORMATTED}")
        stm32_yml_msg(I804 "${INCLUDE_DIRECTORIES_FORMATTED}")
        stm32_yml_msg(I805 "${LINK_OPTIONS_FORMATTED}")
        stm32_yml_msg(I806 "${LINK_LIBRARIES_FORMATTED}")

        # --- Вывод свойств для унаследованной цели STM32:: ---
        set(STM32_FRAMEWORK_TARGET "STM32::${MCU_FAMILY}")

        if(TARGET ${STM32_FRAMEWORK_TARGET})
            get_target_property(STM32_COMPILE_OPTIONS ${STM32_FRAMEWORK_TARGET} INTERFACE_COMPILE_OPTIONS)
            get_target_property(STM32_COMPILE_DEFS  ${STM32_FRAMEWORK_TARGET} INTERFACE_COMPILE_DEFINITIONS)
            get_target_property(STM32_LINK_OPTIONS  ${STM32_FRAMEWORK_TARGET} INTERFACE_LINK_OPTIONS)
            get_target_property(STM32_INCLUDE_DIRS  ${STM32_FRAMEWORK_TARGET} INTERFACE_INCLUDE_DIRECTORIES)

            stm32_yml_msg(I807 "${STM32_FRAMEWORK_TARGET}")

            string(REPLACE ";" " \n    " STM32_COMPILE_OPTIONS_FMT "${STM32_COMPILE_OPTIONS}")
            string(REPLACE ";" " \n    " STM32_COMPILE_DEFS_FMT  "${STM32_COMPILE_DEFS}")
            string(REPLACE ";" " \n    " STM32_LINK_OPTIONS_FMT  "${STM32_LINK_OPTIONS}")
            string(REPLACE ";" " \n    " STM32_INCLUDE_DIRS_FMT  "${STM32_INCLUDE_DIRS}")

            stm32_yml_msg(I808 "${STM32_COMPILE_OPTIONS_FMT}")
            stm32_yml_msg(I809 "${STM32_COMPILE_DEFS_FMT}")
            stm32_yml_msg(I810 "${STM32_LINK_OPTIONS_FMT}")
        endif()

        stm32_yml_msg(I811)
    endif()

    # =======================================================================
    # 2. САНИТАРНЫЕ ПРОВЕРКИ: hal_conf.h
    # =======================================================================
    if(NOT toolchain_backend STREQUAL "arduino" AND use_hal)
        # На всякий случай переводим семейство в нижний регистр, если вдруг переменной нет в скоупе
        if(NOT DEFINED MCU_FAMILY_LOWER)
            string(TOLOWER "${MCU_FAMILY}" MCU_FAMILY_LOWER)
        endif()

        set(HAL_CONF_FILENAME "stm32${MCU_FAMILY_LOWER}xx_hal_conf.h")
        set(HAL_CONF_FOUND FALSE)

        get_target_property(INCLUDE_DIRS ${TARGET_NAME} INCLUDE_DIRECTORIES)

        foreach(dir IN LISTS INCLUDE_DIRS)
            if(EXISTS "${dir}/${HAL_CONF_FILENAME}")
                set(HAL_CONF_FOUND TRUE)
                stm32_yml_msg(I812 "${dir}/${HAL_CONF_FILENAME}")
                break()
            endif()
        endforeach()

        if(NOT HAL_CONF_FOUND)
            stm32_yml_msg(E801 "${HAL_CONF_FILENAME}" "${PROJECT_CONFIG_FILE}")
        endif()
    endif()

    # =======================================================================
    # 3. САНИТАРНЫЕ ПРОВЕРКИ: Размеры памяти в скрипте компоновщика (.ld)
    # =======================================================================
    stm32_yml_ensure_default_value(validate_linker_script "true")
    if(NOT DEFINED validate_linker_script OR "${validate_linker_script}" STREQUAL "")
        set(validate_linker_script "true")
    endif()

    if(validate_linker_script)
        if(toolchain_backend STREQUAL "arduino")
            stm32_yml_msg(I813)
        elseif(NOT LINKER_SCRIPT_PATH OR NOT EXISTS "${LINKER_SCRIPT_PATH}")
            # Скрипт формирует stm32-cmake (ТЗ 4.11.5): сравнивать не с чем.
            stm32_yml_msg(I814)
        else()
            stm32_yml_msg(I815)

            # Эталон: RAM + CCRAM + RAM_SHARE MCU с учётом ядра (ТЗ 4.13.4, 4.7.8).
            # CCM-память F3 и G4 входит в сумму, поэтому не даёт ложного превышения.
            set(EXPECTED_RAM_SIZE_BYTES 0)
            set(_expected_parts "")
            foreach(_kind IN ITEMS RAM CCRAM RAM_SHARE)
                stm32_yml_mcu_memory_size(${_kind} _kind_bytes _kind_text)
                if(_kind_bytes GREATER 0)
                    math(EXPR EXPECTED_RAM_SIZE_BYTES "${EXPECTED_RAM_SIZE_BYTES} + ${_kind_bytes}")
                    list(APPEND _expected_parts "${_kind} ${_kind_text}")
                endif()
            endforeach()

            set(ACTUAL_RAM_SIZE_BYTES 0)
            set(_ram_sections_found "")
            file(STRINGS ${LINKER_SCRIPT_PATH} _all_ld_lines)

            foreach(_line IN LISTS _all_ld_lines)
                if(_line MATCHES "[A-Za-z_0-9]+[ \t]*(\\([ \t]*[xr]*rw[xr]*[ \t]*\\))")
                    if(NOT _line MATCHES "ORIGIN[ \t]*=[ \t]*0x0+[^0-9]")
                        string(REGEX MATCH "LENGTH[ \t]*=[ \t]*([0-9]+[KkMm]?)" _m "${_line}")
                        if(CMAKE_MATCH_1)
                            set(_sz "${CMAKE_MATCH_1}")
                            string(TOUPPER "${_sz}" _sz_upper)
                            if(_sz_upper MATCHES "^([0-9]+)K$")
                                math(EXPR _bytes "${CMAKE_MATCH_1} * 1024")
                            elseif(_sz_upper MATCHES "^([0-9]+)M$")
                                math(EXPR _bytes "${CMAKE_MATCH_1} * 1024 * 1024")
                            else()
                                set(_bytes "${_sz_upper}")
                            endif()
                            math(EXPR ACTUAL_RAM_SIZE_BYTES "${ACTUAL_RAM_SIZE_BYTES} + ${_bytes}")
                            string(REGEX MATCH "^[ \t]*([A-Za-z_0-9]+)" _nm "${_line}")
                            list(APPEND _ram_sections_found "${CMAKE_MATCH_1}:${_sz}")
                        endif()
                    endif()
                endif()
            endforeach()

            if(NOT _ram_sections_found)
                stm32_yml_msg(W801 "${LINKER_SCRIPT_PATH}")
            else()
                string(REPLACE ";" " + " _ram_sections_str "${_ram_sections_found}")
                string(REPLACE ";" " + " _expected_str "${_expected_parts}")
                stm32_yml_msg(I816 "${_ram_sections_str}" "${ACTUAL_RAM_SIZE_BYTES}")

                if(ACTUAL_RAM_SIZE_BYTES EQUAL EXPECTED_RAM_SIZE_BYTES)
                    set(_rel "==")
                elseif(ACTUAL_RAM_SIZE_BYTES LESS EXPECTED_RAM_SIZE_BYTES)
                    set(_rel "<")
                else()
                    set(_rel ">")
                endif()

                math(EXPR _actual_k "${ACTUAL_RAM_SIZE_BYTES} / 1024")
                math(EXPR _expected_k "${EXPECTED_RAM_SIZE_BYTES} / 1024")
                stm32_yml_msg(I817 "${_expected_str}" "${EXPECTED_RAM_SIZE_BYTES}")
                stm32_yml_msg(I818 "${ACTUAL_RAM_SIZE_BYTES}" "${_actual_k}")
                stm32_yml_msg(I819 "${_actual_k}" "${_rel}" "${_expected_k}")
            endif()
        endif()
    endif()

endfunction()
