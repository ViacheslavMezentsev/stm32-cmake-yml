# ==============================================================================
# Модуль: ПРОФИЛИ СБОРКИ И ТОЧЕЧНЫЕ CMAKE-OVERRIDES.
# ==============================================================================
# Реализует два уровня внешней конфигурируемости поверх stm32_config.yml:
#
#   Уровень 1 — именованный профиль (-DSTM32_YML_PROFILE=<name>):
#     Профиль — это именованный блок параметров внутри секции `profiles:`
#     в stm32_config.yml (или во внешнем файле, заданном через `profiles_file:`).
#     Параметры профиля перекрывают одноимённые базовые параметры из YAML.
#     Для списков (compile_definitions, compile_options, sources,
#     include_directories) действуют две семантики:
#       - Ключ без суффикса    → профиль ЗАМЕНЯЕТ базовый список.
#       - Ключ с суффиксом _append → профиль ДОПОЛНЯЕТ базовый список.
#     Обе семантики можно комбинировать в одном профиле.
#
#   Уровень 2 — точечные overrides (-DSTM32_YML_OVERRIDE_<param>=<value>):
#     Применяются поверх профиля. Предназначены для отладки одного параметра
#     без правки yml-файла. Поддерживают только скалярные значения.
#
# Порядок приоритетов (от низшего к высшему):
#   значения по умолчанию фреймворка
#   → ioc_file
#   → базовые значения stm32_config.yml
#   → профиль (STM32_YML_PROFILE)
#   → точечные overrides (STM32_YML_OVERRIDE_*)
#
# Пример использования в CI:
#   cmake -DSTM32_YML_PROFILE=G431
#   cmake -DSTM32_YML_PROFILE=G474
#   cmake -DSTM32_YML_PROFILE=G474 -DSTM32_YML_OVERRIDE_heap_size=8K
#
# Пример stm32_config.yml:
#
#   profiles:
#     G431:
#       mcu: STM32G431CBUx
#       linker_script: resources/STM32G431XX_FLASH.ld
#       compile_definitions:
#         - STM32G431xx
#         - ARDUINO_GENERIC_G431CBUX
#       compile_definitions_append:
#         - BOARD_REV=1
#     G474:
#       mcu: STM32G474CETx
#       linker_script: resources/STM32G474XX_FLASH.ld
#       compile_definitions:
#         - STM32G474xx
#         - ARDUINO_GENERIC_G474CEUX
#       compile_definitions_append:
#         - BOARD_REV=2
#
# Внешний файл профилей (опционально):
#   profiles_file: "profiles.yml"
#   — позволяет вынести профили в отдельный файл при их разрастании.
# ==============================================================================

# Список параметров, поддерживающих семантику _append для списков.
set(_STM32_YML_LIST_PARAMS
    compile_definitions
    compile_options
    compile_options_c
    compile_options_cxx
    compile_definitions_c
    compile_definitions_cxx
    sources
    include_directories
    hal_components
    freertos_components
    linker_directives
    link_options
    link_libraries
    custom_libraries
    build_artifacts
    cppcheck_ignores
    cppcheck_args
)

