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
