---
name: stm32-simple-sources
description: Упрощённое подключение исходных файлов напрямую к основной цели проекта STM32. Используйте для CubeMX-кода (Core), системных файлов или когда не нужна отдельная библиотека. Обеспечивает 100% совместимость флагов компиляции.
license: MIT
compatibility: Требуется фреймворк stm32-cmake-yml. Файлы добавляются напрямую в основную цель через target_sources().
metadata:
  version: "0.1"
  use_case: CubeMX code, system files, simple source collections
---

# Упрощённое подключение исходников STM32

Этот навык описывает процедуру добавления исходных файлов **напрямую к основной цели проекта** без создания отдельных библиотек. Все файлы компилируются с **теми же флагами**, что и основной проект.

## ⚠️ Когда использовать этот подход

| Сценарий | Рекомендация |
| --- | --- |
| Код из STM32CubeMX (`Core/`) | ✅ **Этот навык** |
| Системные файлы (`system_stm32*.c`, `startup_*.s`) | ✅ **Этот навык** |
| Простой набор файлов без повторного использования | ✅ **Этот навык** |
| Модуль для повторного использования в других проектах | ❌ Используйте `stm32-module-creator` |
| Библиотека с собственными зависимостями | ❌ Используйте `stm32-module-creator` |

## Ключевые преимущества

1. **100% совместимость флагов**: Все файлы компилируются с одинаковыми `-O`, `-g`, `-std`
2. **Нет проблем ABI**: Не может быть несовместимости между модулем и проектом
3. **Проще отладка**: Все файлы в одной цели, легче навигация
4. **Меньше CMake-кода**: Нет необходимости в `add_library()`, `target_link_libraries()`

## Рабочий процесс

### Шаг 1: Создать папку с исходниками

```
Project/
├── Core/
│   ├── Inc/
│   │   ├── main.h
│   │   ├── stm32f4xx_hal_conf.h
│   │   └── stm32f4xx_it.h
│   ├── Src/
│   │   ├── main.c
│   │   ├── stm32f4xx_hal_msp.c
│   │   ├── stm32f4xx_it.c
│   │   └── system_stm32f4xx.c
│   └── CMakeLists.txt    # Файл подключения
└── stm32_config.yml
```

### Шаг 2: Создать CMakeLists.txt для подключения

Используйте этот шаблон. **Критически важно**: используйте `${PROJECT_NAME}` для основной цели.

```cmake
# CMakeLists.txt для папки: Core
# Фреймворк: stm32-cmake-yml
# Подход: Прямое добавление файлов к основной цели

cmake_minimum_required(VERSION 3.19)

# 1. Добавляем пути к заголовочным файлам
# PRIVATE = только файлы этой папки видят эти пути
target_include_directories(${PROJECT_NAME} PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/Inc"
)

# 2. Добавляем исходные файлы напрямую к основной цели
# Все файлы компилируются с флагами основного проекта
target_sources(${PROJECT_NAME} PRIVATE
    Src/main.c
    Src/stm32f4xx_hal_msp.c
    Src/stm32f4xx_it.c
    Src/system_stm32f4xx.c
    Src/dma.c
    Src/gpio.c
    Src/usart.c
    Src/adc.c
    Src/tim.c
)

# 3. (Опционально) Ассемблерные файлы
# target_sources(${PROJECT_NAME} PRIVATE
#     startup_stm32f411xe.s
# )
```

### Шаг 3: Зарегистрировать папку в stm32_config.yml

Добавьте путь в список `sources`:

```yaml
sources:
  - "Core"        # ← Папка с этим CMakeLists.txt
  - "User"
  - "ros_lib"
```

## Сравнение подходов

| Характеристика | Этот навык (Simple Sources) | stm32-module-creator |
| --- | --- | --- |
| **CMake-команда** | `target_sources(${PROJECT_NAME} ...)` | `add_library(modulename STATIC ...)` |
| **Флаги компиляции** | Наследуются автоматически | Требуют `target_link_libraries()` |
| **Заголовки** | `target_include_directories(${PROJECT_NAME} ...)` | `target_include_directories(modulename PUBLIC ...)` |
| **ABI-совместимость** | 100% гарантирована | Зависит от правильной линковки |
| **Повторное использование** | Нет (файлы в основной цели) | Да (отдельная библиотека) |
| **Идеально для** | CubeMX код, системные файлы | Библиотеки, модули, компоненты |

## Примеры использования

### Пример 1: CubeMX-код (Core)

Стандартная структура из STM32CubeMX:

```cmake
# Core/CMakeLists.txt
cmake_minimum_required(VERSION 3.19)

target_include_directories(${PROJECT_NAME} PRIVATE
    "Inc"
)

target_sources(${PROJECT_NAME} PRIVATE
    Src/main.c
    Src/stm32f4xx_hal_msp.c
    Src/stm32f4xx_it.c
    Src/system_stm32f4xx.c
    Src/dma.c
    Src/gpio.c
    Src/usart.c
)
```

