# Руководство пользователя stm32-cmake-yml

Файл `stm32_config.yml` является ядром вашего проекта. Изменяя его, вы управляете всем процессом сборки, подключением драйверов и структурой проекта без необходимости писать сложный код на CMake.

---

## 1. Режимы работы: IOC против ручной настройки

Фреймворк поддерживает два основных режима получения данных о микроконтроллере:

* **Интеграция с STM32CubeMX (`ioc_file`)**: Если вы укажете путь к файлу `.ioc`, фреймворк автоматически считает из него модель MCU, размеры Heap/Stack и версию библиотек. Это самый надежный способ.

    ```yaml
    ioc_file: "my_project.ioc"
    ```

* **Ручной режим**: Если `ioc_file` закомментирован или пуст, вы должны явно указать модель контроллера:

    ```yaml
    mcu: "STM32F401CCU6"
    heap_size: "512"
    stack_size: "1K"
    ```

### Приоритет YAML над .ioc

При использовании `ioc_file` параметры из `stm32_config.yml` имеют явный приоритет над значениями из `.ioc`. Это позволяет точечно переопределять отдельные параметры, не меняя сам `.ioc`:

```yaml
ioc_file: "project.ioc"

# Переопределяем только нужное — остальное берётся из .ioc автоматически
heap_size: 8K
stack_size: 4K
use_freertos: false   # явно отключаем, даже если в .ioc включён FreeRTOS
```

---

## 2. Исходные файлы и структура (`sources`)

В секции `sources` перечисляются папки и файлы, участвующие в сборке.

> **Важное замечание по драйверам и FreeRTOS:**
> Для компонентов драйверов HAL/LL из пакетов STM32Cube_FW_XX файлы `CMakeLists.txt` по умолчанию **не нужны**. Если фреймворк находит эти пакеты (локально в папке `Drivers` или глобально), он подключает их автоматически. Это же касается и FreeRTOS, если она входит в пакет (при `freertos_version: "cube"`).
>
> Файлы `CMakeLists.txt` требуются только для **ваших** папок с кодом (например, `Core`, `User`) или при подключении особых сторонних библиотек.

Существует два основных подхода для ваших исходников:

### Подход А: Код из CubeMX и системные файлы (Упрощенный)

Для папки `Core` (сгенерированной CubeMX) можно прикрепить эти файлы напрямую к основной цели проекта. Это гарантирует совпадение флагов компиляции.
*(Подробнее см. AI-навык `stm32-simple-sources`)*

Пример `Core/CMakeLists.txt`:

```cmake
cmake_minimum_required(VERSION 3.19)

# Добавляем пути к заголовкам
target_include_directories(${PROJECT_NAME} PRIVATE "Inc")

# Добавляем исходники напрямую в проект
target_sources(${PROJECT_NAME} PRIVATE
    Src/main.c
    Src/stm32f4xx_it.c
    Src/system_stm32f4xx.c
)
```

### Подход Б: Собственные модули (Библиотеки)

Если вы пишете переиспользуемый код (например, драйвер дисплея в папке `Middlewares` или `Drivers/Display`), его можно оформить как статическую библиотеку.
*(Подробнее см. AI-навык `stm32-module-creator`)*

Пример `Drivers/Display/CMakeLists.txt`:

```cmake
cmake_minimum_required(VERSION 3.19)
file(GLOB_RECURSE SOURCES "*.c" "*.cpp")

# Создаем библиотеку 'display'
add_library(display STATIC ${SOURCES})
target_include_directories(display PUBLIC "Inc")

# Обязательно наследуем системные настройки
target_link_libraries(display PUBLIC STM32::${MCU_FAMILY} HAL::STM32::${MCU_FAMILY})
```

---

## 3. Драйверы и RTOS

Управление подключением компонентов от STMicroelectronics:

