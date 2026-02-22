# ==============================================================================
# Модуль: ПАРСЕР КОНФИГУРАЦИИ (YAML / IOC)
# ==============================================================================
# Эта функция ТОЛЬКО читает YAML/IOC и подготавливает переменные,
# необходимые для вызова project(). Она НЕ вызывает project() сама.
# ==============================================================================

function(stm32_yml_prepare_project_data OUT_PROJECT_NAME_VAR OUT_LANGUAGES_VAR)

    # =======================================================================
    # 1. ЗАГРУЗКА И ПОДГОТОВКА КОНФИГУРАЦИИ
    # =======================================================================
    set(PROJECT_CONFIG_FILE "stm32_config.yml" CACHE STRING "...")
    set(CONFIG_FILE_PATH "${CMAKE_SOURCE_DIR}/${PROJECT_CONFIG_FILE}")

    # Парсим конфиг (YAML -> JSON)
    stm32_yml_parse_config("${CONFIG_FILE_PATH}")

    # Проверка версии фреймворка
    stm32_yml_ensure_default_value(stm32_cmake_yml_version_check "true")
    if(stm32_cmake_yml_version_check)
        if(NOT DEFINED stm32_cmake_yml_version OR "${stm32_cmake_yml_version}" STREQUAL "")
            message(WARNING "В файле '${PROJECT_CONFIG_FILE}' отсутствует обязательный параметр 'stm32_cmake_yml_version'.")
        else()
            message(STATUS "Версия конфигурации, требуемая проектом STM32-CMAKE-YML: ${stm32_cmake_yml_version}")
            if(stm32_cmake_yml_version VERSION_GREATER STM32_CMAKE_YML_VERSION)
                message(WARNING "Версия фреймворка (${STM32_CMAKE_YML_VERSION}) старше, чем требуется (${stm32_cmake_yml_version}). Возможны ошибки.")
            elseif(stm32_cmake_yml_version VERSION_LESS STM32_CMAKE_YML_VERSION)
                message(WARNING "Версия фреймворка (${STM32_CMAKE_YML_VERSION}) новее, чем требуется (${stm32_cmake_yml_version}).")
            endif()
        endif()
    endif()

    stm32_yml_ensure_default_value(ioc_file "")