### Пример 2: Системные файлы отдельно

Если хотите вынести системные файлы в отдельную папку:

```cmake
# System/CMakeLists.txt
cmake_minimum_required(VERSION 3.19)

target_sources(${PROJECT_NAME} PRIVATE
    Src/system_stm32f4xx.c
    startup_stm32f411xe.s
)

target_include_directories(${PROJECT_NAME} PRIVATE
    "Inc"
)
```

```yaml
# stm32_config.yml
sources:
  - "Core"
  - "System"    # ← Отдельная папка с системными файлами
```

### Пример 3: Драйверы периферии

Папка с драйверами для датчиков/устройств:

```cmake
# Drivers/Sensors/CMakeLists.txt
cmake_minimum_required(VERSION 3.19)

target_include_directories(${PROJECT_NAME} PRIVATE
    "Inc"
)

target_sources(${PROJECT_NAME} PRIVATE
    Src/bme280.c
    Src/mpu6050.c
    Src/i2c_driver.c
)
```

### Пример 4: Явный список vs GLOB

**Рекомендуется: Явный список файлов**
```cmake
target_sources(${PROJECT_NAME} PRIVATE
    Src/main.c
    Src/gpio.c
    Src/usart.c
)
```

**Не рекомендуется: GLOB** (требует перезапуска CMake при добавлении файлов)
```cmake
file(GLOB_RECURSE SOURCES "Src/*.c")
target_sources(${PROJECT_NAME} PRIVATE ${SOURCES})
```

## Частые ошибки и решения

| Ошибка | Причина | Решение |
| --- | --- | --- |
| `${PROJECT_NAME}` не определён | CMakeLists.txt выполняется до `project()` | Убедитесь, что папка добавлена в `sources` **после** вызова `stm32_yml_setup_project()` |
| Файл не найден при сборке | Неправильный относительный путь | Пути в `target_sources()` указываются относительно `CMAKE_CURRENT_SOURCE_DIR` |
| Заголовки не находятся | Нет `target_include_directories()` | Добавьте `target_include_directories(${PROJECT_NAME} PRIVATE "Inc")` |
| `stm32f4xx_hal_conf.h` не найден | Путь не в `include_directories` YAML | Добавьте `"Core/Inc"` в `include_directories` в `stm32_config.yml` |
| Конфликт имён файлов | Одинаковые имена в разных папках | Используйте уникальные имена или организуйте структуру папок |

## Отладка подключения

### Проверка, что файлы добавлены

Включите отладочный вывод в `stm32_config.yml`:

```yaml
log_target_properties: true
verbose_build: true
```

Затем выполните:

```bash
cmake -B build -S . 2>&1 | grep -i "source"
```

Ожидаемый вывод:
```
-- Определение имени проекта: MyProject
-- Подключение модуля из директории: Core
-- Добавление исходного файла: Core/Src/main.c
```

### Проверка флагов компиляции

```bash
cmake -B build -S .
cmake --build build --target MyProject -- VERBOSE=1
```

Убедитесь, что все файлы компилируются с одинаковыми флагами:
```
arm-none-eabi-gcc -Og -g3 -std=gnu17 -DSTM32F4xx ... Core/Src/main.c
arm-none-eabi-gcc -Og -g3 -std=gnu17 -DSTM32F4xx ... Core/Src/gpio.c
```

## Примечания

1. **`${PROJECT_NAME}`**: Эта переменная устанавливается фреймворком `stm32-cmake-yml` в корневом `CMakeLists.txt`. Все подмодули могут её использовать.

2. **Порядок в `sources`**: Файлы добавляются в порядке указания в `stm32_config.yml`. Это может влиять на порядок линковки.

3. **PRIVATE vs PUBLIC**: Для `target_include_directories` используйте `PRIVATE`, так как заголовки не экспортируются другим целям (все файлы в одной цели).

4. **Ассемблерные файлы**: `.s` файлы добавляются так же, как `.c`. Убедитесь, что `ASM` указан в `languages` в `stm32_config.yml`.

5. **Пересборка**: При добавлении новых файлов в явном списке (`target_sources`) CMake автоматически обнаружит изменения. При использовании `GLOB` может потребоваться `rm -rf build`.

6. **CubeMX-регенерация**: При регенерации кода из CubeMX файлы могут перезаписываться. Храните пользовательский код в папке `User/` с отдельным `CMakeLists.txt`.

## Ссылки

- [Навык stm32-config-manager](../stm32-config-manager/SKILL.md) — Управление конфигурацией проекта
- [Навык stm32-module-creator](../stm32-module-creator/SKILL.md) — Создание отдельных библиотек-модулей
- [Документация stm32-cmake-yml](https://github.com/ViacheslavMezentsev/stm32-cmake-yml)
```
