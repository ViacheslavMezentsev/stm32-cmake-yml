# Артефакты и CRC

[Документация](../../index.md) → [Reference 0.9.2](index.md) → Артефакты и CRC · [English](../../../en/reference/0.9.2/postbuild.md)

Общие правила: [семантика](semantics.md). База: `f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0`. История появления опций до 0.9.2 не установлена; наличие подтверждено в этой базе. Если не указано иное, настройка выполняется на Configure/Generate; фактические команды исполняются при Build/Post-build.


**С 0.10.1:** Python CLI выдаёт CRC/BIN-диагностику
в UTF-8 независимо от кодовой страницы; импорт модуля не меняет потоки.
Тексты и бинарные артефакты не изменены. [E009](../../errata/E009.md),
[регрессия TC-88](../../../../tests/test_crc_encoding.py).

<a id="build-artifacts"></a>
## `build_artifacts`

`CFG-BUILD-ARTIFACTS` · **Тип:** list: bin / hex / srec / map / lss · **Default:** []

bin/hex/lss добавляют post-build преобразования, map — флаг линкера. Пустой список не запрещает основную цель и вывод размера. Неизвестные элементы игнорируются. Toolchain должен предоставить функции bin/hex/size и необходимые утилиты.

**Изменение в 0.9.3** (`b9a6cd3`; ТЗ 3.7.3, 4.14.2): добавлен элемент `srec` (`stm32_generate_srec_file`). Неизвестный элемент вызывает предупреждение со списком известных (`bin`, `hex`, `srec`, `map`, `lss`) и пропускается.

**Изменение в 0.9.3** (`2625f19`; ТЗ 4.14.2): `bin` строится фреймворком из секций ELF с адресом загрузки в регионе FLASH, как образ CRC (п. 4.15.9), а не `objcopy -O binary`: секция вне Flash (резервная SRAM, ITCM без `AT> FLASH`) больше не раздувает BIN до сотен мегабайт. Для обычного ELF файл побайтно совпадает с прежним. Регион FLASH берётся из шаблона или явного скрипта, для скрипта stm32-cmake — из `stm32_get_memory_info`; если его не определить, используется `stm32_generate_binary_file` с предупреждением.

**Изменение в 0.10.0** (ТЗ 4.5.7, 4.14.2, 4.14.4): все артефакты называются `<итоговое имя ELF без расширения>.<расширение>` и лежат в каталоге ELF с учётом `OUTPUT_NAME`, `OUTPUT_NAME_<CONFIG>`, `<CONFIG>_POSTFIX`, `RUNTIME_OUTPUT_DIRECTORY` и конфигурации Ninja Multi-Config, в том числе заданных после вызова фреймворка; прежде `lss` и `map` назывались по имени цели, а `map` создавался в рабочем каталоге компоновщика. `hex` и `srec` фреймворк строит командой `objcopy` сам; резервный `bin` — `objcopy -O binary`; функции `stm32_generate_*` toolchain не используются. Побочные файлы (`BYPRODUCTS`) объявляются по итоговым свойствам цели в конце её каталога; при значении свойства с выражением генератора они не объявляются. Промежуточные файлы CRC сохраняют прежние имена.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
build_artifacts: [bin, hex, map, lss]
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_postbuild.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.artifacts-defaults`, `configure.artifacts-all`, `configure.artifacts-map-only`, `configure.artifacts-empty`, `configure.artifacts-unknown`, `configure.artifacts-reconfigure`, `configure.artifacts-build-default`, `configure.artifacts-output-name`, `configure.artifacts-multi-config`, `configure.artifacts-makefiles`, `configure.empty-and-null-defaults`. [Test manifest](../../../../tests/cases.json).

<a id="crc-enable"></a>
## `crc_enable`

`CFG-CRC-ENABLE` · **Тип:** boolean · **Default:** false

Настраивает удаление CRC-секции из промежуточного BIN, запуск Python и update-section ELF после линковки. Нужны Python3, objcopy, скрипт CRC и подходящий .ld. Отсутствующие prerequisites могут отключить CRC с предупреждением. Успех Configure не доказывает корректность CRC или наличие секции в ELF.

**Изменение в 0.9.3** (`4cd3404`; ТЗ 4.15.1, 4.15.2, 4.15.7, 4.15.9): промежуточный образ строится скриптом из секций ELF с адресом загрузки в регионе `FLASH` итогового скрипта компоновщика, без `objcopy --gap-fill`; секции вне Flash (например, в резервной SRAM) не раздувают образ. Со скриптом, который формирует stm32-cmake, CRC — ошибка Configure; если регион `FLASH` не найден, CRC отключается с предупреждением. Любой сбой расчёта завершает сборку ошибкой `[CRC ERROR]` без нулевой заглушки (E006).

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
crc_enable: false
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_postbuild.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.crc-command-generation`, `configure.defaults-blackpill`, `configure.crc-stm32cmake-script-error`, `configure.crc-explicit-script-without-section`, `configure.crc-flash-region-missing`. [Test manifest](../../../../tests/cases.json).

