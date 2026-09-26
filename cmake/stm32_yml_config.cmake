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
    # Изменение конфигурации перезапускает Configure при следующей сборке (ТЗ 3.6.5).
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${CONFIG_FILE_PATH}")

    # --- Баннер версий -------------------------------------------------------
    message(STATUS "Framework : ${STM32_CMAKE_YML_VERSION}")

    stm32_yml_ensure_default_value(stm32_cmake_yml_version_check "true")

    if(stm32_cmake_yml_version_check)
        if(NOT DEFINED stm32_cmake_yml_version OR "${stm32_cmake_yml_version}" STREQUAL "")
            message(STATUS "Config    : (stm32_cmake_yml_version не указан в ${PROJECT_CONFIG_FILE})")
            message(WARNING "В файле '${PROJECT_CONFIG_FILE}' не указан рекомендуемый параметр 'stm32_cmake_yml_version'. "
                            "Укажите версию фреймворка, для которой написана конфигурация (ТЗ 4.2.3).")
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
                message(WARNING
                    "Версия фреймворка (${STM32_CMAKE_YML_VERSION}) новее, чем указано в конфиге "
                    "(${stm32_cmake_yml_version}). Рекомендуется обновить stm32_cmake_yml_version.")
            endif()
        endif()
    endif()
    # -------------------------------------------------------------------------

    # Применяем профиль сборки и точечные cmake-overrides.
    # Вызов до ioc-логики — профиль может переопределить ioc_file и mcu.
    if(STM32_YML_PROFILE STREQUAL "list")
        stm32_yml_list_profiles()
        message(FATAL_ERROR "Передайте -DSTM32_YML_PROFILE=<имя> для выбора профиля.")
    else()
        stm32_yml_apply_profile("${CONFIG_FILE_PATH}")
    endif()

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

    # Значения ручного режима для имени проекта и размеров памяти (ТЗ 4.4.6, 4.4.7).
    # Применяются и при неполном .ioc. До этого запоминаем, заданы ли размеры
    # явно (YAML, профиль, override, .ioc): только такие размеры дают
    # предупреждение, если скрипт компоновщика не генерируется из шаблона (ТЗ 4.11.9).
    macro(_stm32_yml_apply_manual_defaults)
        set(_explicit_memory_sizes "")
        foreach(_mem_key IN ITEMS heap_size stack_size)
            if(NOT "${${_mem_key}}" STREQUAL "")
                list(APPEND _explicit_memory_sizes "${_mem_key}")
            endif()
        endforeach()
        stm32_yml_ensure_default_value(project_name "auto")
        stm32_yml_ensure_default_value(heap_size "512")
        stm32_yml_ensure_default_value(stack_size "1024")
    endmacro()

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

    # Перечислимые значения (ТЗ 3.7.3): неизвестное — предупреждение и замена.
    stm32_yml_check_enum_value(toolchain_backend "stm32-cmake" stm32-cmake arduino)

    if(toolchain_backend STREQUAL "arduino")
        # В режиме Arduino игнорируем IOC-файл, принудительно направляя скрипт в ветку else()
        set(ioc_file "")
    else()
        stm32_yml_ensure_default_value(ioc_file "")
    endif()

    # Обрабатываем IOC или устанавливаем значения по умолчанию.
    if(ioc_file)

        message(STATUS "Обнаружена настройка 'ioc_file'. Чтение данных из: ${ioc_file} ...")

        set(IOC_FILE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/${ioc_file}")

        # Вызываем парсер для .ioc файла.
        stm32_yml_parse_ioc_file(${IOC_FILE_PATH} "IOC_")
        set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${IOC_FILE_PATH}")

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
        # .ioc без ProjectName, HeapSize или StackSize — значения ручного режима.
        _stm32_yml_apply_manual_defaults()

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
                    # Порт по семейству и ядру MCU (ТЗ 4.4.4, приложение A).
                    # Ядро ещё не проверено (п. 4.7.8): для H7 и WL без mcu_core
                    # берётся основное ядро (M7, M4).
                    if(mcu MATCHES "^STM32WL" AND mcu_core STREQUAL "M0PLUS")
                        set(_freertos_port "ARM_CM0")
                    elseif(mcu MATCHES "^STM32(F1|F2|L1|WL)")
                        set(_freertos_port "ARM_CM3")
                    elseif(mcu MATCHES "^STM32H7" AND mcu_core STREQUAL "M4")
                        set(_freertos_port "ARM_CM4F")
                    elseif(mcu MATCHES "^STM32(F7|H7)")
                        set(_freertos_port "ARM_CM7")
                    elseif(mcu MATCHES "^STM32(F3|F4|G4|L4|WB|MP1)")
                        set(_freertos_port "ARM_CM4F")
                    elseif(mcu MATCHES "^STM32(F0|G0|L0|C0|U0)")
                        set(_freertos_port "ARM_CM0")
                    elseif(mcu MATCHES "^STM32(H5|L5|U5)")
                        set(_freertos_port "ARM_CM33_NTZ")
                    else()
                        set(_freertos_port "ARM_CM4F")
                        message(WARNING
                            "Порт FreeRTOS для '${mcu}' не определён таблицей фреймворка; "
                            "используется ARM_CM4F. Задайте freertos_components явно.")
                    endif()
                    set(freertos_components "${_freertos_port}" "Heap::4")
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
            # Источник самого флага use_freertos определяем явно: булевы значения
            # из yml ("true") и из .ioc ("TRUE") различаются регистром, поэтому
            # обобщённый хелпер _stm32_yml_src здесь дал бы ложный [auto].
            if(NOT "${_yml_raw_freertos}" STREQUAL "")
                set(_src_freertos_flag "[yml]")
            elseif(IOC_USE_FREERTOS)
                set(_src_freertos_flag "[ioc]")
            else()
                set(_src_freertos_flag "[auto]")
            endif()

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
        if(NOT toolchain_backend STREQUAL "arduino")
            message(STATUS "Режим ручной конфигурации (ioc_file не указан).")
        endif()
        _stm32_yml_apply_manual_defaults()

        if(NOT toolchain_backend STREQUAL "arduino")
            stm32_yml_ensure_default_value(use_cmsis "true")
            stm32_yml_ensure_default_value(use_hal "true")
            stm32_yml_ensure_default_value(use_freertos "false")
        endif()
    endif()

    # Значения по умолчанию для пропущенных параметров
    stm32_yml_ensure_default_value(linker_script "auto")
    stm32_yml_ensure_default_value(use_newlib_nano "false")

    if(NOT toolchain_backend STREQUAL "arduino")
        stm32_yml_ensure_default_value(mcu_core "")
    endif()

    stm32_yml_ensure_default_value(crc_enable "false")

    # Нормализуем значение в булево для проверки прямо здесь
    string(TOUPPER "${crc_enable}" _crc_check)
    if(_crc_check STREQUAL "TRUE" OR _crc_check STREQUAL "ON" OR _crc_check STREQUAL "1" OR _crc_check STREQUAL "YES")
        stm32_yml_ensure_default_value(crc_section_name ".checksum")
        stm32_yml_ensure_default_value(crc_algorithm "STM32_HW_DEFAULT")
    endif()

    # Остальные перечислимые ключи (ТЗ 3.7.3). Пустые значения не проверяются.
    stm32_yml_check_enum_value(system_library "" NoSys Semihosting)
    stm32_yml_check_enum_value(cmsis_rtos_api "none" none v1 v2)
    # Неизвестная версия ведёт себя как external, как в 0.9.2.
    stm32_yml_check_enum_value(freertos_version "external" cube external)
    stm32_yml_check_enum_list(build_artifacts bin hex srec map lss)

    # --- Значения по умолчанию для Cppcheck ---
    if(NOT DEFINED cppcheck_ignores OR "${cppcheck_ignores}" STREQUAL "")
        set(cppcheck_ignores "STM32Cube/Repository" "Drivers" "Middlewares")
    endif()

    # =======================================================================
    # 2. УСТАНОВКА ОСНОВНЫХ ПАРАМЕТРОВ ПРОЕКТА
    # =======================================================================
    set(CMAKE_C_STANDARD ${c_standard} PARENT_SCOPE)
    set(CMAKE_CXX_STANDARD ${cpp_standard} PARENT_SCOPE)

    # Это производное значение конфигурации, а не независимый override.
    # Без FORCE смена профиля оставляет в кэше MCU от предыдущей настройки.
    set(MCU ${mcu} CACHE STRING "Target STM32 microcontroller" FORCE)

    # Сравнение без разыменования: пустое значение project_name (например, когда
    # .ioc не содержит ProjectManager.ProjectName) сломало бы синтаксис if().
    if(project_name STREQUAL "auto")
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
    # Нормализуем и локально: автоматический экспорт ниже передаёт локальные значения.
    if(_crc_upper STREQUAL "TRUE" OR _crc_upper STREQUAL "ON" OR _crc_upper STREQUAL "1" OR _crc_upper STREQUAL "YES")
        set(crc_enable TRUE)
    else()
        set(crc_enable FALSE)
    endif()
    set(crc_enable ${crc_enable} PARENT_SCOPE)
    set(crc_section_name ${crc_section_name} PARENT_SCOPE)
    set(crc_algorithm ${crc_algorithm} PARENT_SCOPE)
    set(cppcheck_enable ${cppcheck_enable} PARENT_SCOPE)
    set(cppcheck_args ${cppcheck_args} PARENT_SCOPE)
    set(cppcheck_ignores ${cppcheck_ignores} PARENT_SCOPE)
    set(STM32_YML_PROFILE "${STM32_YML_PROFILE}" PARENT_SCOPE)
    # Размеры памяти, заданные явно, для предупреждения ТЗ 4.11.9.
    set(STM32_YML_EXPLICIT_MEMORY_SIZES "${_explicit_memory_sizes}" PARENT_SCOPE)
    # Параметры toolchain backend.
    set(toolchain_backend ${toolchain_backend} PARENT_SCOPE)
    # Параметр папки поиска скрипта компоновщика.
    set(linker_script_dir ${linker_script_dir} PARENT_SCOPE)
    # Параметры секции arduino: — пробрасываются как arduino_<param>.
    set(arduino_core_path       ${arduino_core_path}       PARENT_SCOPE)
    set(arduino_core_cmake_dir  ${arduino_core_cmake_dir}  PARENT_SCOPE)
    set(arduino_mcu_target      ${arduino_mcu_target}      PARENT_SCOPE)
    set(arduino_use_core_main   ${arduino_use_core_main}   PARENT_SCOPE)
    set(arduino_libraries       ${arduino_libraries}       PARENT_SCOPE)
    set(arduino_custom_libraries ${arduino_custom_libraries} PARENT_SCOPE)

    # 2. АВТОМАТИЧЕСКИЙ ПРОБРОС ДИНАМИЧЕСКИХ ПАРАМЕТРОВ ИЗ YAML
    # Любой новый ключ (в том числе вложенный), добавленный в yaml, автоматически
    # пробросится в основную цель сборки. Нам больше не нужно писать set() вручную!
    # Ключи профиля и override пробрасываются так же, в том числе отсутствующие
    # в корне YAML (ТЗ 3.4.9, E008). Значения берутся из этой области, то есть
    # уже обработанные выше.
    foreach(yaml_key IN LISTS YAML_PARSED_KEYS STM32_YML_PROFILE_KEYS)
        set(${yaml_key} "${${yaml_key}}" PARENT_SCOPE)
    endforeach()

endfunction()
