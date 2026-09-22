# Начало работы

[Документация](index.md) · [English](../en/getting-started.md)

## Требования

- **CMake** >= 3.19
- **ARM GCC Toolchain** (например, xPack GNU Arm Embedded GCC)
- **yq** (консольная утилита для парсинга YAML)
- **Python 3.x** (требуется только для расчёта и внедрения CRC32)

## Подключение к проекту

Фреймворк предназначен для подключения в ваш проект в качестве Git-сабмодуля.

### 1. Рекомендуемая структура проекта

```text
my-project/
├── Core/                            # Сгенерированный CubeMX код
│   └── CMakeLists.txt
├── User/                            # Пользовательский код
├── modules/
│   ├── stm32-cmake/                 # Git Submodule
│   └── stm32-cmake-yml/             # Git Submodule (этот фреймворк)
├── STM32F411XE_FLASH.ld.in          # Шаблон скрипта компоновщика (опционально)
├── CMakeLists.txt
└── stm32_config.yml
```

Для проектов с поддержкой нескольких MCU рекомендуется структура с папками по ревизиям:

```text
my-project/
├── F411/
│   ├── Core/                        # Сгенерировано CubeMX для F411
│   ├── project_F411.ioc
│   └── STM32F411XE_FLASH.ld.in
├── G474/
│   ├── Core/                        # Сгенерировано CubeMX для G474
│   ├── project_G474.ioc
│   └── STM32G474XX_FLASH.ld.in
├── User/                            # Общий пользовательский код
├── modules/
│   ├── stm32-cmake/
│   └── stm32-cmake-yml/
├── CMakeLists.txt
└── stm32_config.yml                 # С секцией profiles:
```

### 2. Подключение

Добавьте сабмодули:

```bash
git submodule add https://github.com/ObKo/stm32-cmake.git modules/stm32-cmake
git submodule add https://github.com/ViacheslavMezentsev/stm32-cmake-yml.git modules/stm32-cmake-yml
```

Создайте минимальный `CMakeLists.txt`:

```cmake
cmake_minimum_required(VERSION 3.19)

set(CMAKE_TOOLCHAIN_FILE
    "${CMAKE_CURRENT_SOURCE_DIR}/modules/stm32-cmake/cmake/stm32_gcc.cmake")

list(APPEND CMAKE_MODULE_PATH
    "${CMAKE_CURRENT_SOURCE_DIR}/modules/stm32-cmake-yml")

include(stm32_yml)

stm32_yml_prepare_project_data(PROJECT_NAME PROJECT_LANGUAGES)
project(${PROJECT_NAME} LANGUAGES ${PROJECT_LANGUAGES})
stm32_yml_setup_project(${PROJECT_NAME})
```

Создайте `stm32_config.yml` и настройте под ваш проект. Подробное описание всех
параметров — в [справочнике опций](reference/0.9.2/index.md).


Дальше: [сценарии](scenarios.md), [кэш и bare metal](development.md).
