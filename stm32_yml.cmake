cmake_minimum_required(VERSION 3.19)

# ==============================================================================
#      ФРЕЙМВОРК STM32-CMAKE-YML
# ==============================================================================

# Подключаем наши вспомогательные утилиты.
include(stm32_yml_utils)

# Определяем текущую версию фреймворка.
set(STM32_CMAKE_YML_VERSION "0.4.1")

# ==============================================================================
#      [НОВАЯ ФУНКЦИЯ] ПОДГОТОВКА ДАННЫХ ДЛЯ ПРОЕКТА
# ==============================================================================
# Эта функция ТОЛЬКО читает YAML/IOC и подготавливает переменные,
# необходимые для вызова project(). Она НЕ вызывает project() сама.
#
# @param OUT_PROJECT_NAME_VAR - Имя переменной, куда будет записано имя проекта.
# @param OUT_LANGUAGES_VAR    - Имя переменной, куда будет записан список языков.
#
function(stm32_yml_prepare_project_data OUT_PROJECT_NAME_VAR OUT_LANGUAGES_VAR)

    # =======================================================================
    # 1. ЗАГРУЗКА И ПОДГОТОВКА КОНФИГУРАЦИИ.
    # =======================================================================

    # Устанавливаем имя конфигурационного файла
    set(PROJECT_CONFIG_FILE "stm32_config.yml" CACHE STRING "...")
    set(CONFIG_FILE_PATH "${CMAKE_SOURCE_DIR}/${PROJECT_CONFIG_FILE}")

    # 1. Парсим конфиг
    # Эта функция использует внешний инструмент 'yq' для преобразования YAML в JSON,
    # а затем использует встроенные возможности CMake для разбора JSON.
    stm32_yml_parse_config("${CONFIG_FILE_PATH}")

    # Устанавливаем значение по умолчанию для флага проверки
    stm32_yml_ensure_default_value(stm32_cmake_yml_version_check "true")

    # Выполняем проверку, только если она не отключена
    if(stm32_cmake_yml_version_check)
        # Проверяем, что версия указана в YAML-файле
        if(NOT DEFINED stm32_cmake_yml_version OR "${stm32_cmake_yml_version}" STREQUAL "")
            message(WARNING "В файле '${PROJECT_CONFIG_FILE}' отсутствует или пуст обязательный параметр 'stm32_cmake_yml_version'. "
                            "Рекомендуется добавить 'stm32_cmake_yml_version: \"${STM32_CMAKE_YML_VERSION}\"' для обеспечения совместимости.")
        else()
            message(STATUS "Версия конфигурации, требуемая проектом STM32-CMAKE-YML: ${stm32_cmake_yml_version}")

            # Сравниваем версии. CMake умеет сравнивать версии в формате X.Y.Z
            if(stm32_cmake_yml_version VERSION_GREATER STM32_CMAKE_YML_VERSION)
                message(WARNING "Версия фреймворка (${STM32_CMAKE_YML_VERSION}), которую вы используете, старше, чем та, что требуется "
                                "проекту (${stm32_cmake_yml_version}). Возможны отсутствующие функции. Рекомендуется обновить фреймворк.")
            elseif(stm32_cmake_yml_version VERSION_LESS STM32_CMAKE_YML_VERSION)
                message(WARNING "Версия фреймворка (${STM32_CMAKE_YML_VERSION}), которую вы используете, новее, чем та, что требуется "
                                "проекту (${stm32_cmake_yml_version}). Возможны изменения в поведении. Рекомендуется согласовать описание в вашем .yml файле.")
            endif()
        endif()
    endif()

    # 2. Обрабатываем IOC или устанавливаем значения по умолчанию
    stm32_yml_ensure_default_value(ioc_file "")

    # --- ГЛАВНЫЙ БЛОК ОПРЕДЕЛЕНИЯ КОНФИГУРАЦИИ ---
    if(ioc_file)
        message(STATUS "Обнаружена настройка 'ioc_file'. Загрузка конфигурации из: ${ioc_file}")
        set(IOC_FILE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/${ioc_file}")

        # Вызываем парсер для .ioc файла
        stm32_yml_parse_ioc_file(${IOC_FILE_PATH} "IOC_")

        # Переопределяем ключевые переменные значениями из .ioc
        set(mcu ${IOC_MCU})
        set(project_name ${IOC_PROJECT_NAME})
        set(heap_size ${IOC_HEAP_SIZE})
        set(stack_size ${IOC_STACK_SIZE})

        # Принудительно включаем CMSIS и HAL, так как проекты из CubeMX всегда их используют.
        set(use_cmsis true)
        set(use_hal true)

        # Логика для определения версии пакета
        if(IOC_USE_LOCAL_DRIVERS)
            # Если библиотеки скопированы в проект, используем их
            set(cubefw_package "auto")
        else()
            # Иначе используем версию, указанную в .ioc
            set(cubefw_package ${IOC_CUBEFW_PACKAGE})
        endif()

        message(STATUS "Конфигурация из .ioc файла загружена: CubeFW=${cubefw_package}, MCU=${mcu}, Project=${project_name}, Heap=${heap_size}, Stack=${stack_size}")
    else()
        message(STATUS "Режим ручной конфигурации (ioc_file не указан).")

        # Если .ioc не используется, устанавливаем значения по умолчанию для YAML-параметров.
        stm32_yml_ensure_default_value(project_name "auto")
        stm32_yml_ensure_default_value(use_cmsis "true")
        stm32_yml_ensure_default_value(use_hal "true")
        stm32_yml_ensure_default_value(heap_size "512")
        stm32_yml_ensure_default_value(stack_size "1024")
        stm32_yml_ensure_default_value(use_freertos "false")
    endif()

    # Устанавливаем значения по умолчанию для пропущенных параметров.
    stm32_yml_ensure_default_value(linker_script "auto")
    stm32_yml_ensure_default_value(use_newlib_nano "false")
    stm32_yml_ensure_default_value(mcu_core "")

    # =======================================================================
    # 2. УСТАНОВКА ОСНОВНЫХ ПАРАМЕТРОВ ПРОЕКТА.
    # =======================================================================

    set(CMAKE_C_STANDARD ${c_standard})
    set(CMAKE_CXX_STANDARD ${cpp_standard})

    # Микроконтроллер (можно переопределять через -D).
    set(MCU ${mcu} CACHE STRING "Target STM32 microcontroller")

    # В качестве имени проекта используем имя папки (см. tasks.json и launch.json).
    if(${project_name} STREQUAL "auto")
        get_filename_component(LOCAL_PROJECT_NAME ${CMAKE_SOURCE_DIR} NAME)
    else()
        set(LOCAL_PROJECT_NAME ${project_name}) # Используем переменную из YAML (с маленькой 'p')
    endif()
    message(STATUS "Определено имя проекта: ${LOCAL_PROJECT_NAME}")

    # Определяем языки проекта.
    # Если в конфиге не указано, используем C, CXX, ASM по умолчанию.
    if(NOT DEFINED languages OR "${languages}" STREQUAL "")
        set(LOCAL_LANGUAGES C CXX ASM)
        message(STATUS "Языки проекта не указаны. Используется по умолчанию: ${LOCAL_LANGUAGES}")
    else()
        set(LOCAL_LANGUAGES ${languages})
        message(STATUS "Используются языки проекта из конфига: ${LOCAL_LANGUAGES}")
    endif()

    # 5. Возвращаем результаты через PARENT_SCOPE
    set(${OUT_PROJECT_NAME_VAR} ${LOCAL_PROJECT_NAME} PARENT_SCOPE)
    set(${OUT_LANGUAGES_VAR} ${LOCAL_LANGUAGES} PARENT_SCOPE)

    # ==============================================================================
    #      "Пробрасываем" ВСЕ переменные, нужные для setup_project, наверх.
    # ==============================================================================

    # Переменные, возвращаемые через аргументы функции (для команды project())
    set(${OUT_PROJECT_NAME_VAR} ${LOCAL_PROJECT_NAME} PARENT_SCOPE)
    set(${OUT_LANGUAGES_VAR} ${LOCAL_LANGUAGES} PARENT_SCOPE)

    # Все остальные переменные, которые были прочитаны из YAML или установлены по умолчанию
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

endfunction()

# ==============================================================================
#      ОСНОВНАЯ ФУНКЦИЯ НАСТРОЙКИ (принимает имя цели)
# ==============================================================================
# @param TARGET_NAME - Имя цели (исполняемого файла), которую нужно настроить.
#
function(stm32_yml_setup_project TARGET_NAME)

# Включаем подробный вывод, если это указано в конфиге.
stm32_yml_ensure_default_value(verbose_build "false")
if(verbose_build)
    message(STATUS "Включен подробный вывод команд сборки (CMAKE_VERBOSE_MAKEFILE=ON).")
    # [ИЗМЕНЕНИЕ] Определяем переменную как BOOL и добавляем в кэш
    set(CMAKE_VERBOSE_MAKEFILE ON CACHE BOOL "Enable verbose build output" FORCE)
else()
    # [ИЗМЕНЕНИЕ] Явно выключаем ее в кэше, если в .yml стоит false
    set(CMAKE_VERBOSE_MAKEFILE OFF CACHE BOOL "Enable verbose build output" FORCE)
endif()

add_executable(${TARGET_NAME})

# stm32-cmake автоматически определяет семейство (FAMILY) и тип (TYPE) из имени MCU.
stm32_get_chip_info(${MCU} FAMILY MCU_FAMILY TYPE MCU_TYPE)

target_compile_definitions(${TARGET_NAME} PRIVATE STM32${MCU_TYPE})

# =======================================================================
# 3. ОПРЕДЕЛЕНИЕ ИСХОДНЫХ ФАЙЛОВ.
# =======================================================================

# Создаем пустые списки для сбора информации
set(PROJECT_SOURCES "")         # для одиночных файлов

# [НОВОЕ] Конструируем имена файлов, которые мы будем искать
string(TOLOWER ${MCU_FAMILY} MCU_FAMILY_LOWER)
string(TOLOWER ${MCU_TYPE} MCU_TYPE_LOWER)

set(SYSTEM_FILENAME_TARGET "system_stm32${MCU_FAMILY_LOWER}xx.c")

# Шаблон для startup-файла (например, startup_stm32f401xc.s)
set(STARTUP_FILENAME_PATTERN "startup_stm32${MCU_TYPE_LOWER}.*\\.s")

# Перебираем список 'sources' из YAML-конфига.
foreach(src_item IN LISTS sources)
    set(full_path "${CMAKE_CURRENT_SOURCE_DIR}/${src_item}")
    get_filename_component(filename ${src_item} NAME) # Получаем только имя файла
    string(TOLOWER ${filename} filename_lower)

    # --- ПРОВЕРКА НА ОСОБЫЕ СИСТЕМНЫЕ ФАЙЛЫ ---
    # Мы выполняем эту проверку, только если автоматическое подключение HAL включено.
    set(is_special_file FALSE) # Флаг, чтобы избежать двойной обработки

    # Если файл найден, мы устанавливаем переменную для stm32-cmake
    # и НЕ добавляем его в список для прямой компиляции.
    if(use_hal)
        if(filename_lower STREQUAL SYSTEM_FILENAME_TARGET)
            if(mcu_core)
                set(CMSIS_${MCU_FAMILY}_${mcu_core}_SYSTEM ${full_path})
            else()
                set(CMSIS_${MCU_FAMILY}_SYSTEM ${full_path})
            endif()
            message(STATUS "Обнаружен пользовательский system-файл. Переопределение: ${full_path}")
            set(is_special_file TRUE)

        elseif(filename_lower MATCHES ${STARTUP_FILENAME_PATTERN})
            if(mcu_core)
                set(CMSIS_${MCU_FAMILY}_${mcu_core}_${MCU_TYPE}_STARTUP ${full_path})
            else()
                set(CMSIS_${MCU_FAMILY}_${MCU_TYPE}_STARTUP ${full_path})
            endif()
            message(STATUS "Обнаружен пользовательский startup-файл. Переопределение: ${full_path}")
            set(is_special_file TRUE)
        endif()
    endif()

    # --- СТАНДАРТНАЯ ОБРАБОТКА ОСТАЛЬНЫХ ФАЙЛОВ ---
    # Этот блок будет выполнен, только если файл не был определен как специальный.
    if(NOT is_special_file)
        # Вариант 1: Если это директория, подключаем ее как модуль.
        if(IS_DIRECTORY ${full_path})
            #message(STATUS "Подключение модуля из директории: ${src_item}")
            add_subdirectory(${src_item})

        # Вариант 2: Если это существующий файл, добавляем его в список исходников.
        elseif(EXISTS ${full_path})
            #message(STATUS "Добавление исходного файла: ${src_item}")
            list(APPEND PROJECT_SOURCES ${full_path})

        # Вариант 3: Если путь не найден.
        else()
            message(WARNING "Источник '${src_item}' не найден и будет проигнорирован.")
        endif()
    endif()
endforeach()

target_sources(${TARGET_NAME} PRIVATE ${PROJECT_SOURCES})

# =======================================================================
# 4. НАСТРОЙКА ОКРУЖЕНИЯ STM32 И БИБЛИОТЕК.
# =======================================================================

# ---  БЛОК 1: Определение путей к STM32Cube FW ---
# Эта логика теперь выполняется всегда, если включен хотя бы один из модулей ST.
if(use_cmsis OR use_hal OR (use_freertos AND freertos_version STREQUAL "cube"))

    stm32_yml_ensure_default_value(cubefw_package "auto")

    # Разворачиваем окружение сборки (STM32Cube MCU Firmware Package).
    if(cubefw_package STREQUAL "auto")
        message(STATUS "Режим 'auto': поиск драйверов...")

        # ПРИОРИТЕТ 1: Ищем локальные драйверы в папке проекта
        set(LOCAL_DRIVERS_PATH "${CMAKE_CURRENT_SOURCE_DIR}/Drivers")

        if(EXISTS "${LOCAL_DRIVERS_PATH}/CMSIS" AND EXISTS "${LOCAL_DRIVERS_PATH}/STM32${MCU_FAMILY}xx_HAL_Driver")
            message(STATUS "Обнаружены локальные драйверы в '${LOCAL_DRIVERS_PATH}'. Используются они.")
            # Напрямую устанавливаем пути к локальным драйверам
            set(STM32_CMSIS_PATH                "${LOCAL_DRIVERS_PATH}/CMSIS")
            set(STM32_HAL_${MCU_FAMILY}_PATH    "${LOCAL_DRIVERS_PATH}/STM32${MCU_FAMILY}xx_HAL_Driver")
            set(CUBEFW_PACKAGE "local") # Устанавливаем флаг, что используются локальные драйверы
            message(STATUS "STM32Cube MCU Firmware Package: ${CUBEFW_PACKAGE}")

        # ПРИОРИТЕТ 2: Если локальные не найдены, ищем последнюю версию в пользовательском репозитории
        else()
            message(STATUS "Локальные драйверы не найдены. Поиск последней версии в пользовательском репозитории...")

            # Сначала получаем путь из переменной окружения
            set(USER_HOME_PATH "$ENV{CMAKE_USER_HOME}")
            # Затем принудительно конвертируем его в формат CMake (C:/Users/User)
            file(TO_CMAKE_PATH "${USER_HOME_PATH}" USER_HOME_PATH)

            set(CUBE_REPO_PATH "${USER_HOME_PATH}/STM32Cube/Repository")

            stm32_yml_find_latest_stm32_cube_fw(${MCU_FAMILY} ${CUBE_REPO_PATH} LATEST_FW_VERSION)
            set(CUBEFW_PACKAGE ${LATEST_FW_VERSION})
            message(STATUS "Использование найденной версии STM32Cube FW: ${CUBEFW_PACKAGE}")

            # Устанавливаем пути на основе найденной глобальной версии.
            if(CUBEFW_PACKAGE)
                set(STM32_CUBE_PATH                 "${CUBE_REPO_PATH}/STM32Cube/Repository/STM32Cube_FW_${MCU_FAMILY}_${CUBEFW_PACKAGE}")
                set(STM32_CUBE_${MCU_FAMILY}_PATH   "${STM32_CUBE_PATH}/Drivers")
                set(STM32_CMSIS_PATH                "${STM32_CUBE_${MCU_FAMILY}_PATH}/CMSIS")
                set(STM32_HAL_${MCU_FAMILY}_PATH    "${STM32_CUBE_${MCU_FAMILY}_PATH}/STM32${MCU_FAMILY}xx_HAL_Driver")
            endif()
        endif()

    # Сценарий, когда версия указана явно.
    else()
        # Используем версию, указанную пользователем.
        set(CUBEFW_PACKAGE ${cubefw_package})
        message(STATUS "Использование указанной версии STM32Cube FW: ${CUBEFW_PACKAGE}")

        # Сначала получаем путь из переменной окружения
        set(USER_HOME_PATH "$ENV{CMAKE_USER_HOME}")
        # Затем принудительно конвертируем его в формат CMake (C:/Users/User)
        file(TO_CMAKE_PATH "${USER_HOME_PATH}" USER_HOME_PATH)

        set(CUBE_REPO_PATH "${USER_HOME_PATH}/STM32Cube/Repository")

        # Устанавливаем пути на основе указанной глобальной версии.
        if(CUBEFW_PACKAGE)
            set(STM32_CUBE_PATH                 "${CUBE_REPO_PATH}/STM32Cube_FW_${MCU_FAMILY}_${CUBEFW_PACKAGE}")
            set(STM32_CUBE_${MCU_FAMILY}_PATH   "${STM32_CUBE_PATH}/Drivers")
            set(STM32_CMSIS_PATH                "${STM32_CUBE_${MCU_FAMILY}_PATH}/CMSIS")
            set(STM32_HAL_${MCU_FAMILY}_PATH    "${STM32_CUBE_${MCU_FAMILY}_PATH}/STM32${MCU_FAMILY}xx_HAL_Driver")
        endif()
    endif()

    # Финальная проверка и установка пути к CMSIS Device
    if(NOT DEFINED STM32_CMSIS_PATH)
        message(FATAL_ERROR "Не удалось определить пути к драйверам HAL/CMSIS. Проверьте настройки 'cubefw_package' или наличие драйверов.")
    endif()

    # [ВАЖНО] Определяем переменную STM32_CUBE_${MCU_FAMILY}_PATH,
    # на которую полагается FindFreeRTOS.cmake
    if(CUBEFW_PACKAGE STREQUAL "local")
        # Если драйверы локальные, "родительская" папка - это корень проекта
        set(STM32_CUBE_${MCU_FAMILY}_PATH ${CMAKE_CURRENT_SOURCE_DIR})
    else()
        set(USER_HOME_PATH "$ENV{CMAKE_USER_HOME}")
        file(TO_CMAKE_PATH "${USER_HOME_PATH}" USER_HOME_PATH)
        set(STM32_CUBE_${MCU_FAMILY}_PATH "${USER_HOME_PATH}/STM32Cube/Repository/STM32Cube_FW_${MCU_FAMILY}_${CUBEFW_PACKAGE}")
    endif()
endif()

set(CMSIS_TARGET_TO_LINK "")

# --- БЛОК 1: Обработка CMSIS ---
if(use_cmsis)
    message(STATUS "Автоматическое подключение CMSIS включено.")

    set(STM32_CMSIS_${MCU_FAMILY}_PATH "${STM32_CMSIS_PATH}/Device/ST/STM32${MCU_FAMILY}xx")

    if(mcu_core)
        find_package(CMSIS COMPONENTS STM32${MCU_FAMILY}_${mcu_core} REQUIRED)
    else()
        find_package(CMSIS COMPONENTS STM32${MCU_FAMILY} REQUIRED)
    endif()

    # Переопределение system/startup файлов теперь должно быть внутри этого блока
    # ... (foreach(src_item IN LISTS sources) ... if(is_special_file))
endif()

# --- БЛОК 2: Обработка HAL ---
set(HAL_TARGETS "")

if(use_hal)
    message(STATUS "Автоматическое подключение компонентов HAL/LL включено.")

    if(NOT use_cmsis)
        message(FATAL_ERROR "use_hal: true требует use_cmsis: true. HAL не может работать без CMSIS.")
    endif()

    # Автоматически добавляем USE_HAL_DRIVER, если в конфиге указан хотя бы один HAL-компонент.
    # Команда if() для списка считается истинной, если список не пуст.
    if(hal_components)
        #message(STATUS "Обнаружены компоненты HAL/LL. Автоматически добавляется определение: USE_HAL_DRIVER")

        set(STM32_CMSIS_${MCU_FAMILY}_PATH  "${STM32_CMSIS_PATH}/Device/ST/STM32${MCU_FAMILY}xx")

        list(APPEND compile_definitions "USE_HAL_DRIVER")

        if(mcu_core)
            find_package(HAL COMPONENTS STM32${MCU_FAMILY}_${mcu_core} REQUIRED)
        else()
            find_package(HAL COMPONENTS STM32${MCU_FAMILY} REQUIRED)
        endif()

        # Формируем префикс для целевых библиотек.
        set(HAL_TARGET_PREFIX "HAL::STM32::${MCU_FAMILY}")
        if(mcu_core)
            set(HAL_TARGET_PREFIX "${HAL_TARGET_PREFIX}::${mcu_core}")
        endif()

        # Подключаем необходимые библиотеки на основе конфига.
        # Сначала создаем список целевых HAL-библиотек, добавляя префикс к каждому элементу.
        list(TRANSFORM hal_components PREPEND "${HAL_TARGET_PREFIX}::" OUTPUT_VARIABLE HAL_TARGETS)

        # TODO: Проверить, добавляется ли автоматически в stm32-cmake.
        #target_compile_definitions(${TARGET_NAME} PRIVATE USE_HAL_DRIVER)

        # Проверяем, есть ли среди компонентов LL-драйверы.
        set(LL_DRIVER_FOUND FALSE)
        foreach(component IN LISTS hal_components)
            if(component MATCHES "^LL_")
                set(LL_DRIVER_FOUND TRUE)
                break()
            endif()
        endforeach()

        if(LL_DRIVER_FOUND)
            #message(STATUS "Обнаружены LL компоненты. Автоматически добавляется определение: USE_FULL_LL_DRIVER")
            target_compile_definitions(${TARGET_NAME} PRIVATE USE_FULL_LL_DRIVER)
        endif()
    endif()
else()
    message(STATUS "Автоматическое подключение компонентов HAL/LL отключено. Убедитесь, что все необходимые исходники указаны в секции 'sources'.")
    set(HAL_TARGETS "") # Убеждаемся, что список целей HAL пуст
endif()

# --- БЛОК 3: Обработка FreeRTOS ---
set(FREERTOS_TARGETS "")

if(use_freertos)
    message(STATUS "Автоматическое подключение FreeRTOS включено.")
    stm32_yml_ensure_default_value(freertos_version "cube")

    # Ищем порт (ARM_XXX) среди компонентов, указанных пользователем.
    set(FREERTOS_PORT "")
    set(OTHER_FREERTOS_COMPONENTS "") # Список для остальных компонентов (Heap, Timers,...)

    foreach(component IN LISTS freertos_components)
        if(component MATCHES "^ARM_")
            if(FREERTOS_PORT)
                message(FATAL_ERROR "Найдено несколько портов FreeRTOS в 'freertos_components': '${FREERTOS_PORT}' и '${component}'. Пожалуйста, укажите только один.")
            endif()
            set(FREERTOS_PORT ${component})
        else()
            list(APPEND OTHER_FREERTOS_COMPONENTS ${component})
        endif()
    endforeach()

    # Проверяем, что порт был найден.
    if(NOT FREERTOS_PORT)
        message(FATAL_ERROR "В списке 'freertos_components' не найден обязательный компонент порта (например, 'ARM_CM4F').")
    endif()
    message(STATUS "Используется порт FreeRTOS: ${FREERTOS_PORT}")

    # Ищем пакет FreeRTOS с явно указанным портом и семейством
    find_package(FreeRTOS COMPONENTS ${FREERTOS_PORT} STM32${MCU_FAMILY} REQUIRED)

    # Формируем список компонентов для find_package
    set(FREERTOS_FIND_COMPONENTS ${FREERTOS_PORT})
    if(freertos_version STREQUAL "cube")
        list(APPEND FREERTOS_FIND_COMPONENTS STM32${MCU_FAMILY})
    endif()

    # Формируем префикс для целевых библиотек
    set(FREERTOS_TARGET_PREFIX "FreeRTOS") # 1. Префикс по умолчанию

    if(freertos_version STREQUAL "cube") # 2. Проверяем, не "кубовая" ли версия
        # 3. Устанавливаем базовый префикс для Cube-версии
        set(FREERTOS_TARGET_PREFIX "FreeRTOS::STM32::${MCU_FAMILY}")

        if(mcu_core) # 4. Если это многоядерный MCU...
            # ...добавляем суффикс ядра к префиксу
            set(FREERTOS_TARGET_PREFIX "${FREERTOS_TARGET_PREFIX}::${mcu_core}")
        endif()
    endif()

    # Формируем список целевых библиотек
    set(FREERTOS_TARGETS "")
    # Сначала добавляем главную цель с портом
    list(APPEND FREERTOS_TARGETS "${FREERTOS_TARGET_PREFIX}::${FREERTOS_PORT}")

    # Затем добавляем остальные опциональные компоненты
    foreach(component IN LISTS OTHER_FREERTOS_COMPONENTS)
        list(APPEND FREERTOS_TARGETS "${FREERTOS_TARGET_PREFIX}::${component}")
    endforeach()

    # Обрабатываем CMSIS-RTOS API
    if(cmsis_rtos_api STREQUAL "v1") # 1. Проверяем, не запрошена ли версия 1
        # 2. Ищем специальный компонент RTOS в пакете CMSIS
        #find_package(CMSIS COMPONENTS RTOS REQUIRED)

        # 3. Добавляем целевую библиотеку обертки в наш список
        list(APPEND FREERTOS_TARGETS "CMSIS::STM32::${MCU_FAMILY}::RTOS")

        message(STATUS "Подключена обертка CMSIS-RTOS API v1.")

    elseif(cmsis_rtos_api STREQUAL "v2") # 4. Проверяем, не запрошена ли версия 2
        # 5. Ищем компонент RTOS2
        #find_package(CMSIS COMPONENTS RTOS2 REQUIRED)

        # 6. Добавляем целевую библиотеку обертки v2
        list(APPEND FREERTOS_TARGETS "CMSIS::STM32::${MCU_FAMILY}::RTOS_V2")

        message(STATUS "Подключена обертка CMSIS-RTOS API v2.")
    endif()
endif()

# Добавляем системные библиотеки C/C++.
# Использование newlib-nano для уменьшения размера кода.
if(use_newlib_nano)
    target_link_libraries(${TARGET_NAME} PRIVATE STM32::Nano)
endif()

# Заглушки для системных вызовов. Выберите ИЛИ NoSys, ИЛИ Semihosting.
if(system_library STREQUAL "NoSys")
    target_link_libraries(${TARGET_NAME} PRIVATE STM32::NoSys)
# Альтернатива для отладки через SWD/JTAG.
elseif(system_library STREQUAL "Semihosting")
    target_link_libraries(${TARGET_NAME} PRIVATE STM32::Semihosting)
endif()

# =======================================================================
# 5. НАСТРОЙКИ КОМПИЛЯЦИИ И КОМПОНОВКИ.
# =======================================================================

# Добавляем пути к заголовочным файлам из конфига.
target_include_directories(${TARGET_NAME} PRIVATE
    # Пользовательские опции из project_config.yml
    ${include_directories}
)

# Добавляем определения компилятора из конфига.
target_compile_definitions(${TARGET_NAME} PRIVATE
    # Пользовательские опции из project_config.yml
    ${compile_definitions}
)

target_compile_options(${TARGET_NAME} PRIVATE
    # Пользовательские опции из project_config.yml
    ${compile_options}
)

# Добавляем опции и директивы компоновщика из конфига.
if("map" IN_LIST build_artifacts)
    target_link_options(${TARGET_NAME} PRIVATE LINKER:-Map=${TARGET_NAME}.map)
endif()

# Опции, передаваемые компилятору (например, -lm)
target_link_options(${TARGET_NAME} PRIVATE ${link_options})

# Прямые директивы для компоновщика (например, --print-memory-usage)
foreach(directive IN LISTS linker_directives)
    target_link_options(${TARGET_NAME} PRIVATE "LINKER:${directive}")
endforeach()

# =======================================================================
# 6. ГЕНЕРАЦИЯ ФАЙЛОВ И АРТЕФАКТОВ СБОРКИ.
# =======================================================================

# Переменная для хранения пути к найденному скрипту.
set(LINKER_SCRIPT_PATH "")

# CMSIS creates the following targets:
#
# `CMSIS::STM32::<FAMILY>` (e.g. `CMSIS::STM32::F4`) - common includes, compiler flags and defines for family
# `CMSIS::STM32::<TYPE>` (e.g. `CMSIS::STM32::F407xx`) - common startup source for device type and peripheral access layer files, depends on `CMSIS::STM32::<FAMILY>`
# `CMSIS::STM32::<DEVICE>` (e.g. `CMSIS::STM32::F407VG`) - linker script for device, depends on `CMSIS::STM32::<TYPE>`

# Управление скриптом компоновщика.
if(linker_script STREQUAL "auto")
    # Генерируем .ld-файл из шаблона.
    message(STATUS "Генерация скрипта компоновщика из шаблона...")
    string(REGEX REPLACE "..$" "XX" MCU_TYPE_GENERIC "${MCU_TYPE}")
    set(TEMPLATE_FILE_PATH "${CMAKE_SOURCE_DIR}/STM32${MCU_TYPE_GENERIC}_FLASH.ld.in")

    if(EXISTS ${TEMPLATE_FILE_PATH})
        message(STATUS "Найден локальный шаблон: ${TEMPLATE_FILE_PATH}")

        # Размеры кучи и стека (можно переопределять через -D).
        # Нормализуем значения размеров памяти в байты.
        stm32_yml_normalize_memory(heap_size)
        stm32_yml_normalize_memory(stack_size)

        set(HEAP_SIZE ${heap_size} CACHE STRING "Required amount of heap")
        set(STACK_SIZE ${stack_size} CACHE STRING "Required amount of stack")

        # Проверяем версию GCC и задаём USE_READONLY.
        if(CMAKE_C_COMPILER_VERSION VERSION_GREATER_EQUAL 11.0)
            set(USE_READONLY "(READONLY)")
            message(STATUS "Using READONLY in linker script (GCC >= 11.0)")
        else()
            set(USE_READONLY "")
            message(STATUS "Not using READONLY in linker script (GCC < 11.0)")
        endif()

        set(LINKER_SCRIPT_PATH "${CMAKE_BINARY_DIR}/STM32${MCU_TYPE}_FLASH.ld")
        configure_file(${TEMPLATE_FILE_PATH} ${LINKER_SCRIPT_PATH} @ONLY)
    else()
        message(STATUS "Локальный шаблон не найден. Будет использован стандартный скрипт компоновщика от stm32-cmake.")
    endif()

    # Выбираем, какую "матрёшку" CMSIS подключать, на основе того,
    # нашли ли мы собственный скрипт компоновщика.
    if(LINKER_SCRIPT_PATH)
        # Мы нашли свой скрипт (из шаблона или пользовательский).
        # Для многоядерных систем нужно явно указать ядро
        if(use_cmsis)
            if(mcu_core)
                list(APPEND CMSIS_TARGET_TO_LINK "CMSIS::STM32::${MCU_TYPE}::${mcu_core}")
            else()
                list(APPEND CMSIS_TARGET_TO_LINK "CMSIS::STM32::${MCU_TYPE}")
            endif()
        endif()
        message(STATUS "Подключение скрипта компоновщика: ${LINKER_SCRIPT_PATH}")
        # Подключаем наш найденный скрипт
        stm32_add_linker_script(${TARGET_NAME} PRIVATE ${LINKER_SCRIPT_PATH})
    else()
        # Свой скрипт не найден, поэтому доверяем всё stm32-cmake.
        string(SUBSTRING ${MCU} 5 6 MCU_DEVICE)
        # Для многоядерных систем нужно явно указать ядро
        if(use_cmsis)
            if(mcu_core)
                list(APPEND CMSIS_TARGET_TO_LINK "CMSIS::STM32::${MCU_DEVICE}::${mcu_core}")
            else()
                list(APPEND CMSIS_TARGET_TO_LINK "CMSIS::STM32::${MCU_DEVICE}")
            endif()
        endif()
        message(STATUS "Подключение встроенного скрипта компоновщика: ${CMAKE_CURRENT_BINARY_DIR}/${MCU_DEVICE}.ld")
    endif()

else()
    # Для многоядерных систем нужно явно указать ядро
    if(use_cmsis)
        if(mcu_core)
            list(APPEND CMSIS_TARGET_TO_LINK "CMSIS::STM32::${MCU_TYPE}::${mcu_core}")
        else()
            list(APPEND CMSIS_TARGET_TO_LINK "CMSIS::STM32::${MCU_TYPE}")
        endif()
    endif()
    # Подключаем конфигурационный файл компоновщика.
    set(custom_script_path "${CMAKE_CURRENT_SOURCE_DIR}/${linker_script}")
    if(EXISTS ${custom_script_path})
        message(STATUS "Использование пользовательского скрипта компоновщика: ${custom_script_path}")
        stm32_add_linker_script(${TARGET_NAME} PRIVATE ${custom_script_path})
    else()
        message(FATAL_ERROR "Указанный скрипт компоновщика не найден: ${custom_script_path}")
    endif()
endif()

# =======================================================================
# 7. ФИНАЛЬНАЯ КОМПОНОВКА БИБЛИОТЕК.
# =======================================================================

# Обрабатываем список пользовательских статических библиотек.
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

# Теперь подключаем все библиотеки одним вызовом.
target_link_libraries(${TARGET_NAME} PRIVATE
    # Подключаем "матрёшку" CMSIS.
    ${CMSIS_TARGET_TO_LINK}

    # Подключаем цели HAL
    ${HAL_TARGETS}

    # Подключаем цели FreeRTOS
    ${FREERTOS_TARGETS}

    # Добавляем наши кастомные библиотеки
    ${CUSTOM_LIBRARY_PATHS}

    # Подключаем дополнительные библиотеки
    ${link_libraries}
)

# Генерируем артефакты сборки на основе списка из конфигурации.
stm32_print_size_of_target(${TARGET_NAME})

if("bin" IN_LIST build_artifacts)
    stm32_generate_binary_file(${TARGET_NAME})
endif()
if("hex" IN_LIST build_artifacts)
    stm32_generate_hex_file(${TARGET_NAME})
endif()
if("lss" IN_LIST build_artifacts)
    stm32_yml_generate_lss_file(${TARGET_NAME})
endif()

# =======================================================================
# 8. ОТЛАДОЧНЫЙ ВЫВОД СВОЙСТВ ЦЕЛИ
# =======================================================================

stm32_yml_ensure_default_value(log_target_properties "false")
if(log_target_properties)
    # --- БЛОК 1: Вывод свойств для финальной цели ${TARGET_NAME} ---
    # (Этот блок у вас уже есть)
    get_target_property(COMPILE_OPTIONS ${TARGET_NAME} COMPILE_OPTIONS)
    get_target_property(COMPILE_DEFINITIONS ${TARGET_NAME} COMPILE_DEFINITIONS)
    get_target_property(INCLUDE_DIRECTORIES ${TARGET_NAME} INCLUDE_DIRECTORIES)
    get_target_property(LINK_OPTIONS ${TARGET_NAME} LINK_OPTIONS)
    get_target_property(LINK_LIBRARIES ${TARGET_NAME} LINK_LIBRARIES)

    message(STATUS "--- Отладочная информация для финальной цели '${TARGET_NAME}' ---")

    string(REPLACE ";" " \n    " COMPILE_OPTIONS_FORMATTED "${COMPILE_OPTIONS}")
    string(REPLACE ";" " \n    " COMPILE_DEFINITIONS_FORMATTED "${COMPILE_DEFINITIONS}")
    string(REPLACE ";" " \n    " INCLUDE_DIRECTORIES_FORMATTED "${INCLUDE_DIRECTORIES}")
    string(REPLACE ";" " \n    " LINK_OPTIONS_FORMATTED "${LINK_OPTIONS}")
    string(REPLACE ";" " \n    " LINK_LIBRARIES_FORMATTED "${LINK_LIBRARIES}")

    message(STATUS "Опции компиляции (COMPILE_OPTIONS):\n    ${COMPILE_OPTIONS_FORMATTED}")
    message(STATUS "Определения компиляции (COMPILE_DEFINITIONS):\n    ${COMPILE_DEFINITIONS_FORMATTED}")
    message(STATUS "Директории для #include (INCLUDE_DIRECTORIES):\n    ${INCLUDE_DIRECTORIES_FORMATTED}")
    message(STATUS "Опции компоновки (LINK_OPTIONS):\n    ${LINK_OPTIONS_FORMATTED}")
    message(STATUS "Библиотеки для компоновки (LINK_LIBRARIES):\n    ${LINK_LIBRARIES_FORMATTED}")

    # =======================================================================
    # Вывод свойств для унаследованной цели STM32::${MCU_FAMILY}
    # =======================================================================
    set(STM32_FRAMEWORK_TARGET "STM32::${MCU_FAMILY}")

    # Проверяем, что цель существует, прежде чем запрашивать ее свойства
    if(TARGET ${STM32_FRAMEWORK_TARGET})
        # Для INTERFACE библиотек нужно запрашивать INTERFACE_* свойства
        get_target_property(STM32_COMPILE_OPTIONS ${STM32_FRAMEWORK_TARGET} INTERFACE_COMPILE_OPTIONS)
        get_target_property(STM32_COMPILE_DEFS  ${STM32_FRAMEWORK_TARGET} INTERFACE_COMPILE_DEFINITIONS)
        get_target_property(STM32_LINK_OPTIONS  ${STM32_FRAMEWORK_TARGET} INTERFACE_LINK_OPTIONS)
        get_target_property(STM32_INCLUDE_DIRS  ${STM32_FRAMEWORK_TARGET} INTERFACE_INCLUDE_DIRECTORIES)

        message(STATUS "\n--- Отладочная информация для унаследованной цели '${STM32_FRAMEWORK_TARGET}' ---")

        string(REPLACE ";" " \n    " STM32_COMPILE_OPTIONS_FMT "${STM32_COMPILE_OPTIONS}")
        string(REPLACE ";" " \n    " STM32_COMPILE_DEFS_FMT  "${STM32_COMPILE_DEFS}")
        string(REPLACE ";" " \n    " STM32_LINK_OPTIONS_FMT  "${STM32_LINK_OPTIONS}")
        string(REPLACE ";" " \n    " STM32_INCLUDE_DIRS_FMT  "${STM32_INCLUDE_DIRS}")

        message(STATUS "INTERFACE Опции компиляции:\n    ${STM32_COMPILE_OPTIONS_FMT}")
        message(STATUS "INTERFACE Определения компиляции:\n    ${STM32_COMPILE_DEFS_FMT}")
        message(STATUS "INTERFACE Опции компоновки:\n    ${STM32_LINK_OPTIONS_FMT}")
        #message(STATUS "INTERFACE Директории для #include:\n    ${STM32_INCLUDE_DIRS_FMT}")
    endif()
    # =======================================================================

    message(STATUS "---------------------------------------------------------------------------------")
endif()

# =======================================================================
# 9. САНИТАРНЫЕ ПРОВЕРКИ
# =======================================================================

# Проверка наличия файла hal_conf.h
if(use_hal)
    set(HAL_CONF_FILENAME "stm32${MCU_FAMILY_LOWER}xx_hal_conf.h")
    set(HAL_CONF_FOUND FALSE)

    # Получаем все пути, которые "видит" компилятор
    get_target_property(INCLUDE_DIRS ${TARGET_NAME} INCLUDE_DIRECTORIES)

    foreach(dir IN LISTS INCLUDE_DIRS)
        if(EXISTS "${dir}/${HAL_CONF_FILENAME}")
            set(HAL_CONF_FOUND TRUE)
            message(STATUS "Найден файл конфигурации HAL: ${dir}/${HAL_CONF_FILENAME}")
            break()
        endif()
    endforeach()

    if(NOT HAL_CONF_FOUND)
        message(FATAL_ERROR "Файл конфигурации HAL '${HAL_CONF_FILENAME}' не найден ни в одной из директорий, "
                            "указанных в 'include_directories'. Библиотека HAL не сможет скомпилироваться без него. "
                            "Убедитесь, что путь к этому файлу (например, 'Core/Inc') добавлен в 'include_directories' в project_config.yml.")
    endif()
endif()

# ПРОВЕРКА КОРРЕКТНОСТИ СКРИПТА КОМПОНОВЩИКА
stm32_yml_ensure_default_value(validate_linker_script "true") # Включаем проверку по умолчанию

if(validate_linker_script)
    message(STATUS "Выполнение проверки скрипта компоновщика...")

    # --- Шаг 1: Получаем эталонный размер RAM от stm32-cmake ---
    stm32_get_memory_info(CHIP ${mcu} RAM SIZE EXPECTED_RAM_SIZE_STR) # Получаем строку, например, "64K"

    # Конвертируем строку "64K" в байты для сравнения
    string(REGEX REPLACE "K$" " * 1024" EXPECTED_RAM_SIZE_EXPR "${EXPECTED_RAM_SIZE_STR}")
    math(EXPR EXPECTED_RAM_SIZE_BYTES "${EXPECTED_RAM_SIZE_EXPR}")

    # --- Шаг 2: Получаем размер RAM, реально используемый в сборке ---
    set(ACTUAL_RAM_SIZE_BYTES 0)

    # Проверяем, был ли сгенерирован/использован локальный скрипт
    if(LINKER_SCRIPT_PATH AND EXISTS ${LINKER_SCRIPT_PATH})
        # Читаем содержимое .ld файла (сгенерированного или кастомного)
        file(STRINGS ${LINKER_SCRIPT_PATH} ld_content REGEX "RAM \\(xrw\\) *: *ORIGIN *= *[0-9xA-Fa-f]+, *LENGTH *= *([0-9]+[KkMm])")

        if(ld_content)
            # Извлекаем значение LENGTH, например, "64K"
            string(REGEX MATCH "LENGTH *= *([0-9]+[KkMm])" ACTUAL_RAM_SIZE_STR "${ld_content}")
            set(ACTUAL_RAM_SIZE_STR ${CMAKE_MATCH_1})

            # Конвертируем строку "64K" в байты
            string(TOUPPER ${ACTUAL_RAM_SIZE_STR} ACTUAL_RAM_SIZE_STR_UPPER)
            string(REGEX REPLACE "K$" " * 1024" ACTUAL_RAM_SIZE_EXPR "${ACTUAL_RAM_SIZE_STR_UPPER}")
            string(REGEX REPLACE "M$" " * 1024 * 1024" ACTUAL_RAM_SIZE_EXPR "${ACTUAL_RAM_SIZE_EXPR}")
            math(EXPR ACTUAL_RAM_SIZE_BYTES "${ACTUAL_RAM_SIZE_EXPR}")
        else()
             message(WARNING "Не удалось извлечь размер RAM из скрипта ${LINKER_SCRIPT_PATH}. Проверка пропущена.")
        endif()

    else()
        # Если используется скрипт от stm32-cmake, размер RAM должен быть равен эталонному
        set(ACTUAL_RAM_SIZE_BYTES ${EXPECTED_RAM_SIZE_BYTES})
    endif()

    # --- Шаг 3: Сравниваем и выдаем ошибку, если есть несоответствие ---
    if(ACTUAL_RAM_SIZE_BYTES GREATER 0 AND ACTUAL_RAM_SIZE_BYTES LESS EXPECTED_RAM_SIZE_BYTES)
        message(WARNING "Размер RAM в скрипте компоновщика (${ACTUAL_RAM_SIZE_STR}) МЕНЬШЕ, чем ожидается для ${mcu} (${EXPECTED_RAM_SIZE_STR}). Это может привести к неиспользованию всей памяти.")

    elseif(ACTUAL_RAM_SIZE_BYTES GREATER EXPECTED_RAM_SIZE_BYTES)
        message(FATAL_ERROR "КРИТИЧЕСКАЯ ОШИБКА КОНФИГУРАЦИИ!\n"
                            "Размер RAM в вашем скрипте компоновщика (${ACTUAL_RAM_SIZE_STR}) БОЛЬШЕ, чем физически существует в ${mcu} (${EXPECTED_RAM_SIZE_STR}).\n"
                            "Это приведет к Hard Fault при запуске, так как указатель стека будет указывать на несуществующую память.\n"
                            "Исправьте 'LENGTH' для секции 'RAM' в вашем .ld или .ld.in файле!")
    else()
        message(STATUS "Проверка размера RAM в скрипте компоновщика пройдена успешно. (${EXPECTED_RAM_SIZE_STR})")
    endif()
endif()

endfunction()
