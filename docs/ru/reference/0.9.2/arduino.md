# Arduino backend

[Документация](../../index.md) → [Reference 0.9.2](index.md) → Arduino backend · [English](../../../en/reference/0.9.2/arduino.md)

Общие правила: [семантика](semantics.md). База: `f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0`. История появления опций до 0.9.2 не установлена; наличие подтверждено в этой базе. Если не указано иное, настройка выполняется на Configure/Generate; фактические команды исполняются при Build/Post-build.

<a id="arduino-core-path"></a>
## `arduino.core_path`

`CFG-ARDUINO-CORE-PATH` · **Тип:** string: relative directory · **Default:** required for arduino

Путь от корня к Arduino_Core_STM32; отсутствие значения/каталога — ошибка. Экспортируется ARDUINO_CORE_DIR. Само ядро не скачивается и целиком автоматически не собирается.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
arduino:
  core_path: modules/Arduino_Core_STM32
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_arduino.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.arduino-defaults`, `configure.arduino-missing-core`. [Test manifest](../../../../tests/cases.json).

<a id="arduino-core-cmake-dir"></a>
## `arduino.core_cmake_dir`

`CFG-ARDUINO-CORE-CMAKE-DIR` · **Тип:** string: relative directory · **Default:** Arduino/Core

Папка пользовательской CMake-обёртки относительно корня. CMakeLists.txt подключается add_subdirectory; отсутствие предупреждает. Обёртка должна создать нужные targets, которые затем указываются в link_libraries.

**Изменение в 0.10.0** (ТЗ 4.6.8): каталог сборки подключаемого каталога — его относительный путь от корня проекта, для каталога вне проекта — `_deps/<путь без ведущих ..>` (например, `../modules/etl` → `build/_deps/modules/etl`); при совпадении путей добавляется суффикс `-<4 символа SHA-1>`. Прежние имена `external_*`, `arduino_lib_*`, `arduino_custom_*`, `arduino_core` не используются; после перехода с 0.9.x нужна сборка в чистой папке.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
arduino:
  core_cmake_dir: Arduino/Core
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_arduino.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.arduino-defaults`. [Test manifest](../../../../tests/cases.json).

<a id="arduino-mcu-target"></a>
## `arduino.mcu_target`

`CFG-ARDUINO-MCU-TARGET` · **Тип:** string · **Default:** existing MCU_TARGET cache / warning

Передаёт идентификатор variant пользовательским обёрткам через MCU_TARGET CACHE FORCE. Сам фреймворк variant не выбирает. При отсутствии YAML сохраняется существующий MCU_TARGET; если нет и его — предупреждение.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
arduino:
  mcu_target: F411
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_arduino.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.arduino-profile`. [Test manifest](../../../../tests/cases.json).

<a id="arduino-use-core-main"></a>
## `arduino.use_core_main`

`CFG-ARDUINO-USE-CORE-MAIN` · **Тип:** boolean · **Default:** not set by framework

При наличии экспортируется USE_CORE_MAIN CACHE BOOL FORCE для обёртки. Отсутствие не означает обязательный false: поведение зависит от обёртки и прежнего кэша. Не добавляет main-файл само по себе.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
arduino:
  use_core_main: false
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_arduino.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.arduino-defaults`. [Test manifest](../../../../tests/cases.json).

<a id="arduino-libraries"></a>
## `arduino.libraries`

`CFG-ARDUINO-LIBRARIES` · **Тип:** list of library directory names · **Default:** []

Ищет CMakeLists.txt в <core_path>/libraries/<имя>. Отсутствие предупреждает; наличие библиотеки в Arduino IDE не гарантирует CMake-обёртку. Автоматической линковки найденных targets к прошивке нет.

