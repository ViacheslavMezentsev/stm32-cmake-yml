# STM32 CMake YML Framework

**`stm32-cmake-yml`** — это фреймворк для системы сборки CMake, предназначенный для кардинального упрощения разработки проектов под микроконтроллеры STM32. Он является высокоуровневой "оберткой" над популярным набором скриптов [stm32-cmake](https://github.com/ObKo/stm32-cmake), заменяя сложное конфигурирование `CMakeLists.txt` на один простой и читаемый файл — `project_config.yml`.

## Философия

* **Декларативность:** Описывайте *что* вы хотите собрать, а не *как*.
* **Централизация:** Все настройки проекта в одном YAML-файле.
* **Автоматизация:** Максимальное количество рутинных операций (поиск драйверов, генерация скриптов) выполняется автоматически.
* **Гибкость:** Поддерживает как стандартные проекты из STM32CubeMX, так и полностью кастомные конфигурации.

## Начало работы

Этот фреймворк не является самостоятельным проектом, а предназначен для подключения в ваши проекты в качестве **Git-сабмодуля**.

### 1. Структура проекта

Рекомендуемая структура вашего конечного проекта:

```
my-project/
├── .vscode/
├── Core/
│ └── CMakeLists.txt
├── modules/
│ ├── stm32-cmake/ # <== Git Submodule
│ └── stm32-cmake-yml/ # <== ЭТОТ ФРЕЙМВОРК (Git Submodule)
├── .gitignore
├── CMakeLists.txt # <-- Главный CMake-файл вашего проекта
└── project_config.yml # <-- Конфигурация вашего проекта
```

### 2. Подключение к проекту

1. В корне вашего проекта добавьте фреймворк и его зависимость `stm32-cmake` как сабмодули:

    ```bash
    git submodule add https://github.com/ObKo/stm32-cmake.git modules/stm32-cmake
    git submodule add https://github.com/your-username/stm32-cmake-yml.git modules/stm32-cmake-yml
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
    #set(PROJECT_CONFIG_FILE "config.yml" CACHE STRING "..." FORCE)

    # Вызываем подготовительную функцию.
    # Она прочитает YAML и вернет нам имя проекта и список языков.
    stm32_yml_prepare_project_data(PROJECT_NAME PROJECT_LANGUAGES)

    project(${PROJECT_NAME} LANGUAGES ${PROJECT_LANGUAGES})

    # Вызываем основную функцию настройки.
    stm32_yml_setup_project(${PROJECT_NAME})
    ```

3. Создайте файл **`project_config.yml`** и настройте его под ваш проект. Для детального описания всех опций обратитесь к [полному руководству пользователя](docs/user_manual.md).

## Документация

Полное руководство по всем возможностям и параметрам `project_config.yml` находится в файле [docs/user_manual.md](docs/user_manual.md).

## Требования

* CMake >= 3.19
* ARM GCC Toolchain
* yq (консольная утилита для обработки YAML)

## Лицензия

Этот проект распространяется под лицензией MIT. См. файл `LICENSE` для получения дополнительной информации.
