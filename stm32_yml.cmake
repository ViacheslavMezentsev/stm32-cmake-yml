cmake_minimum_required(VERSION 3.19)

# ==============================================================================
#      ФРЕЙМВОРК STM32-CMAKE-YML
# ==============================================================================

# Определяем текущую версию фреймворка.
set(STM32_CMAKE_YML_VERSION "0.8")

# Подключаем функциональные модули фреймворка.
include(${CMAKE_CURRENT_LIST_DIR}/cmake/stm32_yml_utils.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/cmake/stm32_yml_config.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/cmake/stm32_yml_sources.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/cmake/stm32_yml_frameworks.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/cmake/stm32_yml_linker.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/cmake/stm32_yml_diagnostics.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/cmake/stm32_yml_postbuild.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/cmake/stm32_yml_code_quality.cmake)

# ==============================================================================
#      ОСНОВНАЯ ФУНКЦИЯ НАСТРОЙКИ ЦЕЛИ СБОРКИ
# ==============================================================================
# @param TARGET_NAME - Имя цели (исполняемого файла), которую нужно настроить.
#
function(stm32_yml_setup_project TARGET_NAME)

    # 1. Базовая инициализация и опции CMake.
    stm32_yml_ensure_default_value(verbose_build "false")
    if(verbose_build)
        message(STATUS "Включен подробный вывод команд сборки (CMAKE_VERBOSE_MAKEFILE=ON).")
        set(CMAKE_VERBOSE_MAKEFILE ON CACHE BOOL "Enable verbose build output" FORCE)
    else()
        set(CMAKE_VERBOSE_MAKEFILE OFF CACHE BOOL "Enable verbose build output" FORCE)
    endif()

    add_executable(${TARGET_NAME})

    # Определяем тип микроконтроллера для макросов.
    stm32_get_chip_info(${MCU} FAMILY MCU_FAMILY TYPE MCU_TYPE)
    target_compile_definitions(${TARGET_NAME} PRIVATE STM32${MCU_TYPE})

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
    target_compile_definitions(${TARGET_NAME} PRIVATE ${compile_definitions})
    target_compile_options(${TARGET_NAME} PRIVATE ${compile_options})

    # --- Флаги только для C ---
    if(compile_options_c)
        target_compile_options(${TARGET_NAME} PRIVATE
            $<$<COMPILE_LANGUAGE:C>:${compile_options_c}>)
        string(REPLACE ";" " " _c_opts_str "${compile_options_c}")
        message(STATUS "Флаги только для C:   ${_c_opts_str}")
    endif()
    if(compile_definitions_c)
        target_compile_definitions(${TARGET_NAME} PRIVATE
            $<$<COMPILE_LANGUAGE:C>:${compile_definitions_c}>)
        string(REPLACE ";" " " _c_defs_str "${compile_definitions_c}")
        message(STATUS "Defines только для C: ${_c_defs_str}")
    endif()

    # --- Флаги только для C++ ---
    if(compile_options_cxx)
        target_compile_options(${TARGET_NAME} PRIVATE
            $<$<COMPILE_LANGUAGE:CXX>:${compile_options_cxx}>)
        string(REPLACE ";" " " _cxx_opts_str "${compile_options_cxx}")
        message(STATUS "Флаги только для C++: ${_cxx_opts_str}")
    endif()
    if(compile_definitions_cxx)
        target_compile_definitions(${TARGET_NAME} PRIVATE
            $<$<COMPILE_LANGUAGE:CXX>:${compile_definitions_cxx}>)
        string(REPLACE ";" " " _cxx_defs_str "${compile_definitions_cxx}")
        message(STATUS "Defines только для C++: ${_cxx_defs_str}")
    endif()

    # 2.5 Контроль качества кода (Cppcheck, и т.д.).
    stm32_yml_setup_code_quality(${TARGET_NAME})

    # Опции и директивы линкера.
    if("map" IN_LIST build_artifacts)
        target_link_options(${TARGET_NAME} PRIVATE LINKER:-Map=${TARGET_NAME}.map)
    endif()
    target_link_options(${TARGET_NAME} PRIVATE ${link_options})
    # link_options уже нормализованы выше вместе с compile_options
    foreach(directive IN LISTS linker_directives)
        target_link_options(${TARGET_NAME} PRIVATE "LINKER:${directive}")
    endforeach()

    # 3. Подключение исходных файлов и папок.
    stm32_yml_setup_sources(${TARGET_NAME})

    # 4. Подключение драйверов и ОС (CMSIS, HAL, FreeRTOS, Newlib).
    stm32_yml_setup_frameworks(${TARGET_NAME})

    # 5. Настройка скрипта компоновщика (.ld).
    stm32_yml_setup_linker_script(${TARGET_NAME})

    # 6. Финальная линковка пользовательских библиотек
    set(CUSTOM_LIBRARY_PATHS "")
    if(DEFINED custom_libraries)
        foreach(lib_path IN LISTS custom_libraries)
            set(full_lib_path "${CMAKE_SOURCE_DIR}/${lib_path}")
            if(EXISTS ${full_lib_path})
                list(APPEND CUSTOM_LIBRARY_PATHS ${full_lib_path})
                message(STATUS "Подключение пользовательской библиотеки: ${full_lib_path}")
            else()
                message(WARNING "Пользовательская библиотека не найдена и будет проигнорирована: ${full_lib_path}")
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
