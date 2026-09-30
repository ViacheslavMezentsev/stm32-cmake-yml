# ==============================================================================
# КАТАЛОГ СООБЩЕНИЙ stm32-cmake-yml (ТЗ 4.16.5, 4.16.6)
# ==============================================================================
# Формат: stm32_yml_msg_def(<код> [RETIRED] "<текст RU>" "<текст EN>")
#
# Код — класс и три цифры. Класс: I — STATUS, W — WARNING, E — FATAL_ERROR.
# Сотня — модуль: 0xx ядро и чтение конфигурации, 1xx профили, 2xx IOC,
# 3xx исходники и модули, 4xx CMSIS/HAL/FreeRTOS, 5xx Arduino, 6xx скрипт
# компоновщика, 7xx артефакты и CRC, 8xx диагностика; 9xx — только тесты.
# Коды не переиспользуются: исключённое сообщение остаётся с пометкой RETIRED.
#
# Параметры — {1} … {n}, одинаковые в обоих языках. Переменные CMake в текстах
# не используются. Тексты проверяет ci/check_messages.py.
# ==============================================================================

# --- 0xx: ядро и чтение конфигурации ------------------------------------------

stm32_yml_msg_def(E001
    "Внутренняя ошибка stm32-cmake-yml: неизвестный код сообщения '{1}'."
    "stm32-cmake-yml internal error: unknown message code '{1}'.")
stm32_yml_msg_def(E002
    "Внутренняя ошибка stm32-cmake-yml: сообщение '{1}' ожидает параметров: {2}, передано: {3}."
    "stm32-cmake-yml internal error: message '{1}' expects {2} parameters, got {3}.")
stm32_yml_msg_def(W001
    "Неизвестное значение STM32_YML_LANG '{1}': язык выбирается как при auto. Допустимые значения: auto, ru, en."
    "Unknown STM32_YML_LANG value '{1}': the language is chosen as for auto. Valid values: auto, ru, en.")

stm32_yml_msg_def(I001
    "stm32-cmake-yml версия: {1}"
    "stm32-cmake-yml version: {1}")
stm32_yml_msg_def(I002
    "Версия в конфигурации: не указана (stm32_cmake_yml_version в {1})"
    "Configuration version: not set (stm32_cmake_yml_version in {1})")
stm32_yml_msg_def(I003
    "Версия в конфигурации: {1}  (совпадают ✓)"
    "Configuration version: {1}  (match ✓)")
stm32_yml_msg_def(I004
    "Версия в конфигурации: {1}  (конфиг новее — обновите фреймворк !)"
    "Configuration version: {1}  (configuration is newer — update the framework!)")
stm32_yml_msg_def(I005
    "Версия в конфигурации: {1}  (фреймворк новее — обновите конфиг)"
    "Configuration version: {1}  (framework is newer — update the configuration)")
stm32_yml_msg_def(W002
    "В файле '{1}' не указан рекомендуемый параметр 'stm32_cmake_yml_version'. Укажите версию фреймворка, для которой написана конфигурация (ТЗ 4.2.3)."
    "The recommended parameter 'stm32_cmake_yml_version' is not set in '{1}'. Set the framework version the configuration was written for (spec 4.2.3).")
stm32_yml_msg_def(W003
    "Версия фреймворка ({1}) старше, чем требуется конфигом ({2}). Возможны ошибки."
    "The framework version ({1}) is older than the configuration requires ({2}). Errors are possible.")
stm32_yml_msg_def(W004
    "Версия фреймворка ({1}) новее, чем указано в конфиге ({2}). Рекомендуется обновить stm32_cmake_yml_version."
    "The framework version ({1}) is newer than the configuration states ({2}). Update stm32_cmake_yml_version.")
stm32_yml_msg_def(E003
    "Инструмент 'yq' не найден. Пожалуйста, установите его."
    "The 'yq' tool is not found. Please install it.")
stm32_yml_msg_def(E004
    "Файл конфигурации не найден: {1}"
    "Configuration file not found: {1}")
stm32_yml_msg_def(E005
    "Ошибка при конвертации {1} в JSON с помощью yq."
    "yq failed to convert {1} to JSON.")
stm32_yml_msg_def(E006
    "Недопустимый формат размера памяти '{1}: {2}'. Укажите целое число байт или целое число с суффиксом K или M в верхнем регистре, например: 0, 1536, 2K, 1M."
    "Invalid memory size format '{1}: {2}'. Use an integer number of bytes or an integer with an upper-case K or M suffix, for example: 0, 1536, 2K, 1M.")
stm32_yml_msg_def(E007
    "mcu_core: '{1}' недопустим для {2}: stm32-cmake не выделяет ядра для этого MCU. Удалите mcu_core из конфигурации."
    "mcu_core: '{1}' is not valid for {2}: stm32-cmake does not split cores for this MCU. Remove mcu_core from the configuration.")
