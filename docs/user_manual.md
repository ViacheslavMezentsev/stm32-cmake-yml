# Руководство пользователя stm32-cmake-yml

Файл `stm32_config.yml` является ядром вашего проекта. Изменяя его, вы управляете
всем процессом сборки, подключением драйверов и структурой проекта без необходимости
писать сложный код на CMake.

---

## 1. Режимы работы: IOC против ручной настройки

Фреймворк поддерживает два основных режима получения данных о микроконтроллере.

**Интеграция с STM32CubeMX (`ioc_file`):** если вы укажете путь к файлу `.ioc`,
фреймворк автоматически считает из него модель MCU, размеры Heap/Stack и версию
библиотек. Это самый надёжный способ.

```yaml
ioc_file: "my_project.ioc"
```

**Ручной режим:** если `ioc_file` не указан, задайте модель контроллера явно.

```yaml
mcu: "STM32F401CCU6"
heap_size: "512"
stack_size: "1K"
```

### Приоритет YAML над .ioc

Параметры из `stm32_config.yml` имеют явный приоритет над значениями из `.ioc`.
Это позволяет точечно переопределять отдельные параметры, не меняя сам `.ioc`:

```yaml
ioc_file: "project.ioc"

# Переопределяем только нужное — остальное берётся из .ioc автоматически.
heap_size: 8K
stack_size: 4K
use_freertos: false   # явно отключаем, даже если в .ioc включён FreeRTOS
```

---

## 2. Исходные файлы и структура (`sources`)

В секции `sources` перечисляются папки и файлы, участвующие в сборке.

> Для компонентов HAL/LL из пакетов STM32Cube_FW файлы `CMakeLists.txt` не нужны —
> фреймворк подключает их автоматически. Файлы `CMakeLists.txt` требуются только
> для ваших папок с кодом (`Core`, `User`) или сторонних библиотек.

Существует два основных подхода для пользовательских исходников.

### Подход А: код из CubeMX (упрощённый)

Исходники прикрепляются напрямую к основной цели проекта — гарантирует совпадение
флагов компиляции. Подробнее см. AI-навык `stm32-simple-sources`.

Пример `Core/CMakeLists.txt`:

```cmake
cmake_minimum_required(VERSION 3.19)

target_include_directories(${PROJECT_NAME} PRIVATE "Inc")

target_sources(${PROJECT_NAME} PRIVATE
    Src/main.c
    Src/stm32f4xx_it.c
    Src/system_stm32f4xx.c
)
```

### Подход Б: собственные модули (библиотеки)

Переиспользуемый код оформляется как статическая библиотека.
Подробнее см. AI-навык `stm32-module-creator`.

```cmake
cmake_minimum_required(VERSION 3.19)
file(GLOB_RECURSE SOURCES "*.c" "*.cpp")

add_library(display STATIC ${SOURCES})
target_include_directories(display PUBLIC "Inc")
target_link_libraries(display PUBLIC STM32::${MCU_FAMILY} HAL::STM32::${MCU_FAMILY})
```

---

## 3. Драйверы и RTOS

```yaml
use_cmsis: true
use_hal: true
hal_components:
  - "RCC"
  - "GPIO"
  - "LL_USB"   # префикс LL_ автоматически добавляет USE_FULL_LL_DRIVER

use_freertos: true
freertos_components:
  - "ARM_CM4F"  # обязательно: порт ядра
  - "Heap::4"   # обязательно: схема памяти
  - "Timers"
cmsis_rtos_api: "v2"  # "v1", "v2" или "none"
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

```yaml
compile_options_c:
  - Wstrict-prototypes
  - Wmissing-prototypes

compile_options_cxx:
  - fno-exceptions
  - fno-rtti
  - Wold-style-cast

compile_definitions_cxx:
  - EIGEN_NO_DEBUG
