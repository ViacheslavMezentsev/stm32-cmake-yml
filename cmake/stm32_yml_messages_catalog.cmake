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
stm32_yml_msg_def(I040
    "Версии компонентов:"
    "Component versions:")
stm32_yml_msg_def(I041
    "  {1}: {2}"
    "  {1}: {2}")
stm32_yml_msg_def(I042
    "  Компилятор: {1} {2}"
    "  Compiler: {1} {2}")
stm32_yml_msg_def(I043
    "  Компилятор: версия не определена"
    "  Compiler: version unknown")
stm32_yml_msg_def(I044
    "  {1}: версия не определена"
    "  {1}: version unknown")

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
stm32_yml_msg_def(W302
    "Источник '{1}' не найден и будет проигнорирован."
    "Source '{1}' not found and ignored.")
stm32_yml_msg_def(I302
    "Обнаружен пользовательский system-файл. Переопределение: {1}"
    "Custom system file found. Override: {1}")
stm32_yml_msg_def(I303
    "Обнаружен пользовательский startup-файл. Переопределение: {1}"
    "Custom startup file found. Override: {1}")

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
stm32_yml_msg_def(E404
    "Не удалось определить пути к драйверам HAL/CMSIS. Проверьте 'cubefw_package'."
    "Could not determine the HAL/CMSIS driver paths. Check 'cubefw_package'.")
stm32_yml_msg_def(E405
    "use_hal: true требует use_cmsis: true."
    "use_hal: true requires use_cmsis: true.")
stm32_yml_msg_def(E406
    "Компонент HAL '{1}' (hal_components) не найден для семейства {2}: нет цели {3}. Проверьте имя драйвера в пакете STM32Cube {2}."
    "HAL component '{1}' (hal_components) is not found for family {2}: there is no target {3}. Check the driver name in the STM32Cube {2} package.")
stm32_yml_msg_def(E407
    "Компонент HAL '{1}' (hal_components) не найден для семейства {2} (ядро {3}): нет цели {4}. Проверьте имя драйвера в пакете STM32Cube {2}."
    "HAL component '{1}' (hal_components) is not found for family {2} (core {3}): there is no target {4}. Check the driver name in the STM32Cube {2} package.")
stm32_yml_msg_def(E408
    "Найдено несколько портов FreeRTOS: '{1}' и '{2}'."
    "Several FreeRTOS ports found: '{1}' and '{2}'.")
stm32_yml_msg_def(E409
    "В 'freertos_components' не найден порт (например, 'ARM_CM4F')."
    "No port found in 'freertos_components' (for example, 'ARM_CM4F').")
stm32_yml_msg_def(E410
    "freertos_version: external требует путь к FreeRTOS: задайте FREERTOS_PATH (-DFREERTOS_PATH=... или переменная окружения) — каталог FreeRTOS-Kernel или Middlewares/Third_Party/FreeRTOS пакета STM32Cube."
    "freertos_version: external requires a FreeRTOS path: set FREERTOS_PATH (-DFREERTOS_PATH=... or an environment variable) to a FreeRTOS-Kernel directory or to Middlewares/Third_Party/FreeRTOS of an STM32Cube package.")
stm32_yml_msg_def(E411
    "freertos_version: external: в FREERTOS_PATH '{1}' не найдены FreeRTOS.h и tasks.c. Ожидается раскладка FreeRTOS-Kernel (include/, portable/GCC/<порт>) или дерева Cube (Source/...)."
    "freertos_version: external: FreeRTOS.h and tasks.c are not found in FREERTOS_PATH '{1}'. Expected a FreeRTOS-Kernel layout (include/, portable/GCC/<port>) or a Cube tree (Source/...).")
stm32_yml_msg_def(E412
    "freertos_version: external: файлы порта '{1}' не найдены в FREERTOS_PATH '{2}' (portable/GCC/{1})."
    "freertos_version: external: port '{1}' files are not found in FREERTOS_PATH '{2}' (portable/GCC/{1}).")
stm32_yml_msg_def(E413
    "Компонент FreeRTOS '{1}' (freertos_components) не найден: нет цели {2} в пространстве {3}."
    "FreeRTOS component '{1}' (freertos_components) is not found: there is no target {2} in the {3} namespace.")