# ==============================================================================
# @brief Применяет именованный профиль и точечные cmake-overrides к текущим
#        переменным конфигурации.
#
# Вызывается из stm32_yml_prepare_project_data() после парсинга YAML,
# до ioc-логики и stm32_yml_ensure_default_value().
#
# Читает:
#   STM32_YML_PROFILE        — имя профиля (cmake cache, опционально).
#   STM32_YML_OVERRIDE_*     — точечные overrides (cmake cache, опционально).
#   profiles                 — список ключей верхнего уровня секции profiles
#                              (заполняется парсером YAML через YAML_PARSED_KEYS).
#   profiles_file            — путь к внешнему yml-файлу с профилями (опционально).
#
# @param CONFIG_FILE_PATH  Путь к основному stm32_config.yml (для сообщений).
# ==============================================================================
function(stm32_yml_apply_profile CONFIG_FILE_PATH)

    # ------------------------------------------------------------------
    # Шаг 0: определяем источник профилей.
    # По умолчанию профили берутся из основного конфига (уже распарсен).
    # Если задан profiles_file — парсим его поверх.
    # ------------------------------------------------------------------
    if(DEFINED profiles_file AND NOT "${profiles_file}" STREQUAL "")
        set(_profiles_src_path "${CMAKE_SOURCE_DIR}/${profiles_file}")
        if(EXISTS "${_profiles_src_path}")
            message(STATUS "Загрузка профилей из внешнего файла: ${_profiles_src_path}")
            stm32_yml_parse_config("${_profiles_src_path}")
        else()
            message(WARNING "Файл профилей не найден: ${_profiles_src_path}")
        endif()
    endif()

    # ------------------------------------------------------------------
    # Шаг 1: применяем именованный профиль.
    # ------------------------------------------------------------------
    set(STM32_YML_PROFILE "" CACHE STRING "Имя профиля сборки из секции profiles: в stm32_config.yml.")

    if(NOT "${STM32_YML_PROFILE}" STREQUAL "")
        message(STATUS "Применение профиля сборки: '${STM32_YML_PROFILE}'")

        # Проверяем, что такой профиль существует в распарсенных переменных.
        # Парсер создаёт переменные вида profiles_<name>_<param>.
        set(_pfx "profiles_${STM32_YML_PROFILE}")

        # Получаем список всех ключей профиля из YAML_PARSED_KEYS.
        set(_profile_keys "")
        if(DEFINED YAML_PARSED_KEYS)
            foreach(_k IN LISTS YAML_PARSED_KEYS)
                if(_k MATCHES "^${_pfx}_(.+)$")
                    list(APPEND _profile_keys "${CMAKE_MATCH_1}")
                endif()
            endforeach()
        endif()

        if(NOT _profile_keys)
            message(WARNING
                "Профиль '${STM32_YML_PROFILE}' не найден в конфигурации. "
                "Доступные профили можно посмотреть в секции 'profiles:' файла ${CONFIG_FILE_PATH}.")
        else()
            foreach(_key IN LISTS _profile_keys)
                # Пропускаем ключи с суффиксом _append — обработаем их отдельно.
                if(_key MATCHES "_append$")
                    continue()
                endif()

                set(_pval "${${_pfx}_${_key}}")

                # Семантика ЗАМЕНЫ: профиль перекрывает базовое значение.
                set(${_key} "${_pval}" PARENT_SCOPE)
                message(STATUS "  [профиль] ${_key} = ${_pval}")
            endforeach()

            # Семантика ДОПОЛНЕНИЯ: _append добавляет к уже установленному значению.
            foreach(_key IN LISTS _profile_keys)
                if(NOT _key MATCHES "_append$")
                    continue()
                endif()

                # Убираем суффикс _append, чтобы получить имя базового параметра.
                string(REGEX REPLACE "_append$" "" _base_key "${_key}")
                set(_append_val "${${_pfx}_${_key}}")
                set(_base_val "${${_base_key}}")

                # Объединяем: сначала базовый список, затем дополнение из профиля.
                list(APPEND _base_val ${_append_val})
                set(${_base_key} "${_base_val}" PARENT_SCOPE)
                message(STATUS "  [профиль +] ${_base_key} += ${_append_val}")
            endforeach()
        endif()
    endif()

    # ------------------------------------------------------------------
    # Шаг 2: применяем точечные cmake-overrides поверх профиля.
    # Сканируем все cmake CACHE-переменные с префиксом STM32_YML_OVERRIDE_.
    # ------------------------------------------------------------------
    get_cmake_property(_all_vars CACHE_VARIABLES)
    set(_overrides_applied 0)

    foreach(_var IN LISTS _all_vars)
        if(_var MATCHES "^STM32_YML_OVERRIDE_(.+)$")
            set(_param_name "${CMAKE_MATCH_1}")
            set(_param_val  "${${_var}}")

            if(NOT "${_param_val}" STREQUAL "")
                set(${_param_name} "${_param_val}" PARENT_SCOPE)
                message(STATUS "  [override] ${_param_name} = ${_param_val}")
                math(EXPR _overrides_applied "${_overrides_applied} + 1")
            endif()
        endif()
    endforeach()

    if(_overrides_applied GREATER 0)
        message(STATUS "Применено точечных cmake-overrides: ${_overrides_applied}.")
    endif()

endfunction()

# ==============================================================================
# @brief Выводит список доступных профилей из распарсенной конфигурации.
#        Вызывается при передаче -DSTM32_YML_PROFILE=list.
# ==============================================================================
function(stm32_yml_list_profiles)
    set(_found_profiles "")

    if(DEFINED YAML_PARSED_KEYS)
        foreach(_k IN LISTS YAML_PARSED_KEYS)
            if(_k MATCHES "^profiles_([^_]+)_mcu$")
                list(APPEND _found_profiles "${CMAKE_MATCH_1}")
            endif()
        endforeach()
    endif()

    if(_found_profiles)
        message(STATUS "Доступные профили сборки:")
        foreach(_p IN LISTS _found_profiles)
            message(STATUS "  - ${_p}")
        endforeach()
    else()
        message(STATUS "Профили сборки не определены в конфигурации.")
    endif()
endfunction()