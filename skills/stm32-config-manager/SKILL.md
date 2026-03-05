---
name: stm32-config-manager
description: Управление конфигурацией проектов STM32 через stm32_config.yml для фреймворка stm32-cmake-yml. Используйте для настройки MCU, драйверов HAL/CMSIS, FreeRTOS, линковки, CRC и параметров сборки.
license: MIT
compatibility: Требуется фреймворк stm32-cmake-yml (версия 0.8+), CMake 3.19+, инструмент yq для парсинга YAML.
metadata:
  version: "0.2"
  framework: stm32-cmake-yml
---

# Менеджер конфигурации проекта STM32

Этот навык описывает правила модификации файла `stm32_config.yml`. Этот файл является **"Единственным Источником Правды"** (Single Source of Truth) для всех настроек проекта.

## ⚠️ Критически важные правила

1. **НЕ изменяйте** корневой `CMakeLists.txt` для смены настроек проекта (имени, чипа, библиотек). Используйте только `stm32_config.yml`.
2. **Версионирование**: Параметр `stm32_cmake_yml_version` обязателен. Не удаляйте его.
3. **IOC-интеграция**: Если задан `ioc_file`, параметры `mcu`, `project_name`, `heap_size`, `stack_size` берутся из `.ioc` автоматически как значения по умолчанию. Явные значения в YAML имеют **приоритет** над `.ioc` — используйте это для точечного переопределения.
4. **HAL без CMSIS невозможен**: Если `use_hal: true`, то `use_cmsis` должен быть `true`.

---

## Структура конфигурации

### 1. Версия фреймворка

| Параметр | Тип | По умолчанию | Описание |
| --- | --- | --- | --- |
| `stm32_cmake_yml_version` | String | - | Версия фреймворка (например, `"0.8"`) |
| `stm32_cmake_yml_version_check` | Bool | `true` | Проверка совместимости версий |

```yaml
stm32_cmake_yml_version: "0.8"
stm32_cmake_yml_version_check: true
```

### 2. Основные параметры проекта

| Параметр | Тип | По умолчанию | Описание |
| --- | --- | --- | --- |
| `ioc_file` | String | - | Путь к `.ioc` файлу (CubeMX). Значения из него используются как fallback |
| `project_name` | String | `auto` | Имя проекта. `auto` = имя папки |
| `mcu` | String | - | Точное название MCU (например, `STM32F411CEU6`). Обязательно, если нет IOC |
| `mcu_core` | String | - | Ядро для многоядерных MCU (`M7`, `M4`). Опустить для обычных MCU |
| `heap_size` | String | `"512"` | Размер кучи (`"1024"`, `"2K"`) |
| `stack_size` | String | `"1024"` | Размер стека (`"1024"`, `"1K"`) |

```yaml
ioc_file: "mcu_power_board.ioc"
project_name: "auto"
# mcu: "STM32F411CEU6"  # Обязательно, если нет ioc_file
# mcu_core: "M7"        # Раскомментировать для STM32H7
heap_size: "512"        # Переопределяет значение из .ioc
stack_size: "1K"        # Переопределяет значение из .ioc
```

### 3. Исходные файлы и структура

| Параметр | Тип | Описание |
| --- | --- | --- |
| `sources` | List | Папки (с собственным `CMakeLists.txt`) или файлы |
| `include_directories` | List | Пути к заголовочным файлам |

```yaml
sources:
  - "Core"        # Код из CubeMX
  - "User"        # Пользовательский код
  - "ros_lib"
  - "Core/Src/system_stm32f4xx.c"
  - "startup_stm32f411xe.s"

include_directories:
  - "."           # Для stm32f4xx_hal_conf.h
  - "Core/Inc"
```

### 4. Драйверы STM32Cube

| Параметр | Тип | По умолчанию | Описание |
| --- | --- | --- | --- |
| `use_cmsis` | Bool | `true` | Поддержка CMSIS |
| `use_hal` | Bool | `true` | Поддержка HAL/LL |
| `cubefw_package` | String | `"auto"` | `"auto"`, `"V1.28.2"`, `"local"` |
| `hal_components` | List | - | Компоненты для линковки |

```yaml
use_cmsis: true
use_hal: true
cubefw_package: "auto"  # Сначала локальные Drivers/, затем глобальный репозиторий

hal_components:
  - "CORTEX"
  - "FLASH"
  - "DMA"
  - "GPIO"
  - "UART"
  - "LL_USART"  # Префикс LL_ добавит USE_FULL_LL_DRIVER
```

### 5. RTOS (FreeRTOS)

| Параметр | Тип | По умолчанию | Описание |
| --- | --- | --- | --- |
| `use_freertos` | Bool | `false` | Включить FreeRTOS |
| `freertos_version` | String | `"cube"` | `"cube"` или `"external"` |
| `freertos_components` | List | - | Порт, куча, опции |
| `cmsis_rtos_api` | String | `"none"` | `"v1"`, `"v2"`, `"none"` |

