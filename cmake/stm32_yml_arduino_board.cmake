# ==============================================================================
# Модуль: ПЛАТА И CMSIS ДЛЯ BACKEND ARDUINO (ТЗ 4.9.10, 4.9.14, 4.9.15)
# ==============================================================================
# Плата берётся из базы cmake/boards_db.cmake ядра Arduino_Core_STM32 без
# updatedb() и Python: из файла читается только блок выбранной платы (около
# 20 интерфейсных целей вместо 13 тысяч у всей базы). Блок начинается строкой
# "# <ID>" и строкой из дефисов; если формат другой, Configure останавливается.
# ==============================================================================

include_guard(GLOBAL)

# Идентификаторы плат базы (заголовки блоков "# <ID>" перед строкой "# ---").
function(_stm32_yml_arduino_board_ids DB OUT_VAR)
    file(STRINGS "${DB}" _lines REGEX "^# ([A-Za-z0-9_]+|-+)$")
    set(_ids "")
    set(_previous "")
    foreach(_line IN LISTS _lines)
        if(_line MATCHES "^# -+$" AND _previous MATCHES "^# ([A-Za-z0-9_]+)$")
            list(APPEND _ids "${CMAKE_MATCH_1}")
        endif()
        set(_previous "${_line}")
    endforeach()
    set(${OUT_VAR} "${_ids}" PARENT_SCOPE)
endfunction()

# ==============================================================================
# Выбор платы по ТЗ 4.9.10.
#
# @param CORE      - Абсолютный путь к Arduino_Core_STM32.
# @param REQUESTED - Значение arduino.board (ID или auto).
# @param OUT_BOARD - Переменная для ID платы; пусто, если выбрать не удалось.
# @param OUT_INFO  - Переменная для кандидатов через запятую (при неудаче).
# ==============================================================================
function(stm32_yml_arduino_select_board CORE REQUESTED OUT_BOARD OUT_INFO)
    set(_db "${CORE}/cmake/boards_db.cmake")
    if(NOT EXISTS "${_db}")
        stm32_yml_msg(E509 "${_db}")
    endif()
    _stm32_yml_arduino_board_ids("${_db}" _ids)
    set(${OUT_BOARD} "" PARENT_SCOPE)
    set(${OUT_INFO} "" PARENT_SCOPE)

    if(NOT REQUESTED STREQUAL "auto")
        if(NOT REQUESTED IN_LIST _ids)
            stm32_yml_msg(E503 "${REQUESTED}" "${_db}")
        endif()
        set(${OUT_BOARD} "${REQUESTED}" PARENT_SCOPE)
        return()
    endif()

    # GENERIC_ + первые семь символов MCU без префикса STM32 + X.
    string(TOUPPER "${MCU}" _mcu)
    string(REGEX REPLACE "^STM32" "" _name "${_mcu}")
    set(_candidates "")
    string(LENGTH "${_name}" _length)
    if(_length GREATER_EQUAL 7)
        string(SUBSTRING "${_name}" 0 7 _prefix)
        set(_exact "GENERIC_${_prefix}X")
        if(_exact IN_LIST _ids)
            set(${OUT_BOARD} "${_exact}" PARENT_SCOPE)
            return()
        endif()
        # Единственный идентификатор с одной буквой суффикса (GENERIC_U575ZITXQ).
        foreach(_id IN LISTS _ids)
            if(_id MATCHES "^${_exact}[A-Z]$")
                list(APPEND _candidates "${_id}")
            endif()
        endforeach()
        list(LENGTH _candidates _count)
        if(_count EQUAL 1)
            set(${OUT_BOARD} "${_candidates}" PARENT_SCOPE)
            return()
        endif()
    endif()
    # Подсказка: идентификаторы GENERIC_ с тем же началом имени MCU.
    if(NOT _candidates AND NOT _name STREQUAL "")
        string(LENGTH "${_name}" _hint_length)
        if(_hint_length GREATER 7)
            set(_hint_length 7)
        endif()
        string(SUBSTRING "${_name}" 0 ${_hint_length} _hint)
        foreach(_id IN LISTS _ids)
            string(FIND "${_id}" "GENERIC_${_hint}" _pos)
            if(_pos EQUAL 0)
                list(APPEND _candidates "${_id}")
            endif()
        endforeach()
    endif()
    if(_candidates)
        string(REPLACE ";" ", " _text "${_candidates}")
    else()
        set(_text "-")
    endif()
    set(${OUT_INFO} "${_text}" PARENT_SCOPE)
