# Компоновка и память

[Документация](../../index.md) → [Reference 0.9.2](index.md) → Компоновка и память · [English](../../../en/reference/0.9.2/linker.md)

Общие правила: [семантика](semantics.md). База: `f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0`. История появления опций до 0.9.2 не установлена; наличие подтверждено в этой базе. Если не указано иное, настройка выполняется на Configure/Generate; фактические команды исполняются при Build/Post-build.

<a id="heap-size"></a>
## `heap_size`

`CFG-HEAP-SIZE` · **Тип:** integer bytes / string with K or M · **Default:** IOC / 512 manually

Размер для подстановки в локальный .ld.in. Поддерживаются 0, целые байты, целые K/M в верхнем регистре. В IOC-ветке берётся HEX-поле; неполный IOC требует явного значения. Готовый .ld не переписывается; стандартный linker stm32-cmake не получает эти значения через эту ветку. Дробные размеры не поддерживаются по контракту (E003). При повторном Configure исходная 0.9.2 сохраняет прежнее значение кэша.

**Изменение в 0.9.3** (`d8708b4`; ТЗ 4.11.4, 4.11.8, 4.11.9): формат проверяется при каждом Configure, а не только при генерации из шаблона: допустимы целое число байт или целое число с `K`/`M` в верхнем регистре (`0`, `1536`, `2K`, `1M`); `1k`, `1.5K`, `-1`, `0x200` — ошибка. Размер, заданный в YAML, профиле, override или IOC, при скрипте stm32-cmake или явном `linker_script` вызывает предупреждение, что он не применяется (для stm32-cmake — с его размерами heap/stack); значения по умолчанию предупреждения не вызывают.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
heap_size: 1K
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_linker.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.linker-template`, `configure.baremetal-no-cube`, `configure.empty-and-null-defaults`, `configure.reconfigure-memory`, `configure.memory-size-format`, `configure.memory-size-unused-warning`, `configure.ioc-missing-values-defaults`. [Test manifest](../../../../tests/cases.json).

**Errata:** [E001](../../errata/E001.md), [E003](../../errata/E003.md).

<a id="stack-size"></a>
## `stack_size`

`CFG-STACK-SIZE` · **Тип:** integer bytes / string with K or M · **Default:** IOC / 1024 manually

Размер для подстановки в локальный .ld.in. Поддерживаются 0, целые байты, целые K/M в верхнем регистре. В IOC-ветке берётся HEX-поле; неполный IOC требует явного значения. Готовый .ld не переписывается; стандартный linker stm32-cmake не получает эти значения через эту ветку. Дробные размеры не поддерживаются по контракту (E003). При повторном Configure исходная 0.9.2 сохраняет прежнее значение кэша.

**Изменение в 0.9.3** (`d8708b4`; ТЗ 4.11.4, 4.11.8, 4.11.9): формат проверяется при каждом Configure, а не только при генерации из шаблона: допустимы целое число байт или целое число с `K`/`M` в верхнем регистре (`0`, `1536`, `2K`, `1M`); `1k`, `1.5K`, `-1`, `0x200` — ошибка. Размер, заданный в YAML, профиле, override или IOC, при скрипте stm32-cmake или явном `linker_script` вызывает предупреждение, что он не применяется (для stm32-cmake — с его размерами heap/stack); значения по умолчанию предупреждения не вызывают.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
stack_size: 1K
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_linker.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.linker-template`, `configure.baremetal-no-cube`, `configure.empty-and-null-defaults`, `configure.reconfigure-memory`, `configure.reconfigure-profile-name-boundaries`, `configure.reconfigure-empty-override`, `configure.memory-size-format`, `configure.memory-size-unused-warning`, `configure.ioc-missing-values-defaults`. [Test manifest](../../../../tests/cases.json).

**Errata:** [E001](../../errata/E001.md), [E003](../../errata/E003.md).

<a id="linker-script"></a>
## `linker_script`

`CFG-LINKER-SCRIPT` · **Тип:** string: auto / relative .ld path · **Default:** auto

auto ищет локальный .ld.in: конкретный тип MCU, замена корпуса на X, затем XX и xx. Сначала linker_script_dir, затем корень. Найденный шаблон создаёт .ld в build с HEAP_SIZE, STACK_SIZE и USE_READONLY (GCC >=11). Без шаблона stm32-cmake использует CMSIS target при use_cmsis; Arduino завершает настройку ошибкой. При bare metal задайте собственный скрипт/шаблон. Явный отсутствующий .ld — ошибка.

