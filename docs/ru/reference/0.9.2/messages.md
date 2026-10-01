# Коды сообщений

[Документация](../../index.md) → [Reference 0.9.2](index.md) → Коды сообщений · [English](../../../en/reference/0.9.2/messages.md)

Перечень построен из каталога `cmake/stm32_yml_messages_catalog.cmake` скриптом `ci/messages_reference.py`; вручную не редактируется. Код `SCY-<класс><номер>`: класс `I` — `STATUS`, `W` — `WARNING`, `E` — `FATAL_ERROR`. В выводе коды показываются при `STM32_YML_MESSAGE_CODES=ON`, в файлах `stm32_yml_messages.jsonl` и `stm32_yml_build_messages.jsonl` — всегда. `{1}`…`{n}` — параметры. Появилось в 0.10.0 (ТЗ 4.16.5–4.16.13).

## 0xx — Ядро и чтение конфигурации

| Код | Уровень | Текст |
| --- | --- | --- |
| `SCY-E001` | FATAL_ERROR | Внутренняя ошибка stm32-cmake-yml: неизвестный код сообщения '{1}'. |
| `SCY-E002` | FATAL_ERROR | Внутренняя ошибка stm32-cmake-yml: сообщение '{1}' ожидает параметров: {2}, передано: {3}. |
| `SCY-E003` | FATAL_ERROR | Инструмент 'yq' не найден. Пожалуйста, установите его. |
| `SCY-E004` | FATAL_ERROR | Файл конфигурации не найден: {1} |
| `SCY-E005` | FATAL_ERROR | Ошибка при конвертации {1} в JSON с помощью yq. |
| `SCY-E006` | FATAL_ERROR | Недопустимый формат размера памяти '{1}: {2}'. Укажите целое число байт или целое число с суффиксом K или M в верхнем регистре, например: 0, 1536, 2K, 1M. |
| `SCY-E007` | FATAL_ERROR | mcu\_core: '{1}' недопустим для {2}: stm32-cmake не выделяет ядра для этого MCU. Удалите mcu\_core из конфигурации. |
| `SCY-E008` | FATAL_ERROR | У {1} несколько ядер ({2}): укажите mcu\_core, например 'mcu\_core: {3}'. |
| `SCY-E009` | FATAL_ERROR | mcu\_core: '{1}' недопустим для {2}. Допустимые значения: {3}. |
| `SCY-E010` | FATAL_ERROR | Подключаемый файл не найден или является каталогом. Цепочка: {1} |
| `SCY-E011` | FATAL_ERROR | Циклическое подключение конфигурации: {1} |
| `SCY-E012` | FATAL_ERROR | Недопустимый include в {1}: ожидается путь или список непустых путей. |
| `SCY-E013` | FATAL_ERROR | Недопустимое дополнение '{1}': \_append и дополняемое значение должны быть списками или пустыми. |
| `SCY-E014` | FATAL_ERROR | Конфигурация {1} должна содержать один объект с ключами. |
| `SCY-E015` | FATAL_ERROR | Неподдерживаемое расширение файла конфигурации {1}: ожидается .yml, .yaml или .toml. |
| `SCY-E016` | FATAL_ERROR | Найдено несколько файлов конфигурации: {1}. Задайте PROJECT\_CONFIG\_FILE явно. |
| `SCY-E017` | FATAL_ERROR | В каталоге {1} не найден stm32\_config.yml, stm32\_config.yaml или stm32\_config.toml. |
| `SCY-W001` | WARNING | Неизвестное значение STM32\_YML\_LANG '{1}': язык выбирается как при auto. Допустимые значения: auto, ru, en. |
| `SCY-W002` | WARNING | В файле '{1}' не указан рекомендуемый параметр 'stm32\_cmake\_yml\_version'. Укажите версию фреймворка, для которой написана конфигурация (ТЗ 4.2.3). |
| `SCY-W003` | WARNING | Версия фреймворка ({1}) старше, чем требуется конфигом ({2}). Возможны ошибки. |
| `SCY-W004` | WARNING | Версия фреймворка ({1}) новее, чем указано в конфиге ({2}). Рекомендуется обновить stm32\_cmake\_yml\_version. |
| `SCY-W005` | WARNING | Неизвестное значение '{1}' параметра '{2}'. Известные значения: {3}. Применяется '{4}'. |
| `SCY-W006` | WARNING | Неизвестное значение '{1}' параметра '{2}'. Известные значения: {3}. Значение не используется. |
| `SCY-W007` | WARNING | Неизвестный элемент '{1}' параметра '{2}'. Известные значения: {3}. Элемент пропускается. |
| `SCY-I001` | STATUS | stm32-cmake-yml версия: {1} |
| `SCY-I002` | STATUS | Версия в конфигурации: не указана (stm32\_cmake\_yml\_version в {1}) |
| `SCY-I003` | STATUS | Версия в конфигурации: {1}  (совпадают ✓) |
| `SCY-I004` | STATUS | Версия в конфигурации: {1}  (конфиг новее — обновите фреймворк !) |
| `SCY-I005` | STATUS | Версия в конфигурации: {1}  (фреймворк новее — обновите конфиг) |
| `SCY-I010` | STATUS | Включен подробный вывод команд сборки (CMAKE\_VERBOSE\_MAKEFILE=ON). |
| `SCY-I011` | STATUS | Флаги только для C:   {1} |
| `SCY-I012` | STATUS | Defines только для C: {1} |
| `SCY-I013` | STATUS | Флаги только для C++: {1} |
| `SCY-I014` | STATUS | Defines только для C++: {1} |
| `SCY-I020` | STATUS | Итоговые параметры проекта (источник: \[yml\]=конфиг / \[ioc\]=CubeMX / \[auto\]=авто): |
| `SCY-I021` | STATUS | MCU:        {1}  {2} |
| `SCY-I022` | STATUS | Проект:     {1}  {2} |
| `SCY-I023` | STATUS | CubeFW:     {1}  {2} |
| `SCY-I024` | STATUS | Heap Size:  {1} байт  {2} |
| `SCY-I025` | STATUS | Stack Size: {1} байт  {2} |
| `SCY-I026` | STATUS | FreeRTOS:   ОТКЛЮЧЕН (переопределено в .yml)  \[yml\] |
| `SCY-I027` | STATUS | FreeRTOS:   Включен  {1} |
| `SCY-I028` | STATUS | API:      {1}  {2} |
| `SCY-I029` | STATUS | Порт:     {1}  {2} |
| `SCY-I030` | STATUS | FreeRTOS:   Отключен |
| `SCY-I031` | STATUS | Режим ручной конфигурации (ioc\_file не указан). |
| `SCY-I032` | STATUS | Определено имя проекта: {1} |
| `SCY-I033` | STATUS | Языки проекта не указаны. Используется по умолчанию: {1} |
| `SCY-I034` | STATUS | Используются языки проекта из конфига: {1} |
| `SCY-I035` | STATUS | Конфигурация из {1} успешно загружена. |
| `SCY-I036` | STATUS | Размер памяти '{1}' нормализован в {2} байт. |
| `SCY-I037` | STATUS | Параметр '{1}' не был задан или был пуст. Установлено значение по умолчанию: '{2}'. |
| `SCY-I038` | STATUS | Ядро MCU не задано, используется единственное ядро {1}: {2}. |
| `SCY-I039` | STATUS | Ядро MCU: {1} |
| `SCY-I040` | STATUS | Версии компонентов: |
| `SCY-I041` | STATUS | {1}: {2} |
| `SCY-I042` | STATUS | Компилятор: {1} {2} |
| `SCY-I043` | STATUS | Компилятор: версия не определена |
| `SCY-I044` | STATUS | {1}: версия не определена |