```

Языково-специфичные флаги передаются через генераторные выражения CMake
`$<COMPILE_LANGUAGE:C>` и `$<COMPILE_LANGUAGE:CXX>`.

### Упрощённая запись флагов

Фреймворк автоматически нормализует все флаги компилятора и линкера.

Несколько флагов в одной строке разбиваются автоматически:

```yaml
compile_options:
  - "-Wall -Wextra -Os"   # эквивалентно трём отдельным строкам
```

Ведущий дефис добавляется если он не указан:

```yaml
compile_options:
  - Wall              # -> -Wall
  - fdata-sections    # -> -fdata-sections
  - "-Os"             # уже корректно, не изменяется
```

Генераторные выражения CMake не затрагиваются:

```yaml
compile_options:
  - "$<$<CONFIG:Debug>:-Og -g3>"  # без изменений
```

Defines разбиваются по пробелам, дефис не добавляется — CMake делает это сам:

```yaml
compile_definitions: [ STM32F4xx, DEBUG, USE_FREERTOS ]
compile_definitions:
  - "USE_HAL_DRIVER HSE_VALUE=25000000"  # два отдельных define
```

---

## 5. Скрипт компоновщика

### Автоматическая генерация (`linker_script: auto`)

При `linker_script: auto` фреймворк ищет шаблон `.ld.in` по четырём вариантам
имени в каждой папке поиска (см. `linker_script_dir` ниже):

| Приоритет | Пример для STM32G474RETx |
|---|---|
| 1 — точное совпадение | `STM32G474RE_FLASH.ld.in` |
| 2 — корпус заменён на X (стиль CubeMX H7) | `STM32G474XE_FLASH.ld.in` |
| 3 — оба символа XX (верхний регистр) | `STM32G474XX_FLASH.ld.in` |
| 4 — оба символа xx (нижний регистр, стиль CubeMX G4/F4) | `STM32G474xx_FLASH.ld.in` |

Если шаблон найден, из него генерируется `.ld` в папке сборки с подстановкой
`@HEAP_SIZE@` и `@STACK_SIZE@`. Если не найден — используется встроенный скрипт
от stm32-cmake.

Файлы `.ld.in` получают из `.ld`, сгенерированных CubeMX, заменив жёстко заданные
размеры на переменные `@HEAP_SIZE@` и `@STACK_SIZE@`.

### Папка поиска шаблона (`linker_script_dir`)

По умолчанию шаблон ищется в корне проекта. Параметр `linker_script_dir` задаёт
альтернативную папку поиска — полезно при использовании профилей, когда скрипты
для разных MCU лежат в отдельных папках.

```yaml
profiles:
  F411:
    linker_script_dir: "F411"   # ищет шаблон в F411/, затем в корне проекта
  G474:
    linker_script_dir: "G474"   # ищет шаблон в G474/, затем в корне проекта