stm32_yml_msg_def(E414
    "cmsis_rtos_api: {1}: обёртка CMSIS-RTOS не найдена (нет цели {2}). Её исходники берутся из Middlewares/Third_Party/FreeRTOS пакета STM32Cube {3} и требуют use_cmsis: true; в пакете может не быть FreeRTOS (например, H5, U5). Используйте cmsis_rtos_api: none."
    "cmsis_rtos_api: {1}: the CMSIS-RTOS wrapper is not found (there is no target {2}). Its sources come from Middlewares/Third_Party/FreeRTOS of the STM32Cube {3} package and require use_cmsis: true; the package may have no FreeRTOS (for example, H5, U5). Use cmsis_rtos_api: none.")
stm32_yml_msg_def(I401
    "Режим 'auto': поиск драйверов..."
    "'auto' mode: looking for drivers...")
stm32_yml_msg_def(I402
    "Обнаружены локальные драйверы в '{1}'. Используются они."
    "Local drivers found in '{1}'. They are used.")
stm32_yml_msg_def(I403
    "STM32Cube MCU Firmware Package: {1}"
    "STM32Cube MCU Firmware Package: {1}")
stm32_yml_msg_def(I404
    "Локальные драйверы не найдены. Поиск последней версии в пользовательском репозитории..."
    "No local drivers found. Looking for the latest version in the user repository...")
stm32_yml_msg_def(I405
    "Использование найденной версии STM32Cube FW: {1}"
    "Using the STM32Cube FW version found: {1}")
stm32_yml_msg_def(I406
    "Использование указанной версии STM32Cube FW: {1}"
    "Using the specified STM32Cube FW version: {1}")
stm32_yml_msg_def(I407
    "Автоматическое подключение CMSIS включено."
    "Automatic CMSIS integration is enabled.")
stm32_yml_msg_def(I408
    "Автоматическое подключение компонентов HAL/LL включено."
    "Automatic HAL/LL component integration is enabled.")
stm32_yml_msg_def(I409
    "Автоматическое подключение компонентов HAL/LL отключено."
    "Automatic HAL/LL component integration is disabled.")
stm32_yml_msg_def(I410
    "Автоматическое подключение FreeRTOS включено."
    "Automatic FreeRTOS integration is enabled.")
stm32_yml_msg_def(I411
    "Используется порт FreeRTOS: {1}"
    "FreeRTOS port: {1}")
stm32_yml_msg_def(I412
    "FreeRTOS: к порту {1} добавлен {2}"
    "FreeRTOS: {2} added to port {1}")
stm32_yml_msg_def(I413
    "Подключена обертка CMSIS-RTOS API {1}."
    "CMSIS-RTOS API {1} wrapper added.")

# --- 5xx: Arduino -------------------------------------------------------------

stm32_yml_msg_def(E501
    "[arduino] Параметр arduino.core_path не задан в stm32_config.yml.\nУкажите путь к папке Arduino_Core_STM32 относительно корня проекта:\n  arduino:\n    core_path: \"modules/Arduino_Core_STM32\""
    "[arduino] arduino.core_path is not set in stm32_config.yml.\nSet the path to the Arduino_Core_STM32 folder relative to the project root:\n  arduino:\n    core_path: \"modules/Arduino_Core_STM32\"")
stm32_yml_msg_def(E502
    "[arduino] Папка Arduino Core STM32 не найдена: {1}\nПроверьте значение arduino.core_path в stm32_config.yml.\nВ CI убедитесь, что симлинк или папка modules/Arduino_Core_STM32 существует."
    "[arduino] Arduino Core STM32 folder not found: {1}\nCheck arduino.core_path in stm32_config.yml.\nIn CI make sure the modules/Arduino_Core_STM32 symlink or folder exists.")
stm32_yml_msg_def(W501
    "[arduino] Параметр arduino.mcu_target не задан. CMakeLists.txt библиотек, зависящих от MCU_TARGET, могут завершиться ошибкой."
    "[arduino] arduino.mcu_target is not set. CMakeLists.txt of libraries that depend on MCU_TARGET may fail.")