**Errata:** [E006](../../errata/E006.md).

**С 0.10.1 (post-build):** начало внедрения (`SCY-I713`),
рассчитанное значение (`SCY-I709`) и успешная запись (`SCY-I714`) идут через
каталог RU/EN с префиксом `[STM32 CRC32]` и записываются в JSONL сборки.
Имя секции берётся из итогового `crc_section_name`, включая профиль и override.
`none` у `crc_method` по-прежнему означает `auto` и не отключает CRC.

Вызов `objcopy --update-section` выполняет Python-скрипт после расчёта.
Успех показывается только при нулевом коде `objcopy`; его дополнительный вывод
сохраняется как `SCY-I715`. Ненулевой код — `SCY-E713` с секцией, кодом и выводом
инструмента; ошибка запуска — `SCY-E714` с путём инструмента и секцией. В обоих
случаях post-build завершается ошибкой, последующие команды артефактов не идут.
Уже существующие файлы артефактов не удаляются и могут относиться к прошлой сборке.
Ошибка внедрения не сопровождается ложным сообщением «CRC не рассчитан»;
ошибки собственно расчёта сохраняют прежние коды. `--objcopy` допустим только
в ELF-режиме с файлом результата CRC и одной секцией `--exclude` (`SCY-E715`).
Без `--objcopy` прежние режимы CLI не меняются. Внешний вывод читается как UTF-8;
недекодируемые байты заменяются, чтобы не скрывать код завершения инструмента.

Проверки: [TC-92](../../../../tests/test_crc_injection.py) в Host CI,
проверка последовательности сообщений в Firmware и независимая проверка CRC
готовых образов. Успех записи не является проверкой всей разметки FLASH.

Подробно: [метод, разметка, поле длины и чтение CRC](../../crc-methods.md).

<a id="crc-method"></a>
## `crc_method`

`CFG-CRC-METHOD` · **Тип:** string: auto / none · **Default:** auto

**С 0.10.1:** резервирует выбор полного метода расчёта и
размещения CRC. Alias: `crc.method`. Отсутствие, `null`, пустая строка и `none`
означают `auto`; `none` не отключает CRC. Включение задаёт только `crc_enable`.
Иные значения, включая `false` и `0`, завершают Configure ошибкой `SCY-E712`,
даже при отключённом CRC. Значения регистрозависимы.

`auto` сохраняет существующий расчёт `STM32_HW_DEFAULT` и запись в
`crc_section_name`. Пользователь размещает 4-байтовую секцию по выровненному
на 4 байта адресу в конце образа FLASH, после всех секций с FLASH LMA,
включая загрузочную копию `.data`. Фреймворк не перемещает секции и не добавляет
поле длины. Configure показывает метод, алгоритм и фактическое имя секции,
но не подтверждает правильность её итогового положения в ELF.

Профиль и `STM32_YML_OVERRIDE_crc_method` применяются до нормализации;
повторный Configure пересчитывает значение. Правила одинаковы для backend
stm32-cmake и Arduino. В 0.10.0 и раньше опция не имела определённой семантики.

```yaml
crc:
  enable: true
  method: auto
  section_name: .checksum
```

Реализация: `cmake/stm32_yml_config.cmake`, `cmake/stm32_yml_postbuild.cmake`.
Проверки: `configure.crc-method-*` в [manifest](../../../../tests/cases.json)
покрывают нормализацию, профили, override, отключение и ошибку, RU/EN-сообщения.
Это Configure-проверки; они не проверяют исполняемый образ в симуляторе.

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

**Изменение в 0.10.0** (ТЗ 4.16.11): сообщения скрипта CRC выводятся по кодам 7xx на языке Configure и записываются в `stm32_yml_build_messages.jsonl`; метка `[CRC ERROR]` заменена текстом ошибки и строкой `SCY-E708`. [Коды сообщений](messages.md).

**Изменение в 0.9.3** (`3c6bfa3`; ТЗ 4.15.4): при `auto` объём Flash берётся с учётом ядра: у двухъядерного H745 для `M4` — 1024K.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
flash_size: 64K
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_postbuild.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.crc-command-generation`, `configure.h7-dual-core`, `configure.h5-cmsis-hal-freertos-external`. [Test manifest](../../../../tests/cases.json).

**Errata:** [E006](../../errata/E006.md).
