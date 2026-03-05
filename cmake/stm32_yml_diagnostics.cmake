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

        message(STATUS "--- Отладочная информация для финальной цели '${TARGET_NAME}' ---")

        string(REPLACE ";" " \n    " COMPILE_OPTIONS_FORMATTED "${COMPILE_OPTIONS}")
        string(REPLACE ";" " \n    " COMPILE_DEFINITIONS_FORMATTED "${COMPILE_DEFINITIONS}")
        string(REPLACE ";" " \n    " INCLUDE_DIRECTORIES_FORMATTED "${INCLUDE_DIRECTORIES}")
        string(REPLACE ";" " \n    " LINK_OPTIONS_FORMATTED "${LINK_OPTIONS}")
        string(REPLACE ";" " \n    " LINK_LIBRARIES_FORMATTED "${LINK_LIBRARIES}")

        message(STATUS "Опции компиляции (COMPILE_OPTIONS):\n    ${COMPILE_OPTIONS_FORMATTED}")
        message(STATUS "Определения компиляции (COMPILE_DEFINITIONS):\n    ${COMPILE_DEFINITIONS_FORMATTED}")
        message(STATUS "Директории для #include (INCLUDE_DIRECTORIES):\n    ${INCLUDE_DIRECTORIES_FORMATTED}")
        message(STATUS "Опции компоновки (LINK_OPTIONS):\n    ${LINK_OPTIONS_FORMATTED}")
        message(STATUS "Библиотеки для компоновки (LINK_LIBRARIES):\n    ${LINK_LIBRARIES_FORMATTED}")

        # --- Вывод свойств для унаследованной цели STM32:: ---
        set(STM32_FRAMEWORK_TARGET "STM32::${MCU_FAMILY}")

        if(TARGET ${STM32_FRAMEWORK_TARGET})
            get_target_property(STM32_COMPILE_OPTIONS ${STM32_FRAMEWORK_TARGET} INTERFACE_COMPILE_OPTIONS)
            get_target_property(STM32_COMPILE_DEFS  ${STM32_FRAMEWORK_TARGET} INTERFACE_COMPILE_DEFINITIONS)
            get_target_property(STM32_LINK_OPTIONS  ${STM32_FRAMEWORK_TARGET} INTERFACE_LINK_OPTIONS)
            get_target_property(STM32_INCLUDE_DIRS  ${STM32_FRAMEWORK_TARGET} INTERFACE_INCLUDE_DIRECTORIES)

            message(STATUS "\n--- Отладочная информация для унаследованной цели '${STM32_FRAMEWORK_TARGET}' ---")

            string(REPLACE ";" " \n    " STM32_COMPILE_OPTIONS_FMT "${STM32_COMPILE_OPTIONS}")
            string(REPLACE ";" " \n    " STM32_COMPILE_DEFS_FMT  "${STM32_COMPILE_DEFS}")
            string(REPLACE ";" " \n    " STM32_LINK_OPTIONS_FMT  "${STM32_LINK_OPTIONS}")
            string(REPLACE ";" " \n    " STM32_INCLUDE_DIRS_FMT  "${STM32_INCLUDE_DIRS}")

            message(STATUS "INTERFACE Опции компиляции:\n    ${STM32_COMPILE_OPTIONS_FMT}")
            message(STATUS "INTERFACE Определения компиляции:\n    ${STM32_COMPILE_DEFS_FMT}")
            message(STATUS "INTERFACE Опции компоновки:\n    ${STM32_LINK_OPTIONS_FMT}")
        endif()

        message(STATUS "---------------------------------------------------------------------------------")
    endif()

    # =======================================================================
    # 2. САНИТАРНЫЕ ПРОВЕРКИ: hal_conf.h
    # =======================================================================
    if(use_hal)
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
                message(STATUS "Найден файл конфигурации HAL: ${dir}/${HAL_CONF_FILENAME}")
                break()
            endif()
        endforeach()

        if(NOT HAL_CONF_FOUND)
            message(FATAL_ERROR "Файл конфигурации HAL '${HAL_CONF_FILENAME}' не найден ни в одной из директорий, "
                                "указанных в 'include_directories'. Библиотека HAL не сможет скомпилироваться без него. "
                                "Убедитесь, что путь к этому файлу (например, 'Core/Inc') добавлен в 'include_directories' в project_config.yml.")
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
        message(STATUS "Выполнение проверки скрипта компоновщика...")

        # Получаем эталонный размер RAM от stm32-cmake (например, "64K")
        stm32_get_memory_info(CHIP ${mcu} RAM SIZE EXPECTED_RAM_SIZE_STR)

        string(REGEX REPLACE "K$" " * 1024" EXPECTED_RAM_SIZE_EXPR "${EXPECTED_RAM_SIZE_STR}")
        math(EXPR EXPECTED_RAM_SIZE_BYTES "${EXPECTED_RAM_SIZE_EXPR}")

        set(ACTUAL_RAM_SIZE_BYTES 0)
        set(_ram_sections_found "")

        if(LINKER_SCRIPT_PATH AND EXISTS ${LINKER_SCRIPT_PATH})
            # Читаем весь файл и ищем все RAM-секции в блоке MEMORY{}.
            # Стратегия: суммируем LENGTH всех секций с атрибутом (xrw) или (rw),
            # у которых ORIGIN != 0x00000000 (исключаем ITCMRAM — адрес 0x0).
            # Это корректно работает как для однорегионных чипов (F4: одна RAM),
            # так и для многорегионных (H7: DTCMRAM + RAM + RAM_D2 + RAM_D3).
            file(STRINGS ${LINKER_SCRIPT_PATH} _all_ld_lines)

            foreach(_line IN LISTS _all_ld_lines)
                # Ищем строки вида: NAME (xrw) : ORIGIN = 0x..., LENGTH = NNK
                # Пропускаем FLASH (rx) и секции с ORIGIN = 0x00000000 (ITCM)
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
                            # Извлекаем имя секции для лога
                            string(REGEX MATCH "^[ \t]*([A-Za-z_0-9]+)" _nm "${_line}")
                            list(APPEND _ram_sections_found "${CMAKE_MATCH_1}:${_sz}")
                        endif()
                    endif()
                endif()
            endforeach()

            if(NOT _ram_sections_found)
                message(WARNING "Не найдено ни одной RAM-секции (xrw/rw) в скрипте ${LINKER_SCRIPT_PATH}. Проверка размера пропущена.")
                set(ACTUAL_RAM_SIZE_BYTES ${EXPECTED_RAM_SIZE_BYTES})
            else()
                string(REPLACE ";" " + " _ram_sections_str "${_ram_sections_found}")
                message(STATUS "  RAM-секции в скрипте: ${_ram_sections_str} = ${ACTUAL_RAM_SIZE_BYTES} байт")
            endif()
        else()
            set(ACTUAL_RAM_SIZE_BYTES ${EXPECTED_RAM_SIZE_BYTES})
        endif()

        # Информационное сравнение: скрипт vs stm32-cmake (без FATAL_ERROR)
        # H7/H5 имеют несколько RAM-регионов, stm32_get_memory_info возвращает
        # только один — жёсткое равенство здесь неприменимо.
        math(EXPR _expected_bytes "${EXPECTED_RAM_SIZE_EXPR}")
        if(ACTUAL_RAM_SIZE_BYTES EQUAL _expected_bytes)
            set(_rel "==")
        elseif(ACTUAL_RAM_SIZE_BYTES LESS _expected_bytes)
            set(_rel "<")
        else()
            set(_rel ">")
        endif()

        math(EXPR _actual_k "${ACTUAL_RAM_SIZE_BYTES} / 1024")
        message(STATUS "  stm32-cmake RAM : ${EXPECTED_RAM_SIZE_STR}")
        message(STATUS "  Скрипт RAM сумма: ${ACTUAL_RAM_SIZE_BYTES} байт (${_actual_k}K)")
        message(STATUS "  Соотношение     : ${_actual_k}K ${_rel} ${EXPECTED_RAM_SIZE_STR}")
    endif()

endfunction()
