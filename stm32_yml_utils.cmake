# ==============================================================================
#      ФУНКЦИЯ ДЛЯ РАЗБОРА .ioc ФАЙЛА STM32CUBEMX
# ==============================================================================
# Читает .ioc файл и извлекает из него ключевые параметры проекта.
#
# @param IOC_FILE_PATH - Путь к .ioc файлу.
# @param PREFIX        - Префикс для всех создаваемых переменных (например, "IOC_").
#
# ==============================================================================
#      ФУНКЦИЯ ДЛЯ РАЗБОРА .ioc ФАЙЛА STM32CUBEMX
# ==============================================================================
function(stm32_yml_parse_ioc_file IOC_FILE_PATH PREFIX)
    if(NOT EXISTS ${IOC_FILE_PATH})
        message(FATAL_ERROR "Указанный .ioc файл не найден: ${IOC_FILE_PATH}")
    endif()

    file(STRINGS ${IOC_FILE_PATH} IOC_LINES)

    # Устанавливаем значения по умолчанию для опциональных компонентов
    set(${PREFIX}USE_FREERTOS FALSE PARENT_SCOPE)
    set(${PREFIX}CMSIS_RTOS_API "none" PARENT_SCOPE)

    foreach(line IN LISTS IOC_LINES)
        # Ищем строки формата "ключ=значение"
        if(line MATCHES "^([^=]+)=(.*)$")
            set(key ${CMAKE_MATCH_1})
            set(val ${CMAKE_MATCH_2})

            # Убираем пробелы и символы переноса (\r) с краев
            string(STRIP "${val}" val)

            if(key STREQUAL "ProjectManager.DeviceId")
                # Убираем лишние символы типа 'x' в конце (STM32F407VGTx -> STM32F407VGT)
                string(REGEX REPLACE "x$" "" val "${val}")
                set(${PREFIX}MCU ${val} PARENT_SCOPE)

            elseif(key STREQUAL "ProjectManager.FirmwarePackage")
                # Из "STM32Cube FW_F4 V1.28.2" извлекаем "V1.28.2"
                string(REGEX MATCH "V[0-9]+\\.[0-9]+\\.[0-9]+" fw_version "${val}")
                set(${PREFIX}CUBEFW_PACKAGE ${fw_version} PARENT_SCOPE)

            elseif(key STREQUAL "ProjectManager.ProjectName")
                set(${PREFIX}PROJECT_NAME ${val} PARENT_SCOPE)

            elseif(key STREQUAL "ProjectManager.HeapSize")
                # Конвертируем HEX (0x200) в десятичное число
                math(EXPR heap_bytes "${val}")
                set(${PREFIX}HEAP_SIZE ${heap_bytes} PARENT_SCOPE)

            elseif(key STREQUAL "ProjectManager.StackSize")
                math(EXPR stack_bytes "${val}")
                set(${PREFIX}STACK_SIZE ${stack_bytes} PARENT_SCOPE)

            elseif(key STREQUAL "ProjectManager.LibraryCopy")
                # Значение '0' означает полное локальное копирование
                # Значение '1' означает необходимое локальное копирование
                if(val STREQUAL "0" OR val STREQUAL "1")
                    set(${PREFIX}USE_LOCAL_DRIVERS TRUE PARENT_SCOPE)
                else()
                    set(${PREFIX}USE_LOCAL_DRIVERS FALSE PARENT_SCOPE)
                endif()

            # Детектирование FreeRTOS.
            elseif(val STREQUAL "FREERTOS")
                # Если какой-либо IP-блок установлен в FREERTOS.
                set(${PREFIX}USE_FREERTOS TRUE PARENT_SCOPE)

            elseif(key MATCHES "VP_FREERTOS_VS_CMSIS_V([12])")
                # Извлекаем версию CMSIS-RTOS (v1 или v2).
                set(${PREFIX}CMSIS_RTOS_API "v${CMAKE_MATCH_1}" PARENT_SCOPE)
            endif()
        endif()
    endforeach()
