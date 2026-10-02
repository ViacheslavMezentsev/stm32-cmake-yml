cmake_minimum_required(VERSION 3.21)

# ==============================================================================
#      ФРЕЙМВОРК STM32-CMAKE-YML
# ==============================================================================

# Определяем текущую версию фреймворка.
set(STM32_CMAKE_YML_VERSION "0.10.1")

# Подключаем функциональные модули фреймворка. Сообщения — первыми: файл
# сообщений создаётся заново при каждом Configure до project() (ТЗ 4.16.10).
include(${CMAKE_CURRENT_LIST_DIR}/cmake/stm32_yml_messages.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/cmake/stm32_yml_utils.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/cmake/stm32_yml_include.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/cmake/stm32_yml_versions.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/cmake/stm32_yml_config.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/cmake/stm32_yml_build_dirs.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/cmake/stm32_yml_sources.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/cmake/stm32_yml_frameworks.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/cmake/stm32_yml_linker.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/cmake/stm32_yml_diagnostics.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/cmake/stm32_yml_postbuild.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/cmake/stm32_yml_code_quality.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/cmake/stm32_yml_profiles.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/cmake/stm32_yml_arduino.cmake)

# ==============================================================================
#      ОСНОВНАЯ ФУНКЦИЯ НАСТРОЙКИ ЦЕЛИ СБОРКИ
# ==============================================================================
# @param TARGET_NAME - Имя цели (исполняемого файла), которую нужно настроить.
#
function(stm32_yml_setup_project TARGET_NAME)

    # 1. Базовая инициализация и опции CMake.

    # Версия компилятора известна только после project() (ТЗ 4.2.6).
    stm32_yml_print_compiler_version()

    # Устанавливаем backend сборки в начале функции — значение используется
    # далее в нескольких местах: при вызове stm32_get_chip_info, при выборе
    # фреймворка и при настройке линкера.
    stm32_yml_ensure_default_value(toolchain_backend "stm32-cmake")

    # Режим backend Arduino (ТЗ 4.9.8): пусто — wrappers, как в 0.9.3. В режиме
    # native флаги YAML передаются через цель user_settings ядра (ТЗ 4.9.12).
    set(_stm32_yml_native FALSE)
    if(toolchain_backend STREQUAL "arduino")
        stm32_yml_check_enum_value(arduino_integration "wrappers" wrappers native)
        if("${arduino_integration}" STREQUAL "")
            set(arduino_integration "wrappers")
        endif()
        if(arduino_integration STREQUAL "native")
            set(_stm32_yml_native TRUE)
        endif()
    endif()

    stm32_yml_ensure_default_value(verbose_build "false")
    if(verbose_build)
        stm32_yml_msg(I010)
        set(CMAKE_VERBOSE_MAKEFILE ON CACHE BOOL "Enable verbose build output" FORCE)
    else()
        set(CMAKE_VERBOSE_MAKEFILE OFF CACHE BOOL "Enable verbose build output" FORCE)
    endif()

    add_executable(${TARGET_NAME})

    # Определяем тип микроконтроллера для макросов компилятора.
    # stm32_get_chip_info доступна только при backend stm32-cmake —
    # она является частью stm32_gcc.cmake toolchain.
    # При Arduino backend макрос STM32${MCU_TYPE} задаётся пользователем
    # явно через compile_definitions в stm32_config.yml.
    if(NOT toolchain_backend STREQUAL "arduino")
        stm32_get_chip_info(${MCU} FAMILY MCU_FAMILY TYPE MCU_TYPE)
        target_compile_definitions(${TARGET_NAME} PRIVATE STM32${MCU_TYPE})
        # Ядро применяется ко всем целям CMSIS/HAL/FreeRTOS, startup/system
        # и запросам памяти (ТЗ 4.7.8).
        stm32_yml_resolve_mcu_core()
    endif()

    # 2. Настройка флагов компилятора и include-директорий из YAML.

    # --- Нормализация всех списков флагов ---
    # compile_options/*: разбивка по пробелам + автодобавление "-"
    stm32_yml_normalize_flags(compile_options)
    stm32_yml_normalize_flags(compile_options_c)
    stm32_yml_normalize_flags(compile_options_cxx)
    stm32_yml_normalize_flags(link_options)
    # compile_definitions/*: только разбивка по пробелам, "-D" добавляет CMake сам
    stm32_yml_normalize_flags(compile_definitions     NO_AUTO_DASH)
    stm32_yml_normalize_flags(compile_definitions_c   NO_AUTO_DASH)
    stm32_yml_normalize_flags(compile_definitions_cxx NO_AUTO_DASH)

    # --- Общие флаги (для всех языков) — обратная совместимость ---
    target_include_directories(${TARGET_NAME} PRIVATE ${include_directories})
    if(NOT _stm32_yml_native)
        target_compile_definitions(${TARGET_NAME} PRIVATE ${compile_definitions})
        target_compile_options(${TARGET_NAME} PRIVATE ${compile_options})
    endif()

    # --- Флаги только для C ---
    if(compile_options_c AND NOT _stm32_yml_native)
        target_compile_options(${TARGET_NAME} PRIVATE
            $<$<COMPILE_LANGUAGE:C>:${compile_options_c}>)
        string(REPLACE ";" " " _c_opts_str "${compile_options_c}")
        stm32_yml_msg(I011 "${_c_opts_str}")
    endif()
    if(compile_definitions_c AND NOT _stm32_yml_native)
        target_compile_definitions(${TARGET_NAME} PRIVATE
            $<$<COMPILE_LANGUAGE:C>:${compile_definitions_c}>)
        string(REPLACE ";" " " _c_defs_str "${compile_definitions_c}")
        stm32_yml_msg(I012 "${_c_defs_str}")
    endif()

    # --- Флаги только для C++ ---
    if(compile_options_cxx AND NOT _stm32_yml_native)
        target_compile_options(${TARGET_NAME} PRIVATE
            $<$<COMPILE_LANGUAGE:CXX>:${compile_options_cxx}>)
        string(REPLACE ";" " " _cxx_opts_str "${compile_options_cxx}")
        stm32_yml_msg(I013 "${_cxx_opts_str}")
    endif()
    if(compile_definitions_cxx AND NOT _stm32_yml_native)
        target_compile_definitions(${TARGET_NAME} PRIVATE
            $<$<COMPILE_LANGUAGE:CXX>:${compile_definitions_cxx}>)
        string(REPLACE ";" " " _cxx_defs_str "${compile_definitions_cxx}")
        stm32_yml_msg(I014 "${_cxx_defs_str}")
    endif()

    # 2.5 Контроль качества кода (Cppcheck, и т.д.).
    stm32_yml_setup_code_quality(${TARGET_NAME})

    # Опции и директивы линкера.
    if("map" IN_LIST build_artifacts)
        # Имя и каталог — по итоговому имени ELF (ТЗ 4.5.7, 4.14.4).
        stm32_yml_artifact_path(${TARGET_NAME} map _map_path)
        target_link_options(${TARGET_NAME} PRIVATE "LINKER:-Map=${_map_path}")
    endif()
    target_link_options(${TARGET_NAME} PRIVATE ${link_options})
    # link_options уже нормализованы выше вместе с compile_options
    foreach(directive IN LISTS linker_directives)
        target_link_options(${TARGET_NAME} PRIVATE "LINKER:${directive}")
    endforeach()

    # 3. Подключение исходных файлов и папок. Каталоги сборки всех подключаемых
    # каталогов назначаются заранее (ТЗ 4.6.8).
    stm32_yml_collect_subdirectories(_stm32_yml_subdirs)
    stm32_yml_plan_build_dirs(${_stm32_yml_subdirs})
    stm32_yml_setup_sources(${TARGET_NAME})

    # 4. Настраиваем backend сборки: stm32-cmake (по умолчанию) или arduino.
    if(toolchain_backend STREQUAL "arduino")
        stm32_yml_setup_arduino(${TARGET_NAME})
    else()
        # Настраиваем фреймворки (HAL, CMSIS, FreeRTOS).
        stm32_yml_setup_frameworks(${TARGET_NAME})
    endif()

    # Настраиваем системные библиотеки (Newlib Nano, NoSys, Semihosting).
    stm32_yml_setup_system_libraries(${TARGET_NAME})

    # 5. Настройка скрипта компоновщика (.ld).
    stm32_yml_setup_linker_script(${TARGET_NAME})

    # 6. Финальная линковка пользовательских библиотек
    set(CUSTOM_LIBRARY_PATHS "")
    if(DEFINED custom_libraries)
        foreach(lib_path IN LISTS custom_libraries)
            set(full_lib_path "${CMAKE_SOURCE_DIR}/${lib_path}")
            if(EXISTS ${full_lib_path})
                list(APPEND CUSTOM_LIBRARY_PATHS ${full_lib_path})
                stm32_yml_msg(I301 "${full_lib_path}")
            else()
                stm32_yml_msg(W301 "${full_lib_path}")
            endif()
        endforeach()
    endif()

    target_link_libraries(${TARGET_NAME} PRIVATE
        ${CUSTOM_LIBRARY_PATHS}
        ${link_libraries}
    )

    # 7. Санитарные проверки и отладочный вывод.
    stm32_yml_run_diagnostics(${TARGET_NAME})

    # 8. Post-Build задачи (Внедрение CRC32, генерация .hex, .bin, .lss).
    stm32_yml_setup_postbuild(${TARGET_NAME})

endfunction()