## 1xx — Профили

| Код | Уровень | Текст |
| --- | --- | --- |
| `SCY-E101` | FATAL_ERROR | Передайте -DSTM32\_YML\_PROFILE=&lt;имя&gt; для выбора профиля. |
| `SCY-W101` | WARNING | Профиль '{1}' не найден в конфигурации. Доступные профили можно посмотреть в секции 'profiles:' файла {2}. |
| `SCY-W102` | WARNING | Встроенная секция 'profiles:' игнорируется (профили: {1}): задан profiles\_file '{2}', профили берутся только из него. Перенесите нужные профили во внешний файл или удалите встроенную секцию. |
| `SCY-W103` | WARNING | Файл профилей не найден: {1} |
| `SCY-I101` | STATUS | Применение профиля сборки: '{1}' |
| `SCY-I102` | STATUS | \[профиль\] {1} = {2} |
| `SCY-I103` | STATUS | \[профиль +\] {1} += {2} |
| `SCY-I104` | STATUS | \[override\] {1} = {2} |
| `SCY-I105` | STATUS | Применено точечных cmake-overrides: {1}. |
| `SCY-I106` | STATUS | Доступные профили сборки: |
| `SCY-I107` | STATUS | - {1} |
| `SCY-I108` | STATUS | Профили сборки не определены в конфигурации. |
| `SCY-I109` | STATUS | Загрузка профилей из внешнего файла: {1} |