endfunction()

# ==============================================================================
# Создаёт цели выбранной платы из её блока boards_db.cmake и подключает
# варианты по умолчанию, как set_board(): serial generic, USB none, VirtIO
# disable, если они есть у платы.
#
# @param CORE   - Абсолютный путь к Arduino_Core_STM32.
# @param BOARD  - ID платы.
# ==============================================================================
function(stm32_yml_arduino_load_board CORE BOARD)
    set(_db "${CORE}/cmake/boards_db.cmake")
    if(TARGET ${BOARD})
        stm32_yml_msg(E508 "${BOARD}")
    endif()
    file(READ "${_db}" _text)
    string(PREPEND _text "\n")
    string(FIND "${_text}" "\n# ${BOARD}\n# ---" _start)
    if(_start EQUAL -1)
        stm32_yml_msg(E509 "${_db}")
    endif()
    math(EXPR _start "${_start} + 1")
    string(SUBSTRING "${_text}" ${_start} -1 _block)
    # Конец блока — заголовок следующей платы.
    string(REGEX MATCH "\n# [A-Za-z0-9_]+\n# ---" _next "${_block}")
    if(_next)
        string(FIND "${_block}" "${_next}" _end)
        string(SUBSTRING "${_block}" 0 ${_end} _block)
    endif()
    if(NOT _block MATCHES "add_library\\(${BOARD} INTERFACE\\)")
        stm32_yml_msg(E509 "${_db}")
    endif()
    get_filename_component(_db_dir "${_db}" DIRECTORY)
    # Пути вида <core>/cmake/../system приводятся к <core>/system.
    string(REPLACE "\${CMAKE_CURRENT_LIST_DIR}/../" "${CORE}/" _block "${_block}")
    string(REPLACE "\${CMAKE_CURRENT_LIST_DIR}" "${_db_dir}" _block "${_block}")
    cmake_language(EVAL CODE "${_block}")
    foreach(_variant IN ITEMS serial_generic usb_none virtio_disable)
        if(TARGET ${BOARD}_${_variant})
            target_link_libraries(${BOARD} INTERFACE ${BOARD}_${_variant})
        endif()
    endforeach()
    set(ARDUINO_VARIANT_PATH "${${BOARD}_VARIANT_PATH}" PARENT_SCOPE)
endfunction()

# Каталог с CMSIS/Core/Include/cmsis_version.h.
function(_stm32_yml_cmsis_valid DIR OUT_VAR)
    if(EXISTS "${DIR}/CMSIS/Core/Include/cmsis_version.h")
        set(${OUT_VAR} TRUE PARENT_SCOPE)
    else()
        set(${OUT_VAR} FALSE PARENT_SCOPE)
    endif()
endfunction()

# Самая новая версия среди каталогов (по имени каталога).
function(_stm32_yml_newest_dir OUT_VAR)
    set(_best "")
    set(_best_version "0")
    foreach(_dir IN LISTS ARGN)
        get_filename_component(_name "${_dir}" NAME)
        set(_version "0")
        if(_name MATCHES "([0-9]+(\\.[0-9]+)*)")
            set(_version "${CMAKE_MATCH_1}")
        endif()
        if(_best STREQUAL "" OR _version VERSION_GREATER _best_version)
            set(_best "${_dir}")
            set(_best_version "${_version}")
        endif()
    endforeach()
    set(${OUT_VAR} "${_best}" PARENT_SCOPE)
endfunction()