```

Параметр можно задать и на базовом уровне как дефолт для всех профилей:

```yaml
linker_script_dir: "resources"   # дефолтная папка для всех профилей
```

### Пользовательский скрипт

```yaml
linker_script: "STM32H723VG_FLASH.ld"   # путь ищется в linker_script_dir, затем в корне
```

### Проверка RAM

При `validate_linker_script: true` фреймворк суммирует все RAM-секции из `MEMORY{}`
скрипта и выводит информационное сравнение (корректно для H7 с несколькими регионами):

```
--   RAM-секции в скрипте: DTCMRAM:128K + RAM:320K + RAM_D2:32K + RAM_D3:16K = 507904 байт
--   stm32-cmake RAM : 128K
--   Скрипт RAM сумма: 507904 байт (496K)
--   Соотношение     : 496K > 128K
```

---

## 6. Контроль целостности прошивки (CRC32)

Фреймворк поддерживает автоматический расчёт аппаратного CRC32 и его внедрение
в прошивку. Требуется Python 3.

### Настройка в `stm32_config.yml`

```yaml
crc_enable: true
crc_section_name: ".checksum"
crc_algorithm: "STM32_HW_DEFAULT"
```

### Настройка скрипта компоновщика

Правильное расположение секций критически важно:

1. **`__checksum_start`** — метка начала расчёта, перед таблицей векторов прерываний.
2. **`.checksum`** — секция хранения CRC, в самом конце FLASH.
3. **`__checksum_size`** — символ размера прошивки, удобен для загрузчика.

```ld
SECTIONS
{
  .isr_vector :
  {
    __checksum_start = .;      /* метка начала расчёта */
    . = ALIGN(4);
    KEEP(*(.isr_vector))
    . = ALIGN(4);
    LONG(__checksum_size)      /* размер прошивки (для загрузчика) */
  } >FLASH

  /* ... остальные секции ... */

  .checksum :
  {
    . = ALIGN(4);
    __checksum_end = .;        /* метка конца расчёта и место хранения CRC */
    LONG(0);                   /* резервируем 4 байта */
  } >FLASH

  __checksum_size = __checksum_end - __checksum_start;
}
```

### Проверка CRC в коде микроконтроллера

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

```yaml
validate_linker_script: true   # информационный вывод соотношения RAM секций
log_target_properties: true    # свойства цели в CMake логе (includes, defines)
verbose_build: true            # полные команды компилятора при сборке
```

---

## 8. Профили сборки и cmake-overrides

Фреймворк поддерживает два уровня внешней конфигурируемости поверх `stm32_config.yml`.
Основное назначение — поддержка нескольких ревизий платы или MCU в одном проекте
при плавном портировании прошивки.

### Порядок приоритетов

```
значения по умолчанию фреймворка
  -> ioc_file
  -> базовые значения stm32_config.yml
  -> профиль (-DSTM32_YML_PROFILE)
  -> точечные overrides (-DSTM32_YML_OVERRIDE_*)
```

### Именованные профили

Профили объявляются в секции `profiles:`. Параметры профиля перекрывают базовые
значения при его активации.

Для списочных параметров (`compile_definitions`, `compile_options`, `sources`,
`include_directories` и других) поддерживаются две семантики:

| Ключ | Поведение |
|---|---|
| `compile_definitions` | заменяет базовый список из yml |
| `compile_definitions_append` | дополняет базовый список из yml |

Пример для проекта с двумя ревизиями платы:

```yaml
# Общие настройки для всех ревизий.
hal_components: [ GPIO, UART, DMA, CRC ]
use_freertos: true
freertos_components: [ ARM_CM4F, "Heap::4", Timers ]
crc_enable: true
build_artifacts: [ bin, hex, map ]

profiles:
  F411:
    ioc_file: "F411/project.ioc"
    linker_script_dir: "F411"
    sources:
      - "F411/Core"
      - "User"
      - "F411/Core/Src/system_stm32f4xx.c"
      - "F411/startup_stm32f411xe.s"
    compile_definitions:
      - STM32F4xx
      - USE_FREERTOS
    compile_definitions_append:
      - BOARD_REV=1

  G474:
    ioc_file: "G474/project.ioc"
    linker_script_dir: "G474"
    sources:
      - "G474/Core"
      - "User"
      - "G474/Core/Src/system_stm32g4xx.c"
      - "G474/startup_stm32g474xx.s"
    compile_definitions:
      - STM32G4xx
      - USE_FREERTOS
    compile_definitions_append:
      - BOARD_REV=2
    hal_components_append:
      - FDCAN
