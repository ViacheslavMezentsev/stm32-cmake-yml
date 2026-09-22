# CMSIS, HAL and FreeRTOS

[Documentation](../../index.md) → [Reference 0.9.2](index.md) → CMSIS, HAL and FreeRTOS · [Русский](../../../ru/reference/0.9.2/frameworks.md)

Shared rules: [semantics](semantics.md). Baseline: `f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0`. Introduction history before 0.9.2 is not established; presence is confirmed in this baseline. Unless stated otherwise, configuration happens at Configure/Generate and actual commands execute at Build/Post-build.

<a id="use-cmsis"></a>
## `use_cmsis`

`CFG-USE-CMSIS` · **Type:** boolean · **Default:** true (stm32-cmake)

Loads CMSIS from Cube. false omits automatic startup/CMSIS targets; the consumer supplies startup, CPU flags and linker script. Arduino does not invoke this mechanism.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
use_cmsis: false
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_frameworks.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.ioc-baremetal-zero`, `configure.baremetal-no-cube`. [Test manifest](../../../../tests/cases.json).

<a id="use-hal"></a>
## `use_hal`

`CFG-USE-HAL` · **Type:** boolean · **Default:** true (stm32-cmake)

Requires use_cmsis: true even with empty hal_components. A nonempty list adds HAL/LL dependencies and USE_HAL_DRIVER. hal_conf.h is checked whenever true, regardless of the list. It does not control Arduino core drivers.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
use_hal: true
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_frameworks.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.hal-requires-cmsis`, `configure.defaults-blackpill`. [Test manifest](../../../../tests/cases.json).

<a id="cubefw-package"></a>
## `cubefw_package`

`CFG-CUBEFW-PACKAGE` · **Type:** string: auto / Vx.y.z · **Default:** IOC / auto

auto searches local Drivers/CMSIS and Drivers/STM32<family>xx_HAL_Driver, then the latest version under $ENV{CMAKE_USER_HOME}/STM32Cube/Repository. Vx.y.z selects an installed package. local is an internal discovery result, not a supported input. Nothing is downloaded; Cube is unnecessary when its dependencies are disabled.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
cubefw_package: V1.8.7
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_frameworks.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.ioc-bluepill-defaults`, `configure.baremetal-no-cube`. [Test manifest](../../../../tests/cases.json).

<a id="hal-components"></a>
## `hal_components`

`CFG-HAL-COMPONENTS` · **Type:** list of upstream components · **Default:** []

Suffixes of HAL::STM32::<family>::... targets, e.g. GPIO, UART, LL_USART. The exact set is determined by stm32-cmake and Cube. LL_ adds USE_FULL_LL_DRIVER. An empty list does not mean all drivers.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
hal_components: [GPIO]
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_frameworks.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.defaults-blackpill`, `configure.bluepill`. [Test manifest](../../../../tests/cases.json).

<a id="use-freertos"></a>
## `use_freertos`

`CFG-USE-FREERTOS` · **Type:** boolean · **Default:** IOC detection / false otherwise

Enables the FreeRTOS branch in the stm32-cmake backend. YAML/profile/override false suppresses IOC detection. Arduino does not invoke it. true requires exactly one port in freertos_components.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
use_freertos: false
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_frameworks.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.baremetal-no-cube`. [Test manifest](../../../../tests/cases.json).

<a id="freertos-version"></a>
## `freertos_version`

`CFG-FREERTOS-VERSION` · **Type:** string: cube / external namespace · **Default:** cube when enabled

cube selects FreeRTOS::STM32::<family> targets. Any other nonempty value selects the FreeRTOS prefix (conventionally external); it neither chooses a release number nor downloads a package. Upstream toolchain discovery/targets must supply the external dependency.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
freertos_version: cube
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_frameworks.cmake) · [Index](index.md)

**Checks (partial coverage):** no automated check of this contract. [Test manifest](../../../../tests/cases.json).

<a id="freertos-components"></a>
## `freertos_components`

`CFG-FREERTOS-COMPONENTS` · **Type:** list of upstream components · **Default:** IOC port inference / [] manually

When enabled, exactly one ARM_* item is required. The IOC branch infers the port by family (F1: ARM_CM3) and Heap::4; manual mode has no such fallback. Other names become targets, e.g. Heap::4 or Timers. Port/MCU compatibility is not validated.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
freertos_components: [ARM_CM3, Heap::4]
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_frameworks.cmake) · [Index](index.md)

**Checks (partial coverage):** no automated check of this contract. [Test manifest](../../../../tests/cases.json).

<a id="cmsis-rtos-api"></a>
## `cmsis_rtos_api`

`CFG-CMSIS-RTOS-API` · **Type:** string: none / v1 / v2 · **Default:** IOC detection / no wrapper

With use_freertos, adds the CMSIS RTOS or RTOS_V2 target. Other values add no wrapper; the enum is not explicitly validated. Required wrapper dependencies must be available.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
cmsis_rtos_api: none
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_frameworks.cmake) · [Index](index.md)

**Checks (partial coverage):** no automated check of this contract. [Test manifest](../../../../tests/cases.json).
