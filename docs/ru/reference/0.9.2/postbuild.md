# Артефакты и CRC

[Документация](../../index.md) → [Reference 0.9.2](index.md) → Артефакты и CRC · [English](../../../en/reference/0.9.2/postbuild.md)

Общие правила: [семантика](semantics.md). База: `f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0`. История появления опций до 0.9.2 не установлена; наличие подтверждено в этой базе. Если не указано иное, настройка выполняется на Configure/Generate; фактические команды исполняются при Build/Post-build.

<a id="build-artifacts"></a>
## `build_artifacts`

`CFG-BUILD-ARTIFACTS` · **Тип:** list: bin / hex / map / lss · **Default:** []

bin/hex/lss добавляют post-build преобразования, map — флаг линкера. Пустой список не запрещает основную цель и вывод размера. Неизвестные элементы игнорируются. Toolchain должен предоставить функции bin/hex/size и необходимые утилиты.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
build_artifacts: [bin, hex, map, lss]
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_postbuild.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.artifacts-defaults`, `configure.artifacts-all`, `configure.artifacts-map-only`, `configure.artifacts-empty`, `configure.artifacts-unknown`, `configure.artifacts-reconfigure`. [Test manifest](../../../../tests/cases.json).

<a id="crc-enable"></a>
## `crc_enable`

`CFG-CRC-ENABLE` · **Тип:** boolean · **Default:** false

Настраивает удаление CRC-секции из промежуточного BIN, запуск Python и update-section ELF после линковки. Нужны Python3, objcopy, скрипт CRC и подходящий .ld. Отсутствующие prerequisites могут отключить CRC с предупреждением. Успех Configure не доказывает корректность CRC или наличие секции в ELF.

**Изменение в 0.9.3** (ветка выпуска, `4cd3404`; ТЗ 4.15.1, 4.15.2, 4.15.7, 4.15.9): промежуточный образ строится скриптом из секций ELF с адресом загрузки в регионе `FLASH` итогового скрипта компоновщика, без `objcopy --gap-fill`; секции вне Flash (например, в резервной SRAM) не раздувают образ. Со скриптом, который формирует stm32-cmake, CRC — ошибка Configure; если регион `FLASH` не найден, CRC отключается с предупреждением. Любой сбой расчёта завершает сборку ошибкой `[CRC ERROR]` без нулевой заглушки (E006).

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
crc_enable: false
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_postbuild.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.crc-command-generation`, `configure.defaults-blackpill`, `configure.crc-stm32cmake-script-error`, `configure.crc-explicit-script-without-section`, `configure.crc-flash-region-missing`. [Test manifest](../../../../tests/cases.json).

**Errata:** [E006](../../errata/E006.md).

<a id="crc-section-name"></a>
## `crc_section_name`

`CFG-CRC-SECTION-NAME` · **Тип:** string: section name · **Default:** .checksum when CRC enabled

Имя секции для удаления из BIN и обновления ELF. Секция должна реально существовать и вмещать четыре байта; фреймворк не создаёт её и не проверяет размещение. Следует исключить её из области расчёта.

**Изменение в 0.9.3** (`4cd3404`; ТЗ 4.15.2): при Configure имя секции ищется в тексте итогового скрипта компоновщика; если его нет — предупреждение, а шаг CRC после сборки завершится ошибкой.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
crc_section_name: .checksum
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_postbuild.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.crc-command-generation`, `configure.crc-explicit-script-without-section`. [Test manifest](../../../../tests/cases.json).

<a id="crc-algorithm"></a>
## `crc_algorithm`

`CFG-CRC-ALGORITHM` · **Тип:** string: STM32_HW_DEFAULT · **Default:** STM32_HW_DEFAULT when CRC enabled

В 0.9.2 только выводится в лог. Не передаётся в Python и не переключает алгоритм; иное имя не реализует иной CRC. Скрипт фиксирован: poly 0x04C11DB7, init 0xFFFFFFFF, слова little-endian, неполное слово дополнено FF, без final XOR.

**Изменение в 0.9.3** (`4cd3404`; ТЗ 4.15.6): иное значение вызывает предупреждение с фактически применяемым `STM32_HW_DEFAULT` (E004).

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
crc_algorithm: STM32_HW_DEFAULT
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_postbuild.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.crc-unknown-algorithm`. [Test manifest](../../../../tests/cases.json).

**Errata:** [E004](../../errata/E004.md).

<a id="flash-size"></a>
## `flash_size`

`CFG-FLASH-SIZE` · **Тип:** integer bytes / string K or M / auto · **Default:** auto

При CRC задаёт максимум размера промежуточного BIN. auto берёт Flash из базы MCU либо из строки FLASH...LENGTH в .ld для Arduino. Это защитный предел, не изменение MEMORY и не длина padding. Суффиксы приводятся к верхнему регистру; используйте целые неотрицательные размеры.

**Изменение в 0.9.3** (`4cd3404`; ТЗ 4.15.7, 4.15.9): образ больше `flash_size` завершает сборку ошибкой `[CRC ERROR]` вместо нулевой заглушки (E006).

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
flash_size: 64K
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_postbuild.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.crc-command-generation`. [Test manifest](../../../../tests/cases.json).

**Errata:** [E006](../../errata/E006.md).
