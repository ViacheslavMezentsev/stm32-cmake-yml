# Компиляция

[Документация](../../index.md) → [Reference 0.9.2](index.md) → Компиляция · [English](../../../en/reference/0.9.2/compiler.md)

Общие правила: [семантика](semantics.md). База: `f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0`. История появления опций до 0.9.2 не установлена; наличие подтверждено в этой базе. Если не указано иное, настройка выполняется на Configure/Generate; фактические команды исполняются при Build/Post-build.

<a id="c-standard"></a>
## `c_standard`

`CFG-C-STANDARD` · **Тип:** integer: CMake C_STANDARD · **Default:** not set by framework

Стандарт C. Значение передаётся CMake, например 11 или 17; поддержку определяют версия CMake и компилятор. Фреймворк не задаёт STANDARD_REQUIRED или EXTENSIONS и не обещает стандарт 17 по умолчанию.

C17 (`c_standard: 17`) требует CMake 3.21 или новее. Для базовой версии CMake 3.19 используйте C11. [CMake C_STANDARD](https://cmake.org/cmake/help/latest/prop_tgt/C_STANDARD.html).

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
c_standard: 17
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_config.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.defaults-blackpill`, `configure.module-explicit-link`. [Test manifest](../../../../tests/cases.json).

<a id="cpp-standard"></a>
## `cpp_standard`

`CFG-CPP-STANDARD` · **Тип:** integer: CMake CXX_STANDARD · **Default:** not set by framework

Стандарт C++. Значение передаётся CMake, например 11 или 17; поддержку определяют версия CMake и компилятор. Фреймворк не задаёт STANDARD_REQUIRED или EXTENSIONS и не обещает стандарт 17 по умолчанию.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
cpp_standard: 17
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_config.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.defaults-blackpill`, `configure.module-explicit-link`. [Test manifest](../../../../tests/cases.json).

<a id="compile-options"></a>
## `compile_options`

`CFG-COMPILE-OPTIONS` · **Тип:** list of flag strings · **Default:** []

PRIVATE флаги для всех языков. Элементы разбиваются по пробелам, дефис добавляется при необходимости; известные опции с отдельным аргументом сохраняют следующий токен. Это не shell-парсер: кавычки YAML не защищают пробел внутри значения от нормализации.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
compile_options: [Wall]
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/stm32_yml.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.defaults-blackpill`, `configure.source-directory-target`, `configure.module-explicit-link`. [Test manifest](../../../../tests/cases.json).

<a id="compile-definitions"></a>
## `compile_definitions`

`CFG-COMPILE-DEFINITIONS` · **Тип:** list of definition strings · **Default:** []

PRIVATE определения для всех языков. Указывайте NAME или NAME=value без -D; CMake добавляет -D. Строки разбиваются по пробелам. Пустой список убирает пользовательские определения, но не автоматический define MCU.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
compile_definitions: [FEATURE=1]
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/stm32_yml.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.defaults-blackpill`, `configure.baremetal-empty-list`, `configure.source-directory-target`, `configure.module-explicit-link`. [Test manifest](../../../../tests/cases.json).

<a id="compile-options-c"></a>
## `compile_options_c`

`CFG-COMPILE-OPTIONS-C` · **Тип:** list of flag strings · **Default:** []

PRIVATE флаги для только C. Элементы разбиваются по пробелам, дефис добавляется при необходимости; известные опции с отдельным аргументом сохраняют следующий токен. Это не shell-парсер: кавычки YAML не защищают пробел внутри значения от нормализации.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
compile_options_c: [Wstrict-prototypes]
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/stm32_yml.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.defaults-blackpill`, `configure.source-directory-target`. [Test manifest](../../../../tests/cases.json).

<a id="compile-definitions-c"></a>
## `compile_definitions_c`

`CFG-COMPILE-DEFINITIONS-C` · **Тип:** list of definition strings · **Default:** []

PRIVATE определения для только C. Указывайте NAME или NAME=value без -D; CMake добавляет -D. Строки разбиваются по пробелам. Пустой список убирает пользовательские определения, но не автоматический define MCU.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
compile_definitions_c: [FEATURE=1]
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/stm32_yml.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.defaults-blackpill`, `configure.source-directory-target`. [Test manifest](../../../../tests/cases.json).

<a id="compile-options-cxx"></a>
## `compile_options_cxx`

`CFG-COMPILE-OPTIONS-CXX` · **Тип:** list of flag strings · **Default:** []

PRIVATE флаги для только C++. Элементы разбиваются по пробелам, дефис добавляется при необходимости; известные опции с отдельным аргументом сохраняют следующий токен. Это не shell-парсер: кавычки YAML не защищают пробел внутри значения от нормализации.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
compile_options_cxx: [fno-exceptions]
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/stm32_yml.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.defaults-blackpill`, `configure.source-directory-target`. [Test manifest](../../../../tests/cases.json).

<a id="compile-definitions-cxx"></a>
## `compile_definitions_cxx`

`CFG-COMPILE-DEFINITIONS-CXX` · **Тип:** list of definition strings · **Default:** []

PRIVATE определения для только C++. Указывайте NAME или NAME=value без -D; CMake добавляет -D. Строки разбиваются по пробелам. Пустой список убирает пользовательские определения, но не автоматический define MCU.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
compile_definitions_cxx: [FEATURE=1]
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/stm32_yml.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.defaults-blackpill`, `configure.source-directory-target`. [Test manifest](../../../../tests/cases.json).