stm32_yml_msg_def(E008
    "У {1} несколько ядер ({2}): укажите mcu_core, например 'mcu_core: {3}'."
    "{1} has several cores ({2}): set mcu_core, for example 'mcu_core: {3}'.")
stm32_yml_msg_def(E009
    "mcu_core: '{1}' недопустим для {2}. Допустимые значения: {3}."
    "mcu_core: '{1}' is not valid for {2}. Valid values: {3}.")
stm32_yml_msg_def(W005
    "Неизвестное значение '{1}' параметра '{2}'. Известные значения: {3}. Применяется '{4}'."
    "Unknown value '{1}' of parameter '{2}'. Known values: {3}. '{4}' is applied.")
stm32_yml_msg_def(W006
    "Неизвестное значение '{1}' параметра '{2}'. Известные значения: {3}. Значение не используется."
    "Unknown value '{1}' of parameter '{2}'. Known values: {3}. The value is not used.")
stm32_yml_msg_def(W007
    "Неизвестный элемент '{1}' параметра '{2}'. Известные значения: {3}. Элемент пропускается."
    "Unknown item '{1}' of parameter '{2}'. Known values: {3}. The item is skipped.")
stm32_yml_msg_def(I010
    "Включен подробный вывод команд сборки (CMAKE_VERBOSE_MAKEFILE=ON)."
    "Verbose build output is enabled (CMAKE_VERBOSE_MAKEFILE=ON).")
stm32_yml_msg_def(I011
    "Флаги только для C:   {1}"
    "C-only flags:     {1}")
stm32_yml_msg_def(I012
    "Defines только для C: {1}"
    "C-only defines:   {1}")
stm32_yml_msg_def(I013
    "Флаги только для C++: {1}"
    "C++-only flags:   {1}")
stm32_yml_msg_def(I014
    "Defines только для C++: {1}"
    "C++-only defines: {1}")
stm32_yml_msg_def(I020
    "Итоговые параметры проекта (источник: [yml]=конфиг / [ioc]=CubeMX / [auto]=авто):"
    "Final project parameters (source: [yml]=configuration / [ioc]=CubeMX / [auto]=automatic):")
stm32_yml_msg_def(I021
    "  MCU:        {1}  {2}"
    "  MCU:        {1}  {2}")
stm32_yml_msg_def(I022
    "  Проект:     {1}  {2}"
    "  Project:    {1}  {2}")
stm32_yml_msg_def(I023
    "  CubeFW:     {1}  {2}"
    "  CubeFW:     {1}  {2}")
stm32_yml_msg_def(I024
    "  Heap Size:  {1} байт  {2}"
    "  Heap Size:  {1} bytes  {2}")
stm32_yml_msg_def(I025
    "  Stack Size: {1} байт  {2}"
    "  Stack Size: {1} bytes  {2}")
stm32_yml_msg_def(I026
    "  FreeRTOS:   ОТКЛЮЧЕН (переопределено в .yml)  [yml]"
    "  FreeRTOS:   DISABLED (overridden in .yml)  [yml]")
stm32_yml_msg_def(I027
    "  FreeRTOS:   Включен  {1}"
    "  FreeRTOS:   Enabled  {1}")
stm32_yml_msg_def(I028
    "    API:      {1}  {2}"
    "    API:      {1}  {2}")
stm32_yml_msg_def(I029
    "    Порт:     {1}  {2}"
    "    Port:     {1}  {2}")
stm32_yml_msg_def(I030
    "  FreeRTOS:   Отключен"
    "  FreeRTOS:   Disabled")
stm32_yml_msg_def(I031
    "Режим ручной конфигурации (ioc_file не указан)."
    "Manual configuration mode (ioc_file is not set).")
stm32_yml_msg_def(I032
    "Определено имя проекта: {1}"
    "Project name: {1}")
stm32_yml_msg_def(I033
    "Языки проекта не указаны. Используется по умолчанию: {1}"
    "Project languages are not set. The default is used: {1}")
stm32_yml_msg_def(I034
    "Используются языки проекта из конфига: {1}"
    "Project languages from the configuration: {1}")
stm32_yml_msg_def(I035
    "Конфигурация из {1} успешно загружена."
    "Configuration loaded from {1}.")
stm32_yml_msg_def(I036
    "Размер памяти '{1}' нормализован в {2} байт."
    "Memory size '{1}' normalized to {2} bytes.")
stm32_yml_msg_def(I037
    "Параметр '{1}' не был задан или был пуст. Установлено значение по умолчанию: '{2}'."
    "Parameter '{1}' was not set or was empty. The default value is used: '{2}'.")