**Изменение в 0.10.0** (ТЗ 4.6.8): каталог сборки подключаемого каталога — его относительный путь от корня проекта, для каталога вне проекта — `_deps/<путь без ведущих ..>` (например, `../modules/etl` → `build/_deps/modules/etl`); при совпадении путей добавляется суффикс `-<4 символа SHA-1>`. Прежние имена `external_*`, `arduino_lib_*`, `arduino_custom_*`, `arduino_core` не используются; после перехода с 0.9.x нужна сборка в чистой папке.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
arduino:
  libraries: [Wire]
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_arduino.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.arduino-library-linked`, `configure.arduino-library-unlinked`, `configure.arduino-library-missing`, `configure.arduino-library-no-wrapper`, `configure.arduino-library-reconfigure`. [Test manifest](../../../../tests/cases.json).

<a id="arduino-custom-libraries"></a>
## `arduino.custom_libraries`

`CFG-ARDUINO-CUSTOM-LIBRARIES` · **Тип:** list of relative directories · **Default:** []

Подключает пользовательские CMakeLists.txt от корня. Отсутствие предупреждает. Targets и их линковку задаёт проект. Arduino::Definitions переносит общие defines и общие/языковые compile_options; языковые compile_definitions_c/cxx в этот interface не копируются.

**Изменение в 0.10.0** (ТЗ 4.6.8): каталог сборки подключаемого каталога — его относительный путь от корня проекта, для каталога вне проекта — `_deps/<путь без ведущих ..>` (например, `../modules/etl` → `build/_deps/modules/etl`); при совпадении путей добавляется суффикс `-<4 символа SHA-1>`. Прежние имена `external_*`, `arduino_lib_*`, `arduino_custom_*`, `arduino_core` не используются; после перехода с 0.9.x нужна сборка в чистой папке.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
arduino:
  custom_libraries: [libraries/probe]
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_arduino.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.arduino-profile`, `configure.arduino-custom-chain`, `configure.arduino-custom-unlinked`, `configure.arduino-custom-missing`, `configure.arduino-custom-no-wrapper`, `configure.arduino-custom-reconfigure`. [Test manifest](../../../../tests/cases.json).

<a id="arduino-integration"></a>
## `arduino.integration`

`CFG-ARDUINO-INTEGRATION` · **Тип:** string: wrappers · **Default:** wrappers

Режим backend Arduino (ТЗ 4.9.8). Пустое или отсутствующее значение — `wrappers`, поведение 0.9.3: ядро и библиотеки подключают обёртки проекта. Неизвестное значение — предупреждение `SCY-W005` и `wrappers`. Режим выводится в лог (`SCY-I508`). Значение `native` (подключение CMake-файлов ядра напрямую) появится в той же версии отдельным изменением.

**Появилось в 0.10.0** (ТЗ 4.9.8–4.9.16).

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
arduino:
  integration: wrappers
```

[Реализация](../../../../cmake/stm32_yml_arduino.cmake) · [Index](index.md)

**Проверки:** `configure.arduino-integration-wrappers`, `configure.arduino-integration-unknown`, `configure.arduino-defaults`. [Test manifest](../../../../tests/cases.json).

<a id="arduino-board"></a>
## `arduino.board`

`CFG-ARDUINO-BOARD` · **Тип:** string: board ID / auto · **Default:** auto, если задан mcu

Плата из `boards.txt` ядра (ТЗ 4.9.10, 4.9.16). При `auto` идентификатор строится по `mcu`: `GENERIC_` + семь символов имени без `STM32` + `X` (`STM32F103C8T6` → `GENERIC_F103C8TX`); если его нет — единственный идентификатор с одной буквой суффикса (`GENERIC_U575ZITXQ`). Данные платы берутся из блока этой платы в `cmake/boards_db.cmake` ядра без `updatedb()` и Python. Выбранная плата выводится в лог (`SCY-I509`), её variant — в кэш `ARDUINO_VARIANT_PATH`, ID — в `ARDUINO_BOARD`. Если `arduino.board` и `arduino.cmsis_path` не заданы и плату выбрать нельзя (короткое имя MCU, нет `mcu` или базы плат), `Arduino::Platform` не создаётся и выводится сообщение (`SCY-I510`, `SCY-I511`, `SCY-I517`) — конфигурации 0.9.3 продолжают работать. При явном значении: неизвестный ID — `SCY-E503`, неудачный `auto` — `SCY-E504` со списком кандидатов, нераспознанный блок — `SCY-E509`, цель проекта с именем платы — `SCY-E508`.

**Появилось в 0.10.0** (ТЗ 4.9.8–4.9.16).

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
arduino:
  board: GENERIC_F103C8TX
```

