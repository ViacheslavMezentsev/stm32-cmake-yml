# Проект и версия

[Документация](../../index.md) → [Reference 0.9.2](index.md) → Проект и версия · [English](../../../en/reference/0.9.2/project.md)

Общие правила: [семантика](semantics.md). База: `f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0`. История появления опций до 0.9.2 не установлена; наличие подтверждено в этой базе. Если не указано иное, настройка выполняется на Configure/Generate; фактические команды исполняются при Build/Post-build.

<a id="stm32-cmake-yml-version"></a>
## `stm32_cmake_yml_version`

`CFG-STM32-CMAKE-YML-VERSION` · **Тип:** string · **Default:** —

Версия, под которую написан YAML. Рекомендуется задавать явно; не выбирает версию кода. При отсутствии или несовпадении проверка выдаёт предупреждение, а не запрет настройки.

**Изменение в 0.9.3** (`d8708b4`; ТЗ 4.2.3): параметр рекомендуемый: при отсутствии или пустом значении предупреждение называет его рекомендуемым, а не обязательным. Из предупреждения о более старой версии конфигурации убрана справка «Что нового в 0.9».

**Изменение в 0.9.3** (`d40f23d`): строки баннера `Framework :` и `Config :` заменены на «stm32-cmake-yml версия: …» и «Версия в конфигурации: …».