## 2xx — IOC

| Код | Уровень | Текст |
| --- | --- | --- |
| `SCY-E201` | FATAL_ERROR | Указанный .ioc файл не найден: {1} |
| `SCY-I201` | STATUS | Обнаружена настройка 'ioc\_file'. Чтение данных из: {1} ... |
| `SCY-I202` | STATUS | Используется CustomerFirmwarePackage: семейство={1}, версия={2} |
| `SCY-I203` | STATUS | Путь: {1} |

## 3xx — Исходники и модули

| Код | Уровень | Текст |
| --- | --- | --- |
| `SCY-E302` | FATAL_ERROR | Каталог проекта '{1}' совпадает с каталогом сборки внешних зависимостей \_deps/. Переименуйте его: внешние каталоги собираются в \_deps/ (ТЗ 4.6.8). |
| `SCY-W301` | WARNING | Пользовательская библиотека не найдена и будет проигнорирована: {1} |
| `SCY-W302` | WARNING | Источник '{1}' не найден и будет проигнорирован. |
| `SCY-I301` | STATUS | Подключение пользовательской библиотеки: {1} |
| `SCY-I302` | STATUS | Обнаружен пользовательский system-файл. Переопределение: {1} |
| `SCY-I303` | STATUS | Обнаружен пользовательский startup-файл. Переопределение: {1} |
| `SCY-I304` | STATUS | Каталог вне проекта {1} собирается в {2} |

## 4xx — CMSIS, HAL, FreeRTOS

| Код | Уровень | Текст |
| --- | --- | --- |
| `SCY-E401` | FATAL_ERROR | Директория STM32Cube не найдена по пути: {1} |
| `SCY-E402` | FATAL_ERROR | Не найдено ни одного пакета для семейства {1} в {2} |
| `SCY-E403` | FATAL_ERROR | Не удалось определить версию из найденных папок для {1}. |
| `SCY-E404` | FATAL_ERROR | Не удалось определить пути к драйверам HAL/CMSIS. Проверьте 'cubefw\_package'. |
| `SCY-E405` | FATAL_ERROR | use\_hal: true требует use\_cmsis: true. |
| `SCY-E406` | FATAL_ERROR | Компонент HAL '{1}' (hal\_components) не найден для семейства {2}: нет цели {3}. Проверьте имя драйвера в пакете STM32Cube {2}. |
| `SCY-E407` | FATAL_ERROR | Компонент HAL '{1}' (hal\_components) не найден для семейства {2} (ядро {3}): нет цели {4}. Проверьте имя драйвера в пакете STM32Cube {2}. |
| `SCY-E408` | FATAL_ERROR | Найдено несколько портов FreeRTOS: '{1}' и '{2}'. |
| `SCY-E409` | FATAL_ERROR | В 'freertos\_components' не найден порт (например, 'ARM\_CM4F'). |
| `SCY-E410` | FATAL_ERROR | freertos\_version: external требует путь к FreeRTOS: задайте FREERTOS\_PATH (-DFREERTOS\_PATH=... или переменная окружения) — каталог FreeRTOS-Kernel или Middlewares/Third\_Party/FreeRTOS пакета STM32Cube. |
| `SCY-E411` | FATAL_ERROR | freertos\_version: external: в FREERTOS\_PATH '{1}' не найдены FreeRTOS.h и tasks.c. Ожидается раскладка FreeRTOS-Kernel (include/, portable/GCC/&lt;порт&gt;) или дерева Cube (Source/...). |
| `SCY-E412` | FATAL_ERROR | freertos\_version: external: файлы порта '{1}' не найдены в FREERTOS\_PATH '{2}' (portable/GCC/{1}). |
| `SCY-E413` | FATAL_ERROR | Компонент FreeRTOS '{1}' (freertos\_components) не найден: нет цели {2} в пространстве {3}. |
| `SCY-E414` | FATAL_ERROR | cmsis\_rtos\_api: {1}: обёртка CMSIS-RTOS не найдена (нет цели {2}). Её исходники берутся из Middlewares/Third\_Party/FreeRTOS пакета STM32Cube {3} и требуют use\_cmsis: true; в пакете может не быть FreeRTOS (например, H5, U5). Используйте cmsis\_rtos\_api: none. |
| `SCY-E415` | FATAL_ERROR | Пакет STM32Cube {1} для семейства {2} не найден: {3}. Установите пакет или укажите cubefw\_package: auto. |
| `SCY-W401` | WARNING | Порт FreeRTOS для '{1}' не определён таблицей фреймворка; используется ARM\_CM4F. Задайте freertos\_components явно. |
| `SCY-I401` | STATUS | Режим 'auto': поиск драйверов... |
| `SCY-I402` | STATUS | Обнаружены локальные драйверы в '{1}'. Используются они. |
| `SCY-I403` | STATUS | STM32Cube MCU Firmware Package: {1} |
| `SCY-I404` | STATUS | Локальные драйверы не найдены. Поиск последней версии в пользовательском репозитории... |
| `SCY-I405` | STATUS | Использование найденной версии STM32Cube FW: {1} |
| `SCY-I406` | STATUS | Использование указанной версии STM32Cube FW: {1} |
| `SCY-I407` | STATUS | Автоматическое подключение CMSIS включено. |
| `SCY-I408` | STATUS | Автоматическое подключение компонентов HAL/LL включено. |
| `SCY-I409` | STATUS | Автоматическое подключение компонентов HAL/LL отключено. |
| `SCY-I410` | STATUS | Автоматическое подключение FreeRTOS включено. |
| `SCY-I411` | STATUS | Используется порт FreeRTOS: {1} |
| `SCY-I412` | STATUS | FreeRTOS: к порту {1} добавлен {2} |
| `SCY-I413` | STATUS | Подключена обертка CMSIS-RTOS API {1}. |