**Изменение в 0.9.3** (`d8708b4`; ТЗ 4.11.9): с явным скриптом или скриптом stm32-cmake явно заданные `heap_size`/`stack_size` вызывают предупреждение, что они не применяются.

**Изменение в 0.9.3** (`2625f19`; ТЗ 4.11.10): если startup (из пакета STM32Cube или из `sources`) задаёт границу стека командой `msr MSPLIM` по символу `_sstack`, как в CubeH5 1.7.0, а итоговый скрипт этот символ не определяет (скрипт stm32-cmake, старые шаблоны), Configure предупреждает заранее и подсказывает строку `_sstack = _estack - _Min_Stack_Size;`. Без неё компоновка завершается ошибкой `undefined reference to _sstack`.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
linker_script: auto
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_linker.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.linker-template`, `configure.explicit-linker`, `configure.missing-linker`, `configure.memory-size-unused-warning`, `configure.h5-cmsis-hal-freertos-external`. [Test manifest](../../../../tests/cases.json).

<a id="linker-script-dir"></a>
## `linker_script_dir`

`CFG-LINKER-SCRIPT-DIR` · **Тип:** string: relative directory · **Default:** project root only

Дополнительная первая папка поиска скрипта/шаблона относительно корня. Корень остаётся fallback. Не меняет базу путей sources или include_directories.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
linker_script_dir: linker
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_linker.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.linker-template`, `configure.explicit-linker`. [Test manifest](../../../../tests/cases.json).

<a id="link-options"></a>
## `link_options`

`CFG-LINK-OPTIONS` · **Тип:** list of flag strings · **Default:** []

PRIVATE опции драйвера компоновки, нормализуются как compile_options. Для прямых аргументов линкера удобнее linker_directives.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
link_options: [nostartfiles]
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/stm32_yml.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.system-link-options`. [Test manifest](../../../../tests/cases.json).

<a id="linker-directives"></a>
## `linker_directives`

`CFG-LINKER-DIRECTIVES` · **Тип:** list of linker arguments · **Default:** []

Каждый элемент передаётся как LINKER:<элемент>. Отдельная нормализация дефисов не выполняется; задавайте полные директивы.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
linker_directives: [--print-memory-usage]
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/stm32_yml.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.system-link-options`. [Test manifest](../../../../tests/cases.json).

<a id="use-newlib-nano"></a>
## `use_newlib_nano`

`CFG-USE-NEWLIB-NANO` · **Тип:** boolean · **Default:** false

Подключает STM32::Nano; этот target должен предоставить toolchain, в том числе при Arduino. Не включает float printf автоматически.

**Примечание 0.9.3** (ТЗ 4.10.4): вывод и ввод чисел с плавающей точкой в `printf`/`scanf` newlib-nano подключается целями stm32-cmake через `link_libraries: [STM32::Nano::FloatPrint]` и `STM32::Nano::FloatScan`; отдельного ключа YAML нет.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
use_newlib_nano: false
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_frameworks.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.system-nosys-nano`, `configure.system-semihost-nano`, `configure.system-disabled`, `configure.system-reconfigure`. [Test manifest](../../../../tests/cases.json).

<a id="system-library"></a>
## `system_library`

`CFG-SYSTEM-LIBRARY` · **Тип:** string: NoSys / Semihosting · **Default:** none

Подключает одноимённый STM32 target. Неизвестное/пустое значение ничего не добавляет. NoSys должен предоставить toolchain; Semihosting имеет fallback. Для выполнения semihosting нужна поддержка отладчика/симулятора (в примере QEMU используется -semihosting).

**Изменение в 0.9.3** (`b9a6cd3`; ТЗ 3.7.3): неизвестное непустое значение (например, `nosys`) вызывает предупреждение со списком известных (`NoSys`, `Semihosting`); библиотека не подключается. Пустое значение — без предупреждения.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
system_library: NoSys
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_frameworks.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.defaults-blackpill`, `configure.system-nosys-nano`, `configure.system-semihost-nano`, `configure.system-disabled`, `configure.system-reconfigure`, `configure.enum-unknown-values`, `configure.empty-and-null-defaults`. [Test manifest](../../../../tests/cases.json).