stm32_yml_msg_def(W502
    "[arduino] CMakeLists.txt ядра Arduino не найден: {1}\nУкажите правильный путь через arduino.core_cmake_dir в stm32_config.yml."
    "[arduino] Arduino core CMakeLists.txt not found: {1}\nSet the correct path with arduino.core_cmake_dir in stm32_config.yml.")
stm32_yml_msg_def(W503
    "[arduino] Библиотека '{1}' не найдена в {2}.\nПроверьте имя в arduino.libraries и наличие CMakeLists.txt."
    "[arduino] Library '{1}' not found in {2}.\nCheck the name in arduino.libraries and that CMakeLists.txt exists.")
stm32_yml_msg_def(W504
    "[arduino] Кастомная библиотека не найдена: {1}."
    "[arduino] Custom library not found: {1}.")
stm32_yml_msg_def(I501
    "Arduino Core STM32: {1}"
    "Arduino Core STM32: {1}")
stm32_yml_msg_def(I502
    "Arduino MCU_TARGET: {1}"
    "Arduino MCU_TARGET: {1}")
stm32_yml_msg_def(I503
    "Arduino::Definitions создан."
    "Arduino::Definitions created.")
stm32_yml_msg_def(I504
    "Arduino USE_CORE_MAIN: {1}"
    "Arduino USE_CORE_MAIN: {1}")
stm32_yml_msg_def(I505
    "Подключение Arduino Core: {1}"
    "Adding Arduino Core: {1}")
stm32_yml_msg_def(I506
    "Подключение Arduino библиотеки: {1}"
    "Adding Arduino library: {1}")
stm32_yml_msg_def(I507
    "Подключение кастомной библиотеки: {1}"
    "Adding custom library: {1}")

# --- 6xx: скрипт компоновщика -------------------------------------------------

stm32_yml_msg_def(E601
    "В режиме Arduino Backend генерация скрипта без локального шаблона не поддерживается. Добавьте шаблон или укажите готовый скрипт."
    "The Arduino backend cannot generate a linker script without a local template. Add a template or set a ready linker script.")
stm32_yml_msg_def(E602
    "Указанный скрипт компоновщика не найден: '{1}'\nПапки поиска: {2}"
    "The specified linker script is not found: '{1}'\nSearch directories: {2}")
stm32_yml_msg_def(W601
    "Заданные размеры памяти ({1}) не применяются: скрипт компоновщика формирует stm32-cmake с собственными размерами heap {2} и stack {3} байт. Добавьте шаблон {4} (в корень проекта или linker_script_dir) или задайте размеры в явном linker_script."
    "The memory sizes set ({1}) are not applied: stm32-cmake generates the linker script with its own sizes, heap {2} and stack {3} bytes. Add a {4} template (to the project root or linker_script_dir) or set the sizes in an explicit linker_script.")
stm32_yml_msg_def(W602
    "Заданные размеры памяти ({1}) не применяются: размеры задаёт явный скрипт компоновщика '{2}'. Измените их в скрипте или используйте шаблон .ld.in (linker_script: auto)."
    "The memory sizes set ({1}) are not applied: the explicit linker script '{2}' sets the sizes. Change them in the script or use an .ld.in template (linker_script: auto).")
stm32_yml_msg_def(W603
    "Startup {1} задаёт границу стека (MSPLIM) по символу _sstack, но скрипт компоновщика {2} его не определяет: компоновка завершится ошибкой 'undefined reference to _sstack'. Добавьте в шаблон .ld.in или явный скрипт строку '_sstack = _estack - _Min_Stack_Size;' либо подключите через sources собственный startup без MSPLIM."
    "Startup {1} sets the stack limit (MSPLIM) from the _sstack symbol, but linker script {2} does not define it: linking will fail with 'undefined reference to _sstack'. Add the line '_sstack = _estack - _Min_Stack_Size;' to the .ld.in template or the explicit script, or add your own startup without MSPLIM through sources.")
stm32_yml_msg_def(W604
    "Startup {1} задаёт границу стека (MSPLIM) по символу _sstack, но скрипт компоновщика stm32-cmake его не определяет: компоновка завершится ошибкой 'undefined reference to _sstack'. Добавьте в шаблон .ld.in или явный скрипт строку '_sstack = _estack - _Min_Stack_Size;' либо подключите через sources собственный startup без MSPLIM."
    "Startup {1} sets the stack limit (MSPLIM) from the _sstack symbol, but the stm32-cmake linker script does not define it: linking will fail with 'undefined reference to _sstack'. Add the line '_sstack = _estack - _Min_Stack_Size;' to an .ld.in template or an explicit script, or add your own startup without MSPLIM through sources.")
