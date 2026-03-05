# STM32 CMake YML Framework

[![Version](https://img.shields.io/badge/version-0.8.0-blue.svg)](https://github.com/yourname/yourrepo/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Refactored by AI](https://img.shields.io/badge/AI_Assisted-Claude-blueviolet.svg)](https://claude.ai/)

**`stm32-cmake-yml`** — это фреймворк для системы сборки CMake, предназначенный для кардинального упрощения разработки проектов под микроконтроллеры STM32. Он является высокоуровневой "оберткой" над популярным набором скриптов(https://github.com/ObKo/stm32-cmake), заменяя сложное конфигурирование `CMakeLists.txt` на один простой и читаемый файл — `stm32_config.yml`.

## Философия и возможности

* **Декларативность:** Описывайте *что* вы хотите собрать, а не *как*.
* **Централизация:** Все настройки проекта в одном YAML-файле.
* **Автоматизация:** Максимальное количество рутинных операций (поиск драйверов, генерация скриптов компоновщика) выполняется автоматически.
* **Контроль целостности:** Автоматический расчет и внедрение **CRC32** непосредственно в `ELF`-файл на этапе сборки.
* **Гибкость:** Поддерживает как стандартные проекты из STM32CubeMX (интеграция с `.ioc` файлами), так и полностью кастомные (legacy) конфигурации.

## Требования

* **CMake** >= 3.19
* **ARM GCC Toolchain** (например, xPack GNU Arm Embedded GCC)
* **yq** (консольная утилита для парсинга YAML)
* **Python 3.x** (требуется **только** для функции автоматического расчета и внедрения CRC32)

## Примеры использования

Готовые шаблоны и примеры проектов, использующих данный фреймворк для различных семейств микроконтроллеров (F0, F1, F4, F7, H5, H7), вы можете найти в репозитории:
👉 **(https://github.com/ViacheslavMezentsev/demo-stm32-cmake)**

## Начало работы

Этот фреймворк не является самостоятельным проектом, а предназначен для подключения в ваши проекты в качестве **Git-сабмодуля**.

### 1. Структура проекта

Рекомендуемая структура вашего конечного проекта:

```text
my-project/
├── .vscode/
├── Core/
│   └── CMakeLists.txt
├── modules/
│   ├── stm32-cmake/         # <== Git Submodule
│   └── stm32-cmake-yml/     # <== ЭТОТ ФРЕЙМВОРК (Git Submodule)
├── .gitignore
├── CMakeLists.txt           # <-- Главный CMake-файл вашего проекта
└── stm32_config.yml         # <-- Конфигурация вашего проекта
```

### 2. Подключение к проекту

1. В корне вашего проекта добавьте фреймворк и его зависимость `stm32-cmake` как сабмодули:

    ```bash
    git submodule add https://github.com/ObKo/stm32-cmake.git modules/stm32-cmake
    git submodule add https://github.com/ViacheslavMezentsev/stm32-cmake-yml.git modules/stm32-cmake-yml
    ```

2. Создайте в корне вашего проекта **`CMakeLists.txt`** со следующим минимальным содержимым:

    ```cmake
    cmake_minimum_required(VERSION 3.19)

    # Используется набор скриптов для STM32: https://github.com/ObKo/stm32-cmake
    set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_SOURCE_DIR}/modules/stm32-cmake/cmake/stm32_gcc.cmake")

    # Определяем путь к нашему фреймворку.
    set(STM32_YML_FRAMEWORK_DIR "${CMAKE_CURRENT_SOURCE_DIR}/modules/stm32-cmake-yml")

    # Добавляем путь к фреймворку в CMAKE_MODULE_PATH.
    list(APPEND CMAKE_MODULE_PATH "${STM32_YML_FRAMEWORK_DIR}")

    # Подключаем главный файл фреймворка.
    include(stm32_yml)

    # (Опционально) Если вы хотите использовать нестандартное имя для конфига.
    # set(PROJECT_CONFIG_FILE "my_custom_config.yml" CACHE STRING "..." FORCE)

    # Вызываем подготовительную функцию.
    # Она прочитает YAML и вернет нам имя проекта и список языков.
    stm32_yml_prepare_project_data(PROJECT_NAME PROJECT_LANGUAGES)

    project(${PROJECT_NAME} LANGUAGES ${PROJECT_LANGUAGES})

    # Вызываем основную функцию настройки.
    stm32_yml_setup_project(${PROJECT_NAME})
    ```

3. Создайте файл **`stm32_config.yml`** и настройте его под ваш проект. Для детального описания опций обратитесь к [Руководству пользователя](docs/user_manual.md).

## Документация

* [Руководство пользователя](docs/user_manual.md) — полное описание всех параметров `stm32_config.yml`, режимов работы, настройки CRC, флагов компилятора и диагностики.

## 🤖 Работа с AI-ассистентами (Agent Skills)

Фреймворк `stm32-cmake-yml` обладает нестандартной, но очень удобной архитектурой. Чтобы нейросети (ChatGPT, Claude, Cursor, Windsurf, Copilot) давали вам правильный код и не пытались переписать корневой `CMakeLists.txt` классическим способом, в репозитории предусмотрена папка `skills/`.

В ней лежат инструкции (навыки) в формате **Agent Skills**, которые объясняют искусственному интеллекту, как правильно работать с вашим проектом.

### Доступные навыки

1. `stm32-config-manager` — Правила редактирования файла `stm32_config.yml` (включение FreeRTOS, HAL, настройка памяти).
2. `stm32-simple-sources` — Правила добавления папок с исходниками напрямую к основной цели (идеально для кода из STM32CubeMX).
3. `stm32-module-creator` — Правила создания переиспользуемых модулей (статических библиотек) с собственным `CMakeLists.txt`.
4. `stm32-build-helper` — База знаний по типичным ошибкам сборки в этом фреймворке (HardFault при старте, ошибки линкера, проблемы с путями).

### Как использовать промпты (Примеры)

При общении с AI в чате или редакторе, явно указывайте ему, какой навык использовать.

**В умных IDE (Cursor, Windsurf):**
Вы можете использовать упоминания файлов (например, `@skills/stm32-module-creator/SKILL.md`) прямо в чате.

**Примеры запросов к AI:**

* **Изменение конфигурации:**
  > "Мне нужно включить FreeRTOS (Heap 4) и драйверы I2C и SPI. Изучи навык `stm32-config-manager` и скажи, как изменить мой `stm32_config.yml`."

* **Подключение кода из CubeMX:**
  > "Я сгенерировал инициализационный код в папку `Core/`. Прочитай навык `stm32-simple-sources` и напиши правильный `CMakeLists.txt` для этой папки, чтобы файлы добавились к основной цели проекта."

* **Создание новой библиотеки:**
  > "Я хочу написать драйвер для экрана ILI9341. Создай структуру папок и `CMakeLists.txt` для нового модуля `Display`, опираясь на правила из `stm32-module-creator`."

* **Помощь с ошибками (Дебаг):**
  > "При сборке я получаю ошибку: `warning: cannot find entry symbol Reset_Handler; defaulting to 08000000`. Изучи файл `stm32-build-helper` и подскажи, что я забыл настроить."

Явное указание на эти файлы сэкономит вам массу времени и предотвратит "галлюцинации" нейросетей, пытающихся применить общие практики CMake к вашей оптимизированной архитектуре.

## 🤖 Благодарности

Архитектура модулей CMake (`Target-Centric Design`) и рефакторинг кодовой базы были спроектированы и реализованы совместно с ИИ-ассистентами (Google Gemini, Anthropic Claude).

## Лицензия

Этот проект распространяется под лицензией MIT. См. файл `LICENSE`.
