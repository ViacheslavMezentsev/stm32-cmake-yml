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

include("${CMAKE_CURRENT_LIST_DIR}/stm32_yml_arduino_board.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/stm32_yml_arduino_native.cmake")

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
        stm32_yml_msg(E501)
    endif()

    get_filename_component(_core_abs "${arduino_core_path}" ABSOLUTE BASE_DIR "${CMAKE_SOURCE_DIR}")

    if(NOT EXISTS "${_core_abs}")
        stm32_yml_msg(E502 "${_core_abs}")
    endif()

    stm32_yml_msg(I501 "${_core_abs}")

    # Режим backend (ТЗ 4.9.8); значение проверено в stm32_yml_setup_project().
    stm32_yml_msg(I508 "${arduino_integration}")

    # Пробрасываем путь в CACHE — CMakeLists.txt библиотек используют его
    # через get_filename_component(STM32_CORE_DIR ... ABSOLUTE).
    set(ARDUINO_CORE_DIR "${_core_abs}" CACHE PATH
        "Абсолютный путь к Arduino Core STM32." FORCE)

    if(arduino_integration STREQUAL "native")
        stm32_yml_setup_arduino_native(${TARGET_NAME} "${_core_abs}")
        _stm32_yml_arduino_custom_libraries()
        return()
    endif()

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
        # Предупреждение — после создания Arduino::Platform: обёртки на её основе
        # MCU_TARGET не используют.
        set(_mcu_target_missing TRUE)
        set(_mcu_target_val "")
    endif()

    if(NOT _mcu_target_val STREQUAL "")
        set(MCU_TARGET "${_mcu_target_val}" CACHE STRING
            "Целевой MCU для Arduino Core STM32 (например G431 или G474)." FORCE)
        stm32_yml_msg(I502 "${MCU_TARGET}")
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

    stm32_yml_msg(I503)

    # Arduino::Options и Arduino::Platform (ТЗ 4.9.15, 4.9.16) — до подключения
    # обёрток, чтобы они могли связываться с этими целями.
    stm32_yml_arduino_setup_wrappers_targets("${_core_abs}")
    if(_mcu_target_missing AND NOT TARGET ArduinoPlatform)
        stm32_yml_msg(W501)
    endif()

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
        stm32_yml_msg(I504 "${USE_CORE_MAIN}")
    endif()
    if(EXISTS "${_core_cmake_dir}/CMakeLists.txt")
        stm32_yml_msg(I505 "${_core_cmake_dir}")
        stm32_yml_add_subdirectory("${_core_cmake_dir}")
    else()
        stm32_yml_msg(W502 "${_core_cmake_dir}")
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
                stm32_yml_msg(I506 "${_lib}")
                stm32_yml_add_subdirectory("${_lib_dir}")
            else()
                stm32_yml_msg(W503 "${_lib}" "${_lib_dir}")
            endif()
        endforeach()
    endif()

    # Шаг 6: кастомные библиотеки пользователя.
    _stm32_yml_arduino_custom_libraries()

endfunction()

# ------------------------------------------------------------------
# Кастомные библиотеки пользователя (arduino.custom_libraries) в обоих
# режимах. Пути — относительно корня проекта.
# ------------------------------------------------------------------
function(_stm32_yml_arduino_custom_libraries)
    if(DEFINED arduino_custom_libraries AND arduino_custom_libraries)
        foreach(_custom_lib IN LISTS arduino_custom_libraries)
            set(_custom_lib_dir "${CMAKE_SOURCE_DIR}/${_custom_lib}")

            if(EXISTS "${_custom_lib_dir}/CMakeLists.txt")
                stm32_yml_msg(I507 "${_custom_lib}")
                # Каталог сборки — относительный путь или _deps/… (ТЗ 4.6.8).
                stm32_yml_add_subdirectory("${_custom_lib_dir}")
            else()
                stm32_yml_msg(W504 "${_custom_lib_dir}")
            endif()
        endforeach()
    endif()

endfunction()