```yaml
use_cmsis: true
use_hal: true
hal_components:
  - "RCC"
  - "GPIO"
  - "LL_USB" # Использование префикса LL_ автоматически добавляет нужные дефайны

use_freertos: true
freertos_components:
  - "ARM_CM4F" # Обязательно укажите порт ядра!
  - "Heap::4"  # Обязательно укажите тип кучи!
  - "Timers"
cmsis_rtos_api: "v2" # Обертка CMSIS-RTOS ("v1", "v2" или "none")
```

---

## 4. Настройки компиляции

### Общие флаги и defines

```yaml
languages: [C, CXX, ASM]
c_standard: 17
cpp_standard: 17

compile_definitions: [ STM32F4xx, DEBUG, USE_FREERTOS ]

compile_options:
  - "$<$<CONFIG:Debug>:-Og -g3>"
  - Wall
  - Wextra
```

### Раздельные флаги для C и C++

Помимо общих ключей `compile_options` и `compile_definitions`, доступны языково-специфичные варианты:

```yaml
# Только для C
compile_options_c:
  - Wstrict-prototypes
  - Wmissing-prototypes

# Только для C++
compile_options_cxx:
  - fno-exceptions
  - fno-rtti
  - Wold-style-cast

# Только для C++
compile_definitions_cxx:
  - EIGEN_NO_DEBUG
```

Под капотом языково-специфичные флаги передаются через генераторные выражения CMake `$<COMPILE_LANGUAGE:C>` и `$<COMPILE_LANGUAGE:CXX>`, поэтому они гарантированно не попадут к «чужому» компилятору.

### Упрощённая запись флагов

Фреймворк автоматически нормализует все флаги компилятора и линкера:

**Несколько флагов в одной строке** разбиваются автоматически:

```yaml
compile_options:
  - "-Wall -Wextra -Os"   # эквивалентно трём отдельным строкам
```

**Ведущий дефис** добавляется автоматически, если он не указан:

```yaml
compile_options:
  - Wall              # → -Wall
  - fdata-sections    # → -fdata-sections
  - "-Os"             # уже корректно, не изменяется
```

**Генераторные выражения CMake** не затрагиваются:

```yaml
compile_options:
  - "$<$<CONFIG:Debug>:-Og -g3>"  # без изменений
```

**Defines** разбиваются по пробелам, но дефис не добавляется — CMake делает это сам через `target_compile_definitions`:

```yaml
compile_definitions: [ STM32F4xx, DEBUG, USE_FREERTOS ]
compile_definitions:
  - "USE_HAL_DRIVER HSE_VALUE=25000000"  # два отдельных define
```

---

## 5. Скрипт компоновщика

### Автоматическая генерация (`linker_script: auto`)

При `linker_script: auto` фреймворк ищет в корне проекта шаблон `.ld.in` по трём вариантам имени — от точного к общему:

| Приоритет | Пример для STM32H723VGT6 |
|---|---|
| 1 — точное совпадение | `STM32H723VG_FLASH.ld.in` |
| 2 — корпус заменён на X (стиль CubeMX) | `STM32H723XG_FLASH.ld.in` |
| 3 — широкий фолбек | `STM32H723XX_FLASH.ld.in` |

Если шаблон найден, из него генерируется `.ld` файл в папке сборки с подстановкой `@HEAP_SIZE@` и `@STACK_SIZE@`. Если не найден — используется встроенный скрипт из `stm32-cmake`.

Файлы `.ld.in` можно получить, взяв за основу файлы `.ld`, сгенерированные STM32CubeMX, и заменив в них жёстко заданные размеры на переменные `@HEAP_SIZE@` и `@STACK_SIZE@`.

### Пользовательский скрипт

```yaml
linker_script: "STM32H723VG_FLASH.ld"  # путь относительно корня проекта
```

### Проверка RAM

При `validate_linker_script: true` фреймворк суммирует все RAM-секции из блока `MEMORY{}` скрипта (корректно для H7 с несколькими регионами) и выводит информационное сравнение:

```
--   RAM-секции в скрипте: DTCMRAM:128K + RAM:320K + RAM_D2:32K + RAM_D3:16K = 507904 байт
--   stm32-cmake RAM : 128K
--   Скрипт RAM сумма: 507904 байт (496K)
--   Соотношение     : 496K > 128K
```

