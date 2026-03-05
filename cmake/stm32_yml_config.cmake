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

    # --- Баннер версий -------------------------------------------------------
    message(STATUS "Framework : ${STM32_CMAKE_YML_VERSION}")

    stm32_yml_ensure_default_value(stm32_cmake_yml_version_check "true")
    if(stm32_cmake_yml_version_check)
        if(NOT DEFINED stm32_cmake_yml_version OR "${stm32_cmake_yml_version}" STREQUAL "")
            message(STATUS "Config    : (stm32_cmake_yml_version не указан в ${PROJECT_CONFIG_FILE})")
            message(WARNING "В файле '${PROJECT_CONFIG_FILE}' отсутствует обязательный параметр 'stm32_cmake_yml_version'.")
        else()
            if(stm32_cmake_yml_version VERSION_EQUAL STM32_CMAKE_YML_VERSION)
                set(_ver_status "совпадают ✓")
            elseif(stm32_cmake_yml_version VERSION_GREATER STM32_CMAKE_YML_VERSION)
                set(_ver_status "конфиг новее — обновите фреймворк !")
            else()
                set(_ver_status "фреймворк новее — обновите конфиг")
            endif()
            message(STATUS "Config    : ${stm32_cmake_yml_version}  (${_ver_status})")

            if(stm32_cmake_yml_version VERSION_GREATER STM32_CMAKE_YML_VERSION)
                message(WARNING "Версия фреймворка (${STM32_CMAKE_YML_VERSION}) старше, чем требуется конфигом (${stm32_cmake_yml_version}). Возможны ошибки.")
            elseif(stm32_cmake_yml_version VERSION_LESS STM32_CMAKE_YML_VERSION)
                message(WARNING "Версия фреймворка (${STM32_CMAKE_YML_VERSION}) новее, чем указано в конфиге (${stm32_cmake_yml_version}). Рекомендуется обновить stm32_cmake_yml_version.")
            endif()
        endif()
    else()
    endif()
    # -------------------------------------------------------------------------

    # Сохраняем значения, явно заданные пользователем в .yml, до того как
    # override-логика и ensure_default_value могут их изменить.
    # Используются хелпером _stm32_yml_src для расстановки меток [yml]/[ioc]/[auto].
    set(_YAML_mcu                "${mcu}")
    set(_YAML_project_name       "${project_name}")
    set(_YAML_heap_size          "${heap_size}")
    set(_YAML_stack_size         "${stack_size}")
    set(_YAML_cubefw_package     "${cubefw_package}")
    set(_YAML_use_freertos       "${use_freertos}")
    set(_YAML_cmsis_rtos_api     "${cmsis_rtos_api}")
    set(_YAML_freertos_components "${freertos_components}")
    stm32_yml_ensure_default_value(ioc_file "")
    # Хелпер: определяет и возвращает метку источника значения переменной.
    # yml_raw  — значение, пришедшее из YAML (до override-логики)
    # ioc_raw  — значение, пришедшее из .ioc
    # final    — итоговое значение
    # out_var  — имя переменной, в которую запишется метка
    macro(_stm32_yml_src yml_raw ioc_raw final out_var)
        if(NOT "${yml_raw}" STREQUAL "" AND "${final}" STREQUAL "${yml_raw}")
            set(${out_var} "[yml]")
        elseif(NOT "${ioc_raw}" STREQUAL "" AND "${final}" STREQUAL "${ioc_raw}")
            set(${out_var} "[ioc]")
        else()
            set(${out_var} "[auto]")
        endif()
    endmacro()

