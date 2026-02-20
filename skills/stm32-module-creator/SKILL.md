---
name: stm32-module-creator
description: Создание новых модулей (библиотек) для проектов STM32 на базе фреймворка stm32-cmake-yml. Обеспечивает наследование флагов компиляции, правильную линковку зависимостей и совместимость с основным проектом.
license: MIT
compatibility: Требуется фреймворк stm32-cmake-yml (версия 0.5+), CMake 3.19+. Все модули должны быть указаны в stm32_config.yml.
metadata:
  version: "0.1"
  framework: stm32-cmake-yml
---

# Создание модулей для STM32 проекта

Этот навык описывает процедуру добавления новых модулей кода (статических библиотек) в проект на базе **stm32-cmake-yml**.

## ⚠️ Критически важные правила

1. **ЕДИНЫЕ ФЛАГИ**: Модуль **НАСЛЕДУЕТ** все флаги компиляции из корневого проекта. НЕ устанавливайте `CMAKE_C_STANDARD`, `CMAKE_CXX_STANDARD`, `compile_options` внутри модуля.
2. **ОБЯЗАТЕЛЬНЫЙ CMakeLists.txt**: Каждая папка в `sources` (stm32_config.yml) должна содержать свой `CMakeLists.txt`. Без него сборка упадет с ошибкой.
3. **СОВМЕСТИМОСТЬ**: Модуль линкуется к тем же целям (CMSIS, HAL, FreeRTOS), что и основной проект, через `target_link_libraries`.
4. **ИМЯ БИБЛИОТЕКИ**: Должно совпадать с именем папки (в нижнем регистре) для предсказуемости.

---

## Рабочий процесс

### Шаг 1: Создать структуру папок

```
Project/
├── MyModule/
│     ├── Inc/
│     │   └── my_module.h
│     ├── Src/
│     │   └── my_module.c
│     └── CMakeLists.txt    # ОБЯЗАТЕЛЬНО
└── stm32_config.yml
```

### Шаг 2: Создать CMakeLists.txt модуля

Используйте этот шаблон. Он **наследует** все настройки от корневого проекта:

```cmake
# CMakeLists.txt для модуля: {MODULE_NAME}
# Фреймворк: stm32-cmake-yml
# ВАЖНО: Не устанавливайте CMAKE_C_STANDARD здесь - наследуется от проекта!

cmake_minimum_required(VERSION 3.19)

# 1. Находим все исходные файлы рекурсивно
file(GLOB_RECURSE MODULE_SOURCES
    "${CMAKE_CURRENT_SOURCE_DIR}/Src/*.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/Src/*.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/Src/*.s"
)

# 2. Создаем статическую библиотеку
# Имя должно быть уникальным в пределах проекта
add_library({module_name} STATIC ${MODULE_SOURCES})

# 3. Открываем заголовочные файлы для основного проекта
# PUBLIC = модуль и все кто его линкует видят эти пути
target_include_directories({module_name} PUBLIC
    "${CMAKE_CURRENT_SOURCE_DIR}/Inc"
    "${CMAKE_CURRENT_SOURCE_DIR}"
)

# 4. Линковка зависимостей (НАСЛЕДОВАНИЕ от проекта)
# Модуль должен компилироваться с теми же определениями, что и проект
# Если модуль использует HAL/CMSIS/FreeRTOS - линкуем к глобальным целям
target_link_libraries({module_name} PUBLIC
    # Эти цели создаются в корневом CMakeLists.txt через stm32_yml_setup_project
    # Модуль получит все флаги, определения и пути от них
    STM32::${MCU_FAMILY}           # CMSIS цели (семейство)
    HAL::STM32::${MCU_FAMILY}      # HAL цели (если use_hal: true)
    FreeRTOS::STM32::${MCU_FAMILY} # FreeRTOS цели (если use_freertos: true)
)

# 5. (Опционально) Специфичные определения только для этого модуля
# target_compile_definitions({module_name} PRIVATE MY_MODULE_ENABLED)
```

