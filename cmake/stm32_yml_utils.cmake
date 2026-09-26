# ==============================================================================
#      ФУНКЦИЯ ДЛЯ РАЗБОРА .ioc ФАЙЛА STM32CUBEMX
# ==============================================================================
# Читает .ioc файл и извлекает из него ключевые параметры проекта.
#
# @param IOC_FILE_PATH - Путь к .ioc файлу.
# @param PREFIX        - Префикс для всех создаваемых переменных (например, "IOC_").
# ==============================================================================
function(stm32_yml_parse_ioc_file IOC_FILE_PATH PREFIX)
    if(NOT EXISTS ${IOC_FILE_PATH})
        message(FATAL_ERROR "Указанный .ioc файл не найден: ${IOC_FILE_PATH}")
    endif()

    file(STRINGS ${IOC_FILE_PATH} IOC_LINES)

    # Значения по умолчанию для опциональных компонентов.
    # Накапливаются в локальных переменных: set(... PARENT_SCOPE) не меняет
    # переменную в текущей области, поэтому постобработка после цикла не
    # увидела бы значений, записанных внутри него.
    set(_use_freertos         FALSE)
    set(_cmsis_rtos_api       "none")
    set(_use_customer_fw_path FALSE)
    set(_customer_fw_family   "")
    set(_customer_fw_version  "")
    set(_customer_fw_path     "")
    set(_cubefw_package       "")

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

            elseif(key STREQUAL "ProjectManager.DefaultFWLocation")
                # false — пользователь выбрал нестандартный путь к пакету.
                if(val STREQUAL "false")
                    set(_use_customer_fw_path TRUE)
                else()
                    set(_use_customer_fw_path FALSE)
                endif()

            elseif(key STREQUAL "ProjectManager.CustomerFirmwarePackage")
                # Путь вида C:\Users\...\STM32Cube_FW_H7_V1.12.1
                # Извлекаем семейство и версию из имени последней компоненты пути.
                string(REGEX MATCH "STM32Cube_FW_([A-Za-z0-9]+)_(V[0-9]+\\.[0-9]+\\.[0-9]+)" _customer_match "${val}")
                if(_customer_match)
                    set(_customer_fw_family  "${CMAKE_MATCH_1}")
                    set(_customer_fw_version "${CMAKE_MATCH_2}")
                    # Сохраняем сам путь (нормализуем разделители).
                    string(REPLACE "\\" "/" _customer_fw_path "${val}")
                endif()

            elseif(key STREQUAL "ProjectManager.FirmwarePackage")
                # Из "STM32Cube FW_F4 V1.28.2" извлекаем "V1.28.2".
                # Используется только когда DefaultFWLocation=true (значение по умолчанию).
                string(REGEX MATCH "V[0-9]+\\.[0-9]+\\.[0-9]+" fw_version "${val}")
                set(_cubefw_package "${fw_version}")

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
                # Значение '0' означает полное локальное копирование.
                # Значение '1' означает необходимое локальное копирование.
                if(val STREQUAL "0" OR val STREQUAL "1")
                    set(${PREFIX}USE_LOCAL_DRIVERS TRUE PARENT_SCOPE)
                else()
                    set(${PREFIX}USE_LOCAL_DRIVERS FALSE PARENT_SCOPE)
                endif()

                        # Детектирование FreeRTOS.
                        elseif(val STREQUAL "FREERTOS")
                            # Если какой-либо IP-блок установлен в FREERTOS.
                            set(_use_freertos TRUE)

                        elseif(key MATCHES "VP_FREERTOS_VS_CMSIS_V([12])")
                            # Извлекаем версию CMSIS-RTOS (v1 или v2).
                            set(_cmsis_rtos_api "v${CMAKE_MATCH_1}")
                        endif()
                    endif()
                endforeach()

                # После перебора всех строк выбираем финальную версию пакета.
                # Если пользователь выбрал нестандартный путь и он содержит валидное имя
                # папки — используем CustomerFirmwarePackage, иначе оставляем FirmwarePackage.
                if(_use_customer_fw_path AND NOT "${_customer_fw_version}" STREQUAL "")
                    set(_cubefw_package "${_customer_fw_version}")
                    message(STATUS "Используется CustomerFirmwarePackage: семейство=${_customer_fw_family}, версия=${_customer_fw_version}")
                    message(STATUS "  Путь: ${_customer_fw_path}")
                endif()

                # Экспортируем накопленные значения в область вызывающего кода.
                set(${PREFIX}USE_FREERTOS         "${_use_freertos}"         PARENT_SCOPE)
                set(${PREFIX}CMSIS_RTOS_API       "${_cmsis_rtos_api}"       PARENT_SCOPE)
                set(${PREFIX}USE_CUSTOMER_FW_PATH "${_use_customer_fw_path}" PARENT_SCOPE)
                set(${PREFIX}CUSTOMER_FW_FAMILY   "${_customer_fw_family}"   PARENT_SCOPE)
                set(${PREFIX}CUSTOMER_FW_VERSION  "${_customer_fw_version}"  PARENT_SCOPE)
                set(${PREFIX}CUSTOMER_FW_PATH     "${_customer_fw_path}"     PARENT_SCOPE)
                set(${PREFIX}CUBEFW_PACKAGE       "${_cubefw_package}"       PARENT_SCOPE)
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

            elseif(type STREQUAL "BOOLEAN")
                # Явно нормализуем булев тип в стандартные CMake-литералы.
                # string(JSON GET) для булевых возвращает "TRUE"/"FALSE" (верхний регистр),
                # но мы явно проверяем и нормализуем на случай любых edge-cases.
                string(JSON value GET "${JSON_STR}" "${key}")
                string(TOUPPER "${value}" value_upper)
                if(value_upper STREQUAL "TRUE" OR value_upper STREQUAL "ON" OR value_upper STREQUAL "1" OR value_upper STREQUAL "YES")
                    set(${new_prefix} "TRUE" PARENT_SCOPE)
                else()
                    set(${new_prefix} "FALSE" PARENT_SCOPE)
                endif()
                list(APPEND local_vars "${new_prefix}")

            else()
                # БАЗОВЫЕ ТИПЫ (NUMBER, STRING)
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
    # Необязательный второй аргумент — выражение yq, выбирающее часть файла
    # (например, только секцию profiles: внешнего файла профилей, ТЗ 3.4.8).
    set(_yq_expression ".")
    if(ARGC GREATER 1)
        set(_yq_expression "${ARGV1}")
    endif()
    find_program(YQ_EXECUTABLE yq)
    if(NOT YQ_EXECUTABLE)
        message(FATAL_ERROR "Инструмент 'yq' не найден. Пожалуйста, установите его.")
    endif()
    if(NOT EXISTS ${config_file})
        message(FATAL_ERROR "Файл конфигурации не найден: ${config_file}")
    endif()

    execute_process(
        COMMAND ${YQ_EXECUTABLE} -o=json "${_yq_expression}" ${config_file}
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
# Допустимые форматы (ТЗ 4.11.4):
#   - "1536" (целое число байт, в том числе 0)
#   - "2K"   (целое число килобайт, суффикс только в верхнем регистре)
#   - "1M"   (целое число мегабайт, суффикс только в верхнем регистре)
# Иной формат, в том числе дробный ("1.5K") и "1k", — ошибка Configure.
# Результат (целое число байт) помещается в переменную с тем же именем.
#
function(stm32_yml_normalize_memory var_name)
    _stm32_yml_memory_bytes(${var_name} result)
    message(STATUS "Размер памяти '${${var_name}}' нормализован в ${result} байт.")
    set(${var_name} ${result} PARENT_SCOPE)
endfunction()

# Разбирает значение переменной VAR_NAME по формату ТЗ 4.11.4 в OUT_VAR (байты).
function(_stm32_yml_memory_bytes VAR_NAME OUT_VAR)
    set(value_str "${${VAR_NAME}}")
    if(value_str MATCHES "^([0-9]+)M$")
        math(EXPR result "${CMAKE_MATCH_1} * 1024 * 1024")
    elseif(value_str MATCHES "^([0-9]+)K$")
        math(EXPR result "${CMAKE_MATCH_1} * 1024")
    elseif(value_str MATCHES "^[0-9]+$")
        math(EXPR result "${value_str}")
    else()
        message(FATAL_ERROR
            "Недопустимый формат размера памяти '${VAR_NAME}: ${value_str}'. "
            "Укажите целое число байт или целое число с суффиксом K или M "
            "в верхнем регистре, например: 0, 1536, 2K, 1M.")
    endif()
    set(${OUT_VAR} ${result} PARENT_SCOPE)
endfunction()

# ==============================================================================
# Проверяет формат заданных размеров памяти при каждом Configure (ТЗ 4.11.8),
# не изменяя сами значения. Пустое значение не проверяется.
#
# @param ARGN - Имена переменных (heap_size, stack_size).
# ==============================================================================
function(stm32_yml_check_memory_format)
    foreach(_var IN LISTS ARGN)
        if(NOT "${${_var}}" STREQUAL "")
            _stm32_yml_memory_bytes(${_var} _bytes)
        endif()
    endforeach()
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
#      ФУНКЦИЯ НОРМАЛИЗАЦИИ СПИСКА ФЛАГОВ КОМПИЛЯТОРА / ЛИНКЕРА
# ==============================================================================
# Принимает имя переменной, содержащей список флагов, и нормализует его на месте:
#
#   1. Разбивает элементы, содержащие пробелы, на отдельные флаги.
#      "-Wall -Wextra"  ->  "-Wall"  "-Wextra"
#      "fdata-sections ffunction-sections"  ->  "-fdata-sections"  "-ffunction-sections"
#
#   2. Добавляет ведущий дефис к флагам, у которых его нет.
#      "Wall"  ->  "-Wall"
#      "O2"    ->  "-O2"
#
#      Не трогает:
#        - флаги, уже начинающиеся с "-" или "--"
#        - генераторные выражения CMake: $<...>
#        - пустые строки
#        - токен, являющийся значением предыдущего флага (см. пункт 3)
#
#   3. Распознаёт флаги, у которых значение передаётся отдельным токеном,
#      и оставляет это значение без изменений.
#      "--param max-inline-insns-single=500"
#          ->  "--param"  "max-inline-insns-single=500"
#      Без этой проверки значение получило бы ведущий дефис
#      ("-max-inline-insns-single=500") и компилятор отверг бы опцию.
#
# @param LIST_VAR  Имя переменной (список). Результат записывается обратно
#                  в переменную с тем же именем в PARENT_SCOPE.
#
# Поддерживаемые режимы:
#   stm32_yml_normalize_flags(MY_LIST)            — с автодобавлением "-"
#   stm32_yml_normalize_flags(MY_LIST NO_AUTO_DASH) — только разбивка по пробелам
function(stm32_yml_normalize_flags LIST_VAR)
    # Проверяем наличие опционального аргумента NO_AUTO_DASH
    set(_auto_dash TRUE)
    if(ARGC GREATER 1 AND ARGV1 STREQUAL "NO_AUTO_DASH")
        set(_auto_dash FALSE)
    endif()

    # Опции GCC и ld, принимающие значение отдельным токеном.
    # Следующий за такой опцией токен передаётся как есть: он является
    # значением, а не самостоятельным флагом.
    set(_flags_with_arg
        "--param"
        "-include"
        "-imacros"
        "-isystem"
        "-iquote"
        "-idirafter"
        "-x"
        "-Xlinker"
        "-Xpreprocessor"
        "-Xassembler"
        "-u"
        "-T"
        "-MT"
        "-MF"
        "-MQ"
        "-aux-info"
        "-specs"
        "-D"
        "-U"
        "-I"
        "-L")

    set(_input "${${LIST_VAR}}")
    set(_result "")

    # Признак того, что предыдущий обработанный токен ожидает значение.
    # Состояние сохраняется между элементами списка: флаг и его значение
    # могут быть записаны как одной строкой, так и двумя отдельными.
    set(_prev_takes_arg FALSE)

    foreach(_item IN LISTS _input)
        # Шаг 1: разбиваем элемент по пробелам на части.
        string(REPLACE " " ";" _parts "${_item}")

        foreach(_flag IN LISTS _parts)
            # Пропускаем пустые части (двойные пробелы и т.п.).
            if(_flag STREQUAL "")
                continue()
            endif()

            # Шаг 2: значение предыдущей опции переносим без изменений.
            if(_prev_takes_arg)
                list(APPEND _result "${_flag}")
                set(_prev_takes_arg FALSE)
                continue()
            endif()

            # Шаг 3: добавляем дефис если нужно (только в режиме auto_dash).
            # Не трогаем: уже начинается с "-", генераторные выражения "$<...>".
            if(_auto_dash AND NOT _flag MATCHES "^-" AND NOT _flag MATCHES "^\\$<")
                set(_flag "-${_flag}")
            endif()

            # Шаг 4: запоминаем, что следующий токен будет значением опции.
            if(_flag IN_LIST _flags_with_arg)
                set(_prev_takes_arg TRUE)
            endif()

            list(APPEND _result "${_flag}")
        endforeach()
    endforeach()

    set(${LIST_VAR} "${_result}" PARENT_SCOPE)
endfunction()

# ==============================================================================
#      ФУНКЦИЯ ДЛЯ УСТАНОВКИ ЗНАЧЕНИЯ ПО УМОЛЧАНИЮ
# ==============================================================================
# Проверяет, была ли переменная с именем VAR_NAME определена и непуста.
# Если она не определена или пуста, устанавливает для неё значение по умолчанию.
#
# @param VAR_NAME       - Имя переменной, которую нужно проверить.
# @param DEFAULT_VALUE  - Значение, которое нужно установить по умолчанию.
# ==============================================================================
function(stm32_yml_ensure_default_value VAR_NAME DEFAULT_VALUE)
    # Проверяем, что переменная НЕ определена ИЛИ она определена, но является пустой строкой.
    # Это надежный способ покрыть оба случая: отсутствие ключа в YAML и ключ с пустым значением.
    if(NOT DEFINED ${VAR_NAME} OR "${${VAR_NAME}}" STREQUAL "")
        set(${VAR_NAME} "${DEFAULT_VALUE}" PARENT_SCOPE)
        message(STATUS "Параметр '${VAR_NAME}' не был задан или был пуст. Установлено значение по умолчанию: '${DEFAULT_VALUE}'.")
    endif()
endfunction()

# ==============================================================================
# Проверяет значение перечислимого параметра (ТЗ 3.7).
# Пустое значение не проверяется (ТЗ 3.7.4). Неизвестное непустое значение даёт
# предупреждение с именем параметра, заданным и фактически применяемым значением
# и заменяется на FALLBACK (ТЗ 3.7.1, 3.7.2); Configure продолжается.
# Пустой FALLBACK означает, что значение не используется (system_library).
#
# @param VAR_NAME  - Имя параметра.
# @param FALLBACK  - Значение, применяемое вместо неизвестного.
# @param ARGN      - Известные значения.
# ==============================================================================
function(stm32_yml_check_enum_value VAR_NAME FALLBACK)
    set(_value "${${VAR_NAME}}")
    if("${_value}" STREQUAL "" OR "${_value}" IN_LIST ARGN)
        return()
    endif()
    string(REPLACE ";" ", " _known "${ARGN}")
    if("${FALLBACK}" STREQUAL "")
        set(_applied "значение не используется")
    else()
        set(_applied "применяется '${FALLBACK}'")
    endif()
    message(WARNING "Неизвестное значение '${_value}' параметра '${VAR_NAME}'. "
                    "Известные значения: ${_known}. ${_applied}.")
    set(${VAR_NAME} "${FALLBACK}" PARENT_SCOPE)
endfunction()

# ==============================================================================
# Проверяет элементы перечислимого списка (ТЗ 3.7): неизвестный элемент даёт
# предупреждение и удаляется из списка; Configure продолжается.
#
# @param VAR_NAME  - Имя параметра-списка.
# @param ARGN      - Известные значения элементов.
# ==============================================================================
function(stm32_yml_check_enum_list VAR_NAME)
    set(_result "")
    string(REPLACE ";" ", " _known "${ARGN}")
    foreach(_item IN LISTS ${VAR_NAME})
        if("${_item}" IN_LIST ARGN)
            list(APPEND _result "${_item}")
        else()
            message(WARNING "Неизвестный элемент '${_item}' параметра '${VAR_NAME}'. "
                            "Известные значения: ${_known}. Элемент пропускается.")
        endif()
    endforeach()
    set(${VAR_NAME} "${_result}" PARENT_SCOPE)
endfunction()

# ==============================================================================
#      ФОЛБЕК-ОПРЕДЕЛЕНИЕ ЦЕЛИ STM32::Semihosting
# ==============================================================================
# Оба штатных toolchain-файла (stm32_gcc.cmake из stm32-cmake и кастомный
# gcc-arm-none-eabi.cmake) уже определяют эту цель. Определение здесь —
# страховка для проектов с собственным toolchain, где её может не быть.
# Проверка if(NOT TARGET) гарантирует отсутствие конфликта.
# ==============================================================================
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

# ==============================================================================
# Определяет ядро MCU по списку stm32-cmake (ТЗ 4.7.8) и записывает его в
# mcu_core вызывающей области:
#   нет ядер       — mcu_core должен быть пуст;
#   одно ядро      — используется оно, если mcu_core не задан;
#   несколько ядер — mcu_core обязателен.
# mcu_core вне списка — ошибка Configure со списком допустимых значений.
# ==============================================================================
function(stm32_yml_resolve_mcu_core)
    stm32_get_cores(_cores CHIP ${MCU})
    string(REPLACE ";" ", " _cores_text "${_cores}")
    if(NOT _cores)
        if(NOT "${mcu_core}" STREQUAL "")
            message(FATAL_ERROR
                "mcu_core: '${mcu_core}' недопустим для ${MCU}: stm32-cmake не выделяет ядра "
                "для этого MCU. Удалите mcu_core из конфигурации.")
        endif()
        return()
    endif()
    if("${mcu_core}" STREQUAL "")
        list(LENGTH _cores _count)
        if(_count GREATER 1)
            message(FATAL_ERROR
                "У ${MCU} несколько ядер (${_cores_text}): укажите mcu_core, "
                "например 'mcu_core: ${_cores}'.")
        endif()
        message(STATUS "Ядро MCU не задано, используется единственное ядро ${MCU}: ${_cores}.")
        set(mcu_core "${_cores}" PARENT_SCOPE)
    elseif(NOT "${mcu_core}" IN_LIST _cores)
        message(FATAL_ERROR
            "mcu_core: '${mcu_core}' недопустим для ${MCU}. Допустимые значения: ${_cores_text}.")
    else()
        message(STATUS "Ядро MCU: ${mcu_core}")
    endif()
endfunction()

# ==============================================================================
# Размер области памяти MCU в байтах по stm32_get_memory_info с учётом ядра
# (ТЗ 4.7.8). KIND: RAM, CCRAM, RAM_SHARE, FLASH. Неизвестный размер — 0.
#
# @param KIND       - Область памяти.
# @param OUT_BYTES  - Переменная для размера в байтах.
# @param ARGV2      - Необязательная переменная для исходной строки stm32-cmake.
# ==============================================================================
function(stm32_yml_mcu_memory_size KIND OUT_BYTES)
    set(_core_args "")
    if(NOT "${mcu_core}" STREQUAL "")
        set(_core_args CORE ${mcu_core})
    endif()
    stm32_get_memory_info(CHIP ${MCU} ${_core_args} ${KIND} SIZE _size)
    if("${_size}" STREQUAL "" OR _size MATCHES "NOTFOUND")
        set(_bytes 0)
    else()
        # Строки вида "64K", "1M", "0x400" или "64K-4" (WB) приводятся к выражению.
        string(TOUPPER "${_size}" _expr)
        string(REGEX REPLACE "([0-9]+)K" "(\\1*1024)" _expr "${_expr}")
        string(REGEX REPLACE "([0-9]+)M" "(\\1*1048576)" _expr "${_expr}")
        string(REPLACE "0X" "0x" _expr "${_expr}")
        math(EXPR _bytes "${_expr}")
    endif()
    set(${OUT_BYTES} ${_bytes} PARENT_SCOPE)
    if(ARGC GREATER 2)
        set(${ARGV2} "${_size}" PARENT_SCOPE)
    endif()
endfunction()

# ==============================================================================
# Регион FLASH итогового скрипта компоновщика (ТЗ 4.15.9, 4.14.2): из шаблона
# или явного скрипта (LINKER_SCRIPT_PATH), а для скрипта stm32-cmake — по
# stm32_get_memory_info с учётом ядра. Если регион не определить, OUT_ORIGIN пуст.
#
# @param OUT_ORIGIN  - Переменная для начального адреса (как в скрипте, 0x...).
# @param OUT_LENGTH  - Переменная для длины в байтах.
# ==============================================================================
function(stm32_yml_flash_region OUT_ORIGIN OUT_LENGTH)
    set(${OUT_ORIGIN} "" PARENT_SCOPE)
    set(${OUT_LENGTH} "" PARENT_SCOPE)
    if(LINKER_SCRIPT_PATH AND EXISTS "${LINKER_SCRIPT_PATH}")
        file(READ "${LINKER_SCRIPT_PATH}" _ld_text)
        set(_flash_re "(^|\n)[ \t]*FLASH[ \t]*(\\([^)]*\\))?[ \t]*:[ \t]*ORIGIN[ \t]*=[ \t]*(0[xX][0-9A-Fa-f]+|[0-9]+)[ \t]*,[ \t]*LENGTH[ \t]*=[ \t]*(0[xX][0-9A-Fa-f]+|[0-9]+[KkMm]?)")
        if(NOT _ld_text MATCHES "${_flash_re}")
            return()
        endif()
        set(_origin "${CMAKE_MATCH_3}")
        string(TOUPPER "${CMAKE_MATCH_4}" _length)
    elseif(NOT toolchain_backend STREQUAL "arduino" AND use_cmsis)
        # Скрипт формирует stm32-cmake по той же базе памяти.
        set(_core_args "")
        if(NOT "${mcu_core}" STREQUAL "")
            set(_core_args CORE ${mcu_core})
        endif()
        stm32_get_memory_info(CHIP ${MCU} ${_core_args} FLASH SIZE _length ORIGIN _origin)
        string(TOUPPER "${_length}" _length)
    else()
        return()
    endif()
    if(_length MATCHES "^0X")
        math(EXPR _bytes "${_length}")
    elseif(_length MATCHES "^([0-9]+)K$")
        math(EXPR _bytes "${CMAKE_MATCH_1} * 1024")
    elseif(_length MATCHES "^([0-9]+)M$")
        math(EXPR _bytes "${CMAKE_MATCH_1} * 1024 * 1024")
    else()
        set(_bytes "${_length}")
    endif()
    set(${OUT_ORIGIN} "${_origin}" PARENT_SCOPE)
    set(${OUT_LENGTH} "${_bytes}" PARENT_SCOPE)
endfunction()

# ==============================================================================
# BIN-артефакт только из секций ELF с адресом загрузки в регионе FLASH
# (ТЗ 4.14.2, 4.15.9). objcopy -O binary заполнил бы промежуток до секции вне
# Flash (резервная SRAM, ITCM без AT> FLASH) и дал бы файл в сотни мегабайт.
# Для обычного ELF результат побайтно совпадает с objcopy -O binary. Команда
# добавляется после внедрения CRC, поэтому BIN содержит записанную CRC.
# Имя файла — как у функций stm32-cmake: OUTPUT_NAME цели или её имя.
# Если регион FLASH или Python недоступны — функция toolchain с предупреждением.
# ==============================================================================
function(stm32_yml_generate_bin_file TARGET)
    get_target_property(_output_name ${TARGET} OUTPUT_NAME)
    if(NOT _output_name)
        set(_output_name "${TARGET}")
    endif()
    get_target_property(_output_dir ${TARGET} RUNTIME_OUTPUT_DIRECTORY)
    if(_output_dir)
        set(_bin "${_output_dir}/${_output_name}.bin")
    else()
        set(_bin "${_output_name}.bin")
    endif()

    stm32_yml_flash_region(_flash_origin _flash_length)
    find_package(Python3 COMPONENTS Interpreter QUIET)
    set(_script "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../scripts/stm32_crc.py")
    if("${_flash_origin}" STREQUAL "" OR NOT Python3_FOUND OR NOT EXISTS "${_script}")
        message(WARNING
            "bin: не удалось определить регион FLASH скрипта компоновщика или найти Python3; "
            "BIN создаётся objcopy -O binary и может оказаться большим, если в ELF есть "
            "секции вне Flash.")
        stm32_generate_binary_file(${TARGET})
        return()
    endif()

    add_custom_command(TARGET ${TARGET} POST_BUILD
        COMMAND ${Python3_EXECUTABLE} ${_script}
                --elf $<TARGET_FILE:${TARGET}>
                --flash ${_flash_origin}:${_flash_length}
                --image ${_bin}
        BYPRODUCTS ${_bin}
        COMMENT "Generating binary file ${_output_name}.bin from FLASH sections of the ELF output file."
        VERBATIM
    )
endfunction()