endfunction()

# ==============================================================================
#      ВСПОМОГАТЕЛЬНАЯ ФУНКЦИЯ ДЛЯ РЕКУРСИВНОГО ПАРСИНГА JSON
# ==============================================================================
# Обходит вложенные объекты JSON и формирует плоские переменные.
# Например: { "boot": { "offset": "0x800" } } -> boot_offset = "0x800"
function(_stm32_yml_parse_json_node JSON_STR PREFIX OUT_VARS_LIST)
    set(local_vars "")
    string(JSON num_keys LENGTH "${JSON_STR}")

    if(num_keys GREATER 0)
        math(EXPR last_key_index "${num_keys} - 1")
        foreach(idx RANGE ${last_key_index})
            string(JSON key MEMBER "${JSON_STR}" ${idx})
            string(JSON type TYPE "${JSON_STR}" "${key}")

            # Формируем имя переменной (с префиксом, если мы внутри объекта)
            if(PREFIX STREQUAL "")
                set(new_prefix "${key}")
            else()
                set(new_prefix "${PREFIX}_${key}")
            endif()

            if(type STREQUAL "OBJECT")
                # РЕКУРСИЯ: Проваливаемся во вложенный словарь
                string(JSON sub_json GET "${JSON_STR}" "${key}")
                _stm32_yml_parse_json_node("${sub_json}" "${new_prefix}" sub_vars)

                # Забираем переменные из дочернего вызова и пробрасываем их выше
                foreach(var IN LISTS sub_vars)
                    set(${var} "${${var}}" PARENT_SCOPE)
                    list(APPEND local_vars "${var}")
                endforeach()

            elseif(type STREQUAL "ARRAY")
                # ОБРАБОТКА МАССИВА
                set(temp_list "")
                string(JSON array_length LENGTH "${JSON_STR}" "${key}")
                if(array_length GREATER 0)
                    math(EXPR last_item_index "${array_length} - 1")
                    foreach(item_idx RANGE ${last_item_index})
                        string(JSON item_value GET "${JSON_STR}" "${key}" ${item_idx})
                        list(APPEND temp_list "${item_value}")
                    endforeach()
                endif()
                set(${new_prefix} "${temp_list}" PARENT_SCOPE)
                list(APPEND local_vars "${new_prefix}")

            elseif(type STREQUAL "NULL")
                # Пропускаем null значения
                set(${new_prefix} "" PARENT_SCOPE)
                list(APPEND local_vars "${new_prefix}")

            else()
                # БАЗОВЫЕ ТИПЫ (NUMBER, STRING, BOOLEAN)
                string(JSON value GET "${JSON_STR}" "${key}")
                set(${new_prefix} "${value}" PARENT_SCOPE)
                list(APPEND local_vars "${new_prefix}")
            endif()
        endforeach()
    endif()

    # Возвращаем список созданных переменных
    set(${OUT_VARS_LIST} "${local_vars}" PARENT_SCOPE)
endfunction()