```yaml
use_freertos: true
freertos_version: "cube"

freertos_components:
  - "ARM_CM4F"      # [ОБЯЗАТЕЛЬНО] Порт под ядро
  - "Heap::4"       # [ОБЯЗАТЕЛЬНО] Схема памяти
  - "Timers"        # Программные таймеры
  - "EventGroups"   # Группы событий

cmsis_rtos_api: "v2"  # Обертка CMSIS-RTOS API v2
```

**Доступные порты FreeRTOS:**
- `ARM_CM0`, `ARM_CM3`, `ARM_CM4F`, `ARM_CM7`, `ARM_CM23`, `ARM_CM33`

**Примечание:** Если `ioc_file` содержит FreeRTOS, но вы хотите его отключить — явно укажите `use_freertos: false` в YAML. Значение из YAML имеет приоритет над `.ioc`.

### 6. Настройки компиляции

| Параметр | Тип | Описание |
| --- | --- | --- |
| `languages` | List | `[C, CXX, ASM]` |
| `c_standard` | Int | `17` (C17) |
| `cpp_standard` | Int | `17` (C++17) |
| `compile_definitions` | List | Defines для всех языков |
| `compile_definitions_c` | List | Defines только для C |
| `compile_definitions_cxx` | List | Defines только для C++ |
| `compile_options` | List | Флаги для всех языков |
| `compile_options_c` | List | Флаги только для C |
| `compile_options_cxx` | List | Флаги только для C++ |

```yaml
languages: [C, CXX, ASM]
c_standard: 17
cpp_standard: 17

compile_definitions:
  - "STM32F4xx"
  - "DEBUG"
  - "USE_HAL_DRIVER HSE_VALUE=25000000"  # несколько define в одной строке

compile_options:
  - "$<$<CONFIG:Debug>:-Og -g3>"  # генераторные выражения не изменяются
  - Wall                          # дефис добавляется автоматически -> -Wall
  - "Wextra Wdouble-promotion"    # строка разбивается по пробелам

compile_options_c:
  - Wstrict-prototypes    # только для C

compile_options_cxx:
  - fno-exceptions        # только для C++
  - fno-rtti
```

**Правила записи флагов (нормализация):**
- Ведущий `-` добавляется автоматически: `Wall` → `-Wall`
- Строка с пробелами разбивается на отдельные флаги: `"Wall Wextra"` → `-Wall -Wextra`
- Генераторные выражения `$<...>` не изменяются
- Для `compile_definitions` `-D` добавляет CMake сам, писать его не нужно

### 7. Настройки компоновки

| Параметр | Тип | По умолчанию | Описание |
| --- | --- | --- | --- |
| `linker_script` | String | `"auto"` | `"auto"` или путь к `.ld` |
| `link_options` | List | - | Опции линковщика |
| `linker_directives` | List | - | Прямые директивы |
| `custom_libraries` | List | - | Пути к `.a` файлам |
| `link_libraries` | List | - | Дополнительные библиотеки |
| `use_newlib_nano` | Bool | `false` | Оптимизация размера |
| `system_library` | String | - | `"NoSys"` или `"Semihosting"` |

```yaml
linker_script: "auto"  # Ищет шаблон *.ld.in в корне проекта, см. ниже

linker_directives:
  - "--print-memory-usage"
  - "--no-warn-rwx-segments"

use_newlib_nano: true   # Для MCU с Flash < 256 КБ
system_library: "NoSys"
```

**Поиск шаблона при `linker_script: auto`:**

Фреймворк ищет `.ld.in` файл в корне проекта по трём вариантам имени (для MCU `STM32H723VGT6`):
1. `STM32H723VG_FLASH.ld.in` — точное совпадение
2. `STM32H723XG_FLASH.ld.in` — корпус заменён на X (стиль CubeMX)
3. `STM32H723XX_FLASH.ld.in` — широкий фолбек

Если шаблон не найден — используется встроенный скрипт от `stm32-cmake`.

### 8. Контроль целостности (CRC32)

| Параметр | Тип | По умолчанию | Описание |
| --- | --- | --- | --- |
| `crc_enable` | Bool | `false` | Включить расчёт CRC |
| `crc_section_name` | String | `".checksum"` | Секция в .ld для CRC |
| `crc_algorithm` | String | `"STM32_HW_DEFAULT"` | Алгоритм расчёта |

```yaml
crc_enable: true
crc_section_name: ".checksum"
crc_algorithm: "STM32_HW_DEFAULT"  # Poly: 0x04C11DB7, Init: 0xFFFFFFFF
```

**Требования для CRC:**
- Требуется Python 3 в системе
- Секция `.checksum` должна быть объявлена в линкер-скрипте в конце FLASH
- После компиляции CRC внедряется в ELF автоматически

### 9. Артефакты сборки

```yaml
build_artifacts: ["bin", "hex", "map", "lss"]
```

**Доступные артефакты:**
- `bin` — бинарный файл прошивки
- `hex` — Intel HEX файл
- `map` — файл карты памяти
- `lss` — листинг дизассемблирования

