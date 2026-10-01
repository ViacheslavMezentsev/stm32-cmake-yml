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
        stm32_yml_msg(E201 "${IOC_FILE_PATH}")
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
                    stm32_yml_msg(I202 "${_customer_fw_family}" "${_customer_fw_version}")
                    stm32_yml_msg(I203 "${_customer_fw_path}")
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
# Требования: CMake >= 3.21, 'yq' должен быть установлен и доступен в PATH.
#
function(stm32_yml_parse_config config_file)
    _stm32_yml_input_format("${config_file}" _input_format)
    # Необязательный второй аргумент — выражение yq, выбирающее часть файла
    # (например, только секцию profiles: внешнего файла профилей, ТЗ 3.4.8).
    set(_yq_expression ".")
    if(ARGC GREATER 1)
        set(_yq_expression "${ARGV1}")
    endif()
    find_program(YQ_EXECUTABLE yq)
    if(NOT YQ_EXECUTABLE)
        stm32_yml_msg(E003)
    endif()
    if(NOT EXISTS ${config_file})
        stm32_yml_msg(E004 "${config_file}")
    endif()

    if(ARGC GREATER 1)
        # profiles_file remains a separate source: only profiles are read;
        # its other keys (including include) must not affect the base config.
        execute_process(
            COMMAND "${YQ_EXECUTABLE}" "-p=${_input_format}" -o=json "${_yq_expression}" "${config_file}"
            OUTPUT_VARIABLE YAML_AS_JSON
            RESULT_VARIABLE YQ_RESULT
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
        if(NOT YQ_RESULT EQUAL 0)
            stm32_yml_msg(E005 "${config_file}")
        endif()

        stm32_yml_msg(I035 "${config_file}")
    else()
        _stm32_yml_load_includes("${config_file}" "{}" "" YAML_AS_JSON)
        set(_STM32_YML_MERGED_JSON "${YAML_AS_JSON}" PARENT_SCOPE)
    endif()

    # Запускаем рекурсивный парсинг с корня
    _stm32_yml_parse_json_node("${YAML_AS_JSON}" "" PARSED_VARS)

    # Пробрасываем все найденные переменные в PARENT_SCOPE
    foreach(var IN LISTS PARSED_VARS)
        set(${var} "${${var}}" PARENT_SCOPE)
    endforeach()

    # СОХРАНЯЕМ СПИСОК ПЕРЕМЕННЫХ, чтобы следующий модуль мог пробросить их дальше
    set(YAML_PARSED_KEYS "${PARSED_VARS}" PARENT_SCOPE)

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
    stm32_yml_msg(I036 "${${var_name}}" "${result}")
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
        stm32_yml_msg(E006 "${VAR_NAME}" "${value_str}")
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
        stm32_yml_msg(E401 "${CUBE_REPO_PATH}")
    endif()

    # Ищем все папки, подходящие под наш шаблон семейства
    file(GLOB FW_DIRS LIST_DIRECTORIES true "${CUBE_REPO_PATH}/STM32Cube_FW_${MCU_FAMILY}_V*")

    if(NOT FW_DIRS)
        stm32_yml_msg(E402 "${MCU_FAMILY}" "${CUBE_REPO_PATH}")
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
        stm32_yml_msg(E403 "${MCU_FAMILY}")
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
        stm32_yml_msg(I037 "${VAR_NAME}" "${DEFAULT_VALUE}")
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
        stm32_yml_msg(W006 "${_value}" "${VAR_NAME}" "${_known}")
    else()
        stm32_yml_msg(W005 "${_value}" "${VAR_NAME}" "${_known}" "${FALLBACK}")
    endif()
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
            stm32_yml_msg(W007 "${_item}" "${VAR_NAME}" "${_known}")
        endif()
    endforeach()
    set(${VAR_NAME} "${_result}" PARENT_SCOPE)
endfunction()

# ==============================================================================
#      ФОЛБЕК-ОПРЕДЕЛЕНИЕ ЦЕЛИ STM32::Semihosting
# ==============================================================================
# stm32-cmake (stm32/common.cmake) определяет STM32::NoSys, STM32::Nano,
# STM32::Nano::FloatPrint и STM32::Nano::FloatScan, но не STM32::Semihosting.
# Поэтому для system_library: Semihosting цель определяет фреймворк
# (ТЗ 4.10.2); toolchain проекта может определить её раньше — тогда
# проверка if(NOT TARGET) оставляет его определение.
# ==============================================================================
if(NOT (TARGET STM32::Semihosting))
    add_library(STM32::Semihosting INTERFACE IMPORTED)
    target_link_options(STM32::Semihosting INTERFACE -lrdimon $<$<C_COMPILER_ID:GNU>:--specs=rdimon.specs>)
endif()

# ==============================================================================
# Листинг objdump -h -S (ТЗ 4.14.2); путь по ТЗ 4.14.4.
# ==============================================================================
function(stm32_yml_generate_lss_file TARGET)
    stm32_yml_artifact_path(${TARGET} lss _lss)
    add_custom_command(
        TARGET ${TARGET}
        POST_BUILD
        COMMAND ${CMAKE_OBJDUMP} -h -S "$<TARGET_FILE:${TARGET}>" > "${_lss}"
        COMMENT "Generating extended listing file ${TARGET}.lss from ELF output file."
    )
endfunction()

# ==============================================================================
# Путь артефакта: <итоговое имя ELF без расширения>.<EXT> в каталоге ELF
# (ТЗ 4.14.4). Выражения генератора учитывают OUTPUT_NAME, OUTPUT_NAME_<CONFIG>,
# <CONFIG>_POSTFIX, RUNTIME_OUTPUT_DIRECTORY и конфигурацию многоконфигурационного
# генератора, в том числе заданные после вызова фреймворка. Артефакт
# регистрируется для объявления BYPRODUCTS в конце каталога цели.
# ==============================================================================
function(stm32_yml_artifact_path TARGET EXT OUT_VAR)
    set(${OUT_VAR} "$<TARGET_FILE_DIR:${TARGET}>/$<TARGET_FILE_BASE_NAME:${TARGET}>.${EXT}" PARENT_SCOPE)
    get_property(_registered TARGET ${TARGET} PROPERTY _STM32_YML_ARTIFACTS)
    if(EXT IN_LIST _registered)
        return()
    endif()
    set_property(TARGET ${TARGET} APPEND PROPERTY _STM32_YML_ARTIFACTS ${EXT})
    if(NOT _registered)
        # Аргументы DEFER CALL вычисляются при вызове, поэтому имя цели
        # подставляется сейчас через EVAL.
        cmake_language(EVAL CODE
            "cmake_language(DEFER CALL _stm32_yml_declare_artifacts [[${TARGET}]])")
    endif()
endfunction()

# ==============================================================================
# BYPRODUCTS артефактов цели (ТЗ 4.14.4). Выражения генератора, зависящие от
# цели, CMake в BYPRODUCTS не допускает, поэтому пути вычисляются по итоговым
# свойствам цели в конце её каталога и объявляются пустой командой POST_BUILD.
# Свойство со значением-выражением генератора — побочные файлы не объявляются:
# команды артефактов от этого не зависят.
# ==============================================================================
function(_stm32_yml_declare_artifacts TARGET)
    get_property(_extensions TARGET ${TARGET} PROPERTY _STM32_YML_ARTIFACTS)
    get_target_property(_binary_dir ${TARGET} BINARY_DIR)
    get_property(_multi GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
    if(_multi)
        set(_configs ${CMAKE_CONFIGURATION_TYPES})
    else()
        set(_configs "${CMAKE_BUILD_TYPE}")
    endif()
    set(_byproducts "")
    foreach(_config IN LISTS _configs)
        string(TOUPPER "${_config}" _upper)
        set(_dir "")
        set(_name "")
        set(_postfix "")
        if(NOT _upper STREQUAL "")
            get_target_property(_dir ${TARGET} RUNTIME_OUTPUT_DIRECTORY_${_upper})
            get_target_property(_name ${TARGET} OUTPUT_NAME_${_upper})
            get_target_property(_postfix ${TARGET} ${_upper}_POSTFIX)
        endif()
        if(NOT _dir)
            get_target_property(_dir ${TARGET} RUNTIME_OUTPUT_DIRECTORY)
            if(NOT _dir)
                set(_dir "${_binary_dir}")
            endif()
            if(_multi)
                string(APPEND _dir "/${_config}")
            endif()
        endif()
        if(NOT _name)
            get_target_property(_name ${TARGET} OUTPUT_NAME)
            if(NOT _name)
                set(_name "${TARGET}")
            endif()
        endif()
        if(NOT _postfix)
            set(_postfix "")
        endif()
        if("${_dir}${_name}${_postfix}" MATCHES "\\$<")
            return()
        endif()
        get_filename_component(_dir "${_dir}" ABSOLUTE BASE_DIR "${_binary_dir}")
        foreach(_extension IN LISTS _extensions)
            set(_path "${_dir}/${_name}${_postfix}.${_extension}")
            if(_multi)
                set(_path "$<$<CONFIG:${_config}>:${_path}>")
            endif()
            list(APPEND _byproducts "${_path}")
        endforeach()
    endforeach()
    add_custom_command(TARGET ${TARGET} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E true
        BYPRODUCTS ${_byproducts}
        VERBATIM
    )
endfunction()

# ==============================================================================
# hex, srec и резервный bin строит фреймворк командой objcopy из ELF после
# внедрения CRC (ТЗ 4.14.2); функции stm32_generate_* toolchain не используются
# (ТЗ 5.2.1, 5.2.2).
#
# @param TARGET  - Исполняемая цель.
# @param EXT     - Расширение файла (hex, srec, bin).
# @param FORMAT  - Формат objcopy (ihex, srec, binary).
# ==============================================================================
function(stm32_yml_generate_objcopy_file TARGET EXT FORMAT)
    stm32_yml_artifact_path(${TARGET} ${EXT} _output)
    add_custom_command(TARGET ${TARGET} POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O ${FORMAT} "$<TARGET_FILE:${TARGET}>" "${_output}"
        COMMENT "Generating ${EXT} file ${TARGET}.${EXT} from ELF output file."
        VERBATIM
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
            stm32_yml_msg(E007 "${mcu_core}" "${MCU}")
        endif()
        return()
    endif()
    if("${mcu_core}" STREQUAL "")
        list(LENGTH _cores _count)
        if(_count GREATER 1)
            list(GET _cores 0 _first_core)
            stm32_yml_msg(E008 "${MCU}" "${_cores_text}" "${_first_core}")
        endif()
        stm32_yml_msg(I038 "${MCU}" "${_cores}")
        set(mcu_core "${_cores}" PARENT_SCOPE)
    elseif(NOT "${mcu_core}" IN_LIST _cores)
        stm32_yml_msg(E009 "${mcu_core}" "${MCU}" "${_cores_text}")
    else()
        stm32_yml_msg(I039 "${mcu_core}")
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
    get_property(_variant_script GLOBAL PROPERTY _STM32_YML_ARDUINO_VARIANT_SCRIPT)
    get_property(_variant_size GLOBAL PROPERTY _STM32_YML_ARDUINO_FLASH_SIZE)
    if(LINKER_SCRIPT_PATH AND "${LINKER_SCRIPT_PATH}" STREQUAL "${_variant_script}"
            AND NOT "${_variant_size}" STREQUAL "")
        # Скрипт variant Arduino (режим native, ТЗ 4.9.11): FLASH задан через
        # LD_FLASH_OFFSET и LD_MAX_SIZE; длина — размер Flash платы из базы плат.
        file(READ "${LINKER_SCRIPT_PATH}" _ld_text)
        if(_ld_text MATCHES "FLASH[ \t]*\\([^)]*\\)[ \t]*:[ \t]*ORIGIN[ \t]*=[ \t]*(0[xX][0-9A-Fa-f]+)")
            set(${OUT_ORIGIN} "${CMAKE_MATCH_1}" PARENT_SCOPE)
            set(${OUT_LENGTH} "${_variant_size}" PARENT_SCOPE)
        endif()
        return()
    elseif(LINKER_SCRIPT_PATH AND EXISTS "${LINKER_SCRIPT_PATH}")
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
# Путь файла — по ТЗ 4.14.4. Если регион FLASH или Python недоступны —
# objcopy -O binary с предупреждением.
# ==============================================================================
function(stm32_yml_generate_bin_file TARGET)
    stm32_yml_artifact_path(${TARGET} bin _bin)
    stm32_yml_flash_region(_flash_origin _flash_length)
    find_package(Python3 COMPONENTS Interpreter QUIET)
    set(_script "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../scripts/stm32_crc.py")
    if("${_flash_origin}" STREQUAL "" OR NOT Python3_FOUND OR NOT EXISTS "${_script}")
        stm32_yml_msg(W701)
        stm32_yml_generate_objcopy_file(${TARGET} bin binary)
        return()
    endif()

    get_property(_build_messages GLOBAL PROPERTY _STM32_YML_BUILD_MESSAGES)
    add_custom_command(TARGET ${TARGET} POST_BUILD
        COMMAND ${Python3_EXECUTABLE} ${_script}
                --messages ${_build_messages}
                --elf $<TARGET_FILE:${TARGET}>
                --flash ${_flash_origin}:${_flash_length}
                --image ${_bin}
        COMMENT "Generating binary file ${TARGET}.bin from FLASH sections of the ELF output file."
        VERBATIM
    )
endfunction()