[Реализация](../../../../cmake/stm32_yml_arduino_board.cmake) · [Index](index.md)

**Проверки:** `configure.arduino-platform-arduino15`, `configure.arduino-board-explicit`, `configure.arduino-board-unknown`, `configure.arduino-board-short-mcu`, `configure.arduino-board-auto-explicit`, `configure.arduino-board-suffix`, `configure.arduino-board-ambiguous`, `configure.arduino-board-malformed`, `configure.arduino-board-target-clash`, `configure.arduino-platform-no-mcu`. [Test manifest](../../../../tests/cases.json).

<a id="arduino-cmsis-path"></a>
## `arduino.cmsis_path`

`CFG-ARDUINO-CMSIS-PATH` · **Тип:** string: directory / external · **Default:** поиск

Источник CMSIS для `Arduino::Platform` (ТЗ 4.9.14). Путь от корня проекта или абсолютный — каталог с `CMSIS/Core/Include/cmsis_version.h`, иначе `SCY-E505`. Без значения — поиск по порядку: Arduino IDE (`<Arduino15>/packages/STMicroelectronics/tools/CMSIS/<версия>`, самая новая версия; `<Arduino15>` — `%LOCALAPPDATA%\Arduino15`, `~/.arduino15`, `~/Library/Arduino15`), кэш загрузок ядра (`~/.Arduino_Core_STM32_dl/*/dist/CMSIS6`), `Drivers` пакета STM32Cube семейства — локальный `Drivers/`, явный `cubefw_package` или самый новый пакет в `$CMAKE_USER_HOME/STM32Cube/Repository` (CMSIS 5 вместо CMSIS 6: при явном `arduino.board` — предупреждение `SCY-W505`, иначе сообщение `SCY-I518`). Найденный источник выводится в лог (`SCY-I514`). Ничего не найдено: при значениях по умолчанию — сообщение `SCY-I512` без `Arduino::Platform`, при явном `arduino.board` — `SCY-E506` с местами поиска. `external` — фреймворк путей CMSIS не добавляет, см. `arduino.cmsis_target`.

**Появилось в 0.10.0** (ТЗ 4.9.8–4.9.16).

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
arduino:
  cmsis_path: modules/CMSIS_6
```

[Реализация](../../../../cmake/stm32_yml_arduino_board.cmake) · [Index](index.md)

**Проверки:** `configure.arduino-platform-arduino15`, `configure.arduino-platform-dl-cache`, `configure.arduino-platform-cube`, `configure.arduino-platform-cube-explicit`, `configure.arduino-platform-no-cmsis`, `configure.arduino-platform-no-cmsis-explicit`, `configure.arduino-cmsis-path`, `configure.arduino-cmsis-path-invalid`, `configure.arduino-cmsis-external`. [Test manifest](../../../../tests/cases.json).

<a id="arduino-cmsis-target"></a>
## `arduino.cmsis_target`

`CFG-ARDUINO-CMSIS-TARGET` · **Тип:** string: target · **Default:** not set

Интерфейсная цель проекта с CMSIS при `arduino.cmsis_path: external` (ТЗ 4.9.14): подключается к `Arduino::Platform` (`SCY-I515`). Цель может быть определена после вызова фреймворка; если к концу `CMakeLists.txt` её нет — `SCY-E507`. Без `cmsis_target` выводится сообщение, что CMSIS подключает проект (`SCY-I516`). Минимальный набор файлов CMSIS Core — в документации режима `native`.

**Появилось в 0.10.0** (ТЗ 4.9.8–4.9.16).

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
arduino:
  cmsis_path: external
  cmsis_target: ProjectCmsis
```

[Реализация](../../../../cmake/stm32_yml_arduino_board.cmake) · [Index](index.md)

**Проверки:** `configure.arduino-cmsis-external-target`, `configure.arduino-cmsis-external-missing`, `configure.arduino-cmsis-external`. [Test manifest](../../../../tests/cases.json).