### 10. Отладочные настройки

| Параметр | Тип | По умолчанию | Описание |
| --- | --- | --- | --- |
| `validate_linker_script` | Bool | `true` | Информационный вывод соотношения RAM секций |
| `log_target_properties` | Bool | `false` | Вывод свойств цели в лог CMake |
| `verbose_build` | Bool | `false` | Подробный вывод команд сборки |

```yaml
validate_linker_script: true   # Выводит сравнение RAM секций скрипта и данных от stm32-cmake
log_target_properties: false   # true для отладки зависимостей CMake
verbose_build: false           # true для просмотра команд компилятора
```

---

## Примеры использования

### Пример 1: Включение FreeRTOS

**Запрос:** "Включи FreeRTOS с 4-й схемой памяти для ядра Cortex-M4F"

```yaml
use_freertos: true
freertos_components:
  - "ARM_CM4F"
  - "Heap::4"
  - "Timers"
```

### Пример 2: Отключение FreeRTOS из .ioc

**Запрос:** "В .ioc включён FreeRTOS, но я хочу его отключить"

```yaml
ioc_file: "project.ioc"
use_freertos: false   # YAML имеет приоритет над .ioc
```

### Пример 3: Добавление LL-драйверов

**Запрос:** "Добавь поддержку LL-драйверов для USART"

```yaml
hal_components:
  - "GPIO"
  - "RCC"
  - "LL_USART"  # Префикс LL_ добавит USE_FULL_LL_DRIVER
```

### Пример 4: Раздельные флаги для C и C++

**Запрос:** "Добавь `-fno-exceptions` и `-fno-rtti` только для C++, и `-Wstrict-prototypes` только для C"

```yaml
compile_options_c:
  - Wstrict-prototypes

compile_options_cxx:
  - fno-exceptions
  - fno-rtti
```

### Пример 5: Настройка CRC для проверки прошивки

**Запрос:** "Включи расчёт CRC32 для проверки целостности прошивки"

```yaml
crc_enable: true
crc_section_name: ".checksum"
crc_algorithm: "STM32_HW_DEFAULT"
```

Убедитесь, что в линкер-скрипте есть секция в конце FLASH:
```ld
.checksum :
{
  . = ALIGN(4);
  __checksum_end = .;
  LONG(0);
} >FLASH
```

### Пример 6: Переход на локальные драйверы

**Запрос:** "Используй локальные драйверы из папки Drivers"

Убедитесь, что структура папок правильная:
```
Project/
├── Drivers/
│   ├── CMSIS/
│   └── STM32F4xx_HAL_Driver/
└── stm32_config.yml
```

```yaml
cubefw_package: "auto"  # Автоматически найдёт локальные драйверы
```

### Пример 7: Отладка проблем сборки

**Запрос:** "Помоги разобраться, какие флаги компиляции используются"

```yaml
log_target_properties: true   # Покажет свойства цели в CMake логе
verbose_build: true           # Покажет команды компилятора
```

---

## Частые ошибки и решения

| Ошибка | Причина | Решение |
| --- | --- | --- |
| `HAL не может работать без CMSIS` | `use_hal: true` при `use_cmsis: false` | Установите `use_cmsis: true` |
| `Не найден порт FreeRTOS` | Отсутствует `ARM_CM*` в `freertos_components` | Добавьте порт (например, `ARM_CM4F`) |
| `Файл hal_conf.h не найден` | Путь не в `include_directories` | Добавьте `"Core/Inc"` в `include_directories` |
| `section .bss will not fit in region RAM` | `.bss` и `.data` в одном регионе, который переполнен | Переместите `.bss` в другой RAM-регион в `.ld.in` |
| `Локальный шаблон не найден` | Имя `.ld.in` не совпадает ни с одним вариантом поиска | Переименуйте в `STM32{FAMILY}XX_FLASH.ld.in` или укажите `linker_script: "path/to/script.ld"` |
| `CRC не рассчитывается` | Нет Python 3 в системе | Установите Python 3 или отключите `crc_enable` |
| `crc_enable: false` не отключает CRC | Устаревший CMake кэш | Выполните clean reconfigure: удалите папку `build` и пересоберите |

---

## Валидация конфигурации

После изменения `stm32_config.yml` выполните:

```bash
# Проверка конфигурации CMake (при проблемах — удалить папку build)
cmake -B build -S .

# Сборка проекта
cmake --build build
```

---

## Примечания

1. **Приоритет настроек:** YAML конфиг > IOC файл > значения по умолчанию
2. **Локальные драйверы:** При `cubefw_package: "auto"` сначала ищутся в `Drivers/`, затем в глобальном репозитории
3. **Многоядерные MCU:** Для STM32H7/WB обязательно укажите `mcu_core`
4. **Newlib-nano:** Рекомендуется для MCU с Flash < 256 КБ, но может требовать дополнительной настройки для `printf` с float
5. **Булевы значения:** `true`/`false` можно писать без кавычек — YAML и фреймворк оба корректно их обрабатывают
