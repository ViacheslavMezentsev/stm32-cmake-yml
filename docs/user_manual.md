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

## 8. 🤖 Работа с AI-ассистентами (Agent Skills)

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