```

Активация профиля:

```bash
cmake -DSTM32_YML_PROFILE=F411 -B build/F411 -S .
cmake -DSTM32_YML_PROFILE=G474 -B build/G474 -S .
```

Просмотр доступных профилей:

```bash
cmake -DSTM32_YML_PROFILE=list -B build_tmp -S .
```

Если профили разрастаются, их можно вынести в отдельный файл:

```yaml
# stm32_config.yml
profiles_file: "profiles.yml"
```

### Рекомендуемая структура проекта при двух MCU

При портировании между MCU рекомендуется хранить всё MCU-специфичное
(`.ioc`, сгенерированный `Core/`, `.ld.in`) в папках по ревизиям:

```text
my-project/
├── F411/
│   ├── Core/
│   ├── project.ioc
│   └── STM32F411XE_FLASH.ld.in
├── G474/
│   ├── Core/
│   ├── project.ioc
│   └── STM32G474xx_FLASH.ld.in
├── User/                        # общий пользовательский код
├── modules/
└── stm32_config.yml
```

### Точечные cmake-overrides

Позволяют перекрыть один скалярный параметр без правки yml. Применяются поверх
профиля. Удобны для отладки и экспериментов в CI.

```bash
cmake -DSTM32_YML_PROFILE=G474 \
      -DSTM32_YML_OVERRIDE_heap_size=8K \
      -DSTM32_YML_OVERRIDE_verbose_build=true
```

### Пример конфигурации CI (GitLab)

```yaml
build_firmware:
  parallel:
    matrix:
      - BUILD_TYPE: ["Debug", "Release"]
        MCU_PROFILE: ["F411", "G474"]
  script:
    - cmake -S . -B build/${BUILD_TYPE}_${MCU_PROFILE} -G Ninja
        -DCMAKE_BUILD_TYPE=${BUILD_TYPE}
        -DSTM32_YML_PROFILE=${MCU_PROFILE}
    - cmake --build build/${BUILD_TYPE}_${MCU_PROFILE}