---

## 6. Контроль целостности прошивки (CRC32)

Фреймворк поддерживает автоматический расчёт аппаратного CRC32 и его внедрение в прошивку. Это позволяет реализовать самопроверку устройства при загрузке. Для работы механизма требуется установленный **Python 3**.

### Настройка в `stm32_config.yml`

```yaml
crc_enable: true
crc_section_name: ".checksum"
crc_algorithm: "STM32_HW_DEFAULT"
```

### Настройка скрипта компоновщика (.ld)

Для работы механизма в ваш `.ld` файл (или шаблон `.ld.in`) необходимо добавить специальные секции и символы.

Правильное расположение секций критически важно:

1. **`__checksum_start`** — метка начала расчёта. Должна находиться в самом начале прошивки, перед таблицей векторов прерываний.
2. **`.checksum`** — секция для хранения контрольной суммы. Должна находиться в самом **конце** области `FLASH`. Такое расположение удобно для загрузчиков и скриптов верификации.
3. **Размер прошивки** — удобно сохранять сразу после таблицы векторов. Загрузчику часто необходимо знать точный размер прошивки перед передачей управления.

Пример модификации `.ld` файла:

```ld
SECTIONS
{
  .isr_vector :
  {
    __checksum_start = .;      /* МЕТКА НАЧАЛА расчёта (самое начало FLASH) */
    . = ALIGN(4);
    KEEP(*(.isr_vector))
    . = ALIGN(4);
    LONG(__checksum_size)      /* Размер прошивки после векторов (для загрузчика) */
  } >FLASH

  /* ... остальные секции (.text, .rodata, и т.д.) ... */

  .checksum :
  {
    . = ALIGN(4);
    __checksum_end = .;        /* Метка конца расчёта и место хранения CRC */
    LONG(0);                   /* Резервируем 4 байта под CRC */
  } >FLASH

  __checksum_size = __checksum_end - __checksum_start;
}
```

### Проверка CRC в коде микроконтроллера

Фреймворк только *рассчитывает и записывает* CRC в файл `.elf`. Проверку при запуске вы должны реализовать самостоятельно.

```c
extern uint32_t __checksum_start[];
extern uint32_t __checksum_end[];
extern uint32_t __checksum_size[];

int CheckFirmwareIntegrity(CRC_HandleTypeDef *hcrc)
{
    uint32_t data_len_words = (uint32_t)__checksum_size / sizeof(uint32_t);
    uint32_t calc_crc = HAL_CRC_Calculate(hcrc, (uint32_t*)__checksum_start, data_len_words);
    uint32_t stored_crc = (uint32_t)__checksum_end;

    if (calc_crc != stored_crc)
    {
        printf("КРИТИЧЕСКАЯ ОШИБКА: ПРОВЕРКА ЦЕЛОСТНОСТИ КОДА НЕ ПРОЙДЕНА!\n");
        printf("Stored CRC: 0x%08lX, Calc CRC: 0x%08lX\n", stored_crc, calc_crc);
        return HAL_ERROR;
    }

    return HAL_OK;
}
```

---

## 7. Отладка и диагностика сборки

Если проект не собирается или вы хотите понять, какие флаги применяются «под капотом», используйте опции в `stm32_config.yml`:

```yaml
# Информационный вывод соотношения RAM в скрипте компоновщика и данных от stm32-cmake
validate_linker_script: true

# Вывод детальной информации о флагах (includes, defines) в лог CMake
log_target_properties: true

# Вывод полных команд компилятора GCC в терминал при сборке
verbose_build: true
```

---

## 8. Профили сборки и cmake-overrides

Фреймворк поддерживает два уровня внешней конфигурируемости, которые применяются
поверх значений `stm32_config.yml`. Это позволяет использовать один конфигурационный
файл для нескольких ревизий платы или MCU без дублирования настроек.

### Порядок приоритетов