# ==============================================================================
# Источник CMSIS по ТЗ 4.9.14.
#
# @param OUT_DIR     - Каталог, содержащий CMSIS/Core/Include; пусто — не найден
#                      или external.
# @param OUT_SOURCE  - Метка источника: arduino.cmsis_path, Arduino15,
#                      Arduino_Core_STM32_dl, STM32Cube, external.
# @param OUT_PLACES  - Места поиска через "; " (если не найден).
# ==============================================================================
function(stm32_yml_arduino_find_cmsis OUT_DIR OUT_SOURCE OUT_PLACES)
    set(${OUT_DIR} "" PARENT_SCOPE)
    set(${OUT_PLACES} "" PARENT_SCOPE)
    if(arduino_cmsis_path STREQUAL "external")
        set(${OUT_SOURCE} "external" PARENT_SCOPE)
        return()
    endif()
    if(NOT "${arduino_cmsis_path}" STREQUAL "")
        get_filename_component(_dir "${arduino_cmsis_path}" ABSOLUTE BASE_DIR "${CMAKE_SOURCE_DIR}")
        _stm32_yml_cmsis_valid("${_dir}" _ok)
        if(NOT _ok)
            stm32_yml_msg(E505 "${_dir}")
        endif()
        set(${OUT_DIR} "${_dir}" PARENT_SCOPE)
        set(${OUT_SOURCE} "arduino.cmsis_path" PARENT_SCOPE)
        return()
    endif()

    set(_places "")
    # 1. Установка Arduino IDE.
    if(CMAKE_HOST_WIN32)
        set(_arduino15 "$ENV{LOCALAPPDATA}/Arduino15")
        set(_home "$ENV{USERPROFILE}")
    elseif(CMAKE_HOST_APPLE)
        set(_arduino15 "$ENV{HOME}/Library/Arduino15")
        set(_home "$ENV{HOME}")
    else()
        set(_arduino15 "$ENV{HOME}/.arduino15")
        set(_home "$ENV{HOME}")
    endif()
    file(TO_CMAKE_PATH "${_arduino15}" _arduino15)
    file(TO_CMAKE_PATH "${_home}" _home)
    set(_tools "${_arduino15}/packages/STMicroelectronics/tools/CMSIS")
    list(APPEND _places "${_tools}/<version>")
    file(GLOB _dirs LIST_DIRECTORIES true "${_tools}/*")
    set(_valid "")
    foreach(_dir IN LISTS _dirs)
        _stm32_yml_cmsis_valid("${_dir}" _ok)
        if(_ok)
            list(APPEND _valid "${_dir}")
        endif()
    endforeach()
    if(_valid)
        _stm32_yml_newest_dir(_dir ${_valid})
        set(${OUT_DIR} "${_dir}" PARENT_SCOPE)
        set(${OUT_SOURCE} "Arduino15" PARENT_SCOPE)
        return()
    endif()

    # 2. Кэш загрузок ядра (ensure_core_deps()).
    set(_cache "${_home}/.Arduino_Core_STM32_dl")
    list(APPEND _places "${_cache}/*/dist/CMSIS6")
    file(GLOB _dirs LIST_DIRECTORIES true "${_cache}/*/dist/CMSIS6")
    list(SORT _dirs)
    foreach(_dir IN LISTS _dirs)
        _stm32_yml_cmsis_valid("${_dir}" _ok)
        if(_ok)
            set(${OUT_DIR} "${_dir}" PARENT_SCOPE)
            set(${OUT_SOURCE} "Arduino_Core_STM32_dl" PARENT_SCOPE)
            return()
        endif()
    endforeach()

    # 3. Drivers пакета STM32Cube семейства (CMSIS 5): локальный Drivers/,
    # явный cubefw_package или самый новый пакет репозитория (как ТЗ 4.7.2).
    string(TOUPPER "${MCU}" _mcu)
    if(_mcu MATCHES "^STM32([A-Z][0-9A-Z])")
        set(_family "${CMAKE_MATCH_1}")
        set(_repo "$ENV{CMAKE_USER_HOME}")
        file(TO_CMAKE_PATH "${_repo}" _repo)
        set(_repo "${_repo}/STM32Cube/Repository")
        set(_drivers "")
        if(NOT "${cubefw_package}" STREQUAL "" AND NOT cubefw_package STREQUAL "auto")
            set(_drivers "${_repo}/STM32Cube_FW_${_family}_${cubefw_package}/Drivers")
            list(APPEND _places "${_drivers}")
        else()
            list(APPEND _places "${CMAKE_SOURCE_DIR}/Drivers" "${_repo}/STM32Cube_FW_${_family}_V*/Drivers")
            _stm32_yml_cmsis_valid("${CMAKE_SOURCE_DIR}/Drivers" _ok)
            if(_ok)
                set(_drivers "${CMAKE_SOURCE_DIR}/Drivers")
            else()
                file(GLOB _packages LIST_DIRECTORIES true "${_repo}/STM32Cube_FW_${_family}_V*")
                if(_packages)
                    _stm32_yml_newest_dir(_package ${_packages})
                    set(_drivers "${_package}/Drivers")
                endif()
            endif()
        endif()
        if(NOT _drivers STREQUAL "")
            _stm32_yml_cmsis_valid("${_drivers}" _ok)
            if(_ok)
                # Предупреждение — только при явной плате; при значениях по умолчанию
                # конфигурации 0.9.3 без Arduino::Platform не получают нового
                # предупреждения (ТЗ 7.7).
                if("${arduino_board}" STREQUAL "")
                    stm32_yml_msg(I518 "${_drivers}")
                else()
                    stm32_yml_msg(W505 "${_drivers}")
                endif()
                set(${OUT_DIR} "${_drivers}" PARENT_SCOPE)
                set(${OUT_SOURCE} "STM32Cube" PARENT_SCOPE)
                return()
            endif()
        endif()
    endif()

    string(REPLACE ";" "; " _places "${_places}")
    set(${OUT_PLACES} "${_places}" PARENT_SCOPE)
    set(${OUT_SOURCE} "" PARENT_SCOPE)