# Обрабатываем IOC или устанавливаем значения по умолчанию
    if(ioc_file)
        message(STATUS "Обнаружена настройка 'ioc_file'. Чтение данных из: ${ioc_file} ...")
        set(IOC_FILE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/${ioc_file}")

        # Вызываем парсер для .ioc файла
        stm32_yml_parse_ioc_file(${IOC_FILE_PATH} "IOC_")

        # ------------------------------------------------------------------
        # Шаг A: применяем базовые значения из .ioc (они имеют низший приоритет).
        # Пользователь может переопределить любой из них в stm32_config.yml.
        # ------------------------------------------------------------------

        # mcu и project_name: берём из .ioc только если не заданы в YAML явно
        if(NOT DEFINED mcu OR "${mcu}" STREQUAL "")
            set(mcu ${IOC_MCU})
        endif()
        if(NOT DEFINED project_name OR "${project_name}" STREQUAL "")
            set(project_name ${IOC_PROJECT_NAME})
        endif()

        # heap_size / stack_size: берём из .ioc только если не заданы в YAML
        if(NOT DEFINED heap_size OR "${heap_size}" STREQUAL "")
            set(heap_size ${IOC_HEAP_SIZE})
        endif()
        if(NOT DEFINED stack_size OR "${stack_size}" STREQUAL "")
            set(stack_size ${IOC_STACK_SIZE})
        endif()

        # Проекты из CubeMX всегда используют CMSIS и HAL (если не отключено явно)
        if(NOT DEFINED use_cmsis OR "${use_cmsis}" STREQUAL "")
            set(use_cmsis true)
        endif()
        if(NOT DEFINED use_hal OR "${use_hal}" STREQUAL "")
            set(use_hal true)
        endif()

        # cubefw_package: локальные драйверы или версия из .ioc (если не задано в YAML)
        if(NOT DEFINED cubefw_package OR "${cubefw_package}" STREQUAL "")
            if(IOC_USE_LOCAL_DRIVERS)
                set(cubefw_package "auto")
            else()
                set(cubefw_package ${IOC_CUBEFW_PACKAGE})
            endif()
        endif()

        # ------------------------------------------------------------------
        # Шаг B: интеграция FreeRTOS из .ioc.
        # Если в YAML явно задан use_freertos=false — .ioc игнорируется.
        # ------------------------------------------------------------------
        if(IOC_USE_FREERTOS)
            # YAML-override: пользователь может явно отключить FreeRTOS
            if(NOT DEFINED use_freertos OR "${use_freertos}" STREQUAL "")
                set(use_freertos true)
            endif()

            if(use_freertos)
                if(NOT DEFINED freertos_version OR "${freertos_version}" STREQUAL "")
                    set(freertos_version "cube")
                endif()

                # cmsis_rtos_api: YAML имеет приоритет над .ioc
                if(NOT DEFINED cmsis_rtos_api OR "${cmsis_rtos_api}" STREQUAL "")
                    set(cmsis_rtos_api ${IOC_CMSIS_RTOS_API})
                endif()

                # freertos_components: YAML имеет приоритет; автоопределение если не задано
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
                        set(freertos_components "ARM_CM4F" "Heap::4")
                    endif()
                endif()
            endif()
        endif()

        # =======================================================
        # Итоговая таблица: значения + источник [yml]/[ioc]/[auto]
        # =======================================================
        # Сохраняем «сырые» значения YAML для определения источника.
        # После блока override-логики (патч задачи 4) переменные уже итоговые,
        # а YAML_RAW_* — то, что было явно задано пользователем в .yml.
        set(_yml_raw_mcu            "${_YAML_mcu}")
        set(_yml_raw_project_name   "${_YAML_project_name}")
        set(_yml_raw_heap_size      "${_YAML_heap_size}")
        set(_yml_raw_stack_size     "${_YAML_stack_size}")
        set(_yml_raw_cubefw         "${_YAML_cubefw_package}")
        set(_yml_raw_freertos       "${_YAML_use_freertos}")
        set(_yml_raw_rtos_api       "${_YAML_cmsis_rtos_api}")
        set(_yml_raw_freertos_comp  "${_YAML_freertos_components}")

        _stm32_yml_src("${_yml_raw_mcu}"          "${IOC_MCU}"           "${mcu}"            _src_mcu)
        _stm32_yml_src("${_yml_raw_project_name}" "${IOC_PROJECT_NAME}"  "${project_name}"   _src_proj)
        _stm32_yml_src("${_yml_raw_heap_size}"    "${IOC_HEAP_SIZE}"     "${heap_size}"      _src_heap)
        _stm32_yml_src("${_yml_raw_stack_size}"   "${IOC_STACK_SIZE}"    "${stack_size}"     _src_stack)
        _stm32_yml_src("${_yml_raw_cubefw}"       "${IOC_CUBEFW_PACKAGE}" "${cubefw_package}" _src_cube)

        message(STATUS "Итоговые параметры проекта (источник: [yml]=конфиг / [ioc]=CubeMX / [auto]=авто):")
        message(STATUS "  MCU:        ${mcu}  ${_src_mcu}")
        message(STATUS "  Проект:     ${project_name}  ${_src_proj}")
        message(STATUS "  CubeFW:     ${cubefw_package}  ${_src_cube}")
        message(STATUS "  Heap Size:  ${heap_size} байт  ${_src_heap}")
        message(STATUS "  Stack Size: ${stack_size} байт  ${_src_stack}")
        if(use_freertos)
            _stm32_yml_src("${_yml_raw_rtos_api}"      "${IOC_CMSIS_RTOS_API}" "${cmsis_rtos_api}"     _src_api)
            _stm32_yml_src("${_yml_raw_freertos_comp}" ""                      "${freertos_components}" _src_fc)
            string(REPLACE ";" ", " _freertos_comp_str "${freertos_components}")
            if("${_yml_raw_freertos}" STREQUAL "false")
                message(STATUS "  FreeRTOS:   ОТКЛЮЧЕН (переопределено в .yml)  [yml]")
            else()
                message(STATUS "  FreeRTOS:   Включен  ${_src_freertos_flag}")
                message(STATUS "    API:      ${cmsis_rtos_api}  ${_src_api}")
                message(STATUS "    Порт:     ${_freertos_comp_str}  ${_src_fc}")
            endif()
        else()
            message(STATUS "  FreeRTOS:   Отключен")
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
    # Нормализуем перед пробросом: гарантируем TRUE/FALSE независимо от кэша.
    if(DEFINED crc_enable)
        string(TOUPPER "${crc_enable}" _crc_upper)
    else()
        set(_crc_upper "FALSE")
    endif()
    if(_crc_upper STREQUAL "TRUE" OR _crc_upper STREQUAL "ON" OR _crc_upper STREQUAL "1" OR _crc_upper STREQUAL "YES")
        set(crc_enable TRUE PARENT_SCOPE)
    else()
        set(crc_enable FALSE PARENT_SCOPE)
    endif()
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