## 5xx — Arduino

| Код | Уровень | Текст |
| --- | --- | --- |
| `SCY-E501` | FATAL_ERROR | \[arduino\] Параметр arduino.core\_path не задан в stm32\_config.yml.<br>Укажите путь к папке Arduino\_Core\_STM32 относительно корня проекта:<br>  arduino:<br>    core\_path: "modules/Arduino\_Core\_STM32" |
| `SCY-E502` | FATAL_ERROR | \[arduino\] Папка Arduino Core STM32 не найдена: {1}<br>Проверьте значение arduino.core\_path в stm32\_config.yml.<br>В CI убедитесь, что симлинк или папка modules/Arduino\_Core\_STM32 существует. |
| `SCY-E503` | FATAL_ERROR | \[arduino\] Плата '{1}' не найдена в {2}.<br>Укажите в arduino.board идентификатор из boards.txt ядра или auto. |
| `SCY-E504` | FATAL_ERROR | \[arduino\] Не удалось выбрать плату по mcu '{1}'. Кандидаты: {2}.<br>Задайте arduino.board в stm32\_config.yml. |
| `SCY-E505` | FATAL_ERROR | \[arduino\] arduino.cmsis\_path: нет CMSIS/Core/Include/cmsis\_version.h в {1}. |
| `SCY-E506` | FATAL_ERROR | \[arduino\] CMSIS не найден. Места поиска: {1}.<br>Задайте arduino.cmsis\_path (каталог с CMSIS/Core/Include) или external. |
| `SCY-E507` | FATAL_ERROR | \[arduino\] arduino.cmsis\_target: цель '{1}' не определена в проекте. |
| `SCY-E508` | FATAL_ERROR | \[arduino\] Цель '{1}' уже существует: имя совпадает с идентификатором платы. Переименуйте цель проекта. |
| `SCY-E509` | FATAL_ERROR | \[arduino\] Формат базы плат не распознан: {1}. |
| `SCY-E510` | FATAL_ERROR | \[arduino\] Цель '{1}' уже существует: в режиме native это имя цели ядра Arduino. Переименуйте цель проекта. |
| `SCY-W501` | WARNING | \[arduino\] Параметр arduino.mcu\_target не задан. CMakeLists.txt библиотек, зависящих от MCU\_TARGET, могут завершиться ошибкой. |
| `SCY-W502` | WARNING | \[arduino\] CMakeLists.txt ядра Arduino не найден: {1}<br>Укажите правильный путь через arduino.core\_cmake\_dir в stm32\_config.yml. |
| `SCY-W503` | WARNING | \[arduino\] Библиотека '{1}' не найдена в {2}.<br>Проверьте имя в arduino.libraries и наличие CMakeLists.txt. |
| `SCY-W504` | WARNING | \[arduino\] Кастомная библиотека не найдена: {1}. |
| `SCY-W505` | WARNING | \[arduino\] CMSIS из STM32Cube (CMSIS 5 вместо ожидаемого ядром CMSIS 6): {1} |
| `SCY-W506` | WARNING | \[arduino\] {1} не используется в режиме native. |
| `SCY-I501` | STATUS | Arduino Core STM32: {1} |
| `SCY-I502` | STATUS | Arduino MCU\_TARGET: {1} |
| `SCY-I503` | STATUS | Arduino::Definitions создан. |
| `SCY-I504` | STATUS | Arduino USE\_CORE\_MAIN: {1} |
| `SCY-I505` | STATUS | Подключение Arduino Core: {1} |
| `SCY-I506` | STATUS | Подключение Arduino библиотеки: {1} |
| `SCY-I507` | STATUS | Подключение кастомной библиотеки: {1} |
| `SCY-I508` | STATUS | Режим Arduino: {1} |
| `SCY-I509` | STATUS | Плата Arduino: {1} (arduino.board: {2}) |
| `SCY-I510` | STATUS | Arduino::Platform не создан: mcu не задан. |
| `SCY-I511` | STATUS | Arduino::Platform не создан: плату по mcu '{1}' выбрать не удалось (кандидаты: {2}). Задайте arduino.board. |
| `SCY-I512` | STATUS | Arduino::Platform не создан: CMSIS не найден (места поиска: {1}). Задайте arduino.cmsis\_path. |
| `SCY-I513` | STATUS | Arduino::Platform создан: {1}. |
| `SCY-I514` | STATUS | CMSIS для Arduino: {1} ({2}) |
| `SCY-I515` | STATUS | CMSIS для Arduino подключает цель проекта {1} (arduino.cmsis\_path: external). |
| `SCY-I516` | STATUS | CMSIS для Arduino подключает проект (arduino.cmsis\_path: external). |
| `SCY-I517` | STATUS | Arduino::Platform не создан: нет базы плат {1}. |
| `SCY-I518` | STATUS | CMSIS из STM32Cube (CMSIS 5 вместо ожидаемого ядром CMSIS 6): {1} |
| `SCY-I519` | STATUS | Arduino main(): из ядра (cores/arduino/main.cpp). |
| `SCY-I520` | STATUS | Arduino main(): из проекта; main.cpp ядра исключён, добавлен --undefined=\_write. main() проекта вызывает init() и initVariant(). |
| `SCY-I521` | STATUS | Скрипт компоновщика variant платы: {1}. heap\_size и stack\_size не применяются; для них задайте шаблон .ld.in или linker\_script. |