endfunction()

# ==============================================================================
# Режим wrappers: Arduino::Options и Arduino::Platform (ТЗ 4.9.15, 4.9.16).
# При значениях по умолчанию (arduino.board и arduino.cmsis_path не заданы)
# неудача выбора платы или поиска CMSIS — сообщение без Arduino::Platform,
# чтобы конфигурации 0.9.3 продолжали работать (ТЗ 7.7).
#
# @param CORE  - Абсолютный путь к Arduino_Core_STM32.
# ==============================================================================
function(stm32_yml_arduino_setup_wrappers_targets CORE)
    # Arduino::Options: общие и языковые compile_options.
    if(NOT TARGET ArduinoOptions)
        add_library(ArduinoOptions INTERFACE)
        add_library(Arduino::Options ALIAS ArduinoOptions)
    endif()
    if(compile_options)
        target_compile_options(ArduinoOptions INTERFACE ${compile_options})
    endif()
    if(compile_options_c)
        target_compile_options(ArduinoOptions INTERFACE $<$<COMPILE_LANGUAGE:C>:${compile_options_c}>)
    endif()
    if(compile_options_cxx)
        target_compile_options(ArduinoOptions INTERFACE $<$<COMPILE_LANGUAGE:CXX>:${compile_options_cxx}>)
    endif()

    set(_explicit FALSE)
    if(NOT "${arduino_board}" STREQUAL "" OR NOT "${arduino_cmsis_path}" STREQUAL "")
        set(_explicit TRUE)
    endif()
    set(_requested "${arduino_board}")
    if(_requested STREQUAL "")
        if("${MCU}" STREQUAL "")
            stm32_yml_msg(I510)
            return()
        endif()
        set(_requested auto)
    endif()

    if(NOT EXISTS "${CORE}/cmake/boards_db.cmake")
        if(_explicit)
            stm32_yml_msg(E509 "${CORE}/cmake/boards_db.cmake")
        endif()
        stm32_yml_msg(I517 "${CORE}/cmake/boards_db.cmake")
        return()
    endif()
    stm32_yml_arduino_select_board("${CORE}" "${_requested}" _board _candidates)
    if(_board STREQUAL "")
        if(_explicit)
            stm32_yml_msg(E504 "${MCU}" "${_candidates}")
        endif()
        stm32_yml_msg(I511 "${MCU}" "${_candidates}")
        return()
    endif()

    stm32_yml_arduino_find_cmsis(_cmsis _cmsis_source _places)
    if(_cmsis_source STREQUAL "")
        if(_explicit)
            stm32_yml_msg(E506 "${_places}")
        endif()
        stm32_yml_msg(I512 "${_places}")
        return()
    endif()

    stm32_yml_arduino_load_board("${CORE}" "${_board}")
    stm32_yml_msg(I509 "${_board}" "${_requested}")

    add_library(ArduinoPlatform INTERFACE)
    add_library(Arduino::Platform ALIAS ArduinoPlatform)
    # Флаги ядра и FPU, определения и include-каталоги платы. Параметры
    # компоновщика платы (--default-script, --defsym) не переносятся: скрипт
    # компоновщика в режиме wrappers задаёт фреймворк (ТЗ 4.11).
    foreach(_property IN ITEMS INTERFACE_COMPILE_OPTIONS INTERFACE_COMPILE_DEFINITIONS
            INTERFACE_INCLUDE_DIRECTORIES INTERFACE_LINK_LIBRARIES)
        get_target_property(_value ${_board} ${_property})
        if(_value)
            set_property(TARGET ArduinoPlatform PROPERTY ${_property} "${_value}")
        endif()
    endforeach()
    get_target_property(_link_options ${_board} INTERFACE_LINK_OPTIONS)
    if(_link_options)
        list(FILTER _link_options EXCLUDE REGEX "^LINKER:")
        set_property(TARGET ArduinoPlatform PROPERTY INTERFACE_LINK_OPTIONS "${_link_options}")
    endif()
    target_link_options(ArduinoPlatform INTERFACE -mthumb)
    # Общие настройки base_config ядра (cmake/set_base_arduino_config.cmake).
    set(_cores "${CORE}/cores/arduino")
    set(_libraries "${CORE}/libraries")
    target_compile_definitions(ArduinoPlatform INTERFACE USE_HAL_DRIVER USE_FULL_LL_DRIVER ARDUINO_ARCH_STM32)
    target_compile_options(ArduinoPlatform INTERFACE
        -mthumb
        "SHELL:--param max-inline-insns-single=500"
        $<$<COMPILE_LANGUAGE:CXX>:-fno-rtti>
        $<$<COMPILE_LANGUAGE:CXX>:-fno-exceptions>
        $<$<COMPILE_LANGUAGE:CXX>:-fno-use-cxa-atexit>
        $<$<COMPILE_LANGUAGE:CXX>:-fno-threadsafe-statics>
        -ffunction-sections
        -fdata-sections)
    target_include_directories(ArduinoPlatform INTERFACE
        "${_cores}" "${_cores}/avr" "${_cores}/stm32"
        "${_libraries}/SrcWrapper/inc" "${_libraries}/SrcWrapper/inc/LL")
    set(ARDUINO_VARIANT_PATH "${ARDUINO_VARIANT_PATH}" CACHE PATH
        "Каталог variant выбранной платы Arduino / variant directory of the Arduino board." FORCE)
    set(ARDUINO_BOARD "${_board}" CACHE STRING "Плата Arduino / Arduino board ID." FORCE)

    stm32_yml_arduino_attach_cmsis(ArduinoPlatform "${_cmsis}" "${_cmsis_source}")
    stm32_yml_msg(I513 "${_board}")
endfunction()

# ==============================================================================
# Подключает CMSIS к интерфейсной цели (ArduinoPlatform или user_settings).
# ==============================================================================
function(stm32_yml_arduino_attach_cmsis TARGET DIR SOURCE)
    if(SOURCE STREQUAL "external")
        if(NOT "${arduino_cmsis_target}" STREQUAL "")
            target_link_libraries(${TARGET} INTERFACE ${arduino_cmsis_target})
            stm32_yml_msg(I515 "${arduino_cmsis_target}")
            # Цель проекта может появиться позже вызова фреймворка.
            cmake_language(EVAL CODE
                "cmake_language(DEFER CALL _stm32_yml_check_cmsis_target [[${arduino_cmsis_target}]])")
        else()
            stm32_yml_msg(I516)
        endif()
        return()
    endif()
    target_include_directories(${TARGET} INTERFACE "${DIR}/CMSIS/Core/Include")
    stm32_yml_msg(I514 "${DIR}" "${SOURCE}")
endfunction()

function(_stm32_yml_check_cmsis_target NAME)
    if(NOT TARGET ${NAME})
        stm32_yml_msg(E507 "${NAME}")
    endif()
endfunction()