# Обрабатываем IOC или устанавливаем значения по умолчанию
    if(ioc_file)
        message(STATUS "Обнаружена настройка 'ioc_file'. Чтение данных из: ${ioc_file} ...")
        set(IOC_FILE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/${ioc_file}")

        # Вызываем парсер для .ioc файла
        stm32_yml_parse_ioc_file(${IOC_FILE_PATH} "IOC_")

        # Переопределяем базовые переменные значениями из .ioc
        set(mcu ${IOC_MCU})
        set(project_name ${IOC_PROJECT_NAME})
        set(heap_size ${IOC_HEAP_SIZE})
        set(stack_size ${IOC_STACK_SIZE})

        # Проекты из CubeMX всегда используют CMSIS и HAL
        set(use_cmsis true)
        set(use_hal true)

        if(IOC_USE_LOCAL_DRIVERS)
            set(cubefw_package "auto")
        else()
            set(cubefw_package ${IOC_CUBEFW_PACKAGE})
        endif()

        # =======================================================
        # Интеграция FreeRTOS из .ioc файла
        # =======================================================
        if(IOC_USE_FREERTOS)
            set(use_freertos true)
            set(freertos_version "cube")

            # Если пользователь не указал API вручную в .yml, берем из .ioc
            if(NOT DEFINED cmsis_rtos_api OR "${cmsis_rtos_api}" STREQUAL "")
                set(cmsis_rtos_api ${IOC_CMSIS_RTOS_API})
            endif()

            # Автоопределение порта FreeRTOS на основе семейства MCU!
            # (CubeMX обычно использует Heap_4 по умолчанию для динамической памяти)
            if(NOT DEFINED freertos_components OR "${freertos_components}" STREQUAL "")
                if(mcu MATCHES "^STM32(F1|F2|L1)")
                    set(freertos_components "ARM_CM3" "Heap::4")
                elseif(mcu MATCHES "^STM32(F3|F4|G4|L4)")
                    set(freertos_components "ARM_CM4F" "Heap::4")
                elseif(mcu MATCHES "^STM32(F0|G0|L0)")
                    set(freertos_components "ARM_CM0" "Heap::4")
                elseif(mcu MATCHES "^STM32(F7|H7)")
                    set(freertos_components "ARM_CM7" "Heap::4")
                else()
                    # Безопасный фолбек
                    set(freertos_components "ARM_CM4F" "Heap::4")
                endif()
            endif()
        endif()

        # =======================================================
        # Красивый табличный вывод распарсенных параметров
        # =======================================================
        message(STATUS "Параметры .ioc файла успешно применены:")
        message(STATUS "  MCU:        ${mcu}")
        message(STATUS "  Проект:     ${project_name}")
        message(STATUS "  CubeFW:     ${cubefw_package}")
        message(STATUS "  Heap Size:  ${heap_size} байт")
        message(STATUS "  Stack Size: ${stack_size} байт")
        if(use_freertos)
            string(REPLACE ";" ", " FREERTOS_COMPONENTS_STR "${freertos_components}")
            message(STATUS "  FreeRTOS:   Включен (API: ${cmsis_rtos_api}, Компоненты: ${FREERTOS_COMPONENTS_STR})")
        endif()
else()
        message(STATUS "Режим ручной конфигурации (ioc_file не указан).")
        stm32_yml_ensure_default_value(project_name "auto")
        stm32_yml_ensure_default_value(use_cmsis "true")
        stm32_yml_ensure_default_value(use_hal "true")
        stm32_yml_ensure_default_value(heap_size "512")
        stm32_yml_ensure_default_value(stack_size "1024")
        stm32_yml_ensure_default_value(use_freertos "false")
    endif()

    # Значения по умолчанию для пропущенных параметров
    stm32_yml_ensure_default_value(linker_script "auto")
    stm32_yml_ensure_default_value(use_newlib_nano "false")
    stm32_yml_ensure_default_value(mcu_core "")
    stm32_yml_ensure_default_value(crc_enable "false")
    stm32_yml_ensure_default_value(crc_section_name ".checksum")
    stm32_yml_ensure_default_value(crc_algorithm "STM32_HW_DEFAULT")
    # --- Значения по умолчанию для Cppcheck ---
    if(NOT DEFINED cppcheck_ignores OR "${cppcheck_ignores}" STREQUAL "")
        set(cppcheck_ignores "STM32Cube/Repository" "Drivers" "Middlewares")
    endif()

    # =======================================================================
    # 2. УСТАНОВКА ОСНОВНЫХ ПАРАМЕТРОВ ПРОЕКТА
    # =======================================================================
    set(CMAKE_C_STANDARD ${c_standard} PARENT_SCOPE)
    set(CMAKE_CXX_STANDARD ${cpp_standard} PARENT_SCOPE)

    set(MCU ${mcu} CACHE STRING "Target STM32 microcontroller")

    if(${project_name} STREQUAL "auto")
        get_filename_component(LOCAL_PROJECT_NAME ${CMAKE_SOURCE_DIR} NAME)
    else()
        set(LOCAL_PROJECT_NAME ${project_name})
    endif()
    message(STATUS "Определено имя проекта: ${LOCAL_PROJECT_NAME}")

    if(NOT DEFINED languages OR "${languages}" STREQUAL "")
        set(LOCAL_LANGUAGES C CXX ASM)
        message(STATUS "Языки проекта не указаны. Используется по умолчанию: ${LOCAL_LANGUAGES}")
    else()
        set(LOCAL_LANGUAGES ${languages})
        message(STATUS "Используются языки проекта из конфига: ${LOCAL_LANGUAGES}")
    endif()

    # ==============================================================================
    # "Пробрасываем" ВСЕ переменные, нужные для setup_project, наверх.
    # ==============================================================================

    # 1. Сначала пробрасываем служебные переменные, сгенерированные фреймворком
    set(${OUT_PROJECT_NAME_VAR} ${LOCAL_PROJECT_NAME} PARENT_SCOPE)
    set(${OUT_LANGUAGES_VAR} ${LOCAL_LANGUAGES} PARENT_SCOPE)

    set(mcu ${mcu} PARENT_SCOPE)
    set(mcu_core ${mcu_core} PARENT_SCOPE)
    set(c_standard ${c_standard} PARENT_SCOPE)
    set(cpp_standard ${cpp_standard} PARENT_SCOPE)
    set(heap_size ${heap_size} PARENT_SCOPE)
    set(stack_size ${stack_size} PARENT_SCOPE)
    set(sources ${sources} PARENT_SCOPE)
    set(include_directories ${include_directories} PARENT_SCOPE)
    set(use_cmsis ${use_cmsis} PARENT_SCOPE)
    set(use_hal ${use_hal} PARENT_SCOPE)
    set(cubefw_package ${cubefw_package} PARENT_SCOPE)
    set(hal_components ${hal_components} PARENT_SCOPE)
    set(use_freertos ${use_freertos} PARENT_SCOPE)
    set(freertos_version ${freertos_version} PARENT_SCOPE)
    set(freertos_components ${freertos_components} PARENT_SCOPE)
    set(cmsis_rtos_api ${cmsis_rtos_api} PARENT_SCOPE)
    set(compile_options ${compile_options} PARENT_SCOPE)
    set(compile_definitions ${compile_definitions} PARENT_SCOPE)
    set(linker_script ${linker_script} PARENT_SCOPE)
    set(link_options ${link_options} PARENT_SCOPE)
    set(linker_directives ${linker_directives} PARENT_SCOPE)
    set(custom_libraries ${custom_libraries} PARENT_SCOPE)
    set(link_libraries ${link_libraries} PARENT_SCOPE)
    set(use_newlib_nano ${use_newlib_nano} PARENT_SCOPE)
    set(system_library ${system_library} PARENT_SCOPE)
    set(build_artifacts ${build_artifacts} PARENT_SCOPE)
    set(validate_linker_script ${validate_linker_script} PARENT_SCOPE)
    set(verbose_build ${verbose_build} PARENT_SCOPE)
    set(log_target_properties ${log_target_properties} PARENT_SCOPE)
    set(crc_enable ${crc_enable} PARENT_SCOPE)
    set(crc_section_name ${crc_section_name} PARENT_SCOPE)
    set(crc_algorithm ${crc_algorithm} PARENT_SCOPE)
    set(cppcheck_enable ${cppcheck_enable} PARENT_SCOPE)
    set(cppcheck_args ${cppcheck_args} PARENT_SCOPE)
    set(cppcheck_ignores ${cppcheck_ignores} PARENT_SCOPE)

    # 2. АВТОМАТИЧЕСКИЙ ПРОБРОС ДИНАМИЧЕСКИХ ПАРАМЕТРОВ ИЗ YAML
    # Любой новый ключ (в том числе вложенный), добавленный в yaml, автоматически
    # пробросится в основную цель сборки. Нам больше не нужно писать set() вручную!
    if(DEFINED YAML_PARSED_KEYS)
        foreach(yaml_key IN LISTS YAML_PARSED_KEYS)
            set(${yaml_key} "${${yaml_key}}" PARENT_SCOPE)
        endforeach()
    endif()

endfunction()