## 6xx — Скрипт компоновщика

| Код | Уровень | Текст |
| --- | --- | --- |
| `SCY-E601` | FATAL_ERROR | В режиме Arduino Backend генерация скрипта без локального шаблона не поддерживается. Добавьте шаблон или укажите готовый скрипт. |
| `SCY-E602` | FATAL_ERROR | Указанный скрипт компоновщика не найден: '{1}'<br>Папки поиска: {2} |
| `SCY-W601` | WARNING | Заданные размеры памяти ({1}) не применяются: скрипт компоновщика формирует stm32-cmake с собственными размерами heap {2} и stack {3} байт. Добавьте шаблон {4} (в корень проекта или linker\_script\_dir) или задайте размеры в явном linker\_script. |
| `SCY-W602` | WARNING | Заданные размеры памяти ({1}) не применяются: размеры задаёт явный скрипт компоновщика '{2}'. Измените их в скрипте или используйте шаблон .ld.in (linker\_script: auto). |
| `SCY-W603` | WARNING | Startup {1} задаёт границу стека (MSPLIM) по символу \_sstack, но скрипт компоновщика {2} его не определяет: компоновка завершится ошибкой 'undefined reference to \_sstack'. Добавьте в шаблон .ld.in или явный скрипт строку '\_sstack = \_estack - \_Min\_Stack\_Size;' либо подключите через sources собственный startup без MSPLIM. |
| `SCY-W604` | WARNING | Startup {1} задаёт границу стека (MSPLIM) по символу \_sstack, но скрипт компоновщика stm32-cmake его не определяет: компоновка завершится ошибкой 'undefined reference to \_sstack'. Добавьте в шаблон .ld.in или явный скрипт строку '\_sstack = \_estack - \_Min\_Stack\_Size;' либо подключите через sources собственный startup без MSPLIM. |
| `SCY-I601` | STATUS | Папка поиска скрипта компоновщика: {1} |
| `SCY-I602` | STATUS | Генерация скрипта компоновщика из шаблона... |
| `SCY-I603` | STATUS | Найден локальный шаблон: {1} |
| `SCY-I604` | STATUS | В скрипте компоновщика используется READONLY (GCC &gt;= 11.0) |
| `SCY-I605` | STATUS | В скрипте компоновщика не используется READONLY (GCC &lt; 11.0) |
| `SCY-I606` | STATUS | Локальный шаблон не найден. Будет использован стандартный скрипт компоновщика. |
| `SCY-I607` | STATUS | Подключение скрипта компоновщика: {1} |
| `SCY-I608` | STATUS | Подключение встроенного скрипта компоновщика: {1} |
| `SCY-I609` | STATUS | Использование пользовательского скрипта компоновщика: {1} |

