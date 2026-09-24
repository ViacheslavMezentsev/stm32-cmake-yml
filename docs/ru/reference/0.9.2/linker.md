# Компоновка и память

[Документация](../../index.md) → [Reference 0.9.2](index.md) → Компоновка и память · [English](../../../en/reference/0.9.2/linker.md)

Общие правила: [семантика](semantics.md). База: `f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0`. История появления опций до 0.9.2 не установлена; наличие подтверждено в этой базе. Если не указано иное, настройка выполняется на Configure/Generate; фактические команды исполняются при Build/Post-build.

<a id="heap-size"></a>
## `heap_size`

`CFG-HEAP-SIZE` · **Тип:** integer bytes / string with K or M · **Default:** IOC / 512 manually

Размер для подстановки в локальный .ld.in. Поддерживаются 0, целые байты, целые K/M в верхнем регистре. В IOC-ветке берётся HEX-поле; неполный IOC требует явного значения. Готовый .ld не переписывается; стандартный linker stm32-cmake не получает эти значения через эту ветку. Дробные размеры не поддерживаются по контракту (E003). При повторном Configure исходная 0.9.2 сохраняет прежнее значение кэша.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
heap_size: 1K
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_linker.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.linker-template`, `configure.baremetal-no-cube`, `configure.empty-and-null-defaults`, `configure.reconfigure-memory`. [Test manifest](../../../../tests/cases.json).

**Errata:** [E001](../../errata/E001.md), [E003](../../errata/E003.md).

<a id="stack-size"></a>
## `stack_size`

`CFG-STACK-SIZE` · **Тип:** integer bytes / string with K or M · **Default:** IOC / 1024 manually

Размер для подстановки в локальный .ld.in. Поддерживаются 0, целые байты, целые K/M в верхнем регистре. В IOC-ветке берётся HEX-поле; неполный IOC требует явного значения. Готовый .ld не переписывается; стандартный linker stm32-cmake не получает эти значения через эту ветку. Дробные размеры не поддерживаются по контракту (E003). При повторном Configure исходная 0.9.2 сохраняет прежнее значение кэша.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
stack_size: 1K
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_linker.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.linker-template`, `configure.baremetal-no-cube`, `configure.empty-and-null-defaults`, `configure.reconfigure-memory`, `configure.reconfigure-profile-name-boundaries`, `configure.reconfigure-empty-override`. [Test manifest](../../../../tests/cases.json).

**Errata:** [E001](../../errata/E001.md), [E003](../../errata/E003.md).

<a id="linker-script"></a>
## `linker_script`

`CFG-LINKER-SCRIPT` · **Тип:** string: auto / relative .ld path · **Default:** auto

auto ищет локальный .ld.in: конкретный тип MCU, замена корпуса на X, затем XX и xx. Сначала linker_script_dir, затем корень. Найденный шаблон создаёт .ld в build с HEAP_SIZE, STACK_SIZE и USE_READONLY (GCC >=11). Без шаблона stm32-cmake использует CMSIS target при use_cmsis; Arduino завершает настройку ошибкой. При bare metal задайте собственный скрипт/шаблон. Явный отсутствующий .ld — ошибка.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
linker_script: auto
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_linker.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.linker-template`, `configure.explicit-linker`, `configure.missing-linker`. [Test manifest](../../../../tests/cases.json).

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

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
system_library: NoSys
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_frameworks.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.defaults-blackpill`, `configure.system-nosys-nano`, `configure.system-semihost-nano`, `configure.system-disabled`, `configure.system-reconfigure`. [Test manifest](../../../../tests/cases.json).
