# ==============================================================================
# Модуль: НАСТРОЙКА СКРИПТА КОМПОНОВЩИКА (LINKER SCRIPT)
# ==============================================================================
# Отвечает за генерацию .ld файла из шаблона или подключение кастомного скрипта.
# Также подключает базовую CMSIS-цель, содержащую файлы startup_xx.s и memory maps.
# ==============================================================================

function(stm32_yml_setup_linker_script TARGET_NAME)
    set(LOCAL_CMSIS_TARGET_TO_LINK "")
    set(LOCAL_LINKER_SCRIPT_PATH "")

    stm32_yml_ensure_default_value(linker_script "auto")

    # =======================================================================
    # 1. ОПРЕДЕЛЕНИЕ И ПОДКЛЮЧЕНИЕ СКРИПТА
    # =======================================================================
    if(linker_script STREQUAL "auto")
        message(STATUS "Генерация скрипта компоновщика из шаблона...")

        # MCU_TYPE из stm32_get_chip_info возвращает обобщённый тип "H723xx"
        # (нужен для макроса компилятора STM32H723xx), но не подходит для поиска
        # шаблона. Извлекаем конкретные 6 символов типа напрямую из MCU-строки.
        # Пример: "STM32H723VGT6" -> substr(5,6) -> "H723VG"
        string(SUBSTRING "${MCU}" 5 6 _mcu_type_concrete)

        # Ищем шаблон по трём вариантам имени — от точного к общему:
        #   1. STM32H723VG_FLASH.ld.in  — точное совпадение
        #   2. STM32H723XG_FLASH.ld.in  — корпус (5й символ) заменён на X (стиль CubeMX)
        #   3. STM32H723XX_FLASH.ld.in  — оба последних символа XX (широкий фолбек)

        # Вариант 1: точное имя
        set(TEMPLATE_FILE_PATH "${CMAKE_SOURCE_DIR}/STM32${_mcu_type_concrete}_FLASH.ld.in")

        if(NOT EXISTS "${TEMPLATE_FILE_PATH}")
            # Вариант 2: заменяем 5й символ (тип корпуса: V/Z/A/R...) на X
            string(REGEX REPLACE "^(....).(.)$" "\\1X\\2" _mcu_x_pkg "${_mcu_type_concrete}")
            set(TEMPLATE_FILE_PATH "${CMAKE_SOURCE_DIR}/STM32${_mcu_x_pkg}_FLASH.ld.in")
        endif()

        if(NOT EXISTS "${TEMPLATE_FILE_PATH}")
            # Вариант 3: оба последних символа -> XX
            string(REGEX REPLACE "..$" "XX" _mcu_xx "${_mcu_type_concrete}")
            set(TEMPLATE_FILE_PATH "${CMAKE_SOURCE_DIR}/STM32${_mcu_xx}_FLASH.ld.in")
        endif()

        if(EXISTS "${TEMPLATE_FILE_PATH}")
            message(STATUS "Найден локальный шаблон: ${TEMPLATE_FILE_PATH}")

            # Нормализуем размеры памяти
            stm32_yml_normalize_memory(heap_size)
            stm32_yml_normalize_memory(stack_size)

            set(HEAP_SIZE ${heap_size} CACHE STRING "Required amount of heap")
            set(STACK_SIZE ${stack_size} CACHE STRING "Required amount of stack")

            # Проверяем версию GCC и задаём USE_READONLY
            if(CMAKE_C_COMPILER_VERSION VERSION_GREATER_EQUAL 11.0)
                set(USE_READONLY "(READONLY)")
                message(STATUS "Using READONLY in linker script (GCC >= 11.0)")
            else()
                set(USE_READONLY "")
                message(STATUS "Not using READONLY in linker script (GCC < 11.0)")
            endif()

            # Генерируем скрипт — имя файла берём из конкретного типа MCU, не из MCU_TYPE
            set(LOCAL_LINKER_SCRIPT_PATH "${CMAKE_BINARY_DIR}/STM32${_mcu_type_concrete}_FLASH.ld")
            configure_file(${TEMPLATE_FILE_PATH} ${LOCAL_LINKER_SCRIPT_PATH} @ONLY)
        else()
            message(STATUS "Локальный шаблон не найден. Будет использован стандартный скрипт компоновщика от stm32-cmake.")
        endif()

        # Подключаем найденный или сгенерированный скрипт
        if(LOCAL_LINKER_SCRIPT_PATH)
            if(use_cmsis)
                if(mcu_core)
                    list(APPEND LOCAL_CMSIS_TARGET_TO_LINK "CMSIS::STM32::${MCU_TYPE}::${mcu_core}")
                else()
                    list(APPEND LOCAL_CMSIS_TARGET_TO_LINK "CMSIS::STM32::${MCU_TYPE}")
                endif()
            endif()
            message(STATUS "Подключение скрипта компоновщика: ${LOCAL_LINKER_SCRIPT_PATH}")
            stm32_add_linker_script(${TARGET_NAME} PRIVATE ${LOCAL_LINKER_SCRIPT_PATH})
        else()
            # Доверяем stm32-cmake
            string(SUBSTRING ${MCU} 5 6 MCU_DEVICE)
            if(use_cmsis)
                if(mcu_core)
                    list(APPEND LOCAL_CMSIS_TARGET_TO_LINK "CMSIS::STM32::${MCU_DEVICE}::${mcu_core}")
                else()
                    list(APPEND LOCAL_CMSIS_TARGET_TO_LINK "CMSIS::STM32::${MCU_DEVICE}")
                endif()
            endif()
            message(STATUS "Подключение встроенного скрипта компоновщика: ${CMAKE_CURRENT_BINARY_DIR}/${MCU_DEVICE}.ld")
        endif()

    else()
        # Пользовательский скрипт из .yml
        if(use_cmsis)
            if(mcu_core)
                list(APPEND LOCAL_CMSIS_TARGET_TO_LINK "CMSIS::STM32::${MCU_TYPE}::${mcu_core}")
            else()
                list(APPEND LOCAL_CMSIS_TARGET_TO_LINK "CMSIS::STM32::${MCU_TYPE}")
            endif()
        endif()

        set(LOCAL_LINKER_SCRIPT_PATH "${CMAKE_CURRENT_SOURCE_DIR}/${linker_script}")

        if(EXISTS ${LOCAL_LINKER_SCRIPT_PATH})
            message(STATUS "Использование пользовательского скрипта компоновщика: ${LOCAL_LINKER_SCRIPT_PATH}")
            stm32_add_linker_script(${TARGET_NAME} PRIVATE ${LOCAL_LINKER_SCRIPT_PATH})
        else()
            message(FATAL_ERROR "Указанный скрипт компоновщика не найден: ${LOCAL_LINKER_SCRIPT_PATH}")
        endif()
    endif()

    # =======================================================================
    # 2. ПОДКЛЮЧЕНИЕ СИСТЕМНОЙ БИБЛИОТЕКИ CMSIS
    # =======================================================================
    if(LOCAL_CMSIS_TARGET_TO_LINK)
        # Линкуем CMSIS сразу здесь! Больше не нужно тащить её в конец файла.
        target_link_libraries(${TARGET_NAME} PRIVATE ${LOCAL_CMSIS_TARGET_TO_LINK})
    endif()

    # =======================================================================
    # 3. ЭКСПОРТ ПЕРЕМЕННЫХ
    # =======================================================================
    # Отправляем путь к скрипту наружу, чтобы модуль diagnostics смог прочитать RAM
    set(LINKER_SCRIPT_PATH "${LOCAL_LINKER_SCRIPT_PATH}" PARENT_SCOPE)

endfunction()