```
значения по умолчанию фреймворка
  → ioc_file
  → базовые значения stm32_config.yml
  → профиль (-DSTM32_YML_PROFILE)
  → точечные overrides (-DSTM32_YML_OVERRIDE_*)
```

### Именованные профили

Профили объявляются в секции `profiles:` файла `stm32_config.yml`. Каждый профиль
содержит параметры, которые перекрывают базовые значения при его активации.

```yaml
# Базовые настройки, общие для всех ревизий платы.
compile_options:
  - Wall
  - "$<$<CONFIG:Debug>:-Og -g3>"

build_artifacts: [ bin, hex, map ]
crc_enable: true

# Профили для двух ревизий платы.
profiles:
  G431:
    mcu: STM32G431CBUx
    linker_script: resources/STM32G431XX_FLASH.ld
    compile_definitions:
      - STM32G431xx
      - ARDUINO_GENERIC_G431CBUX
    compile_definitions_append:
      - BOARD_REV=1

  G474:
    mcu: STM32G474CETx
    linker_script: resources/STM32G474XX_FLASH.ld
    compile_definitions:
      - STM32G474xx
      - ARDUINO_GENERIC_G474CEUX
    compile_definitions_append:
      - BOARD_REV=2
```

Активация профиля при конфигурировании:

```bash
cmake -DSTM32_YML_PROFILE=G431 -B build/G431 -S .
cmake -DSTM32_YML_PROFILE=G474 -B build/G474 -S .
```

Просмотр доступных профилей:

```bash
cmake -DSTM32_YML_PROFILE=list -B build_tmp -S .
```

Для списочных параметров (`compile_definitions`, `compile_options`, `sources`,
`include_directories` и других) профиль поддерживает две семантики:

| Ключ | Поведение |
|---|---|
| `compile_definitions` | заменяет базовый список из yml |
| `compile_definitions_append` | дополняет базовый список из yml |

Обе семантики можно комбинировать в одном профиле.

Если профили разрастаются, их можно вынести в отдельный файл:

```yaml
# stm32_config.yml
profiles_file: "profiles.yml"
```

### Точечные cmake-overrides

Позволяют перекрыть один параметр без правки yml-файла. Применяются поверх профиля.
Удобны для отладки или разовых экспериментов в CI.

```bash
cmake -DSTM32_YML_PROFILE=G474 \
      -DSTM32_YML_OVERRIDE_heap_size=8K \
      -DSTM32_YML_OVERRIDE_verbose_build=true
```

Поддерживаются только скалярные значения. Для списков используйте профили.

### Пример конфигурации CI (GitLab)

```yaml
build_firmware:
  parallel:
    matrix:
      - BUILD_TYPE: ["Debug", "Release"]
        MCU_TARGET: ["G431", "G474"]
  script:
    - cmake -S . -B build/${BUILD_TYPE}_${MCU_TARGET} -G Ninja
        -DCMAKE_BUILD_TYPE=${BUILD_TYPE}
        -DSTM32_YML_PROFILE=${MCU_TARGET}
    - cmake --build build/${BUILD_TYPE}_${MCU_TARGET}
```

---

## 9. Arduino Core STM32 как backend сборки

Фреймворк поддерживает два backend'а сборки, выбираемых параметром
`toolchain_backend` в `stm32_config.yml`:

| Значение | Поведение |
|---|---|
| `stm32-cmake` | По умолчанию. HAL/CMSIS через stm32-cmake, ioc_file, FreeRTOS. |
| `arduino` | Arduino Core STM32. HAL/CMSIS через SrcWrapper. |

При `toolchain_backend: arduino` фреймворк не подключает stm32-cmake HAL/CMSIS
и не использует `ioc_file`. Вместо этого активируется модуль `stm32_yml_arduino.cmake`.

### Настройка toolchain

Toolchain при Arduino backend задаётся в `CMakeLists.txt` проекта так же, как
и без фреймворка — через `CMAKE_TOOLCHAIN_FILE`. Фреймворк не управляет toolchain.

Пример с кастомным toolchain-файлом (как в Arduino-проектах):