### Шаг 3: Зарегистрировать модуль в stm32_config.yml

Добавьте путь к папке в список `sources`:

```yaml
sources:
  - "Core"
  - "User"
  - "MyModule"      # <-- Добавить эту строку
  - "ros_lib"
```

### Шаг 4: Использовать модуль в основном коде

В `main.c` или других файлах проекта:

```c
#include "my_module.h"  // Путь автоматически добавлен через target_include_directories

int main(void) {
    MyModule_Init();    // Функции из модуля доступны
    return 0;
}
```

---

## Почему это работает правильно

### Наследование флагов компиляции

| Настройка | Где устанавливается | Как наследуется |
| --- | --- | --- |
| `CMAKE_C_STANDARD` | Корневой CMakeLists.txt | Автоматически для всех целей |
| `CMAKE_CXX_STANDARD` | Корневой CMakeLists.txt | Автоматически для всех целей |
| `compile_options` | stm32_config.yml → root CMake | Через `target_link_libraries` к STM32:: цели |
| `compile_definitions` | stm32_config.yml → root CMake | Через `target_link_libraries` к HAL/FreeRTOS целям |
| `include_directories` | stm32_config.yml → root CMake | Через `PUBLIC` в target_include_directories модуля |

### Механизм наследования

```
┌─────────────────────────────────────────────────────────────┐
│                    КОРНЕВОЙ ПРОЕКТ                          │
│  stm32_yml_setup_project(${PROJECT_NAME})                   │
│  ├── Устанавливает CMAKE_C_STANDARD = 17                    │
│  ├── Устанавливает compile_options: -Og -g3 -gdwarf-2       │
│  ├── Подключает CMSIS::STM32::F4 (INTERFACE цели)           │
│  ├── Подключает HAL::STM32::F4 (INTERFACE цели)             │
│  └── Подключает FreeRTOS::STM32::F4 (INTERFACE цели)        │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ target_link_libraries(module PUBLIC STM32::F4 ...)
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      МОДУЛЬ (библиотека)                    │
│  add_library(mymodule STATIC ...)                           │
│  ├── Наследует CMAKE_C_STANDARD = 17                        │
│  ├── Наследует compile_options: -Og -g3 -gdwarf-2           │
│  ├── Наследует определения: STM32F4xx, USE_HAL_DRIVER...    │
│  └── Наследует include пути: Drivers/CMSIS/...              │
└─────────────────────────────────────────────────────────────┘
```

---

## Частые ошибки и решения

| Ошибка | Причина | Решение |
| --- | --- | --- |
| `undefined reference to HAL_GPIO_WritePin` | Модуль не линкован к HAL цели | Добавить `HAL::STM32::${MCU_FAMILY}` в `target_link_libraries` |
| `stm32f4xx_hal.h not found` | Нет путей include от CMSIS | Линковаться к `STM32::${MCU_FAMILY}` цели |
| `conflicting types for 'printf'` | Разные флаги newlib между модулем и проектом | НЕ устанавливать флаги в модуле, наследовать от проекта |
| `CMake Error: sources list is empty` | Неправильный путь в `file(GLOB_RECURSE)` | Проверить относительные пути от `CMAKE_CURRENT_SOURCE_DIR` |
| `module not found in stm32_config.yml` | Папка не добавлена в `sources` | Добавить путь в `stm32_config.yml` |

---

## Продвинутые сценарии

### Модуль без зависимостей HAL

Если модуль чисто математический и не использует периферию:

```cmake
add_library(math_utils STATIC ${MODULE_SOURCES})

target_include_directories(math_utils PUBLIC
    "${CMAKE_CURRENT_SOURCE_DIR}/Inc"
)

# НЕ линковать к HAL/CMSIS - уменьшит зависимости
# target_link_libraries(math_utils PUBLIC)  # Пустой список
```