stm32_yml_msg_def(I601
    "Папка поиска скрипта компоновщика: {1}"
    "Linker script search directory: {1}")
stm32_yml_msg_def(I602
    "Генерация скрипта компоновщика из шаблона..."
    "Generating the linker script from a template...")
stm32_yml_msg_def(I603
    "Найден локальный шаблон: {1}"
    "Local template found: {1}")
stm32_yml_msg_def(I604
    "В скрипте компоновщика используется READONLY (GCC >= 11.0)"
    "Using READONLY in linker script (GCC >= 11.0)")
stm32_yml_msg_def(I605
    "В скрипте компоновщика не используется READONLY (GCC < 11.0)"
    "Not using READONLY in linker script (GCC < 11.0)")
stm32_yml_msg_def(I606
    "Локальный шаблон не найден. Будет использован стандартный скрипт компоновщика."
    "No local template found. The standard linker script is used.")
stm32_yml_msg_def(I607
    "Подключение скрипта компоновщика: {1}"
    "Adding linker script: {1}")
stm32_yml_msg_def(I608
    "Подключение встроенного скрипта компоновщика: {1}"
    "Adding the built-in linker script: {1}")
stm32_yml_msg_def(I609
    "Использование пользовательского скрипта компоновщика: {1}"
    "Using the custom linker script: {1}")

# --- 7xx: артефакты и CRC -----------------------------------------------------

stm32_yml_msg_def(W701
    "bin: не удалось определить регион FLASH скрипта компоновщика или найти Python3; BIN создаётся objcopy -O binary и может оказаться большим, если в ELF есть секции вне Flash."
    "bin: could not find the FLASH region of the linker script or Python3; BIN is created by objcopy -O binary and may be large if the ELF has sections outside Flash.")
stm32_yml_msg_def(E701
    "crc_enable: скрипт компоновщика формирует stm32-cmake, секции '{1}' (crc_section_name) в нём нет. Используйте шаблон STM32<MCU>_FLASH.ld.in (linker_script: auto) или явный linker_script с секцией '{1}', либо crc_enable: false."
    "crc_enable: stm32-cmake generates the linker script and it has no '{1}' section (crc_section_name). Use an STM32<MCU>_FLASH.ld.in template (linker_script: auto) or an explicit linker_script with a '{1}' section, or crc_enable: false.")
stm32_yml_msg_def(W702
    " Расчет CRC отключен. Не удалось автоматически определить размер FLASH из {1}. Задайте 'flash_size' в stm32_config.yml."
    " CRC calculation is disabled. Could not determine the FLASH size from {1}. Set 'flash_size' in stm32_config.yml.")
stm32_yml_msg_def(W703
    "crc_enable: секция '{1}' (crc_section_name) не найдена в скрипте {2}. Шаг CRC после сборки завершится ошибкой."
    "crc_enable: section '{1}' (crc_section_name) is not found in script {2}. The post-build CRC step will fail.")
stm32_yml_msg_def(W704
    " Расчет CRC отключен. Не удалось определить регион FLASH (ORIGIN, LENGTH) в скрипте {1}."
    " CRC calculation is disabled. Could not determine the FLASH region (ORIGIN, LENGTH) in script {1}.")
stm32_yml_msg_def(W705
    " Интерпретатор Python3 не найден. Расчет CRC отключен."
    " Python3 interpreter not found. CRC calculation is disabled.")
stm32_yml_msg_def(W706
    " Утилита objcopy не найдена. Расчет CRC отключен."
    " objcopy not found. CRC calculation is disabled.")
stm32_yml_msg_def(W707
    " Скрипт расчета не найден по пути: {1}. Расчет CRC отключен."
    " CRC script not found: {1}. CRC calculation is disabled.")
stm32_yml_msg_def(I701
    "Настройка механизма внедрения CRC32 в прошивку..."
    "Setting up CRC32 injection into the firmware...")
