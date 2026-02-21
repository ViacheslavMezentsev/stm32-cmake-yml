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
        string(REGEX REPLACE "..$" "XX" MCU_TYPE_GENERIC "${MCU_TYPE}")
        set(TEMPLATE_FILE_PATH "${CMAKE_SOURCE_DIR}/STM32${MCU_TYPE_GENERIC}_FLASH.ld.in")

        if(EXISTS ${TEMPLATE_FILE_PATH})
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

            # Генерируем скрипт
            set(LOCAL_LINKER_SCRIPT_PATH "${CMAKE_BINARY_DIR}/STM32${MCU_TYPE}_FLASH.ld")
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