```cmake
set(CMAKE_TOOLCHAIN_FILE
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/gcc-arm-none-eabi.cmake")
```

Пример с toolchain из stm32-cmake (если он доступен в modules/):

```cmake
set(CMAKE_TOOLCHAIN_FILE
    "${CMAKE_CURRENT_SOURCE_DIR}/modules/stm32-cmake/cmake/stm32_gcc.cmake")
```

### Параметры секции arduino:

```yaml
toolchain_backend: arduino

arduino:
  # Путь к папке Arduino_Core_STM32 относительно корня проекта.
  # В CI обычно задаётся через симлинк modules/Arduino_Core_STM32 -> /opt/...
  core_path: "modules/Arduino_Core_STM32"

  # Путь к папке с CMakeLists.txt пользовательского ядра Arduino.
  # По умолчанию: Arduino/Core в корне проекта.
  core_cmake_dir: "Arduino/Core"

  # Значение MCU_TARGET, пробрасываемое в CMakeLists.txt библиотек.
  # Используется в Arduino/Core/CMakeLists.txt для выбора variant.
  # Может быть переопределено профилем или cmake-override.
  mcu_target: "G474"

  # Подключать ли стандартный Arduino main() из ядра.
  # false — если вы пишете свой int main() в src/main.cpp.
  use_core_main: false

  # Стандартные библиотеки из <core_path>/libraries/.
  # Фреймворк вызывает add_subdirectory для каждой из них.
  libraries:
    - SrcWrapper     # HAL/LL обёртки — почти всегда нужна.
    - EEPROM
    - IWatchdog
    - Wire

  # Кастомные библиотеки — пути от корня проекта.
  # Фреймворк вызывает add_subdirectory для каждой из них.
  custom_libraries:
    - "cli"
```

### Что фреймворк делает автоматически

При `toolchain_backend: arduino` фреймворк:

1. Проверяет наличие папки `arduino.core_path` и выдаёт понятную ошибку если
   она не найдена (актуально для CI где Arduino Core подключается симлинком).
2. Создаёт INTERFACE-таргет `Arduino::Definitions` с `compile_definitions` и
   `compile_options` из yml. Пользовательские `CMakeLists.txt` библиотек
   линкуются с ним через `target_link_libraries(... Arduino::Definitions)`.
3. Пробрасывает `MCU_TARGET` и `ARDUINO_CORE_DIR` в CMake CACHE — их
   используют `CMakeLists.txt` `Arduino/Core` и библиотек.
4. Вызывает `add_subdirectory` для `arduino.core_cmake_dir` (ядро Arduino).
5. Вызывает `add_subdirectory` для каждой библиотеки из `arduino.libraries`.
6. Вызывает `add_subdirectory` для каждой библиотеки из `arduino.custom_libraries`.

### Что остаётся в CMakeLists.txt проекта

Специфическая логика проекта, которая не является типовой задачей фреймворка,
остаётся в `CMakeLists.txt`:

- генерация кода из DSDL/Protobuf/других источников;
- проверка наличия внешних зависимостей (ETL и т.п.);
- `target_link_libraries` основного таргета с Arduino-библиотеками;
- `target_include_directories` специфичные для проекта.

### Использование профилей с Arduino backend

Профили особенно полезны при Arduino backend, так как `mcu_target` и
`compile_definitions` отличаются для каждой ревизии платы:

```yaml
toolchain_backend: arduino

arduino:
  core_path: "modules/Arduino_Core_STM32"
  core_cmake_dir: "Arduino/Core"
  use_core_main: false
  libraries: [SrcWrapper, EEPROM, IWatchdog, Wire]

compile_options:
  - "-mthumb -mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16"
  - fdata-sections
  - ffunction-sections
  - Wall
  - "$<$<CONFIG:Debug>:-Os -g3>"
  - "$<$<CONFIG:Release>:-O2>"

compile_options_cxx:
  - fno-exceptions
  - fno-rtti
  - fno-threadsafe-statics

build_artifacts: [bin, hex, map]
crc_enable: true

profiles:
  G431:
    mcu: STM32G431CBUx
    linker_script: resources/STM32G431XX_FLASH.ld
    arduino:
      mcu_target: G431
    compile_definitions:
      - STM32G431xx
      - ARDUINO_GENERIC_G431CBUX
      - "BOARD_NAME=\"GENERIC_G431CBUX\""
      - "VARIANT_H=\"variant_generic.h\""
    compile_definitions_append:
      - BOARD_REV=1

  G474:
    mcu: STM32G474CETx
    linker_script: resources/STM32G474XX_FLASH.ld
    arduino:
      mcu_target: G474
    compile_definitions:
      - STM32G474xx
      - ARDUINO_GENERIC_G474CEUX
      - "BOARD_NAME=\"GENERIC_G474CEUX\""
      - "VARIANT_H=\"variant_generic.h\""
    compile_definitions_append:
      - BOARD_REV=2
```

Сборка в CI:

```bash
cmake -DSTM32_YML_PROFILE=G431 -B build/G431 -S .
cmake -DSTM32_YML_PROFILE=G474 -B build/G474 -S .
```

### Минимальный CMakeLists.txt при Arduino backend

```cmake
cmake_minimum_required(VERSION 3.19)

# Toolchain — задаётся в проекте, фреймворк его не трогает.
set(CMAKE_TOOLCHAIN_FILE
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/gcc-arm-none-eabi.cmake")

set(STM32_YML_FRAMEWORK_DIR "${CMAKE_CURRENT_SOURCE_DIR}/modules/stm32-cmake-yml")
list(APPEND CMAKE_MODULE_PATH "${STM32_YML_FRAMEWORK_DIR}")
include(stm32_yml)

stm32_yml_prepare_project_data(PROJECT_NAME PROJECT_LANGUAGES)
project(${PROJECT_NAME} LANGUAGES ${PROJECT_LANGUAGES})
stm32_yml_setup_project(${PROJECT_NAME})

# Специфика проекта: линковка, include-пути, кастомные цели.
target_link_libraries(${PROJECT_NAME} PRIVATE
    Arduino::EEPROM
    Arduino::IWatchdog
    Arduino::Wire
    Arduino::SrcWrapper
    Arduino::Core
    Arduino::Definitions
    Cli
)

target_include_directories(${PROJECT_NAME} PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src/include
    ${CMAKE_CURRENT_SOURCE_DIR}/lib/libcanard
    ${CMAKE_CURRENT_SOURCE_DIR}/../modules/etl/include
)
```

## 10. Работа с AI-ассистентами (Agent Skills)

# ==============================================================================
# 2. Обновление skills/stm32-config-manager/SKILL.md
# ==============================================================================

Фреймворк спроектирован так, чтобы современные нейросети (ChatGPT, Claude, а также встроенные в IDE агенты вроде Cursor, Windsurf, Copilot) могли легко с ним работать.

В папке `skills/` в корне репозитория находятся специальные инструкции в формате **Agent Skills**. Они объясняют ИИ специфику архитектуры вашего проекта, чтобы ИИ давал правильный код и не пытался «сломать» конфигурацию стандартными CMake-решениями.

### Как использовать

Общаясь с ИИ, явно просите его опираться на нужный навык (в умных IDE можно использовать символ `@` для упоминания файла).

**Примеры запросов:**

* *"Мне нужно включить FreeRTOS. Изучи навык `stm32-config-manager` и скажи, как изменить мой `stm32_config.yml`."*
* *"Я сгенерировал код в папку Core/. Прочитай навык `stm32-simple-sources` и напиши правильный CMakeLists.txt для этой папки."*
* *"Я хочу написать свой драйвер. Изучи `stm32-module-creator` и создай структуру для нового модуля."*
* *"У меня ошибка `cannot find entry symbol Reset_Handler`. Посмотри `stm32-build-helper` и подскажи решение."*

Использование этих навыков экономит часы отладки и предотвращает галлюцинации нейросетей при работе со сборочными скриптами.