stm32_yml_msg_def(I702
    " Метод: Внедрение в секцию '{1}'"
    " Method: injection into section '{1}'")
stm32_yml_msg_def(I703
    " Алгоритм: {1}"
    " Algorithm: {1}")
stm32_yml_msg_def(I704
    " Регион FLASH скрипта: ORIGIN {1}, LENGTH {2} байт"
    " Script FLASH region: ORIGIN {1}, LENGTH {2} bytes")
stm32_yml_msg_def(I705
    " Max Flash Size: {1} байт ({2})"
    " Max Flash Size: {1} bytes ({2})")
stm32_yml_msg_def(I706
    " Сборка будет выполнена БЕЗ добавления контрольной суммы."
    " The build runs WITHOUT adding a checksum.")

# Сообщения скрипта scripts/stm32_crc.py при сборке (ТЗ 4.16.11). Английский
# текст совпадает с FALLBACK скрипта.

stm32_yml_msg_def(E702
    "'{1}' не является 32-битным ELF-файлом little-endian"
    "'{1}' is not a 32-bit little-endian ELF file")
stm32_yml_msg_def(E703
    "Нет загружаемых секций в FLASH 0x{1}+0x{2} в '{3}'"
    "No loadable sections inside FLASH 0x{1}+0x{2} in '{3}'")
stm32_yml_msg_def(E704
    "Недопустимое число '{1}' в {2}"
    "Invalid number '{1}' in {2}")
stm32_yml_msg_def(E705
    "Недопустимое значение --flash '{1}', ожидается <начало>:<длина>"
    "Invalid --flash value '{1}', expected <origin>:<length>")
stm32_yml_msg_def(E706
    "Образ для CRC больше предела FLASH: {1} > {2} байт. Проверьте 'flash_size' и регион FLASH скрипта компоновщика."
    "CRC image is larger than the FLASH limit: {1} > {2} bytes. Check 'flash_size' and the FLASH region of the linker script.")
stm32_yml_msg_def(E707
    "Передайте <выход.bin> для CRC или --image для образа FLASH"
    "Pass <output.bin> for the CRC or --image for the FLASH image")
stm32_yml_msg_def(E708
    "Сборка прервана: CRC не рассчитан."
    "Build failed: CRC was not calculated.")
stm32_yml_msg_def(E709
    "Входной файл '{1}' не найден."
    "Input file '{1}' not found.")
stm32_yml_msg_def(E710
    "Использование: stm32_crc.py <вход.bin> <выход.bin> [предел] | --elf <вход.elf> --flash <начало>:<длина> --exclude <секция> <выход.bin> [предел]"
    "Usage: stm32_crc.py <input.bin> <output.bin> [limit] | --elf <input.elf> --flash <origin>:<length> --exclude <section> <output.bin> [limit]")
stm32_yml_msg_def(E711
    "Ошибка ввода-вывода: {1}"
    "I/O error: {1}")
stm32_yml_msg_def(I707
    "{1} Пропущена секция {2}: адрес загрузки 0x{3} ({4} байт) вне FLASH"
    "{1} Skipped {2}: load address 0x{3} ({4} bytes) is outside FLASH")
stm32_yml_msg_def(I708
    "{1} Записан {2}: {3} байт с адреса 0x{4}"
    "{1} Written {2}: {3} bytes from 0x{4}")
stm32_yml_msg_def(I709
    "[STM32 CRC32] Рассчитано: 0x{1} (размер: {2} байт с адреса 0x{3})"
    "[STM32 CRC32] Calculated: 0x{1} (Size: {2} bytes from 0x{3})")
stm32_yml_msg_def(I710
    "[STM32 CRC32] Рассчитано: 0x{1} (размер: {2} байт)"
    "[STM32 CRC32] Calculated: 0x{1} (Size: {2} bytes)")

# --- 8xx: диагностика ---------------------------------------------------------

stm32_yml_msg_def(E801
    "Файл конфигурации HAL '{1}' не найден ни в одной из директорий, указанных в 'include_directories'. Библиотека HAL не сможет скомпилироваться без него. Убедитесь, что путь к этому файлу (например, 'Core/Inc') добавлен в 'include_directories' в {2}."
    "HAL configuration file '{1}' is not found in any directory listed in 'include_directories'. The HAL library cannot compile without it. Make sure its path (for example, 'Core/Inc') is in 'include_directories' in {2}.")