## 7xx — Артефакты и CRC

| Код | Уровень | Текст |
| --- | --- | --- |
| `SCY-E701` | FATAL_ERROR | crc\_enable: скрипт компоновщика формирует stm32-cmake, секции '{1}' (crc\_section\_name) в нём нет. Используйте шаблон STM32&lt;MCU&gt;\_FLASH.ld.in (linker\_script: auto) или явный linker\_script с секцией '{1}', либо crc\_enable: false. |
| `SCY-E702` | FATAL_ERROR | '{1}' не является 32-битным ELF-файлом little-endian |
| `SCY-E703` | FATAL_ERROR | Нет загружаемых секций в FLASH 0x{1}+0x{2} в '{3}' |
| `SCY-E704` | FATAL_ERROR | Недопустимое число '{1}' в {2} |
| `SCY-E705` | FATAL_ERROR | Недопустимое значение --flash '{1}', ожидается &lt;начало&gt;:&lt;длина&gt; |
| `SCY-E706` | FATAL_ERROR | Образ для CRC больше предела FLASH: {1} &gt; {2} байт. Проверьте 'flash\_size' и регион FLASH скрипта компоновщика. |
| `SCY-E707` | FATAL_ERROR | Передайте &lt;выход.bin&gt; для CRC или --image для образа FLASH |
| `SCY-E708` | FATAL_ERROR | Сборка прервана: CRC не рассчитан. |
| `SCY-E709` | FATAL_ERROR | Входной файл '{1}' не найден. |
| `SCY-E710` | FATAL_ERROR | Использование: stm32\_crc.py &lt;вход.bin&gt; &lt;выход.bin&gt; \[предел\] \| --elf &lt;вход.elf&gt; --flash &lt;начало&gt;:&lt;длина&gt; --exclude &lt;секция&gt; &lt;выход.bin&gt; \[предел\] |
| `SCY-E711` | FATAL_ERROR | Ошибка ввода-вывода: {1} |
| `SCY-W701` | WARNING | bin: не удалось определить регион FLASH скрипта компоновщика или найти Python3; BIN создаётся objcopy -O binary и может оказаться большим, если в ELF есть секции вне Flash. |
| `SCY-W702` | WARNING | Расчет CRC отключен. Не удалось автоматически определить размер FLASH из {1}. Задайте 'flash\_size' в stm32\_config.yml. |
| `SCY-W703` | WARNING | crc\_enable: секция '{1}' (crc\_section\_name) не найдена в скрипте {2}. Шаг CRC после сборки завершится ошибкой. |
| `SCY-W704` | WARNING | Расчет CRC отключен. Не удалось определить регион FLASH (ORIGIN, LENGTH) в скрипте {1}. |
| `SCY-W705` | WARNING | Интерпретатор Python3 не найден. Расчет CRC отключен. |
| `SCY-W706` | WARNING | Утилита objcopy не найдена. Расчет CRC отключен. |
| `SCY-W707` | WARNING | Скрипт расчета не найден по пути: {1}. Расчет CRC отключен. |
| `SCY-I701` | STATUS | Настройка механизма внедрения CRC32 в прошивку... |
| `SCY-I702` | STATUS | Метод: Внедрение в секцию '{1}' |
| `SCY-I703` | STATUS | Алгоритм: {1} |
| `SCY-I704` | STATUS | Регион FLASH скрипта: ORIGIN {1}, LENGTH {2} байт |
| `SCY-I705` | STATUS | Max Flash Size: {1} байт ({2}) |
| `SCY-I706` | STATUS | Сборка будет выполнена БЕЗ добавления контрольной суммы. |
| `SCY-I707` | STATUS | {1} Пропущена секция {2}: адрес загрузки 0x{3} ({4} байт) вне FLASH |
| `SCY-I708` | STATUS | {1} Записан {2}: {3} байт с адреса 0x{4} |
| `SCY-I709` | STATUS | \[STM32 CRC32\] Рассчитано: 0x{1} (размер: {2} байт с адреса 0x{3}) |
| `SCY-I710` | STATUS | \[STM32 CRC32\] Рассчитано: 0x{1} (размер: {2} байт) |

