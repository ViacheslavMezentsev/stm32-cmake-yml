# ==============================================================================
# Модуль: POST-BUILD АРТЕФАКТЫ И CRC
# ==============================================================================
# Отвечает за генерацию .hex, .bin, .lss файлов, печать размера прошивки
# и внедрение контрольной суммы (CRC32) в собранный ELF файл.
# ==============================================================================

function(stm32_yml_setup_postbuild TARGET_NAME)
    # =======================================================================
    # 1. ВНЕДРЕНИЕ CRC32 В ПРОШИВКУ (POST-BUILD)
    # =======================================================================
    # Нормализуем строковое значение "false"/"true" в булево.
    # YAML-парсер всегда возвращает строки; "false"/"0"/"" -> FALSE, иначе -> TRUE.
    # Делаем это здесь, а не в config.cmake, потому что автоматический проброс
    # YAML_PARSED_KEYS выполняется последним и перезаписал бы нормализованное значение.
    # Нормализуем значение crc_enable в стандартный CMake-булев тип.
    # CMake string(JSON GET) возвращает булевы в ВЕРХНЕМ регистре ("FALSE"/"TRUE"),
    # поэтому сначала приводим к верхнему регистру, затем сравниваем.
    # Защитная нормализация: к этому моменту значение должно быть уже "TRUE"/"FALSE"
    # благодаря нормализации в парсере и в config.cmake. TOUPPER защищает от
    # любых непредвиденных путей (ручной set в CMakeLists.txt пользователя и т.п.)
    if(DEFINED crc_enable)
        string(TOUPPER "${crc_enable}" crc_enable)
    else()
        set(crc_enable "FALSE")
    endif()

    if(crc_enable)
        stm32_yml_msg(I701)

        # По умолчанию считаем, что внедрение возможно
        set(CRC_POSSIBLE TRUE)

        # ЗАЩИТА: Получаем эталонный размер FLASH (нужно для защиты от гигантских файлов)
        stm32_yml_ensure_default_value(flash_size "auto")

        if(NOT "${flash_size}" STREQUAL "auto" AND NOT "${flash_size}" STREQUAL "")
            # 1. Явно задано пользователем в stm32_config.yml
            set(EXPECTED_FLASH_SIZE_STR "${flash_size}")
        else()
            if(NOT toolchain_backend STREQUAL "arduino")
                # 2. Бэкенд stm32-cmake: берем из внутренней базы данных тулчейна
                # С учётом ядра (ТЗ 4.15.4): у двухъядерных H7 Flash делится между ядрами.
                stm32_yml_mcu_memory_size(FLASH _flash_bytes EXPECTED_FLASH_SIZE_STR)
            else()
                # 3. Бэкенд arduino: парсим размер прямо из скрипта компоновщика (.ld)
                set(EXPECTED_FLASH_SIZE_STR "")
                if(LINKER_SCRIPT_PATH AND EXISTS "${LINKER_SCRIPT_PATH}")
                    file(STRINGS "${LINKER_SCRIPT_PATH}" _ld_lines)
                    foreach(_line IN LISTS _ld_lines)
                        # Ищем строку вида: FLASH (rx) : ORIGIN = 0x8000000, LENGTH = 512K
                        if(_line MATCHES "FLASH.*LENGTH[ \t]*=[ \t]*([0-9]+[KkMmGg]?)")
                            set(EXPECTED_FLASH_SIZE_STR "${CMAKE_MATCH_1}")
                            break()
                        endif()
                    endforeach()
                endif()

                if("${EXPECTED_FLASH_SIZE_STR}" STREQUAL "")
                    stm32_yml_msg(W702 "${LINKER_SCRIPT_PATH}")
                    set(CRC_POSSIBLE FALSE)
                endif()
            endif()
        endif()

        if(CRC_POSSIBLE)
            # ТЗ 4.15.6: поддерживается только STM32_HW_DEFAULT (E004).
            stm32_yml_check_enum_value(crc_algorithm "STM32_HW_DEFAULT" STM32_HW_DEFAULT)

            # ТЗ 4.15.2: секцию CRC предоставляет скрипт компоновщика.
            # Пустой LINKER_SCRIPT_PATH означает скрипт, который формирует stm32-cmake:
            # секции CRC в нём нет, и сборка заведомо не сможет записать CRC.
            if(NOT LINKER_SCRIPT_PATH OR NOT EXISTS "${LINKER_SCRIPT_PATH}")
                stm32_yml_msg(E701 "${crc_section_name}")
            endif()
            file(READ "${LINKER_SCRIPT_PATH}" _ld_text)
            string(FIND "${_ld_text}" "${crc_section_name}" _crc_section_pos)
            if(_crc_section_pos EQUAL -1)
                stm32_yml_msg(W703 "${crc_section_name}" "${LINKER_SCRIPT_PATH}")
            endif()

            # ТЗ 4.15.9: образ CRC строится из секций в регионе FLASH итогового скрипта.
            stm32_yml_flash_region(CRC_FLASH_ORIGIN CRC_FLASH_LENGTH)
            if("${CRC_FLASH_ORIGIN}" STREQUAL "")
                stm32_yml_msg(W704 "${LINKER_SCRIPT_PATH}")
                set(CRC_POSSIBLE FALSE)
            endif()
        endif()

        if(CRC_POSSIBLE)
            # 1. Проверяем наличие Python
            find_package(Python3 COMPONENTS Interpreter QUIET)
            if(NOT Python3_FOUND)
                stm32_yml_msg(W705)
                set(CRC_POSSIBLE FALSE)
            endif()

            # 2. Проверяем наличие objcopy (запись CRC в секцию ELF)
            if(NOT CMAKE_OBJCOPY)
                stm32_yml_msg(W706)
                set(CRC_POSSIBLE FALSE)
            endif()

            # 3. Проверяем наличие скрипта (используем путь относительно текущего cmake-файла)
            set(CRC_SCRIPT_PATH "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../scripts/stm32_crc.py")
            if(NOT EXISTS ${CRC_SCRIPT_PATH})
                stm32_yml_msg(W707 "${CRC_SCRIPT_PATH}")
                set(CRC_POSSIBLE FALSE)
            endif()
        endif()

        # 4. Настраиваем Custom Command, если все проверки пройдены
        if(CRC_POSSIBLE)
            string(TOUPPER "${EXPECTED_FLASH_SIZE_STR}" EXPECTED_FLASH_SIZE_UPPER)

            if(EXPECTED_FLASH_SIZE_UPPER MATCHES "K$")
                string(REGEX REPLACE "K$" " * 1024" EXPECTED_FLASH_EXPR "${EXPECTED_FLASH_SIZE_UPPER}")
            elseif(EXPECTED_FLASH_SIZE_UPPER MATCHES "M$")
                string(REGEX REPLACE "M$" " * 1024 * 1024" EXPECTED_FLASH_EXPR "${EXPECTED_FLASH_SIZE_UPPER}")
            else()
                set(EXPECTED_FLASH_EXPR "${EXPECTED_FLASH_SIZE_UPPER}")
            endif()
            math(EXPR EXPECTED_FLASH_BYTES "${EXPECTED_FLASH_EXPR}")

            stm32_yml_msg(I711 "${crc_method}")
            stm32_yml_msg(I702 "${crc_section_name}")
            stm32_yml_msg(I712)
            stm32_yml_msg(I703 "${crc_algorithm}")
            stm32_yml_msg(I704 "${CRC_FLASH_ORIGIN}" "${CRC_FLASH_LENGTH}")
            stm32_yml_msg(I705 "${EXPECTED_FLASH_BYTES}" "${EXPECTED_FLASH_SIZE_STR}")

            # Имена промежуточных файлов: образ Flash без CRC (для диагностики) и значение CRC
            set(BIN_NO_CRC "${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}_no_crc.bin")
            set(CRC_VAL_BIN "${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}_crc_val.bin")
            set(TARGET_ELF "$<TARGET_FILE:${TARGET_NAME}>")

            get_property(_build_messages GLOBAL PROPERTY _STM32_YML_BUILD_MESSAGES)
            add_custom_command(TARGET ${TARGET_NAME} POST_BUILD
                # ТЗ 4.15.9, 4.15.12: образ FLASH, расчёт и внедрение CRC.
                # Любой сбой скрипта или objcopy завершает сборку ошибкой.
                COMMAND ${Python3_EXECUTABLE} ${CRC_SCRIPT_PATH}
                        --messages ${_build_messages}
                        --elf ${TARGET_ELF}
                        --flash ${CRC_FLASH_ORIGIN}:${CRC_FLASH_LENGTH}
                        --exclude ${crc_section_name}
                        --objcopy ${CMAKE_OBJCOPY}
                        --image ${BIN_NO_CRC}
                        ${CRC_VAL_BIN} ${EXPECTED_FLASH_BYTES}

                VERBATIM
            )
        else()
            stm32_yml_msg(I706)
        endif()
    endif()

    # =======================================================================
    # 2. ГЕНЕРАЦИЯ АРТЕФАКТОВ СБОРКИ (BIN, HEX, SREC, LSS, SIZE; ТЗ 4.14.2)
    # =======================================================================

    # Выводим размер потребляемой памяти (RAM/FLASH)
    stm32_print_size_of_target(${TARGET_NAME})

    # Генерируем запрошенные пользователем файлы из YAML
    if("bin" IN_LIST build_artifacts)
        stm32_yml_generate_bin_file(${TARGET_NAME})
    endif()

    if("hex" IN_LIST build_artifacts)
        stm32_yml_generate_objcopy_file(${TARGET_NAME} hex ihex)
    endif()

    if("srec" IN_LIST build_artifacts)
        stm32_yml_generate_objcopy_file(${TARGET_NAME} srec srec)
    endif()

    if("lss" IN_LIST build_artifacts)
        stm32_yml_generate_lss_file(${TARGET_NAME})
    endif()

endfunction()
