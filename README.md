# STM32 CMake YML Framework

[![Version](https://img.shields.io/badge/version-0.9.1-blue.svg)](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Changelog](https://img.shields.io/badge/changelog-CHANGELOG.md-informational.svg)](CHANGELOG.md)

**`stm32-cmake-yml`** — фреймворк для системы сборки CMake, предназначенный для упрощения разработки проектов под микроконтроллеры STM32. Является высокоуровневой обёрткой над [stm32-cmake](https://github.com/ObKo/stm32-cmake), заменяя сложное конфигурирование `CMakeLists.txt` на один читаемый файл — `stm32_config.yml`.

## Философия и возможности

- **Декларативность.** Описывайте *что* вы хотите собрать, а не *как*.
- **Централизация.** Все настройки проекта в одном YAML-файле.
- **Автоматизация.** Поиск драйверов, генерация скриптов компоновщика, сборка артефактов — выполняется без участия разработчика.
- **Контроль целостности.** Автоматический расчёт и внедрение CRC32 в ELF-файл на этапе сборки.
- **Гибкость.** Поддерживает проекты из STM32CubeMX (интеграция с `.ioc` файлами), ручную конфигурацию и Arduino Core STM32.
- **Профили сборки.** Поддержка нескольких ревизий платы или MCU в одном проекте через именованные профили.

## Требования

- **CMake** >= 3.19
- **ARM GCC Toolchain** (например, xPack GNU Arm Embedded GCC)
- **yq** (консольная утилита для парсинга YAML)
- **Python 3.x** (требуется только для расчёта и внедрения CRC32)

## Сценарии применения

### Стандартный проект STM32CubeMX

Минимальная конфигурация: укажите `.ioc` файл — MCU, heap/stack, FreeRTOS и библиотеки
определятся автоматически.

```yaml
stm32_cmake_yml_version: "0.9.1"
ioc_file: "my_project.ioc"
build_artifacts: [ bin, hex, map ]
crc_enable: true
```

### Ручная конфигурация без CubeMX

Для legacy-проектов или нестандартных конфигураций все параметры задаются явно.

```yaml
stm32_cmake_yml_version: "0.9.1"
mcu: STM32F411CEU6
heap_size: 512
stack_size: 1K
sources: [ Core, User ]
hal_components: [ GPIO, UART, DMA, TIMEx ]
use_freertos: true
freertos_components: [ ARM_CM4F, "Heap::4" ]
```

### Поддержка двух ревизий платы (профили)

Один конфигурационный файл, две цели сборки. Профиль перекрывает только то,
что отличается между ревизиями.

```yaml
stm32_cmake_yml_version: "0.9.1"

# Общие настройки для всех ревизий.
hal_components: [ GPIO, UART, DMA, CRC ]
use_freertos: true
crc_enable: true

profiles:
  F411:
    mcu: STM32F411CEU6
    ioc_file: "project_F411.ioc"
    linker_script_dir: "F411"
    sources_append: [ "F411/Core" ]
    compile_definitions: [ STM32F4xx ]

  G474:
    mcu: STM32G474RETx
    ioc_file: "project_G474.ioc"
    linker_script_dir: "G474"
    sources_append: [ "G474/Core" ]
    compile_definitions: [ STM32G4xx ]
    hal_components_append: [ FDCAN ]
```

Сборка:

```bash
cmake -DSTM32_YML_PROFILE=F411 -B build/F411 -S .
cmake -DSTM32_YML_PROFILE=G474 -B build/G474 -S .
```

### Arduino Core STM32

Для проектов на базе Arduino Core STM32 с сохранением всех возможностей фреймворка:
профилей, генерации скрипта компоновщика, расчёта CRC, артефактов и нормализации флагов.

```yaml
stm32_cmake_yml_version: "0.9.1"
toolchain_backend: arduino
mcu: STM32G474RET6  # Требуется для автоматической генерации скрипта компоновщика и CRC.

arduino:
  core_path: "modules/Arduino_Core_STM32"
  core_cmake_dir: "Arduino/Core"
  mcu_target: "G474"
  use_core_main: false

# Подключение модулей через локальные CMake-обертки.
custom_libraries:
  - "Arduino/libraries/SrcWrapper"
  - "Arduino/libraries/Wire"
  - "UserApp"

# Линковка логических модулей и системных библиотек.
link_libraries:
  - UserApp
  - Arduino::SrcWrapper
  - Arduino::Core
  - STM32::Nano

linker_script: auto
crc_enable: true

compile_definitions: [ STM32G474xx, USE_HAL_DRIVER ]
compile_options_cxx: [ fno-exceptions, fno-rtti ]
```

### Точечные cmake-overrides для CI

Любой параметр yml можно перекрыть без правки файла — удобно для экспериментов
и отладки в CI.

```bash
cmake -DSTM32_YML_PROFILE=G474 \
      -DSTM32_YML_OVERRIDE_heap_size=8K \
      -DSTM32_YML_OVERRIDE_verbose_build=true
```

## Структура репозитория

```text
stm32-cmake-yml/
├── stm32_yml.cmake                  # Точка входа, подключается через include()
├── cmake/
│   ├── stm32_yml_config.cmake       # Парсинг YAML и .ioc, подготовка переменных
│   ├── stm32_yml_profiles.cmake     # Профили сборки и cmake-overrides
│   ├── stm32_yml_arduino.cmake      # Arduino Core STM32 backend
│   ├── stm32_yml_frameworks.cmake   # HAL, CMSIS, FreeRTOS через stm32-cmake
│   ├── stm32_yml_sources.cmake      # Подключение исходников и include-директорий
│   ├── stm32_yml_linker.cmake       # Генерация и подключение скрипта компоновщика
│   ├── stm32_yml_postbuild.cmake    # Постсборочные команды: CRC, артефакты
│   ├── stm32_yml_diagnostics.cmake  # Проверка RAM, вывод свойств цели
│   ├── stm32_yml_code_quality.cmake # Статический анализ (Cppcheck)
│   └── stm32_yml_utils.cmake        # Утилиты: парсер YAML/JSON, нормализация флагов
├── scripts/
│   └── stm32_crc.py                 # Расчёт и внедрение CRC32 в ELF
├── docs/
│   └── user_manual.md               # Полное руководство пользователя
├── skills/
│   ├── stm32-config-manager/        # Навык AI: управление stm32_config.yml
│   ├── stm32-simple-sources/        # Навык AI: подключение исходников из CubeMX
│   ├── stm32-module-creator/        # Навык AI: создание библиотечных модулей
│   └── stm32-build-helper/          # Навык AI: диагностика ошибок сборки
├── CHANGELOG.md
└── LICENSE
```

## Начало работы

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
параметров — в [Руководстве пользователя](docs/user_manual.md).

## Примеры проектов

Готовые шаблоны для семейств F0, F1, F4, F7, H5, H7:
[github.com/ViacheslavMezentsev/demo-stm32-cmake](https://github.com/ViacheslavMezentsev/demo-stm32-cmake)

## Документация

- [Руководство пользователя](docs/user_manual.md) — все параметры `stm32_config.yml`,
  режимы работы, профили, CRC, Arduino backend, диагностика.
- [История изменений](CHANGELOG.md)

## Работа с AI-ассистентами

Фреймворк поставляется с набором инструкций для AI-ассистентов (папка `skills/`).
Они объясняют нейросетям архитектуру фреймворка и предотвращают типичные ошибки
при генерации кода — например, попытки переписать `CMakeLists.txt` классическим способом.

Навыки работают в любом AI-инструменте: Claude, ChatGPT, Cursor, Windsurf, Copilot.
В IDE с поддержкой упоминания файлов используйте `@skills/stm32-config-manager/SKILL.md`
прямо в чате.

Доступные навыки:

- `stm32-config-manager` — управление `stm32_config.yml`: MCU, HAL, FreeRTOS, профили,
  Arduino backend, CRC.
- `stm32-simple-sources` — подключение папок с исходниками из STM32CubeMX.
- `stm32-module-creator` — создание переиспользуемых модулей (статических библиотек).
- `stm32-build-helper` — диагностика ошибок: HardFault при старте, ошибки линкера,
  проблемы с путями.

## Благодарности

Архитектура модулей CMake и рефакторинг кодовой базы выполнены совместно
с AI-ассистентами (Google Gemini, Anthropic Claude).

## Лицензия

MIT. См. файл [LICENSE](LICENSE).