## 8xx — Диагностика

| Код | Уровень | Текст |
| --- | --- | --- |
| `SCY-E801` | FATAL_ERROR | Файл конфигурации HAL '{1}' не найден ни в одной из директорий, указанных в 'include\_directories'. Библиотека HAL не сможет скомпилироваться без него. Убедитесь, что путь к этому файлу (например, 'Core/Inc') добавлен в 'include\_directories' в {2}. |
| `SCY-W801` | WARNING | Не найдено ни одной RAM-секции (xrw/rw) в скрипте {1}. Проверка размера пропущена. |
| `SCY-W802` | WARNING | Параметр 'cppcheck\_enable' установлен, но утилита не найдена! |
| `SCY-I801` | STATUS | --- Отладочная информация для финальной цели '{1}' --- |
| `SCY-I802` | STATUS | Опции компиляции (COMPILE\_OPTIONS):<br>    {1} |
| `SCY-I803` | STATUS | Определения компиляции (COMPILE\_DEFINITIONS):<br>    {1} |
| `SCY-I804` | STATUS | Директории для #include (INCLUDE\_DIRECTORIES):<br>    {1} |
| `SCY-I805` | STATUS | Опции компоновки (LINK\_OPTIONS):<br>    {1} |
| `SCY-I806` | STATUS | Библиотеки для компоновки (LINK\_LIBRARIES):<br>    {1} |
| `SCY-I807` | STATUS | <br>--- Отладочная информация для унаследованной цели '{1}' --- |
| `SCY-I808` | STATUS | INTERFACE Опции компиляции:<br>    {1} |
| `SCY-I809` | STATUS | INTERFACE Определения компиляции:<br>    {1} |
| `SCY-I810` | STATUS | INTERFACE Опции компоновки:<br>    {1} |
| `SCY-I811` | STATUS | --------------------------------------------------------------------------------- |
| `SCY-I812` | STATUS | Найден файл конфигурации HAL: {1} |
| `SCY-I813` | STATUS | Проверка размера RAM в скрипте компоновщика пропущена (не поддерживается в Arduino backend). |
| `SCY-I814` | STATUS | Проверка RAM скрипта компоновщика: не проверялось (скрипт формирует stm32-cmake). |
| `SCY-I815` | STATUS | Выполнение проверки скрипта компоновщика... |
| `SCY-I816` | STATUS | RAM-секции в скрипте: {1} = {2} байт |
| `SCY-I817` | STATUS | stm32-cmake RAM : {1} = {2} байт |
| `SCY-I818` | STATUS | Скрипт RAM сумма: {1} байт ({2}K) |
| `SCY-I819` | STATUS | Соотношение     : {1}K {2} {3}K |
| `SCY-I820` | STATUS | Анализатор Cppcheck найден: {1} |
| `SCY-I821` | STATUS | Cppcheck: Игнорируются пути, содержащие '{1}' |
| `SCY-I822` | STATUS | Статический анализ (Cppcheck) активирован |
