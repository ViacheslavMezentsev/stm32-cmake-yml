# Профили

[Документация](../../index.md) → [Reference 0.9.2](index.md) → Профили · [English](../../../en/reference/0.9.2/profiles.md)

Общие правила: [семантика](semantics.md). База: `f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0`. История появления опций до 0.9.2 не установлена; наличие подтверждено в этой базе. Если не указано иное, настройка выполняется на Configure/Generate; фактические команды исполняются при Build/Post-build.

<a id="profiles"></a>
## `profiles`

`CFG-PROFILES` · **Тип:** mapping: name -> option mapping · **Default:** {}

Именованные наборы выбираются -DSTM32_YML_PROFILE=name. Ключ заменяет базовое значение; суффикс _append дополняет уже заменённый список. Вложенные ключи становятся именами с подчёркиваниями. Неизвестный профиль предупреждает и продолжает с базовой конфигурацией. Для переносимых имён используйте буквы/цифры без _ и regex-метасимволов.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
profiles:
  debug:
    stack_size: 2K
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_profiles.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.profile-replace-and-append`, `configure.unknown-profile-warning`, `configure.reconfigure-profile-lists`. [Test manifest](../../../../tests/cases.json).

**Errata:** [E005](../../errata/E005.md).

<a id="profiles-file"></a>
## `profiles_file`

`CFG-PROFILES-FILE` · **Тип:** string: relative YAML path · **Default:** inline profiles

Внешний файл от корня с секцией profiles. При выборе загружается как источник профилей; не является гарантированным merge двух каталогов профилей. Отсутствие файла предупреждает. В исходной 0.9.2 команда list этот файл не читает.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
profiles_file: profiles.yml
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_profiles.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.external-profile`. [Test manifest](../../../../tests/cases.json).

**Errata:** [E002](../../errata/E002.md).