stm32_yml_msg_def(I038
    "Ядро MCU не задано, используется единственное ядро {1}: {2}."
    "The MCU core is not set; the only core of {1} is used: {2}.")
stm32_yml_msg_def(I039
    "Ядро MCU: {1}"
    "MCU core: {1}")

# --- 1xx: профили -------------------------------------------------------------

stm32_yml_msg_def(E101
    "Передайте -DSTM32_YML_PROFILE=<имя> для выбора профиля."
    "Pass -DSTM32_YML_PROFILE=<name> to select a profile.")
stm32_yml_msg_def(W101
    "Профиль '{1}' не найден в конфигурации. Доступные профили можно посмотреть в секции 'profiles:' файла {2}."
    "Profile '{1}' is not found in the configuration. See the 'profiles:' section of {2} for the available profiles.")
stm32_yml_msg_def(W102
    "Встроенная секция 'profiles:' игнорируется (профили: {1}): задан profiles_file '{2}', профили берутся только из него. Перенесите нужные профили во внешний файл или удалите встроенную секцию."
    "The inline 'profiles:' section is ignored (profiles: {1}): profiles_file '{2}' is set and profiles are taken only from it. Move the profiles you need to the external file or remove the inline section.")
stm32_yml_msg_def(W103
    "Файл профилей не найден: {1}"
    "Profiles file not found: {1}")
stm32_yml_msg_def(I101
    "Применение профиля сборки: '{1}'"
    "Applying build profile: '{1}'")
stm32_yml_msg_def(I102
    "  [профиль] {1} = {2}"
    "  [profile] {1} = {2}")
stm32_yml_msg_def(I103
    "  [профиль +] {1} += {2}"
    "  [profile +] {1} += {2}")
stm32_yml_msg_def(I104
    "  [override] {1} = {2}"
    "  [override] {1} = {2}")
stm32_yml_msg_def(I105
    "Применено точечных cmake-overrides: {1}."
    "CMake overrides applied: {1}.")
stm32_yml_msg_def(I106
    "Доступные профили сборки:"
    "Available build profiles:")
stm32_yml_msg_def(I107
    "  - {1}"
    "  - {1}")
stm32_yml_msg_def(I108
    "Профили сборки не определены в конфигурации."
    "No build profiles are defined in the configuration.")
stm32_yml_msg_def(I109
    "Загрузка профилей из внешнего файла: {1}"
    "Loading profiles from the external file: {1}")

# --- 2xx: IOC -----------------------------------------------------------------

stm32_yml_msg_def(E201
    "Указанный .ioc файл не найден: {1}"
    "The specified .ioc file is not found: {1}")
stm32_yml_msg_def(I201
    "Обнаружена настройка 'ioc_file'. Чтение данных из: {1} ..."
    "'ioc_file' is set. Reading data from: {1} ...")
stm32_yml_msg_def(I202
    "Используется CustomerFirmwarePackage: семейство={1}, версия={2}"
    "Using CustomerFirmwarePackage: family={1}, version={2}")
stm32_yml_msg_def(I203
    "  Путь: {1}"
    "  Path: {1}")

# --- 3xx: исходники и модули --------------------------------------------------

stm32_yml_msg_def(W301
    "Пользовательская библиотека не найдена и будет проигнорирована: {1}"
    "Custom library not found and ignored: {1}")
stm32_yml_msg_def(I301
    "Подключение пользовательской библиотеки: {1}"
    "Adding custom library: {1}")

# --- 4xx: CMSIS, HAL, FreeRTOS ------------------------------------------------

stm32_yml_msg_def(E401
    "Директория STM32Cube не найдена по пути: {1}"
    "STM32Cube directory not found: {1}")
stm32_yml_msg_def(E402
    "Не найдено ни одного пакета для семейства {1} в {2}"
    "No package for family {1} found in {2}")
stm32_yml_msg_def(E403
    "Не удалось определить версию из найденных папок для {1}."
    "Could not determine the version from the directories found for {1}.")
stm32_yml_msg_def(W401
    "Порт FreeRTOS для '{1}' не определён таблицей фреймворка; используется ARM_CM4F. Задайте freertos_components явно."
    "The framework table has no FreeRTOS port for '{1}'; ARM_CM4F is used. Set freertos_components explicitly.")

# --- 7xx: артефакты и CRC -----------------------------------------------------

stm32_yml_msg_def(W701
    "bin: не удалось определить регион FLASH скрипта компоновщика или найти Python3; BIN создаётся objcopy -O binary и может оказаться большим, если в ELF есть секции вне Flash."
    "bin: could not find the FLASH region of the linker script or Python3; BIN is created by objcopy -O binary and may be large if the ELF has sections outside Flash.")
