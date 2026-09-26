# ==============================================================================
# Модуль: ФРЕЙМВОРКИ И ДРАЙВЕРЫ (CMSIS, HAL, FreeRTOS, Newlib)
# ==============================================================================
# Отвечает за поиск локальных или глобальных драйверов STM32Cube,
# инициализацию библиотек CMSIS, HAL/LL, FreeRTOS и системных заглушек.
# ==============================================================================

function(stm32_yml_setup_frameworks TARGET_NAME)

    # =======================================================================
    # 1. ОПРЕДЕЛЕНИЕ ПУТЕЙ К STM32CUBE FW
    # =======================================================================
    if(use_cmsis OR use_hal OR (use_freertos AND freertos_version STREQUAL "cube"))

        # Безопасный фолбек значения по умолчанию
        if(NOT DEFINED cubefw_package OR "${cubefw_package}" STREQUAL "")
            set(cubefw_package "auto")
        endif()

        if(cubefw_package STREQUAL "auto")
            message(STATUS "Режим 'auto': поиск драйверов...")
            set(LOCAL_DRIVERS_PATH "${CMAKE_CURRENT_SOURCE_DIR}/Drivers")

            if(EXISTS "${LOCAL_DRIVERS_PATH}/CMSIS" AND EXISTS "${LOCAL_DRIVERS_PATH}/STM32${MCU_FAMILY}xx_HAL_Driver")
                message(STATUS "Обнаружены локальные драйверы в '${LOCAL_DRIVERS_PATH}'. Используются они.")
                set(STM32_CMSIS_PATH                "${LOCAL_DRIVERS_PATH}/CMSIS")
                set(STM32_HAL_${MCU_FAMILY}_PATH    "${LOCAL_DRIVERS_PATH}/STM32${MCU_FAMILY}xx_HAL_Driver")
                set(CUBEFW_PACKAGE "local")
                message(STATUS "STM32Cube MCU Firmware Package: ${CUBEFW_PACKAGE}")
            else()
                message(STATUS "Локальные драйверы не найдены. Поиск последней версии в пользовательском репозитории...")
                set(USER_HOME_PATH "$ENV{CMAKE_USER_HOME}")
                file(TO_CMAKE_PATH "${USER_HOME_PATH}" USER_HOME_PATH)
                set(CUBE_REPO_PATH "${USER_HOME_PATH}/STM32Cube/Repository")

                stm32_yml_find_latest_stm32_cube_fw(${MCU_FAMILY} ${CUBE_REPO_PATH} LATEST_FW_VERSION)
                set(CUBEFW_PACKAGE ${LATEST_FW_VERSION})
                message(STATUS "Использование найденной версии STM32Cube FW: ${CUBEFW_PACKAGE}")

                if(CUBEFW_PACKAGE)
                    set(STM32_CUBE_PATH                 "${CUBE_REPO_PATH}/STM32Cube_FW_${MCU_FAMILY}_${CUBEFW_PACKAGE}")
                    set(STM32_CUBE_${MCU_FAMILY}_PATH   "${STM32_CUBE_PATH}")
                    set(STM32_CMSIS_PATH                "${STM32_CUBE_PATH}/Drivers/CMSIS")
                    set(STM32_HAL_${MCU_FAMILY}_PATH    "${STM32_CUBE_PATH}/Drivers/STM32${MCU_FAMILY}xx_HAL_Driver")
                endif()
            endif()
        else()
            set(CUBEFW_PACKAGE ${cubefw_package})
            message(STATUS "Использование указанной версии STM32Cube FW: ${CUBEFW_PACKAGE}")
            set(USER_HOME_PATH "$ENV{CMAKE_USER_HOME}")
            file(TO_CMAKE_PATH "${USER_HOME_PATH}" USER_HOME_PATH)
            set(CUBE_REPO_PATH "${USER_HOME_PATH}/STM32Cube/Repository")

            if(CUBEFW_PACKAGE)
                set(STM32_CUBE_PATH                 "${CUBE_REPO_PATH}/STM32Cube_FW_${MCU_FAMILY}_${CUBEFW_PACKAGE}")
                set(STM32_CUBE_${MCU_FAMILY}_PATH   "${STM32_CUBE_PATH}")
                set(STM32_CMSIS_PATH                "${STM32_CUBE_PATH}/Drivers/CMSIS")
                set(STM32_HAL_${MCU_FAMILY}_PATH    "${STM32_CUBE_PATH}/Drivers/STM32${MCU_FAMILY}xx_HAL_Driver")
            endif()
        endif()

        if(NOT DEFINED STM32_CMSIS_PATH)
            message(FATAL_ERROR "Не удалось определить пути к драйверам HAL/CMSIS. Проверьте 'cubefw_package'.")
        endif()

        if(CUBEFW_PACKAGE STREQUAL "local")
            set(STM32_CUBE_${MCU_FAMILY}_PATH ${CMAKE_CURRENT_SOURCE_DIR})
        else()
            set(USER_HOME_PATH "$ENV{CMAKE_USER_HOME}")
            file(TO_CMAKE_PATH "${USER_HOME_PATH}" USER_HOME_PATH)
            set(STM32_CUBE_${MCU_FAMILY}_PATH "${USER_HOME_PATH}/STM32Cube/Repository/STM32Cube_FW_${MCU_FAMILY}_${CUBEFW_PACKAGE}")
        endif()
    endif()

    # =======================================================================
    # 2. CMSIS
    # =======================================================================
    if(use_cmsis)
        message(STATUS "Автоматическое подключение CMSIS включено.")
        set(STM32_CMSIS_${MCU_FAMILY}_PATH "${STM32_CMSIS_PATH}/Device/ST/STM32${MCU_FAMILY}xx")

        if(mcu_core)
            find_package(CMSIS COMPONENTS STM32${MCU_FAMILY}_${mcu_core} REQUIRED)
        else()
            find_package(CMSIS COMPONENTS STM32${MCU_FAMILY} REQUIRED)
        endif()
    endif()

    # =======================================================================
    # 3. HAL / LL
    # =======================================================================
    if(use_hal)
        message(STATUS "Автоматическое подключение компонентов HAL/LL включено.")
        if(NOT use_cmsis)
            message(FATAL_ERROR "use_hal: true требует use_cmsis: true.")
        endif()

        if(hal_components)
            set(STM32_CMSIS_${MCU_FAMILY}_PATH  "${STM32_CMSIS_PATH}/Device/ST/STM32${MCU_FAMILY}xx")
            target_compile_definitions(${TARGET_NAME} PRIVATE USE_HAL_DRIVER)

            if(mcu_core)
                find_package(HAL COMPONENTS STM32${MCU_FAMILY}_${mcu_core} REQUIRED)
            else()
                find_package(HAL COMPONENTS STM32${MCU_FAMILY} REQUIRED)
            endif()

            set(HAL_TARGET_PREFIX "HAL::STM32::${MCU_FAMILY}")
            set(_core_text "")
            if(mcu_core)
                set(HAL_TARGET_PREFIX "${HAL_TARGET_PREFIX}::${mcu_core}")
                set(_core_text " (ядро ${mcu_core})")
            endif()

            list(TRANSFORM hal_components PREPEND "${HAL_TARGET_PREFIX}::" OUTPUT_VARIABLE LOCAL_HAL_TARGETS)

            # Каждый компонент проверяется сразу, а не на стадии Generate (ТЗ 4.7.9).
            foreach(_component IN LISTS hal_components)
                if(NOT TARGET "${HAL_TARGET_PREFIX}::${_component}")
                    message(FATAL_ERROR
                        "Компонент HAL '${_component}' (hal_components) не найден для семейства "
                        "${MCU_FAMILY}${_core_text}: нет цели ${HAL_TARGET_PREFIX}::${_component}. "
                        "Проверьте имя драйвера в пакете STM32Cube ${MCU_FAMILY}.")
                endif()
            endforeach()

            # Привязываем библиотеки сразу к цели!
            target_link_libraries(${TARGET_NAME} PRIVATE ${LOCAL_HAL_TARGETS})

            set(LL_DRIVER_FOUND FALSE)
            foreach(component IN LISTS hal_components)
                if(component MATCHES "^LL_")
                    set(LL_DRIVER_FOUND TRUE)
                    break()
                endif()
            endforeach()

            if(LL_DRIVER_FOUND)
                target_compile_definitions(${TARGET_NAME} PRIVATE USE_FULL_LL_DRIVER)
            endif()
        endif()
    else()
        message(STATUS "Автоматическое подключение компонентов HAL/LL отключено.")
    endif()

    # =======================================================================
    # 4. FreeRTOS
    # =======================================================================
    if(use_freertos)
        message(STATUS "Автоматическое подключение FreeRTOS включено.")
        if(NOT DEFINED freertos_version OR "${freertos_version}" STREQUAL "")
            set(freertos_version "cube")
        endif()

        set(FREERTOS_PORT "")
        set(OTHER_FREERTOS_COMPONENTS "")

        foreach(component IN LISTS freertos_components)
            if(component MATCHES "^ARM_")
                if(FREERTOS_PORT)
                    message(FATAL_ERROR "Найдено несколько портов FreeRTOS: '${FREERTOS_PORT}' и '${component}'.")
                endif()
                set(FREERTOS_PORT ${component})
            else()
                list(APPEND OTHER_FREERTOS_COMPONENTS ${component})
            endif()
        endforeach()

        if(NOT FREERTOS_PORT)
            message(FATAL_ERROR "В 'freertos_components' не найден порт (например, 'ARM_CM4F').")
        endif()
        message(STATUS "Используется порт FreeRTOS: ${FREERTOS_PORT}")

        if(freertos_version STREQUAL "cube")
            find_package(FreeRTOS COMPONENTS ${FREERTOS_PORT} STM32${MCU_FAMILY} REQUIRED)
            set(FREERTOS_TARGET_PREFIX "FreeRTOS::STM32::${MCU_FAMILY}")
            if(mcu_core)
                set(FREERTOS_TARGET_PREFIX "${FREERTOS_TARGET_PREFIX}::${mcu_core}")
            endif()
        else()
            # external: FreeRTOS не из STM32Cube (ТЗ 4.8.6, E007). Без компонента
            # семейства stm32-cmake ищет FreeRTOS в FREERTOS_PATH и создаёт цели
            # FreeRTOS::<порт> и FreeRTOS::<компонент>. REQUIRED не используется:
            # в этом режиме stm32-cmake не отмечает компоненты найденными, а при
            # отсутствии файлов лишь предупреждает — проверяем сами.
            find_package(FreeRTOS COMPONENTS ${FREERTOS_PORT})
            if(NOT FREERTOS_PATH)
                message(FATAL_ERROR
                    "freertos_version: external требует путь к FreeRTOS: задайте FREERTOS_PATH "
                    "(-DFREERTOS_PATH=... или переменная окружения) — каталог FreeRTOS-Kernel "
                    "или Middlewares/Third_Party/FreeRTOS пакета STM32Cube.")
            endif()
            if(NOT FreeRTOS_COMMON_INCLUDE OR NOT FreeRTOS_SOURCE_DIR)
                message(FATAL_ERROR
                    "freertos_version: external: в FREERTOS_PATH '${FREERTOS_PATH}' не найдены "
                    "FreeRTOS.h и tasks.c. Ожидается раскладка FreeRTOS-Kernel (include/, "
                    "portable/GCC/<порт>) или дерева Cube (Source/...).")
            endif()
            if(NOT FreeRTOS_${FREERTOS_PORT}_PATH OR NOT FreeRTOS_${FREERTOS_PORT}_SOURCE)
                message(FATAL_ERROR
                    "freertos_version: external: файлы порта '${FREERTOS_PORT}' не найдены в "
                    "FREERTOS_PATH '${FREERTOS_PATH}' (portable/GCC/${FREERTOS_PORT}).")
            endif()
            set(FREERTOS_TARGET_PREFIX "FreeRTOS")
        endif()

        # Порт ARMv8 с TrustZone stm32-cmake создаёт как <порт>::NON_SECURE.
        set(_port_target "${FREERTOS_TARGET_PREFIX}::${FREERTOS_PORT}")
        if(NOT TARGET "${_port_target}" AND TARGET "${_port_target}::NON_SECURE")
            set(_port_target "${_port_target}::NON_SECURE")
        endif()

        set(LOCAL_FREERTOS_TARGETS "${_port_target}")
        foreach(component IN LISTS OTHER_FREERTOS_COMPONENTS)
            list(APPEND LOCAL_FREERTOS_TARGETS "${FREERTOS_TARGET_PREFIX}::${component}")
        endforeach()

        # Каждый компонент проверяется сразу, а не на стадии Generate (ТЗ 4.8.7).
        foreach(_target IN LISTS LOCAL_FREERTOS_TARGETS)
            if(NOT TARGET "${_target}")
                string(REPLACE "${FREERTOS_TARGET_PREFIX}::" "" _component "${_target}")
                message(FATAL_ERROR
                    "Компонент FreeRTOS '${_component}' (freertos_components) не найден: нет цели "
                    "${_target} в пространстве ${FREERTOS_TARGET_PREFIX}.")
            endif()
        endforeach()

        # Обёртка CMSIS-RTOS создаётся целью CMSIS семейства с учётом ядра (ТЗ 4.7.8).
        # С внешним FreeRTOS исходники обёртки берутся из пакета CMSIS семейства,
        # заголовки FreeRTOS — из целей внешнего FreeRTOS (ТЗ 4.8.8).
        set(_cmsis_family_prefix "CMSIS::STM32::${MCU_FAMILY}")
        if(mcu_core)
            set(_cmsis_family_prefix "${_cmsis_family_prefix}::${mcu_core}")
        endif()
        set(_rtos_target "")
        if(cmsis_rtos_api STREQUAL "v1")
            set(_rtos_target "${_cmsis_family_prefix}::RTOS")
        elseif(cmsis_rtos_api STREQUAL "v2")
            set(_rtos_target "${_cmsis_family_prefix}::RTOS_V2")
        endif()
        if(_rtos_target)
            if(NOT TARGET "${_rtos_target}")
                message(FATAL_ERROR
                    "cmsis_rtos_api: ${cmsis_rtos_api}: обёртка CMSIS-RTOS не найдена (нет цели ${_rtos_target}). "
                    "Её исходники берутся из Middlewares/Third_Party/FreeRTOS пакета STM32Cube ${MCU_FAMILY} "
                    "и требуют use_cmsis: true; в пакете может не быть FreeRTOS (например, H5, U5). "
                    "Используйте cmsis_rtos_api: none.")
            endif()
            list(APPEND LOCAL_FREERTOS_TARGETS "${_rtos_target}")
            message(STATUS "Подключена обертка CMSIS-RTOS API ${cmsis_rtos_api}.")
        endif()

        # Привязываем библиотеки сразу к цели!
        target_link_libraries(${TARGET_NAME} PRIVATE ${LOCAL_FREERTOS_TARGETS})
    endif()

    endfunction()

    # ==============================================================================
    # @brief Настраивает системные библиотеки (C-runtime) для цели сборки.
    # Вынесено в отдельную функцию, так как применяется для всех бэкендов.
    #
    # @param TARGET_NAME  Имя основного cmake-таргета проекта.
    # ==============================================================================
    function(stm32_yml_setup_system_libraries TARGET_NAME)
        # =======================================================================
        # СИСТЕМНЫЕ БИБЛИОТЕКИ C/C++ (Newlib, NoSys, Semihosting)
        # =======================================================================
        if(use_newlib_nano)
            target_link_libraries(${TARGET_NAME} PRIVATE STM32::Nano)
        endif()

        # Сравнение через кавычки: параметр может быть не задан в stm32_config.yml,
        # и тогда без кавычек CMake сравнивал бы само имя переменной.
        if("${system_library}" STREQUAL "NoSys")
            target_link_libraries(${TARGET_NAME} PRIVATE STM32::NoSys)
        elseif("${system_library}" STREQUAL "Semihosting")
            target_link_libraries(${TARGET_NAME} PRIVATE STM32::Semihosting)
        endif()
    endfunction()
