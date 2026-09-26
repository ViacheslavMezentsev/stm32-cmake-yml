# CMSIS, HAL и FreeRTOS

[Документация](../../index.md) → [Reference 0.9.2](index.md) → CMSIS, HAL и FreeRTOS · [English](../../../en/reference/0.9.2/frameworks.md)

Общие правила: [семантика](semantics.md). База: `f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0`. История появления опций до 0.9.2 не установлена; наличие подтверждено в этой базе. Если не указано иное, настройка выполняется на Configure/Generate; фактические команды исполняются при Build/Post-build.

<a id="use-cmsis"></a>
## `use_cmsis`

`CFG-USE-CMSIS` · **Тип:** boolean · **Default:** true (stm32-cmake)

Подключает CMSIS из Cube. При false автоматические startup/CMSIS targets не подключаются; пользователь отвечает за startup, CPU flags и linker script. Arduino не вызывает этот механизм.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
use_cmsis: false
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_frameworks.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.ioc-baremetal-zero`, `configure.baremetal-no-cube`, `configure.stm32f0-cmsis-hal`, `configure.stm32f3-cmsis-hal`, `configure.stm32f7-cmsis-hal`, `configure.stm32g4-cmsis-hal`, `configure.stm32f0-bare`. [Test manifest](../../../../tests/cases.json).

<a id="use-hal"></a>
## `use_hal`

`CFG-USE-HAL` · **Тип:** boolean · **Default:** true (stm32-cmake)

Требует use_cmsis: true даже при пустом hal_components. При непустом списке создаёт зависимости HAL/LL и USE_HAL_DRIVER. Проверка hal_conf.h выполняется при true независимо от списка. В Arduino не управляет драйверами ядра.

**Изменение в 0.9.3** (`d8708b4`; ТЗ 4.7.6): подсказка об отсутствующем `hal_conf.h` называет фактический файл конфигурации (`stm32_config.yml` по умолчанию) вместо `project_config.yml`.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
use_hal: true
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_frameworks.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.hal-requires-cmsis`, `configure.defaults-blackpill`, `configure.diagnostics-missing-hal-conf`, `configure.stm32f0-cmsis-hal`, `configure.stm32f3-cmsis-hal`, `configure.stm32f7-cmsis-hal`, `configure.stm32g4-cmsis-hal`, `configure.stm32f0-bare`. [Test manifest](../../../../tests/cases.json).

<a id="cubefw-package"></a>
## `cubefw_package`

`CFG-CUBEFW-PACKAGE` · **Тип:** string: auto / Vx.y.z · **Default:** IOC / auto

auto ищет локальные Drivers/CMSIS и Drivers/STM32<family>xx_HAL_Driver, затем последнюю версию в $ENV{CMAKE_USER_HOME}/STM32Cube/Repository. Vx.y.z выбирает конкретный установленный пакет. local — внутренний результат обнаружения, не поддерживаемое входное значение. Автоскачивания нет; при отключённых зависимостях Cube не нужен.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
cubefw_package: V1.8.7
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_frameworks.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.ioc-bluepill-defaults`, `configure.baremetal-no-cube`, `configure.stm32f0-cmsis-hal`, `configure.stm32f3-cmsis-hal`, `configure.stm32f7-cmsis-hal`, `configure.stm32g4-cmsis-hal`. [Test manifest](../../../../tests/cases.json).

<a id="hal-components"></a>
## `hal_components`

`CFG-HAL-COMPONENTS` · **Тип:** list of upstream components · **Default:** []

Имена суффиксов HAL::STM32::<family>::..., например GPIO, UART, LL_USART. Точный набор определяется stm32-cmake и Cube, а не этим справочником. LL_ включает USE_FULL_LL_DRIVER. Пустой список не означает все драйверы.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
hal_components: [GPIO]
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_frameworks.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.defaults-blackpill`, `configure.bluepill`, `configure.stm32f0-cmsis-hal`, `configure.stm32f3-cmsis-hal`, `configure.stm32f7-cmsis-hal`, `configure.stm32g4-cmsis-hal`, `configure.stm32f0-ll-profile`. [Test manifest](../../../../tests/cases.json).

<a id="use-freertos"></a>
## `use_freertos`

`CFG-USE-FREERTOS` · **Тип:** boolean · **Default:** IOC detection / false otherwise

