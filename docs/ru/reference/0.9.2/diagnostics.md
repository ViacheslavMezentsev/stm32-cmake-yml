# Диагностика

[Документация](../../index.md) → [Reference 0.9.2](index.md) → Диагностика · [English](../../../en/reference/0.9.2/diagnostics.md)

Общие правила: [семантика](semantics.md). База: `f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0`. История появления опций до 0.9.2 не установлена; наличие подтверждено в этой базе. Если не указано иное, настройка выполняется на Configure/Generate; фактические команды исполняются при Build/Post-build.

<a id="validate-linker-script"></a>
## `validate_linker_script`

`CFG-VALIDATE-LINKER-SCRIPT` · **Тип:** boolean · **Default:** true

При Configure выводит сравнение суммы распознанных RAM-секций с базой MCU. Несовпадение размеров само по себе не ошибка. Нераспознанные секции предупреждают; Arduino пропускается. Не проверяет пересечения, стек, CRC или фактическую линковку.

**Изменение в 0.9.3** (`3c6bfa3`; ТЗ 4.13.4): эталон — сумма RAM, CCRAM и RAM_SHARE MCU с учётом ядра, поэтому CCM-память F3 и G4 не даёт ложного превышения. Для скрипта, который формирует stm32-cmake, выводится «не проверялось» вместо равенства без проверки; если RAM-областей не найдено — только предупреждение.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
validate_linker_script: true
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_diagnostics.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.linker-template`, `configure.diagnostics-toggle`, `configure.diagnostics-unrecognized-ram`, `configure.h7-single-core-default`, `configure.h7-dual-core`, `configure.h5-cmsis-hal-freertos-external`. [Test manifest](../../../../tests/cases.json).

<a id="log-target-properties"></a>
## `log_target_properties`

`CFG-LOG-TARGET-PROPERTIES` · **Тип:** boolean · **Default:** false

Выводит свойства цели и доступной STM32 interface-цели при Configure. Не заменяет просмотр сгенерированных команд.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
log_target_properties: false
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_diagnostics.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.diagnostics-toggle`. [Test manifest](../../../../tests/cases.json).

<a id="verbose-build"></a>
## `verbose_build`

`CFG-VERBOSE-BUILD` · **Тип:** boolean · **Default:** false

Принудительно устанавливает CMAKE_VERBOSE_MAKEFILE в ON/OFF. Видимость команд зависит также от генератора; для Ninja можно использовать ninja -v.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
verbose_build: false
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/stm32_yml.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** нет автоматической проверки этого контракта. [Test manifest](../../../../tests/cases.json).

<a id="cppcheck-enable"></a>
## `cppcheck_enable`

`CFG-CPPCHECK-ENABLE` · **Тип:** boolean · **Default:** false

Ищет cppcheck при Configure и задаёт C_CPPCHECK/CXX_CPPCHECK для запуска при сборке. При отсутствии утилиты предупреждает и не активирует анализ. В текущем тестовом образе cppcheck не установлен.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
cppcheck_enable: false
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_code_quality.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.cppcheck-defaults`, `configure.cppcheck-custom`, `configure.cppcheck-empty-fallback`, `configure.cppcheck-unavailable`, `configure.cppcheck-reconfigure`. [Test manifest](../../../../tests/cases.json).

<a id="cppcheck-args"></a>
## `cppcheck_args`

`CFG-CPPCHECK-ARGS` · **Тип:** list of arguments · **Default:** built-in argument list

Непустой список заменяет defaults: --enable=warning,performance,portability,style; --inline-suppr; --suppress=missingInclude; --suppress=unmatchedSuppression. Пустой список включает defaults, а не отключает их. cppcheck_ignores добавляется отдельно.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
cppcheck_args: [--enable=warning]
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_code_quality.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.cppcheck-defaults`, `configure.cppcheck-custom`, `configure.cppcheck-empty-fallback`, `configure.cppcheck-reconfigure`. [Test manifest](../../../../tests/cases.json).

<a id="cppcheck-ignores"></a>
## `cppcheck_ignores`

`CFG-CPPCHECK-IGNORES` · **Тип:** list of path fragments · **Default:** [STM32Cube/Repository, Drivers, Middlewares]

Каждый элемент создаёт --suppress=*:*<элемент>/*. Это подстроки путей, не список каталогов для удаления. Отсутствие или [] восстанавливает defaults; пустым списком их не отключить.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
cppcheck_ignores: [Drivers]
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_code_quality.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.cppcheck-defaults`, `configure.cppcheck-custom`, `configure.cppcheck-empty-fallback`, `configure.cppcheck-reconfigure`. [Test manifest](../../../../tests/cases.json).
