# ==============================================================================
# Модуль: ПОДДЕРЖКА ARDUINO CORE STM32 КАК TOOLCHAIN BACKEND.
# ==============================================================================
# Активируется при toolchain_backend: arduino в stm32_config.yml.
# Берёт на себя:
#   - создание INTERFACE-таргета Arduino::Definitions с compile_definitions
#     и compile_options из yml;
#   - подключение стандартных библиотек Arduino Core STM32 через
#     add_subdirectory по списку arduino.libraries;
#   - подключение пользовательского ядра (Arduino/Core или путь из
#     arduino.core_cmake_dir) через add_subdirectory;
#   - подключение кастомных библиотек из arduino.custom_libraries;
#   - проброс MCU_TARGET и ARDUINO_CORE_DIR в CACHE для использования
#     в CMakeLists.txt подключаемых библиотек.
#
# Toolchain (CMAKE_TOOLCHAIN_FILE) остаётся в CMakeLists.txt проекта —
# фреймворк его не касается.
# ==============================================================================

# ==============================================================================
# @brief Настраивает Arduino Core STM32 как backend сборки.
#
# Вызывается из stm32_yml_setup_project() вместо stm32_yml_setup_frameworks()
# когда toolchain_backend == "arduino".
#
# @param TARGET_NAME  Имя основного cmake-таргета проекта.
# ==============================================================================
function(stm32_yml_setup_arduino TARGET_NAME)

    # ------------------------------------------------------------------
    # Шаг 1: проверяем наличие arduino.core_path.
    # ------------------------------------------------------------------
    if(NOT DEFINED arduino_core_path OR arduino_core_path STREQUAL "")
        message(FATAL_ERROR
            "[arduino] Параметр arduino.core_path не задан в stm32_config.yml.\n"
            "Укажите путь к папке Arduino_Core_STM32 относительно корня проекта:\n"
            "  arduino:\n"
            "    core_path: \"modules/Arduino_Core_STM32\"")
    endif()

    set(_core_abs "${CMAKE_SOURCE_DIR}/${arduino_core_path}")

    if(NOT EXISTS "${_core_abs}")
        message(FATAL_ERROR
            "[arduino] Папка Arduino Core STM32 не найдена: ${_core_abs}\n"
            "Проверьте значение arduino.core_path в stm32_config.yml.\n"
            "В CI убедитесь, что симлинк или папка modules/Arduino_Core_STM32 существует.")
    endif()

    message(STATUS "Arduino Core STM32: ${_core_abs}")

    # Пробрасываем путь в CACHE — CMakeLists.txt библиотек используют его
    # через get_filename_component(STM32_CORE_DIR ... ABSOLUTE).
    set(ARDUINO_CORE_DIR "${_core_abs}" CACHE PATH
        "Абсолютный путь к Arduino Core STM32." FORCE)

    # ------------------------------------------------------------------
    # Шаг 2: пробрасываем MCU_TARGET в CACHE.
    # Arduino/Core/CMakeLists.txt и variant-файлы используют MCU_TARGET
    # для выбора папки variant и дополнительных исходников.
    # Значение берётся из переменной mcu_target (из yml или профиля).
    # ------------------------------------------------------------------
    if(DEFINED arduino_mcu_target AND NOT arduino_mcu_target STREQUAL "")
        set(_mcu_target_val "${arduino_mcu_target}")
    elseif(DEFINED MCU_TARGET AND NOT MCU_TARGET STREQUAL "")
        # Уже задан снаружи через -DMCU_TARGET= — не перезаписываем.
        set(_mcu_target_val "${MCU_TARGET}")
    else()
        message(WARNING
            "[arduino] Параметр arduino.mcu_target не задан. "
            "CMakeLists.txt библиотек, зависящих от MCU_TARGET, могут завершиться ошибкой.")
        set(_mcu_target_val "")
    endif()

    if(NOT _mcu_target_val STREQUAL "")
        set(MCU_TARGET "${_mcu_target_val}" CACHE STRING
            "Целевой MCU для Arduino Core STM32 (например G431 или G474)." FORCE)
        message(STATUS "Arduino MCU_TARGET: ${MCU_TARGET}")
    endif()

    # ------------------------------------------------------------------
    # Шаг 3: создаём INTERFACE-таргет Arduino::Definitions.
    # Содержит compile_definitions и compile_options из yml.
    # Пользовательские CMakeLists.txt библиотек линкуются с ним через
    # target_link_libraries(... Arduino::Definitions).
    # ------------------------------------------------------------------
    if(NOT TARGET ArduinoDefinitions)
        add_library(ArduinoDefinitions INTERFACE)
        add_library(Arduino::Definitions ALIAS ArduinoDefinitions)
    endif()

    # Нормализуем флаги перед применением.
    stm32_yml_normalize_flags(compile_definitions NO_AUTO_DASH)
    stm32_yml_normalize_flags(compile_options)
    stm32_yml_normalize_flags(compile_options_c)
    stm32_yml_normalize_flags(compile_options_cxx)

    if(compile_definitions)
        target_compile_definitions(ArduinoDefinitions INTERFACE ${compile_definitions})
    endif()

    if(compile_options)
        target_compile_options(ArduinoDefinitions INTERFACE ${compile_options})
    endif()

    if(compile_options_c)
        target_compile_options(ArduinoDefinitions INTERFACE
            $<$<COMPILE_LANGUAGE:C>:${compile_options_c}>)
    endif()

    if(compile_options_cxx)
        target_compile_options(ArduinoDefinitions INTERFACE
            $<$<COMPILE_LANGUAGE:CXX>:${compile_options_cxx}>)
    endif()

    message(STATUS "Arduino::Definitions создан.")

    # ------------------------------------------------------------------
    # Шаг 4: подключаем пользовательское ядро Arduino (Arduino/Core).
    # По умолчанию ищем в <PROJECT_ROOT>/Arduino/Core.
    # Переопределяется через arduino.core_cmake_dir.
    # ------------------------------------------------------------------
    if(DEFINED arduino_core_cmake_dir AND NOT arduino_core_cmake_dir STREQUAL "")
        set(_core_cmake_dir "${CMAKE_SOURCE_DIR}/${arduino_core_cmake_dir}")
    else()
        set(_core_cmake_dir "${CMAKE_SOURCE_DIR}/Arduino/Core")
    endif()

    # Пробрасываем флаг use_core_main из YAML в CACHE.
    if(DEFINED arduino_use_core_main)
        set(USE_CORE_MAIN ${arduino_use_core_main} CACHE BOOL "Include default Arduino main file" FORCE)
        message(STATUS "Arduino USE_CORE_MAIN: ${USE_CORE_MAIN}")
    endif()
    if(EXISTS "${_core_cmake_dir}/CMakeLists.txt")
        message(STATUS "Подключение Arduino Core: ${_core_cmake_dir}")
        add_subdirectory("${_core_cmake_dir}" "${CMAKE_BINARY_DIR}/arduino_core")
    else()
        message(WARNING
            "[arduino] CMakeLists.txt ядра Arduino не найден: ${_core_cmake_dir}\n"
            "Укажите правильный путь через arduino.core_cmake_dir в stm32_config.yml.")
    endif()

    # ------------------------------------------------------------------
    # Шаг 5: подключаем стандартные библиотеки Arduino Core STM32.
    # Список задаётся через arduino.libraries в yml.
    # Каждая библиотека ищется в <core_path>/libraries/<LibName>.
    # ------------------------------------------------------------------
    if(DEFINED arduino_libraries AND arduino_libraries)
        foreach(_lib IN LISTS arduino_libraries)
            set(_lib_dir "${_core_abs}/libraries/${_lib}")

            if(EXISTS "${_lib_dir}/CMakeLists.txt")
                message(STATUS "Подключение Arduino библиотеки: ${_lib}")
                add_subdirectory("${_lib_dir}" "${CMAKE_BINARY_DIR}/arduino_lib_${_lib}")
            else()
                message(WARNING
                    "[arduino] Библиотека '${_lib}' не найдена в ${_lib_dir}.\n"
                    "Проверьте имя в arduino.libraries и наличие CMakeLists.txt.")
            endif()
        endforeach()
    endif()

    # ------------------------------------------------------------------
    # Шаг 6: подключаем кастомные библиотеки пользователя.
    # Список задаётся через arduino.custom_libraries в yml.
    # Пути — относительно корня проекта.
    # ------------------------------------------------------------------
    if(DEFINED arduino_custom_libraries AND arduino_custom_libraries)
        foreach(_custom_lib IN LISTS arduino_custom_libraries)
            set(_custom_lib_dir "${CMAKE_SOURCE_DIR}/${_custom_lib}")

            if(EXISTS "${_custom_lib_dir}/CMakeLists.txt")
                message(STATUS "Подключение кастомной библиотеки: ${_custom_lib}")
                get_filename_component(_custom_lib_name "${_custom_lib}" NAME)
                add_subdirectory("${_custom_lib_dir}"
                    "${CMAKE_BINARY_DIR}/arduino_custom_${_custom_lib_name}")
            else()
                message(WARNING
                    "[arduino] Кастомная библиотека не найдена: ${_custom_lib_dir}.")
            endif()
        endforeach()
    endif()

endfunction()
