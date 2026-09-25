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

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
arduino:
  custom_libraries: [libraries/probe]
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_arduino.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.arduino-profile`. [Test manifest](../../../../tests/cases.json).