Включает ветку FreeRTOS в stm32-cmake backend. false в YAML/профиле/override подавляет обнаружение из IOC. Arduino эту ветку не вызывает. При true нужен ровно один порт в freertos_components.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
use_freertos: false
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_frameworks.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.baremetal-no-cube`, `configure.freertos-defaults`, `configure.freertos-disabled`, `configure.freertos-required-package`, `configure.freertos-ioc-f4-v2`, `configure.freertos-ioc-f1-v1`, `configure.freertos-ioc-profile-precedence`, `configure.freertos-ioc-yaml-precedence`, `configure.freertos-ioc-empty-fallback`, `configure.freertos-ioc-override-disable`, `configure.freertos-ioc-reconfigure`. [Test manifest](../../../../tests/cases.json).

<a id="freertos-version"></a>
## `freertos_version`

`CFG-FREERTOS-VERSION` · **Тип:** string: cube / external namespace · **Default:** cube when enabled

cube выбирает targets FreeRTOS::STM32::<family>. Иное непустое значение выбирает префикс FreeRTOS (обычно пишут external); не выбирает номер релиза и не скачивает пакет. Внешний поиск/targets должен обеспечить upstream toolchain.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
freertos_version: cube
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_frameworks.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.freertos-defaults`, `configure.freertos-gcs-v2`, `configure.freertos-demo-heap2`, `configure.freertos-ioc-f4-v2`, `configure.freertos-ioc-f1-v1`, `configure.freertos-ioc-empty-fallback`, `configure.freertos-external-cmake-known-failure`, `configure.freertos-external-env-known-failure`. [Test manifest](../../../../tests/cases.json).

**Отклонение:** [E007](../../errata/E007.md) — со штатным закреплённым upstream external завершается ошибкой Generate даже при корректном FREERTOS_PATH. Тесты фиксируют известную ошибку, а не подтверждают поддержку.

<a id="freertos-components"></a>
## `freertos_components`

`CFG-FREERTOS-COMPONENTS` · **Тип:** list of upstream components · **Default:** IOC port inference / [] manually

При включении нужен ровно один элемент ARM_*. IOC-ветка выводит порт по семейству (F1: ARM_CM3) и Heap::4; ручная настройка этого fallback не имеет. Остальные имена превращаются в targets, например Heap::4, Timers. Список не проверяет совместимость порта с MCU.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
freertos_components: [ARM_CM3, Heap::4]
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_frameworks.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.freertos-defaults`, `configure.freertos-demo-heap2`, `configure.freertos-no-port`, `configure.freertos-multiple-ports`, `configure.freertos-missing-component`, `configure.freertos-ioc-f4-v2`, `configure.freertos-ioc-f1-v1`, `configure.freertos-ioc-profile-precedence`, `configure.freertos-ioc-yaml-precedence`, `configure.freertos-ioc-empty-fallback`, `configure.freertos-ioc-override-disable`, `configure.freertos-ioc-reconfigure`, `configure.stm32f0-ioc-freertos`, `configure.stm32f3-ioc-freertos`, `configure.stm32f7-ioc-freertos`, `configure.stm32g4-ioc-freertos`. [Test manifest](../../../../tests/cases.json).

<a id="cmsis-rtos-api"></a>
## `cmsis_rtos_api`

`CFG-CMSIS-RTOS-API` · **Тип:** string: none / v1 / v2 · **Default:** IOC detection / no wrapper

При use_freertos подключает CMSIS RTOS или RTOS_V2 target. Иные значения не добавляют обёртку; enum явно не проверяется. Зависимости соответствующей обёртки должны быть доступны.

**Пропуск и пустота:** см. [общие правила](semantics.md#empty-values); исключения указаны выше. Профиль/override применяется до выбора defaults. Ограничения backend и путей указаны в описании.

```yaml
cmsis_rtos_api: none
```

[Реализация 0.9.2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_frameworks.cmake) · [Index](index.md)

**Проверки (частичное покрытие):** `configure.freertos-defaults`, `configure.freertos-gcs-v2`, `configure.freertos-demo-heap2`, `configure.freertos-v1`, `configure.freertos-disabled`, `configure.freertos-ioc-f4-v2`, `configure.freertos-ioc-f1-v1`, `configure.freertos-ioc-profile-precedence`, `configure.freertos-ioc-yaml-precedence`, `configure.freertos-ioc-empty-fallback`, `configure.freertos-ioc-override-disable`, `configure.freertos-ioc-reconfigure`, `configure.stm32f0-ioc-freertos`, `configure.stm32f3-ioc-freertos`, `configure.stm32f7-ioc-freertos`, `configure.stm32g4-ioc-freertos`. [Test manifest](../../../../tests/cases.json).
