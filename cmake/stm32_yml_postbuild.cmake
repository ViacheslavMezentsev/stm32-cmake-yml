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
        message(STATUS "Настройка механизма внедрения CRC32 в прошивку...")

        # По умолчанию считаем, что внедрение возможно
        set(CRC_POSSIBLE TRUE)

        # 1. Проверяем наличие Python
        find_package(Python3 COMPONENTS Interpreter QUIET)
        if(NOT Python3_FOUND)
            message(WARNING " Интерпретатор Python3 не найден. Расчет CRC отключен.")
            set(CRC_POSSIBLE FALSE)
        endif()

        # 2. Проверяем наличие objcopy
        if(NOT CMAKE_OBJCOPY)
            message(WARNING " Утилита objcopy не найдена. Расчет CRC отключен.")
            set(CRC_POSSIBLE FALSE)
        endif()

        # 3. Проверяем наличие скрипта (используем путь к фреймворку)
        set(CRC_SCRIPT_PATH "${STM32_YML_FRAMEWORK_DIR}/scripts/stm32_crc.py")
        if(NOT EXISTS ${CRC_SCRIPT_PATH})
            message(WARNING " Скрипт расчета не найден по пути: ${CRC_SCRIPT_PATH}. Расчет CRC отключен.")
            set(CRC_POSSIBLE FALSE)
        endif()

        # 4. Настраиваем Custom Command, если все проверки пройдены
        if(CRC_POSSIBLE)
            # ЗАЩИТА: Получаем эталонный размер FLASH.
            stm32_get_memory_info(CHIP ${mcu} FLASH SIZE EXPECTED_FLASH_SIZE_STR)
            string(TOUPPER "${EXPECTED_FLASH_SIZE_STR}" EXPECTED_FLASH_SIZE_UPPER)

            if(EXPECTED_FLASH_SIZE_UPPER MATCHES "K$")
                string(REGEX REPLACE "K$" " * 1024" EXPECTED_FLASH_EXPR "${EXPECTED_FLASH_SIZE_UPPER}")
            elseif(EXPECTED_FLASH_SIZE_UPPER MATCHES "M$")
                string(REGEX REPLACE "M$" " * 1024 * 1024" EXPECTED_FLASH_EXPR "${EXPECTED_FLASH_SIZE_UPPER}")
            else()
                set(EXPECTED_FLASH_EXPR "${EXPECTED_FLASH_SIZE_UPPER}")
            endif()
            math(EXPR EXPECTED_FLASH_BYTES "${EXPECTED_FLASH_EXPR}")

            message(STATUS " Метод: Внедрение в секцию '${crc_section_name}'")
            message(STATUS " Алгоритм: ${crc_algorithm}")
            message(STATUS " Max Flash Size: ${EXPECTED_FLASH_BYTES} байт (${EXPECTED_FLASH_SIZE_STR})")
            message(STATUS " ВАЖНО: Убедитесь, что секция '${crc_section_name}' существует в вашем .ld файле, иначе сборка упадет с ошибкой!")

            # Имена временных файлов
            set(BIN_NO_CRC "${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}_no_crc.bin")
            set(CRC_VAL_BIN "${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}_crc_val.bin")
            set(TARGET_ELF "$<TARGET_FILE:${TARGET_NAME}>")

            # Жестко вырезаем секции, которые могут вызвать gap-fill
            set(OBJCOPY_EXCLUDES
                "-R" ".ARM.attributes"
                "-R" ".comment"
                "-R" ".debug_*"
            )

            add_custom_command(TARGET ${TARGET_NAME} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E echo " "
                COMMAND ${CMAKE_COMMAND} -E echo "--- Injecting checksum into ${crc_section_name} ---"

                # Шаг 1: Создаем BIN из ELF без секции CRC.
                # Вырезаем CRC и мусорные секции перед созданием .bin.
                COMMAND ${CMAKE_OBJCOPY} -O binary --gap-fill 0xFF ${OBJCOPY_EXCLUDES} --remove-section=${crc_section_name} ${TARGET_ELF} ${BIN_NO_CRC}

                # Шаг 2: Запускаем Python скрипт для расчета CRC.
                COMMAND ${Python3_EXECUTABLE} ${CRC_SCRIPT_PATH} ${BIN_NO_CRC} ${CRC_VAL_BIN} ${EXPECTED_FLASH_BYTES}

                # Шаг 3: Внедряем рассчитанный CRC обратно в ELF файл
                COMMAND ${CMAKE_OBJCOPY} --update-section ${crc_section_name}=${CRC_VAL_BIN} ${TARGET_ELF}

                # Шаг 4: Выводим подтверждение
                COMMAND ${CMAKE_COMMAND} -E echo "--- Injection successful! ---"
                COMMAND ${CMAKE_COMMAND} -E echo " "

                COMMENT "Calculating and injecting CRC32 into firmware..."
                VERBATIM
            )
        else()
            message(STATUS " Сборка будет выполнена БЕЗ добавления контрольной суммы.")
        endif()
    endif()

    # =======================================================================
    # 2. ГЕНЕРАЦИЯ АРТЕФАКТОВ СБОРКИ (BIN, HEX, LSS, SIZE)
    # =======================================================================

    # Выводим размер потребляемой памяти (RAM/FLASH)
    stm32_print_size_of_target(${TARGET_NAME})

    # Генерируем запрошенные пользователем файлы из YAML
    if("bin" IN_LIST build_artifacts)
        stm32_generate_binary_file(${TARGET_NAME})
    endif()

    if("hex" IN_LIST build_artifacts)
        stm32_generate_hex_file(${TARGET_NAME})
    endif()

    if("lss" IN_LIST build_artifacts)
        stm32_yml_generate_lss_file(${TARGET_NAME})
    endif()

endfunction()
