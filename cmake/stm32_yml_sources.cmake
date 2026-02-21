# ==============================================================================
# Модуль: ОПРЕДЕЛЕНИЕ ИСХОДНЫХ ФАЙЛОВ
# ==============================================================================
# Перебирает список 'sources' из конфигурации.
# - Директории подключаются через add_subdirectory.
# - Обычные файлы добавляются напрямую к цели.
# - Системные и startup-файлы перехватываются для переопределения в CMSIS.
# ==============================================================================

function(stm32_yml_setup_sources TARGET_NAME)
    set(LOCAL_PROJECT_SOURCES "")

    # Конструируем имена файлов, которые мы будем искать
    string(TOLOWER ${MCU_FAMILY} MCU_FAMILY_LOWER)
    string(TOLOWER ${MCU_TYPE} MCU_TYPE_LOWER)

    set(SYSTEM_FILENAME_TARGET "system_stm32${MCU_FAMILY_LOWER}xx.c")
    set(STARTUP_FILENAME_PATTERN "startup_stm32${MCU_TYPE_LOWER}.*\\.s")

    # Перебираем список 'sources' из YAML-конфига
    foreach(src_item IN LISTS sources)
        set(full_path "${CMAKE_CURRENT_SOURCE_DIR}/${src_item}")
        get_filename_component(filename ${src_item} NAME)
        string(TOLOWER ${filename} filename_lower)

        set(is_special_file FALSE)

        # Проверка на особые системные файлы (только если HAL/CMSIS включены)
        if(use_hal OR use_cmsis)
            if(filename_lower STREQUAL SYSTEM_FILENAME_TARGET)
                if(mcu_core)
                    set(CMSIS_${MCU_FAMILY}_${mcu_core}_SYSTEM ${full_path} PARENT_SCOPE)
                else()
                    set(CMSIS_${MCU_FAMILY}_SYSTEM ${full_path} PARENT_SCOPE)
                endif()
                message(STATUS "Обнаружен пользовательский system-файл. Переопределение: ${full_path}")
                set(is_special_file TRUE)

            elseif(filename_lower MATCHES ${STARTUP_FILENAME_PATTERN})
                if(mcu_core)
                    set(CMSIS_${MCU_FAMILY}_${mcu_core}_${MCU_TYPE}_STARTUP ${full_path} PARENT_SCOPE)
                else()
                    set(CMSIS_${MCU_FAMILY}_${MCU_TYPE}_STARTUP ${full_path} PARENT_SCOPE)
                endif()
                message(STATUS "Обнаружен пользовательский startup-файл. Переопределение: ${full_path}")
                set(is_special_file TRUE)
            endif()
        endif()

        # Стандартная обработка остальных файлов
        if(NOT is_special_file)
            if(IS_DIRECTORY ${full_path})
                # Подключение директории как модуля (CMakeLists.txt внутри обязателен)
                add_subdirectory(${src_item})
            elseif(EXISTS ${full_path})
                # Добавление одиночного файла
                list(APPEND LOCAL_PROJECT_SOURCES ${full_path})
            else()
                message(WARNING "Источник '${src_item}' не найден и будет проигнорирован.")
            endif()
        endif()
    endforeach()

    # Привязываем собранные файлы к нашей цели
    if(LOCAL_PROJECT_SOURCES)
        target_sources(${TARGET_NAME} PRIVATE ${LOCAL_PROJECT_SOURCES})
    endif()

endfunction()
