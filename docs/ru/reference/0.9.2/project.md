# Проект и версия

[Документация](../../index.md) → [Reference 0.9.2](index.md) → Проект и версия · [English](../../../en/reference/0.9.2/project.md)

Общие правила: [семантика](semantics.md). База: `f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0`. История появления опций до 0.9.2 не установлена; наличие подтверждено в этой базе. Если не указано иное, настройка выполняется на Configure/Generate; фактические команды исполняются при Build/Post-build.

<a id="stm32-cmake-yml-version"></a>
## `stm32_cmake_yml_version`

`CFG-STM32-CMAKE-YML-VERSION` · **Тип:** string · **Default:** —

Версия, под которую написан YAML. Рекомендуется задавать явно; не выбирает версию кода. При отсутствии или несовпадении проверка выдаёт предупреждение, а не запрет настройки.

**Порядок обработки:** сравнение версии выполняется сразу после чтения YAML, **до** профиля и `STM32_YML_OVERRIDE_*`. Поэтому изменение этих двух опций через профиль/override не меняет уже выданную диагностику. Задавайте их в корне YAML. Отсутствующая или пустая версия вызывает предупреждение при включённой проверке; настройка продолжается. Отсутствующий или пустой переключатель получает default `true` (пустой переключатель отдельно не проверен).

```yaml
stm32_cmake_yml_version: 0.9.2
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_config.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.version-equal`, `configure.version-missing`, `configure.version-empty`, `configure.version-older`, `configure.version-newer`, `configure.version-disabled`, `configure.version-before-profile`, `configure.version-before-override`. [Test manifest](../../../../tests/cases.json).

<a id="stm32-cmake-yml-version-check"></a>
## `stm32_cmake_yml_version_check`

`CFG-STM32-CMAKE-YML-VERSION-CHECK` · **Тип:** boolean · **Default:** true

Включает предупреждения о версии конфига. false отключает сравнение; баннер версии фреймворка остаётся.

**Порядок обработки:** сравнение версии выполняется сразу после чтения YAML, **до** профиля и `STM32_YML_OVERRIDE_*`. Поэтому изменение этих двух опций через профиль/override не меняет уже выданную диагностику. Задавайте их в корне YAML. Отсутствующая или пустая версия вызывает предупреждение при включённой проверке; настройка продолжается. Отсутствующий или пустой переключатель получает default `true` (пустой переключатель отдельно не проверен).

```yaml
stm32_cmake_yml_version_check: true
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_config.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.version-equal`, `configure.version-missing`, `configure.version-empty`, `configure.version-older`, `configure.version-newer`, `configure.version-disabled`, `configure.version-before-profile`, `configure.version-before-override`. [Test manifest](../../../../tests/cases.json).

<a id="toolchain-backend"></a>
## `toolchain_backend`

`CFG-TOOLCHAIN-BACKEND` · **Тип:** string: stm32-cmake / arduino · **Default:** stm32-cmake

Выбирает настройку CMSIS/HAL/FreeRTOS либо Arduino-обёрток. Toolchain задаёт потребитель до project(). В 0.9.2 неизвестная непустая строка не отвергается и попадает в ветку stm32-cmake; это не дополнительный backend.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
toolchain_backend: stm32-cmake
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_config.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.arduino-defaults`, `configure.baremetal-no-cube`. [Test manifest](../../../../tests/cases.json).

<a id="ioc-file"></a>
## `ioc_file`

`CFG-IOC-FILE` · **Тип:** string: relative path · **Default:** —

Путь от корня проекта. IOC даёт MCU, имя, heap/stack, Cube FW и сведения о FreeRTOS только при отсутствии соответствующих значений YAML/профиля/override. Отсутствующий файл — ошибка. Arduino игнорирует IOC. Тактирование и исходники из IOC не генерируются.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
ioc_file: bluepill-hsi.ioc
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_config.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.ioc-bluepill-defaults`, `configure.yaml-over-ioc`, `configure.missing-ioc`. [Test manifest](../../../../tests/cases.json).

<a id="project-name"></a>
## `project_name`

`CFG-PROJECT-NAME` · **Тип:** string · **Default:** auto (manual); IOC (ioc_file)

Имя для project() и цели в типичном потребителе. auto означает имя корневой папки. В IOC-ветке отсутствие имени в самом IOC не получает общего fallback auto; задавайте имя явно для неполных IOC.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
project_name: bluepill
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_config.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.ioc-bluepill-defaults`, `configure.yaml-over-ioc`. [Test manifest](../../../../tests/cases.json).

<a id="mcu"></a>
## `mcu`

`CFG-MCU` · **Тип:** string: STM32 part name · **Default:** IOC / required manually

Например STM32F103C8T6. IOC DeviceId теряет только завершающий x. В stm32-cmake backend имя должно поддерживаться его базой MCU. В Arduino передаётся явно для auto-поиска linker template; макросы чипа задаёт пользователь. Производный MCU в исходной 0.9.2 залипает в кэше.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
mcu: STM32F103C8T6
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_config.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.yaml-over-ioc`, `configure.bluepill`, `configure.reconfigure-mcu`. [Test manifest](../../../../tests/cases.json).

**Errata:** [E001](../../errata/E001.md).

<a id="mcu-core"></a>
## `mcu_core`

`CFG-MCU-CORE` · **Тип:** string: upstream core identifier · **Default:** empty

Уточнение ядра для компонентов CMSIS/HAL/FreeRTOS и linker target, например M7 или M4 для поддерживаемого многоядерного MCU. Не требуется для каждого STM32; точные имена определяет stm32-cmake. Arduino эту ветку не использует.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
mcu_core: M4
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_config.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** нет автоматической проверки этого контракта. [Test manifest](../../../../tests/cases.json).

<a id="languages"></a>
## `languages`

`CFG-LANGUAGES` · **Тип:** list of CMake languages · **Default:** [C, CXX, ASM]

Передаётся потребителем в project(). Пустое значение или [] выбирает общий default. Для CMSIS startup-целей stm32-cmake нужен ASM. Список языков должен соответствовать исходникам.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
languages: [C, CXX, ASM]
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_config.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.defaults-blackpill`, `configure.ioc-bluepill-defaults`. [Test manifest](../../../../tests/cases.json).
