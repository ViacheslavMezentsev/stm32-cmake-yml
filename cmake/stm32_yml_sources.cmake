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

    # Конструируем имена системных файлов для их перехвата (только при stm32-cmake backend).
    # При Arduino backend MCU_FAMILY и MCU_TYPE не определены — stm32_get_chip_info
    # не вызывается. Системный и startup файлы при Arduino backend компилируются
    # внутри Arduino/Core и не требуют перехвата.
    if(NOT toolchain_backend STREQUAL "arduino")
        string(TOLOWER ${MCU_FAMILY} MCU_FAMILY_LOWER)
        string(TOLOWER ${MCU_TYPE} MCU_TYPE_LOWER)
        set(SYSTEM_FILENAME_TARGET "system_stm32${MCU_FAMILY_LOWER}xx.c")
        set(STARTUP_FILENAME_PATTERN "startup_stm32${MCU_TYPE_LOWER}.*\\.s")
    endif()

    # Перебираем список 'sources' из YAML-конфига.
    foreach(src_item IN LISTS sources)
        # ТЗ 4.6.1, TC-95: то же разрешение путей, что при планировании каталогов.
        get_filename_component(full_path "${src_item}" ABSOLUTE BASE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
        get_filename_component(filename "${full_path}" NAME)
        string(TOLOWER "${filename}" filename_lower)

        set(is_special_file FALSE)

        # Проверка на особые системные файлы.
        # Только при stm32-cmake backend и только если HAL/CMSIS включены.
        if(NOT toolchain_backend STREQUAL "arduino" AND (use_hal OR use_cmsis))
            if(filename_lower STREQUAL SYSTEM_FILENAME_TARGET)
                if(mcu_core)
                    set(CMSIS_${MCU_FAMILY}_${mcu_core}_SYSTEM "${full_path}" PARENT_SCOPE)
                else()
                    set(CMSIS_${MCU_FAMILY}_SYSTEM "${full_path}" PARENT_SCOPE)
                endif()
                stm32_yml_msg(I302 "${full_path}")
                set(is_special_file TRUE)

            elseif(filename_lower MATCHES ${STARTUP_FILENAME_PATTERN})
                if(mcu_core)
                    set(CMSIS_${MCU_FAMILY}_${mcu_core}_${MCU_TYPE}_STARTUP "${full_path}" PARENT_SCOPE)
                else()
                    set(CMSIS_${MCU_FAMILY}_${MCU_TYPE}_STARTUP "${full_path}" PARENT_SCOPE)
                endif()
                stm32_yml_msg(I303 "${full_path}")
                set(is_special_file TRUE)
            endif()
        endif()

        # Стандартная обработка остальных файлов
        if(NOT is_special_file)
            if(IS_DIRECTORY "${full_path}")
                # Подключение директории как модуля (CMakeLists.txt внутри обязателен);
                # каталог сборки — по ТЗ 4.6.8 (внешние каталоги — в _deps/).
                stm32_yml_add_subdirectory("${full_path}")
            elseif(EXISTS "${full_path}")
                # Добавление одиночного файла
                list(APPEND LOCAL_PROJECT_SOURCES "${full_path}")
            else()
                stm32_yml_msg(W302 "${src_item}")
            endif()
        endif()
    endforeach()

    # Привязываем собранные файлы к нашей цели
    if(LOCAL_PROJECT_SOURCES)
        target_sources(${TARGET_NAME} PRIVATE ${LOCAL_PROJECT_SOURCES})
    endif()

endfunction()

# ==============================================================================
# Каталоги, которые подключаются через add_subdirectory в этом Configure:
# каталоги из sources, а при backend arduino — обёртка ядра, arduino.libraries
# и arduino.custom_libraries. Нужны заранее для плана каталогов сборки (ТЗ 4.6.8).
# ==============================================================================
function(stm32_yml_collect_subdirectories OUT_VAR)
    set(_dirs "")
    foreach(_item IN LISTS sources)
        get_filename_component(_dir "${_item}" ABSOLUTE BASE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
        if(IS_DIRECTORY "${_dir}")
            list(APPEND _dirs "${_dir}")
        endif()
    endforeach()
    if(toolchain_backend STREQUAL "arduino")
        if(arduino_integration STREQUAL "native")
            # Каталоги ядра (ТЗ 4.9.9); каталог variant известен после выбора платы.
            list(APPEND _dirs "${CMAKE_SOURCE_DIR}/${arduino_core_path}/cores/arduino"
                              "${CMAKE_SOURCE_DIR}/${arduino_core_path}/libraries/SrcWrapper")
        elseif(DEFINED arduino_core_cmake_dir AND NOT arduino_core_cmake_dir STREQUAL "")
            list(APPEND _dirs "${CMAKE_SOURCE_DIR}/${arduino_core_cmake_dir}")
        else()
            list(APPEND _dirs "${CMAKE_SOURCE_DIR}/Arduino/Core")
        endif()
        foreach(_lib IN LISTS arduino_libraries)
            list(APPEND _dirs "${CMAKE_SOURCE_DIR}/${arduino_core_path}/libraries/${_lib}")
        endforeach()
        foreach(_lib IN LISTS arduino_custom_libraries)
            list(APPEND _dirs "${CMAKE_SOURCE_DIR}/${_lib}")
        endforeach()
    endif()
    set(${OUT_VAR} "${_dirs}" PARENT_SCOPE)
endfunction()