**Изменение в 0.10.0** (ТЗ 4.16.5–4.16.7): строки версий и предупреждения выводятся по кодам `SCY-I001`…`SCY-I005`, `SCY-W002`…`SCY-W004` на языке [`STM32_YML_LANG`](semantics.md#кэш-и-внешние-управляющие-параметры); на английском баннер — «stm32-cmake-yml version: …».

**Изменение в 0.10.0** (ТЗ 4.2.6, 4.2.7): после строк версии выводятся «Версии компонентов»: CMake, yq, stm32-cmake (тег `git describe`, без тегов — версия из `CHANGELOG.md` с пометкой `+` и коммитом) или Arduino Core STM32 (`version=` из `platform.txt` и коммит), после `project()` — компилятор. Если версию определить нельзя, выводится «версия не определена» без предупреждения.

**К 0.10.1** (ТЗ 4.2.2, 4.2.8; TC-94): баннер имеет вид
`stm32-cmake-yml: 0.10.0 (commit: 02b335e)`; значения здесь примерные.
Версия YAML и результат сравнения выводятся отдельно, без галочки. SHA берётся
из собственного checkout/submodule/worktree каждого подключённого модуля.
Копия без `.git` не получает SHA родительского проекта. Без Git/HEAD или при
ошибке доступа суффикс опускается, Configure продолжается. При staged/unstaged
или новых неигнорируемых файлах: `(commit: 02b335e, modified)`; игнорируемые файлы
и изменения других рабочих деревьев не учитываются. Если status прочитать
нельзя, отсутствие modified не доказывает чистоту. Git вызывается с ограничением
5 с на процесс; global safe.directory не меняется.
Для stm32-cmake сохраняется версия из git describe или приблизительная версия
CHANGELOG с `+`, а SHA выводится отдельно: `stm32-cmake: v2.1.0+ (commit: ecc5acc)`.
Если версия неизвестна, доступный SHA сохраняется после текста об этом.
Версия и Git-суффикс — два аргумента JSONL I001; I044 — имя и суффикс.
Сравнение с YAML использует только версию пакета; формат Arduino не меняется.
Регрессии: `tests/test_component_versions.py`, существующие version/messages Configure.

Уточнение ТЗ 2.21: собственный корень определяется через пустой Git
`rev-parse --show-prefix`, после проверки наличия `.git`. Строки абсолютных
путей не сравниваются: Windows 8.3 и длинное имя могут обозначать один каталог.
TC-94 проверяет оба написания, если файловая система предоставляет короткое имя.


**Порядок обработки:** сравнение версии выполняется сразу после чтения YAML, **до** профиля и `STM32_YML_OVERRIDE_*`. Поэтому изменение этих двух опций через профиль/override не меняет уже выданную диагностику. Задавайте их в корне YAML. Отсутствующая или пустая версия вызывает предупреждение при включённой проверке; настройка продолжается. Отсутствующий или пустой переключатель получает default `true` (пустой переключатель отдельно не проверен).

```yaml
stm32_cmake_yml_version: 0.10.1
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

**Изменение в 0.9.3** (`b9a6cd3`; ТЗ 3.7.3, 4.1.6): неизвестное непустое значение вызывает предупреждение со списком известных (`stm32-cmake`, `arduino`), применяется `stm32-cmake`. Пустое значение по-прежнему означает `stm32-cmake` без предупреждения.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
toolchain_backend: stm32-cmake
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_config.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.arduino-defaults`, `configure.baremetal-no-cube`, `configure.enum-unknown-values`, `configure.empty-and-null-defaults`. [Test manifest](../../../../tests/cases.json).

<a id="ioc-file"></a>
## `ioc_file`

`CFG-IOC-FILE` · **Тип:** string: relative path · **Default:** —

Путь от корня проекта. IOC даёт MCU, имя, heap/stack, Cube FW и сведения о FreeRTOS только при отсутствии соответствующих значений YAML/профиля/override. Отсутствующий файл — ошибка. Arduino игнорирует IOC. Тактирование и исходники из IOC не генерируются.

**Изменение в 0.9.3** (`d8708b4`; ТЗ 3.6.5, 4.4.6): IOC-файл регистрируется как зависимость Configure: его изменение перезапускает Configure при следующей сборке. Если IOC не содержит имени проекта, `HeapSize` или `StackSize`, а YAML, профиль и override их не задают, применяются значения ручного режима `auto`, 512 и 1024.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
ioc_file: bluepill-hsi.ioc
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_config.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.ioc-bluepill-defaults`, `configure.yaml-over-ioc`, `configure.missing-ioc`, `configure.freertos-ioc-f4-v2`, `configure.freertos-ioc-f1-v1`, `configure.freertos-ioc-profile-precedence`, `configure.freertos-ioc-yaml-precedence`, `configure.freertos-ioc-empty-fallback`, `configure.freertos-ioc-override-disable`, `configure.freertos-ioc-reconfigure`, `configure.stm32f0-ioc-freertos`, `configure.stm32f3-ioc-freertos`, `configure.stm32f7-ioc-freertos`, `configure.stm32g4-ioc-freertos`, `configure.ioc-missing-values-defaults`, `configure.configure-depends`. [Test manifest](../../../../tests/cases.json).

<a id="project-name"></a>
## `project_name`

`CFG-PROJECT-NAME` · **Тип:** string · **Default:** auto (manual); IOC (ioc_file)

Имя для project() и цели в типичном потребителе. auto означает имя корневой папки. В IOC-ветке отсутствие имени в самом IOC не получает общего fallback auto; задавайте имя явно для неполных IOC.

**Изменение в 0.9.3** (`d8708b4`; ТЗ 4.4.6): при IOC без имени проекта применяется `auto` (имя каталога проекта), а не пустое значение.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
project_name: bluepill
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_config.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.ioc-bluepill-defaults`, `configure.yaml-over-ioc`, `configure.ioc-missing-values-defaults`. [Test manifest](../../../../tests/cases.json).

<a id="mcu"></a>
## `mcu`

`CFG-MCU` · **Тип:** string: STM32 part name · **Default:** IOC / required manually

Например STM32F103C8T6. IOC DeviceId теряет только завершающий x. В stm32-cmake backend имя должно поддерживаться его базой MCU. В Arduino передаётся явно для auto-поиска linker template; макросы чипа задаёт пользователь. Производный MCU в исходной 0.9.2 залипает в кэше.

**Изменение в 0.9.3** (`858013a`): `MCU` обновляется при смене профиля (E001); для явного переопределения используйте `STM32_YML_OVERRIDE_mcu`.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
mcu: STM32F103C8T6
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_config.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.yaml-over-ioc`, `configure.bluepill`, `configure.reconfigure-mcu`, `configure.stm32f0-cmsis-hal`, `configure.stm32f3-cmsis-hal`, `configure.stm32f7-cmsis-hal`, `configure.stm32g4-cmsis-hal`. [Test manifest](../../../../tests/cases.json).

**Errata:** [E001](../../errata/E001.md).

<a id="mcu-core"></a>
## `mcu_core`

`CFG-MCU-CORE` · **Тип:** string: upstream core identifier · **Default:** empty

Уточнение ядра для компонентов CMSIS/HAL/FreeRTOS и linker target, например M7 или M4 для поддерживаемого многоядерного MCU. Не требуется для каждого STM32; точные имена определяет stm32-cmake. Arduino эту ветку не использует.

**Изменение в 0.9.3** (`3c6bfa3`; ТЗ 4.7.8): ядро определяется по списку stm32-cmake (`stm32_get_cores`): у MCU с одним ядром оно выбирается автоматически (все H7, включая одноядерные, — `M7`; WB, MP1 — `M4`) с сообщением в журнале; у двухъядерных (H745, WL55) `mcu_core` обязателен; значение вне списка и ядро для MCU без ядер (например, F4) — ошибка Configure со списком допустимых значений. Ядро применяется к целям CMSIS, HAL, FreeRTOS, обёртке CMSIS-RTOS, startup/system и к запросам RAM/Flash.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
mcu_core: M4
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_config.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.h7-single-core-default`, `configure.h7-dual-core`, `configure.mcu-core-invalid`, `configure.h7-freertos-cube`. [Test manifest](../../../../tests/cases.json).

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