stm32_yml_msg_def(W801
    "Не найдено ни одной RAM-секции (xrw/rw) в скрипте {1}. Проверка размера пропущена."
    "No RAM section (xrw/rw) found in script {1}. The size check is skipped.")
stm32_yml_msg_def(W802
    "Параметр 'cppcheck_enable' установлен, но утилита не найдена!"
    "'cppcheck_enable' is set, but the tool is not found!")
stm32_yml_msg_def(I801
    "--- Отладочная информация для финальной цели '{1}' ---"
    "--- Debug information for the final target '{1}' ---")
stm32_yml_msg_def(I802
    "Опции компиляции (COMPILE_OPTIONS):\n    {1}"
    "Compile options (COMPILE_OPTIONS):\n    {1}")
stm32_yml_msg_def(I803
    "Определения компиляции (COMPILE_DEFINITIONS):\n    {1}"
    "Compile definitions (COMPILE_DEFINITIONS):\n    {1}")
stm32_yml_msg_def(I804
    "Директории для #include (INCLUDE_DIRECTORIES):\n    {1}"
    "#include directories (INCLUDE_DIRECTORIES):\n    {1}")
stm32_yml_msg_def(I805
    "Опции компоновки (LINK_OPTIONS):\n    {1}"
    "Link options (LINK_OPTIONS):\n    {1}")
stm32_yml_msg_def(I806
    "Библиотеки для компоновки (LINK_LIBRARIES):\n    {1}"
    "Link libraries (LINK_LIBRARIES):\n    {1}")
stm32_yml_msg_def(I807
    "\n--- Отладочная информация для унаследованной цели '{1}' ---"
    "\n--- Debug information for the inherited target '{1}' ---")
stm32_yml_msg_def(I808
    "INTERFACE Опции компиляции:\n    {1}"
    "INTERFACE compile options:\n    {1}")
stm32_yml_msg_def(I809
    "INTERFACE Определения компиляции:\n    {1}"
    "INTERFACE compile definitions:\n    {1}")
stm32_yml_msg_def(I810
    "INTERFACE Опции компоновки:\n    {1}"
    "INTERFACE link options:\n    {1}")
stm32_yml_msg_def(I811
    "---------------------------------------------------------------------------------"
    "---------------------------------------------------------------------------------")
stm32_yml_msg_def(I812
    "Найден файл конфигурации HAL: {1}"
    "HAL configuration file found: {1}")
stm32_yml_msg_def(I813
    "Проверка размера RAM в скрипте компоновщика пропущена (не поддерживается в Arduino backend)."
    "The linker script RAM size check is skipped (not supported by the Arduino backend).")
stm32_yml_msg_def(I814
    "Проверка RAM скрипта компоновщика: не проверялось (скрипт формирует stm32-cmake)."
    "Linker script RAM check: not checked (stm32-cmake generates the script).")
stm32_yml_msg_def(I815
    "Выполнение проверки скрипта компоновщика..."
    "Checking the linker script...")
stm32_yml_msg_def(I816
    "  RAM-секции в скрипте: {1} = {2} байт"
    "  RAM sections in the script: {1} = {2} bytes")
stm32_yml_msg_def(I817
    "  stm32-cmake RAM : {1} = {2} байт"
    "  stm32-cmake RAM : {1} = {2} bytes")
stm32_yml_msg_def(I818
    "  Скрипт RAM сумма: {1} байт ({2}K)"
    "  Script RAM total: {1} bytes ({2}K)")
stm32_yml_msg_def(I819
    "  Соотношение     : {1}K {2} {3}K"
    "  Ratio           : {1}K {2} {3}K")
stm32_yml_msg_def(I820
    "Анализатор Cppcheck найден: {1}"
    "Cppcheck found: {1}")
stm32_yml_msg_def(I821
    "  Cppcheck: Игнорируются пути, содержащие '{1}'"
    "  Cppcheck: paths containing '{1}' are ignored")
stm32_yml_msg_def(I822
    "Статический анализ (Cppcheck) активирован"
    "Static analysis (Cppcheck) is enabled")