```

---

## 9. Arduino Core STM32 как backend сборки

Фреймворк поддерживает два backend сборки, выбираемых параметром `toolchain_backend`:

| Значение | Поведение |
|---|---|
| `stm32-cmake` | По умолчанию. HAL/CMSIS через stm32-cmake, ioc_file, FreeRTOS. |
| `arduino` | Arduino Core STM32. HAL/CMSIS через SrcWrapper. |

При `toolchain_backend: arduino` фреймворк не подключает stm32-cmake HAL/CMSIS
и не использует `ioc_file`. Вместо этого активируется модуль `stm32_yml_arduino.cmake`.

### Настройка toolchain

Toolchain задаётся в `CMakeLists.txt` проекта через `CMAKE_TOOLCHAIN_FILE`.
Фреймворк не управляет toolchain.

```cmake
# Кастомный toolchain (типично для Arduino-проектов).
set(CMAKE_TOOLCHAIN_FILE
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/gcc-arm-none-eabi.cmake")

# Или toolchain из stm32-cmake.
set(CMAKE_TOOLCHAIN_FILE
    "${CMAKE_CURRENT_SOURCE_DIR}/modules/stm32-cmake/cmake/stm32_gcc.cmake")
```

### Параметры секции `arduino:`

```yaml
toolchain_backend: arduino

arduino:
  # Путь к Arduino_Core_STM32 от корня проекта.
  # В CI задаётся через симлинк modules/Arduino_Core_STM32 -> /opt/...
  core_path: "modules/Arduino_Core_STM32"

  # Папка с CMakeLists.txt пользовательского ядра.
  # По умолчанию: Arduino/Core в корне проекта.
  core_cmake_dir: "Arduino/Core"

  # Значение MCU_TARGET для выбора variant в Arduino/Core/CMakeLists.txt.
  # Может быть переопределено профилем.
  mcu_target: "G474"

  # Подключать ли стандартный Arduino main(). false — если пишете свой.
  use_core_main: false

  # Стандартные библиотеки из <core_path>/libraries/.
  libraries:
    - SrcWrapper    # HAL/LL обёртки — почти всегда нужна
    - EEPROM
    - IWatchdog
    - Wire

  # Кастомные библиотеки (пути от корня проекта).
  custom_libraries:
    - "cli"
```

### Что фреймворк делает автоматически

При `toolchain_backend: arduino` фреймворк:

1. Проверяет наличие папки `arduino.core_path` и выдаёт понятную ошибку если
   она не найдена — актуально для CI где Arduino Core подключается симлинком.
2. Создаёт INTERFACE-таргет `Arduino::Definitions` с `compile_definitions` и
   `compile_options` из yml.
3. Пробрасывает `MCU_TARGET` и `ARDUINO_CORE_DIR` в CMake CACHE.
4. Вызывает `add_subdirectory` для `arduino.core_cmake_dir`.
5. Вызывает `add_subdirectory` для каждой библиотеки из `arduino.libraries`.
6. Вызывает `add_subdirectory` для каждой библиотеки из `arduino.custom_libraries`.

### Что остаётся в CMakeLists.txt проекта

Специфическая логика остаётся в `CMakeLists.txt`:

- генерация кода из DSDL/Protobuf/других источников;
- проверка наличия внешних зависимостей (ETL и т.п.);
- `target_link_libraries` основного таргета с Arduino-библиотеками;
- `target_include_directories` специфичные для проекта.

### Использование профилей с Arduino backend

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
  - "$<$<CONFIG:Debug>:-Os -g3>"
  - "$<$<CONFIG:Release>:-O2>"

compile_options_cxx: [ fno-exceptions, fno-rtti, fno-threadsafe-statics ]
build_artifacts: [bin, hex, map]
crc_enable: true

profiles:
  G431:
    mcu: STM32G431CBUx
    linker_script: "resources/STM32G431XX_FLASH.ld"
    compile_definitions:
      - STM32G431xx
      - ARDUINO_GENERIC_G431CBUX
      - "BOARD_NAME=\"GENERIC_G431CBUX\""
      - "VARIANT_H=\"variant_generic.h\""
    compile_definitions_append:
      - BOARD_REV=1

  G474:
    mcu: STM32G474CETx
    linker_script: "resources/STM32G474XX_FLASH.ld"
    compile_definitions:
      - STM32G474xx
      - ARDUINO_GENERIC_G474CEUX
      - "BOARD_NAME=\"GENERIC_G474CEUX\""
      - "VARIANT_H=\"variant_generic.h\""
    compile_definitions_append:
      - BOARD_REV=2
```

### Минимальный CMakeLists.txt при Arduino backend

```cmake
cmake_minimum_required(VERSION 3.19)

set(CMAKE_TOOLCHAIN_FILE
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/gcc-arm-none-eabi.cmake")

list(APPEND CMAKE_MODULE_PATH
    "${CMAKE_CURRENT_SOURCE_DIR}/modules/stm32-cmake-yml")
include(stm32_yml)

stm32_yml_prepare_project_data(PROJECT_NAME PROJECT_LANGUAGES)
project(${PROJECT_NAME} LANGUAGES ${PROJECT_LANGUAGES})
stm32_yml_setup_project(${PROJECT_NAME})

# Специфика проекта.
target_link_libraries(${PROJECT_NAME} PRIVATE
    Arduino::EEPROM Arduino::IWatchdog Arduino::Wire
    Arduino::SrcWrapper Arduino::Core Arduino::Definitions
    Cli
)

target_include_directories(${PROJECT_NAME} PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src/include
    ${CMAKE_CURRENT_SOURCE_DIR}/../modules/etl/include
)
```

---

## 10. Работа с AI-ассистентами

Фреймворк поставляется с набором инструкций для AI-ассистентов (папка `skills/`).
Они объясняют нейросетям архитектуру фреймворка и предотвращают типичные ошибки.

Общаясь с ИИ, явно просите его опираться на нужный навык. В IDE с поддержкой
упоминания файлов используйте символ `@` для указания пути к навыку.

Примеры запросов:

- "Мне нужно включить FreeRTOS. Изучи навык `stm32-config-manager` и скажи, как изменить мой `stm32_config.yml`."
- "Я сгенерировал код в папку Core/. Прочитай навык `stm32-simple-sources` и напиши правильный CMakeLists.txt."
- "Я хочу написать свой драйвер. Изучи `stm32-module-creator` и создай структуру для нового модуля."
- "У меня ошибка `cannot find entry symbol Reset_Handler`. Посмотри `stm32-build-helper` и подскажи решение."
