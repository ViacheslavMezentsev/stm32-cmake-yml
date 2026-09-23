# Исходники и библиотеки

[Документация](../../index.md) → [Reference 0.9.2](index.md) → Исходники и библиотеки · [English](../../../en/reference/0.9.2/sources.md)

Общие правила: [семантика](semantics.md). База: `f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0`. История появления опций до 0.9.2 не установлена; наличие подтверждено в этой базе. Если не указано иное, настройка выполняется на Configure/Generate; фактические команды исполняются при Build/Post-build.

<a id="sources"></a>
## `sources`

`CFG-SOURCES` · **Тип:** list of relative paths · **Default:** []

Файлы добавляются к цели; каталоги подключаются через add_subdirectory и должны иметь CMakeLists.txt. Отсчёт от текущего исходного каталога, обычно корня. ../ разрешён для модулей. Отсутствующий путь предупреждает и пропускается; цель без исходников затем может не пройти Generate. При CMSIS/HAL startup/system файлы перехватываются для замены upstream-файлов.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
sources: [main.c, helper.cpp]
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_sources.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.profile-append`, `configure.profile-replace-and-append`, `configure.reconfigure-profile-lists`, `configure.source-directory-target`, `configure.source-missing-warning`, `configure.source-directory-requires-cmake`, `configure.module-explicit-link`, `configure.module-not-auto-linked`, `configure.module-missing-target`. [Test manifest](../../../../tests/cases.json).

<a id="include-directories"></a>
## `include_directories`

`CFG-INCLUDE-DIRECTORIES` · **Тип:** list of paths · **Default:** []

PRIVATE include-пути цели: относительные разрешает CMake от исходного каталога, абсолютные передаются как есть. При use_hal нужен stm32<family>xx_hal_conf.h непосредственно в одном из этих каталогов; отсутствие — Configure error. Пустой список действительно пуст.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
include_directories: [include]
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/stm32_yml.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.defaults-blackpill`, `configure.baremetal-empty-list`. [Test manifest](../../../../tests/cases.json).

<a id="custom-libraries"></a>
## `custom_libraries`

`CFG-CUSTOM-LIBRARIES` · **Тип:** list of relative file paths · **Default:** []

Существующие файлы библиотек, например .a, ищутся от корня проекта и линкуются PRIVATE. Не найденные предупреждают и пропускаются. Для CMake targets используйте link_libraries.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
custom_libraries: [lib/device.a]
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/stm32_yml.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** нет автоматической проверки этого контракта. [Test manifest](../../../../tests/cases.json).

<a id="link-libraries"></a>
## `link_libraries`

`CFG-LINK-LIBRARIES` · **Тип:** list of targets or library names · **Default:** []

Передаётся target_link_libraries PRIVATE без проверки существования файлов. Именованные targets (например Arduino::Core) должен создать проект или dependency. Неизвестная цель с :: обычно приводит к ошибке Generate; обычное имя может дать ошибку только при линковке.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
link_libraries: [Arduino::Core, Arduino::Probe]
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/stm32_yml.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.arduino-defaults`, `configure.module-explicit-link`, `configure.module-not-auto-linked`, `configure.module-missing-target`. [Test manifest](../../../../tests/cases.json).
