# Профили

[Документация](../../index.md) → [Reference 0.9.2](index.md) → Профили · [English](../../../en/reference/0.9.2/profiles.md)

Общие правила: [семантика](semantics.md). База: `f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0`. История появления опций до 0.9.2 не установлена; наличие подтверждено в этой базе. Если не указано иное, настройка выполняется на Configure/Generate; фактические команды исполняются при Build/Post-build.

<a id="profiles"></a>
## `profiles`

`CFG-PROFILES` · **Тип:** mapping: name -> option mapping · **Default:** {}

Именованные наборы выбираются -DSTM32_YML_PROFILE=name. Ключ заменяет базовое значение; суффикс _append дополняет уже заменённый список. Вложенные ключи становятся именами с подчёркиваниями. Неизвестный профиль предупреждает и продолжает с базовой конфигурацией. Символ _ в имени профиля недопустим, в том числе из-за ограничений путей сборки Arduino. Используйте латинские буквы/цифры, избегайте regex-метасимволов. Это ограничение не распространяется на имена YAML-ключей или генерируемых каталогов.

**Изменение в 0.9.3** (`d8708b4`; ТЗ 3.4.9): ключ профиля без `_append` применяется и экспортируется, даже если его нет в корне YAML, в том числе собственные ключи проекта (E008).

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
profiles:
  debug:
    stack_size: 2K
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_profiles.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.profile-replace-and-append`, `configure.unknown-profile-warning`, `configure.reconfigure-profile-lists`, `configure.reconfigure-profile-name-boundaries`, `configure.profile-only-keys`. [Test manifest](../../../../tests/cases.json).

**Errata:** [E005](../../errata/E005.md).

<a id="profiles-file"></a>
## `profiles_file`

`CFG-PROFILES-FILE` · **Тип:** string: relative YAML path · **Default:** inline profiles

Внешний файл от корня с секцией profiles. При выборе загружается как источник профилей; не является гарантированным merge двух каталогов профилей. Отсутствие файла предупреждает. В исходной 0.9.2 команда list этот файл не читает.

**Изменение в 0.9.3** (`d8708b4`; ТЗ 3.4.8, 3.6.5): из внешнего файла читается только секция `profiles:`; остальные ключи файла игнорируются и не подменяют базовое значение для `_append`. Файл регистрируется как зависимость Configure. Встроенная секция `profiles:` при заданном `profiles_file` по-прежнему не используется, но теперь об этом выводится предупреждение со списком встроенных профилей (ТЗ 3.4.11, вопрос 10.2.16).

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
profiles_file: profiles.yml
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_profiles.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.external-profile`, `configure.external-list-profiles`, `configure.reconfigure-external-profile-reset`, `configure.external-profile-ignores-top-level`, `configure.configure-depends`. [Test manifest](../../../../tests/cases.json).

**Errata:** [E002](../../errata/E002.md).
