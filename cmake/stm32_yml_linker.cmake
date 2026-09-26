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

    # Формат размеров памяти проверяется при каждом Configure, а не только
    # при генерации скрипта из шаблона (ТЗ 4.11.8).
    stm32_yml_check_memory_format(heap_size stack_size)

    # Формируем упорядоченный список папок поиска шаблона/скрипта.
    # linker_script_dir проверяется первым, затем корень проекта.
    set(_search_dirs "")
    if(DEFINED linker_script_dir AND NOT linker_script_dir STREQUAL "")
        set(_search_dirs "${CMAKE_SOURCE_DIR}/${linker_script_dir}")
        message(STATUS "Папка поиска скрипта компоновщика: ${_search_dirs}")
    endif()
    list(APPEND _search_dirs "${CMAKE_SOURCE_DIR}")

    # =======================================================================
    # 1. ОПРЕДЕЛЕНИЕ И ПОДКЛЮЧЕНИЕ СКРИПТА
    # =======================================================================
    if(linker_script STREQUAL "auto")
        message(STATUS "Генерация скрипта компоновщика из шаблона...")

        # MCU_TYPE из stm32_get_chip_info возвращает обобщённый тип "H723xx"
        # (нужен для макроса компилятора STM32H723xx), но не подходит для поиска
        # шаблона. Извлекаем конкретные 6 символов типа напрямую из MCU-строки.
        # Пример: "STM32H723VGT6" -> substr(5,6) -> "H723VG", "STM32G474RET" -> "G474RE"
        string(SUBSTRING "${MCU}" 5 6 _mcu_type_concrete)

        # Подготавливаем все варианты суффиксов имени шаблона.
        # Вариант 2: корпус (5й символ) заменён на X — стиль CubeMX для H7.
        string(REGEX REPLACE "^(....).(.)$" "\\1X\\2" _mcu_x_pkg "${_mcu_type_concrete}")
        # Вариант 3: оба последних символа -> XX (верхний регистр, широкий фолбек).
        string(REGEX REPLACE "..$" "XX" _mcu_xx "${_mcu_type_concrete}")
        # Вариант 4: оба последних символа -> xx (нижний регистр — стиль CubeMX для G4/F4).
        string(REGEX REPLACE "..$" "xx" _mcu_xx_lower "${_mcu_type_concrete}")

        # Ищем шаблон по четырём вариантам имени в каждой папке из _search_dirs.
        # Порядок приоритета: linker_script_dir, затем корень проекта.
        #   1. STM32G474RE_FLASH.ld.in  — точное совпадение.
        #   2. STM32G474XE_FLASH.ld.in  — корпус заменён на X (стиль CubeMX H7).
        #   3. STM32G474XX_FLASH.ld.in  — оба символа XX (верхний регистр).
        #   4. STM32G474xx_FLASH.ld.in  — оба символа xx (нижний регистр, стиль CubeMX G4/F4).
        set(TEMPLATE_FILE_PATH "")
        foreach(_search_dir IN LISTS _search_dirs)
            foreach(_suffix IN ITEMS
                "${_mcu_type_concrete}"
                "${_mcu_x_pkg}"
                "${_mcu_xx}"
                "${_mcu_xx_lower}")
                set(_candidate "${_search_dir}/STM32${_suffix}_FLASH.ld.in")
                if(EXISTS "${_candidate}")
                    set(TEMPLATE_FILE_PATH "${_candidate}")
                    break()
                endif()
            endforeach()
            if(TEMPLATE_FILE_PATH)
                break()
            endif()
        endforeach()

        if(EXISTS "${TEMPLATE_FILE_PATH}")
            message(STATUS "Найден локальный шаблон: ${TEMPLATE_FILE_PATH}")

            # Нормализуем размеры памяти
            stm32_yml_normalize_memory(heap_size)
            stm32_yml_normalize_memory(stack_size)

            # Обновляем производные значения и при повторном Configure:
            # профиль и STM32_YML_OVERRIDE_* уже применены к heap_size/stack_size.
            set(HEAP_SIZE ${heap_size} CACHE STRING "Required amount of heap" FORCE)
            set(STACK_SIZE ${stack_size} CACHE STRING "Required amount of stack" FORCE)

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
            message(STATUS "Локальный шаблон не найден. Будет использован стандартный скрипт компоновщика.")
        endif()

        # Подключаем найденный или сгенерированный скрипт
        if(LOCAL_LINKER_SCRIPT_PATH)
            if(NOT toolchain_backend STREQUAL "arduino" AND use_cmsis)
                if(mcu_core)
                    list(APPEND LOCAL_CMSIS_TARGET_TO_LINK "CMSIS::STM32::${MCU_TYPE}::${mcu_core}")
                else()
                    list(APPEND LOCAL_CMSIS_TARGET_TO_LINK "CMSIS::STM32::${MCU_TYPE}")
                endif()
            endif()
            message(STATUS "Подключение скрипта компоновщика: ${LOCAL_LINKER_SCRIPT_PATH}")
            
            if(toolchain_backend STREQUAL "arduino")
                target_link_options(${TARGET_NAME} PRIVATE "-T${LOCAL_LINKER_SCRIPT_PATH}")
                set_property(TARGET ${TARGET_NAME} APPEND PROPERTY LINK_DEPENDS "${LOCAL_LINKER_SCRIPT_PATH}")
            else()
                stm32_add_linker_script(${TARGET_NAME} PRIVATE ${LOCAL_LINKER_SCRIPT_PATH})
            endif()
        else()
            if(toolchain_backend STREQUAL "arduino")
                message(FATAL_ERROR "В режиме Arduino Backend генерация скрипта без локального шаблона не поддерживается. Добавьте шаблон или укажите готовый скрипт.")
            else()
                # Доверяем stm32-cmake
                string(SUBSTRING ${MCU} 5 6 MCU_DEVICE)
                if(use_cmsis)
                    if(mcu_core)
                        list(APPEND LOCAL_CMSIS_TARGET_TO_LINK "CMSIS::STM32::${MCU_DEVICE}::${mcu_core}")
                    else()
                        list(APPEND LOCAL_CMSIS_TARGET_TO_LINK "CMSIS::STM32::${MCU_DEVICE}")
                    endif()
                    # Скрипт stm32-cmake задаёт свои размеры (stm32_get_memory_info).
                    if(mcu_core)
                        set(_core_args CORE ${mcu_core})
                    else()
                        set(_core_args "")
                    endif()
                    stm32_get_memory_info(CHIP ${MCU} ${_core_args} HEAP SIZE _cmake_heap)
                    stm32_get_memory_info(CHIP ${MCU} ${_core_args} STACK SIZE _cmake_stack)
                    _stm32_yml_warn_unused_memory_sizes(
                        "скрипт компоновщика формирует stm32-cmake с собственными размерами "
                        "heap ${_cmake_heap} и stack ${_cmake_stack} байт. Добавьте шаблон "
                        "STM32${_mcu_type_concrete}_FLASH.ld.in (в корень проекта или linker_script_dir) "
                        "или задайте размеры в явном linker_script.")
                endif()
                message(STATUS "Подключение встроенного скрипта компоновщика: ${CMAKE_CURRENT_BINARY_DIR}/${MCU_DEVICE}.ld")
            endif()
        endif()

    else()
        # Пользовательский скрипт из .yml
        if(NOT toolchain_backend STREQUAL "arduino" AND use_cmsis)
            if(mcu_core)
                list(APPEND LOCAL_CMSIS_TARGET_TO_LINK "CMSIS::STM32::${MCU_TYPE}::${mcu_core}")
            else()
                list(APPEND LOCAL_CMSIS_TARGET_TO_LINK "CMSIS::STM32::${MCU_TYPE}")
            endif()
        endif()

        # Ищем явно указанный скрипт в linker_script_dir, затем в корне проекта.
        set(LOCAL_LINKER_SCRIPT_PATH "")
        foreach(_search_dir IN LISTS _search_dirs)
            if(EXISTS "${_search_dir}/${linker_script}")
                set(LOCAL_LINKER_SCRIPT_PATH "${_search_dir}/${linker_script}")
                break()
            endif()
        endforeach()

        if(LOCAL_LINKER_SCRIPT_PATH)
            message(STATUS "Использование пользовательского скрипта компоновщика: ${LOCAL_LINKER_SCRIPT_PATH}")
            _stm32_yml_warn_unused_memory_sizes(
                "размеры задаёт явный скрипт компоновщика '${linker_script}'. "
                "Измените их в скрипте или используйте шаблон .ld.in (linker_script: auto).")
            if(toolchain_backend STREQUAL "arduino")
                target_link_options(${TARGET_NAME} PRIVATE "-T${LOCAL_LINKER_SCRIPT_PATH}")
                set_property(TARGET ${TARGET_NAME} APPEND PROPERTY LINK_DEPENDS "${LOCAL_LINKER_SCRIPT_PATH}")
            else()
                stm32_add_linker_script(${TARGET_NAME} PRIVATE ${LOCAL_LINKER_SCRIPT_PATH})
            endif()
        else()
            message(FATAL_ERROR
                "Указанный скрипт компоновщика не найден: '${linker_script}'\n"
                "Папки поиска: ${_search_dirs}")
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

# ==============================================================================
# Предупреждает, что заданные heap_size/stack_size не применяются к скрипту
# компоновщика, который не генерируется из шаблона .ld.in (ТЗ 4.11.9).
# Значения ручного режима по умолчанию предупреждения не вызывают:
# STM32_YML_EXPLICIT_MEMORY_SIZES содержит только явно заданные размеры.
#
# @param ARGN - Причина и рекомендация (части сообщения).
# ==============================================================================
function(_stm32_yml_warn_unused_memory_sizes)
    if(NOT STM32_YML_EXPLICIT_MEMORY_SIZES)
        return()
    endif()
    set(_values "")
    foreach(_key IN LISTS STM32_YML_EXPLICIT_MEMORY_SIZES)
        list(APPEND _values "${_key}: ${${_key}}")
    endforeach()
    string(REPLACE ";" ", " _values "${_values}")
    string(CONCAT _reason ${ARGN})
    message(WARNING "Заданные размеры памяти (${_values}) не применяются: ${_reason}")
endfunction()