### Модуль с собственными определениями

```cmake
add_library(sensor_driver STATIC ${MODULE_SOURCES})

target_include_directories(sensor_driver PUBLIC
    "${CMAKE_CURRENT_SOURCE_DIR}/Inc"
)

# Наследуем HAL/CMSIS от проекта
target_link_libraries(sensor_driver PUBLIC
    STM32::${MCU_FAMILY}
    HAL::STM32::${MCU_FAMILY}
)

# Добавляем специфичное определение только для этого модуля
target_compile_definitions(sensor_driver PRIVATE
    SENSOR_DRIVER_VERSION="1.0"
    SENSOR_I2C_ADDRESS=0x48
)
```

### Модуль с зависимостью на другой модуль

```cmake
add_library(display STATIC ${DISPLAY_SOURCES})

target_include_directories(display PUBLIC
    "${CMAKE_CURRENT_SOURCE_DIR}/Inc"
)

# Линкуем к другому модулю + системные цели
target_link_libraries(display PUBLIC
    gui_library              # Другой модуль проекта
    STM32::${MCU_FAMILY}
    HAL::STM32::${MCU_FAMILY}
)
```

---

## Валидация модуля

После создания модуля выполните проверку:

```bash
# 1. Проверка конфигурации CMake
cmake -B build -S .

# 2. Проверка, что модуль найден
cmake -B build -S . 2>&1 | grep -i "mymodule"

# 3. Полная сборка
cmake --build build

# 4. Проверка размеров секций (опционально)
arm-none-eabi-size build/YourProject.elf
```

### Ожидаемый вывод при успешной конфигурации

```
-- Определение имени проекта: YourProject
-- Подключение модуля из директории: MyModule
-- Автоматическое подключение компонентов HAL/LL включено.
-- Подключение скрипта компоновщика: .../STM32F411CE_FLASH.ld
-- Calculating and injecting CRC32 into firmware...
```

---

## Примечания

1. **`PUBLIC` vs `PRIVATE`**: Используйте `PUBLIC` для `target_include_directories`, чтобы главный проект видел заголовки модуля.
2. **Не дублируйте `find_package`**: CMSIS/HAL/FreeRTOS уже найдены в корневом CMakeLists.txt. Модуль только линкуется к готовым целям.
3. **Статическая линковка**: Модули компилируются как статические библиотеки (`.a`) и линкуются в финальный ELF.
4. **Порядок в `sources`**: Порядок папок в `stm32_config.yml` влияет на порядок линковки. Зависимые модули должны идти после зависимостей.
5. **GLOB_RECURSE предупреждение**: При добавлении новых файлов может потребоваться перезапуск CMake (`rm -rf build && cmake -B build`).

---

## Пример полного CMakeLists.txt модуля

```cmake
# MyModule/CMakeLists.txt
cmake_minimum_required(VERSION 3.19)

# Находим исходники
file(GLOB_RECURSE MODULE_SOURCES
    "Src/*.c"
    "Src/*.cpp"
    "Src/*.s"
)

# Создаем библиотеку
add_library(mymodule STATIC ${MODULE_SOURCES})

# Открываем заголовки
target_include_directories(mymodule PUBLIC
    "Inc"
    "."
)

# Линкуем к системным целям (наследование флагов)
target_link_libraries(mymodule PUBLIC
    STM32::${MCU_FAMILY}
    HAL::STM32::${MCU_FAMILY}
)

# Специфичные определения модуля
target_compile_definitions(mymodule PRIVATE
    MYMODULE_ENABLED=1
)
```

---

## Ссылки

- [Документация stm32-cmake-yml](https://github.com/ViacheslavMezentsev/stm32-cmake-yml)
- [CMake target_link_libraries](https://cmake.org/cmake/help/latest/command/target_link_libraries.html)
- [Навык stm32-config-manager](../stm32-config-manager/SKILL.md)
```
