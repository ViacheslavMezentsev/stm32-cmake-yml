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

        if(LINKER_SCRIPT_PATH AND EXISTS ${LINKER_SCRIPT_PATH})
            # Читаем строки из файла и ищем определение RAM
            file(STRINGS ${LINKER_SCRIPT_PATH} ld_lines REGEX "RAM.*LENGTH[ \t]*=")
            list(GET ld_lines 0 ld_line)

            if(ld_line)
                string(REGEX MATCH "LENGTH[ \t]*=[ \t]*([0-9]+[KkMm]?)" MATCH_RESULT "${ld_line}")

                if(CMAKE_MATCH_1)
                    set(ACTUAL_RAM_SIZE_STR ${CMAKE_MATCH_1})
                    string(TOUPPER ${ACTUAL_RAM_SIZE_STR} ACTUAL_RAM_SIZE_STR_UPPER)

                    if(ACTUAL_RAM_SIZE_STR_UPPER MATCHES "K$")
                        string(REGEX REPLACE "K$" " * 1024" ACTUAL_RAM_SIZE_EXPR "${ACTUAL_RAM_SIZE_STR_UPPER}")
                    elseif(ACTUAL_RAM_SIZE_STR_UPPER MATCHES "M$")
                        string(REGEX REPLACE "M$" " * 1024 * 1024" ACTUAL_RAM_SIZE_EXPR "${ACTUAL_RAM_SIZE_STR_UPPER}")
                    else()
                        set(ACTUAL_RAM_SIZE_EXPR "${ACTUAL_RAM_SIZE_STR_UPPER}")
                    endif()

                    math(EXPR ACTUAL_RAM_SIZE_BYTES "${ACTUAL_RAM_SIZE_EXPR}")
                else()
                    message(WARNING "Строка с RAM найдена, но не удалось распарсить значение LENGTH: '${ld_line}'")
                endif()
            else()
                 message(WARNING "Не удалось найти определение RAM (MEMORY { RAM ... }) в скрипте ${LINKER_SCRIPT_PATH}. Проверка размера пропущена.")
            endif()
        else()
            set(ACTUAL_RAM_SIZE_BYTES ${EXPECTED_RAM_SIZE_BYTES})
        endif()

        # Сравниваем и выдаем предупреждение/ошибку
        if(ACTUAL_RAM_SIZE_BYTES GREATER 0 AND ACTUAL_RAM_SIZE_BYTES LESS EXPECTED_RAM_SIZE_BYTES)
            message(WARNING "Размер RAM в скрипте компоновщика (${ACTUAL_RAM_SIZE_STR}) МЕНЬШЕ, чем ожидается для ${mcu} (${EXPECTED_RAM_SIZE_STR}). Это может привести к неиспользованию всей памяти.")
        elseif(ACTUAL_RAM_SIZE_BYTES GREATER EXPECTED_RAM_SIZE_BYTES)
            message(FATAL_ERROR "КРИТИЧЕСКАЯ ОШИБКА КОНФИГУРАЦИИ!\n"
                                "Размер RAM в вашем скрипте компоновщика (${ACTUAL_RAM_SIZE_STR}) БОЛЬШЕ, чем физически существует в ${mcu} (${EXPECTED_RAM_SIZE_STR}).\n"
                                "Это приведет к Hard Fault при запуске, так как указатель стека будет указывать на несуществующую память.\n"
                                "Исправьте 'LENGTH' для секции 'RAM' в вашем .ld или .ld.in файле!")
        else()
            message(STATUS "Проверка размера RAM в скрипте компоновщика пройдена успешно. (${EXPECTED_RAM_SIZE_STR})")
        endif()
    endif()

endfunction()