# ==============================================================================
#      СОВРЕМЕННЫЙ ПАРСЕР КОНФИГУРАЦИИ (YAML -> JSON)
# ==============================================================================
# Эта функция использует внешний инструмент 'yq' для преобразования YAML в JSON,
# а затем использует встроенные возможности CMake для разбора JSON.
# Это надежно, просто и поддерживает весь синтаксис YAML.
#
# Требования: CMake >= 3.19, 'yq' должен быть установлен и доступен в PATH.
#
function(stm32_yml_parse_config config_file)
    find_program(YQ_EXECUTABLE yq)
    if(NOT YQ_EXECUTABLE)
        message(FATAL_ERROR "Инструмент 'yq' не найден. Пожалуйста, установите его.")
    endif()
    if(NOT EXISTS ${config_file})
        message(FATAL_ERROR "Файл конфигурации не найден: ${config_file}")
    endif()

    execute_process(
        COMMAND ${YQ_EXECUTABLE} -o=json "." ${config_file}
        OUTPUT_VARIABLE YAML_AS_JSON
        RESULT_VARIABLE YQ_RESULT
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(NOT YQ_RESULT EQUAL 0)
        message(FATAL_ERROR "Ошибка при конвертации ${config_file} в JSON с помощью yq.")
    endif()

    # Запускаем рекурсивный парсинг с корня
    _stm32_yml_parse_json_node("${YAML_AS_JSON}" "" PARSED_VARS)

    # Пробрасываем все найденные переменные в PARENT_SCOPE
    foreach(var IN LISTS PARSED_VARS)
        set(${var} "${${var}}" PARENT_SCOPE)
    endforeach()

    # СОХРАНЯЕМ СПИСОК ПЕРЕМЕННЫХ, чтобы следующий модуль мог пробросить их дальше
    set(YAML_PARSED_KEYS "${PARSED_VARS}" PARENT_SCOPE)

    message(STATUS "Конфигурация из ${config_file} успешно загружена.")
endfunction()

# ==============================================================================
#      ФУНКЦИЯ ДЛЯ НОРМАЛИЗАЦИИ РАЗМЕРОВ ПАМЯТИ В БАЙТЫ
# ==============================================================================
# Принимает имя переменной, значение которой нужно вычислить.
# Поддерживает форматы:
#   - "1M", "0.25M" (мегабайты)
#   - "1024K", "1.5K" (килобайты)
#   - "512" (байты)
# Результат (целое число байт) помещается в переменную с тем же именем.
#
function(stm32_yml_normalize_memory var_name)
    set(value_str ${${var_name}})
    set(result 0)

    # Проверяем на мегабайты (M или m)
    if(value_str MATCHES "^([0-9.]+)M$")
        set(numeric_part ${CMAKE_MATCH_1})
        math(EXPR result "${numeric_part} * 1024 * 1024")

    # Проверяем на килобайты (K или k)
    elseif(value_str MATCHES "^([0-9.]+)K$")
        set(numeric_part ${CMAKE_MATCH_1})
        math(EXPR result "${numeric_part} * 1024")

    # Проверяем на простое число (считаем, что это байты)
    elseif(value_str MATCHES "^[0-9]+$")
        set(result ${value_str})

    # Если формат не распознан - выдаем ошибку
    else()
        message(FATAL_ERROR "Недопустимый формат размера памяти: '${value_str}'. Используйте целые числа (байты) или числа с суффиксом K/M (например, '1.5K', '256K', '1M').")
    endif()

    message(STATUS "Размер памяти '${value_str}' нормализован в ${result} байт.")
    set(${var_name} ${result} PARENT_SCOPE)
endfunction()

# ==============================================================================
#      ФУНКЦИЯ ДЛЯ ПОИСКА ПОСЛЕДНЕЙ ВЕРСИИ STM32CUBE FW
# ==============================================================================
# Ищет в репозитории STM32Cube последнюю версию прошивки для указанного
# семейства MCU.
#
# @param MCU_FAMILY       - Семейство MCU (например, F4, H7).
# @param CUBE_REPO_PATH   - Путь к папке 'Repository' STM32Cube.
# @param RESULT_VAR       - Имя переменной, в которую будет записан результат (например, "V1.28.2").
#
function(stm32_yml_find_latest_stm32_cube_fw MCU_FAMILY CUBE_REPO_PATH RESULT_VAR)
    if(NOT EXISTS ${CUBE_REPO_PATH})
        message(FATAL_ERROR "Директория STM32Cube не найдена по пути: ${CUBE_REPO_PATH}")
    endif()

    # Ищем все папки, подходящие под наш шаблон семейства
    file(GLOB FW_DIRS LIST_DIRECTORIES true "${CUBE_REPO_PATH}/STM32Cube_FW_${MCU_FAMILY}_V*")

    if(NOT FW_DIRS)
        message(FATAL_ERROR "Не найдено ни одного пакета для семейства ${MCU_FAMILY} в ${CUBE_REPO_PATH}")
    endif()

    set(LATEST_VERSION "V0.0.0") # Начальное значение для сравнения

    # Перебираем найденные папки, чтобы найти самую новую версию
    foreach(dir_path IN LISTS FW_DIRS)
        get_filename_component(dir_name ${dir_path} NAME)

        if(dir_name MATCHES "(V[0-9]+\\.[0-9]+\\.[0-9]+.*)$")
            set(current_ver ${CMAKE_MATCH_1})

            # Убираем 'V' для корректного сравнения версий
            string(SUBSTRING "${current_ver}" 1 -1 current_ver_num)
            string(SUBSTRING "${LATEST_VERSION}" 1 -1 latest_ver_num)

            if(current_ver_num VERSION_GREATER latest_ver_num)
                set(LATEST_VERSION ${current_ver})
            endif()
        endif()
    endforeach()

    if(LATEST_VERSION STREQUAL "V0.0.0")
        message(FATAL_ERROR "Не удалось определить версию из найденных папок для ${MCU_FAMILY}.")
    endif()

    # Записываем результат в переменную, имя которой передал вызывающий код
    set(${RESULT_VAR} ${LATEST_VERSION} PARENT_SCOPE)
endfunction()

# ==============================================================================
#      ФУНКЦИЯ ДЛЯ УСТАНОВКИ ЗНАЧЕНИЯ ПО УМОЛЧАНИЮ
# ==============================================================================
# Проверяет, была ли переменная с именем VAR_NAME определена и непуста.
# Если она не определена или пуста, устанавливает для нее значение по умолчанию.
#
# @param VAR_NAME       - Имя переменной, которую нужно проверить.
# @param DEFAULT_VALUE  - Значение, которое нужно установить по умолчанию.
#
function(stm32_yml_ensure_default_value VAR_NAME DEFAULT_VALUE)
    # Проверяем, что переменная НЕ определена ИЛИ она определена, но является пустой строкой.
    # Это надежный способ покрыть оба случая: отсутствие ключа в YAML и ключ с пустым значением.
    if(NOT DEFINED ${VAR_NAME} OR "${${VAR_NAME}}" STREQUAL "")
        set(${VAR_NAME} "${DEFAULT_VALUE}" PARENT_SCOPE)
        message(STATUS "Параметр '${VAR_NAME}' не был задан или был пуст. Установлено значение по умолчанию: '${DEFAULT_VALUE}'.")
    endif()
endfunction()

if(NOT (TARGET STM32::Semihosting))
    add_library(STM32::Semihosting INTERFACE IMPORTED)
    target_link_options(STM32::Semihosting INTERFACE -lrdimon $<$<C_COMPILER_ID:GNU>:--specs=rdimon.specs>)
endif()

function(stm32_yml_generate_lss_file TARGET)
    set(OUTPUT_FILE_NAME "${TARGET}.lss")

    get_target_property(RUNTIME_OUTPUT_DIRECTORY ${TARGET} RUNTIME_OUTPUT_DIRECTORY)
    if(RUNTIME_OUTPUT_DIRECTORY)
        set(OUTPUT_FILE_PATH "${RUNTIME_OUTPUT_DIRECTORY}/${OUTPUT_FILE_NAME}")
    else()
        set(OUTPUT_FILE_PATH "${OUTPUT_FILE_NAME}")
    endif()

    add_custom_command(
        TARGET ${TARGET}
        POST_BUILD
        COMMAND ${CMAKE_OBJDUMP} -h -S "$<TARGET_FILE:${TARGET}>" > ${OUTPUT_FILE_PATH}
        BYPRODUCTS ${OUTPUT_FILE_PATH}
        COMMENT "Generating extended listing file ${OUTPUT_FILE_NAME} from ELF output file."
    )
endfunction()
