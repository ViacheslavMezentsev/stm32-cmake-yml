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

**Checks (partial coverage):** `configure.ioc-baremetal-zero`, `configure.baremetal-no-cube`, `configure.stm32f0-cmsis-hal`, `configure.stm32f3-cmsis-hal`, `configure.stm32f7-cmsis-hal`, `configure.stm32g4-cmsis-hal`, `configure.stm32f0-bare`. [Test manifest](../../../../tests/cases.json).

<a id="use-hal"></a>
## `use_hal`

`CFG-USE-HAL` · **Type:** boolean · **Default:** true (stm32-cmake)

Requires use_cmsis: true even with empty hal_components. A nonempty list adds HAL/LL dependencies and USE_HAL_DRIVER. hal_conf.h is checked whenever true, regardless of the list. It does not control Arduino core drivers.

**Change in 0.9.3** (`d8708b4`; spec 4.7.6): the missing `hal_conf.h` hint names the actual configuration file (`stm32_config.yml` by default) instead of `project_config.yml`.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
use_hal: true
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_frameworks.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.hal-requires-cmsis`, `configure.defaults-blackpill`, `configure.diagnostics-missing-hal-conf`, `configure.stm32f0-cmsis-hal`, `configure.stm32f3-cmsis-hal`, `configure.stm32f7-cmsis-hal`, `configure.stm32g4-cmsis-hal`, `configure.stm32f0-bare`. [Test manifest](../../../../tests/cases.json).

<a id="cubefw-package"></a>
## `cubefw_package`

`CFG-CUBEFW-PACKAGE` · **Type:** string: auto / Vx.y.z · **Default:** IOC / auto

auto searches local Drivers/CMSIS and Drivers/STM32<family>xx_HAL_Driver, then the latest version under $ENV{CMAKE_USER_HOME}/STM32Cube/Repository. Vx.y.z selects an installed package. local is an internal discovery result, not a supported input. Nothing is downloaded; Cube is unnecessary when its dependencies are disabled.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
cubefw_package: V1.8.7
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_frameworks.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.ioc-bluepill-defaults`, `configure.baremetal-no-cube`, `configure.stm32f0-cmsis-hal`, `configure.stm32f3-cmsis-hal`, `configure.stm32f7-cmsis-hal`, `configure.stm32g4-cmsis-hal`. [Test manifest](../../../../tests/cases.json).

<a id="hal-components"></a>
## `hal_components`

`CFG-HAL-COMPONENTS` · **Type:** list of upstream components · **Default:** []

Suffixes of HAL::STM32::<family>::... targets, e.g. GPIO, UART, LL_USART. The exact set is determined by stm32-cmake and Cube. LL_ adds USE_FULL_LL_DRIVER. An empty list does not mean all drivers.

**Change in 0.9.3** (`3c6bfa3`; spec 4.7.9): every component is checked right after HAL is found: a missing one is a Configure error naming the component and family instead of a Generate error.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
hal_components: [GPIO]
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_frameworks.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.defaults-blackpill`, `configure.bluepill`, `configure.stm32f0-cmsis-hal`, `configure.stm32f3-cmsis-hal`, `configure.stm32f7-cmsis-hal`, `configure.stm32g4-cmsis-hal`, `configure.stm32f0-ll-profile`, `configure.hal-missing-component`, `configure.h7-single-core-default`, `configure.h5-cmsis-hal-freertos-external`. [Test manifest](../../../../tests/cases.json).

<a id="use-freertos"></a>
## `use_freertos`

`CFG-USE-FREERTOS` · **Type:** boolean · **Default:** IOC detection / false otherwise

Enables the FreeRTOS branch in the stm32-cmake backend. YAML/profile/override false suppresses IOC detection. Arduino does not invoke it. true requires exactly one port in freertos_components.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
use_freertos: false
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_frameworks.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.baremetal-no-cube`, `configure.freertos-defaults`, `configure.freertos-disabled`, `configure.freertos-required-package`, `configure.freertos-ioc-f4-v2`, `configure.freertos-ioc-f1-v1`, `configure.freertos-ioc-profile-precedence`, `configure.freertos-ioc-yaml-precedence`, `configure.freertos-ioc-empty-fallback`, `configure.freertos-ioc-override-disable`, `configure.freertos-ioc-reconfigure`. [Test manifest](../../../../tests/cases.json).

<a id="freertos-version"></a>
## `freertos_version`

`CFG-FREERTOS-VERSION` · **Type:** string: cube / external namespace · **Default:** cube when enabled

cube selects FreeRTOS::STM32::<family> targets. Any other nonempty value selects the FreeRTOS prefix (conventionally external); it neither chooses a release number nor downloads a package. Upstream toolchain discovery/targets must supply the external dependency.

**Change in 0.9.3** (`b9a6cd3`; spec 3.7.3): an unknown non-empty value warns with the known values (`cube`, `external`) and `external` applies, matching the actual 0.9.2 behaviour.

**Change in 0.9.3** (`3c6bfa3`; spec 4.8.6): `external` works (E007): FreeRTOS is found in `FREERTOS_PATH` (CMake or environment variable) without the family component, and the `FreeRTOS::<port>` and `FreeRTOS::<component>` targets are linked. Both the Cube FreeRTOS tree and FreeRTOS-Kernel are supported (including H5 and U5, whose packages have no FreeRTOS). A missing `FREERTOS_PATH`, `FreeRTOS.h`/`tasks.c` or port files is a Configure error.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
freertos_version: cube
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_frameworks.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.freertos-defaults`, `configure.freertos-gcs-v2`, `configure.freertos-demo-heap2`, `configure.freertos-ioc-f4-v2`, `configure.freertos-ioc-f1-v1`, `configure.freertos-ioc-empty-fallback`, `configure.freertos-external-cmake`, `configure.freertos-external-env`, `configure.freertos-unknown-enums`, `configure.empty-and-null-defaults`, `configure.freertos-external-kernel`, `configure.freertos-external-no-path`, `configure.freertos-external-missing-port`, `configure.h5-cmsis-hal-freertos-external`. [Test manifest](../../../../tests/cases.json).

**Deviation:** [E007](../../errata/E007.md) — with the pinned standard upstream, external fails Generate even with a valid FREERTOS_PATH. Tests reproduce the known failure rather than demonstrate support.

<a id="freertos-components"></a>
## `freertos_components`

`CFG-FREERTOS-COMPONENTS` · **Type:** list of upstream components · **Default:** IOC port inference / [] manually

When enabled, exactly one ARM_* item is required. The IOC branch infers the port by family (F1: ARM_CM3) and Heap::4; manual mode has no such fallback. Other names become targets, e.g. Heap::4 or Timers. Port/MCU compatibility is not validated.

**Change in 0.9.3** (`3c6bfa3`; spec 4.4.4, 4.8.7): the IOC port follows the table for every stm32-cmake family, including C0, U0, H5, L5, U5 (`ARM_CM33_NTZ`), WL and the H7/WL cores; a family outside the table warns and uses `ARM_CM4F`. Every component is checked right after FreeRTOS is found: a missing one is a Configure error naming the component and target namespace.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
freertos_components: [ARM_CM3, Heap::4]
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_frameworks.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.freertos-defaults`, `configure.freertos-demo-heap2`, `configure.freertos-no-port`, `configure.freertos-multiple-ports`, `configure.freertos-missing-component`, `configure.freertos-ioc-f4-v2`, `configure.freertos-ioc-f1-v1`, `configure.freertos-ioc-profile-precedence`, `configure.freertos-ioc-yaml-precedence`, `configure.freertos-ioc-empty-fallback`, `configure.freertos-ioc-override-disable`, `configure.freertos-ioc-reconfigure`, `configure.stm32f0-ioc-freertos`, `configure.stm32f3-ioc-freertos`, `configure.stm32f7-ioc-freertos`, `configure.stm32g4-ioc-freertos`, `configure.freertos-ioc-port-table`, `configure.freertos-ioc-port-unknown-family`, `configure.freertos-external-missing-component`. [Test manifest](../../../../tests/cases.json).

<a id="cmsis-rtos-api"></a>
## `cmsis_rtos_api`

`CFG-CMSIS-RTOS-API` · **Type:** string: none / v1 / v2 · **Default:** IOC detection / no wrapper

With use_freertos, adds the CMSIS RTOS or RTOS_V2 target. Other values add no wrapper; the enum is not explicitly validated. Required wrapper dependencies must be available.

**Change in 0.9.3** (`b9a6cd3`; spec 3.7.3): an unknown non-empty value warns with the known values (`none`, `v1`, `v2`) and `none` applies (no wrapper).

**Change in 0.9.3** (`3c6bfa3`; spec 4.7.8, 4.8.8): the wrapper is linked in the core namespace (`CMSIS::STM32::H7::M7::RTOS_V2`) and works with external FreeRTOS: wrapper sources come from the family Cube package and headers from the external FreeRTOS. If there is no wrapper (e.g. CubeH5 has no FreeRTOS), Configure fails and recommends `cmsis_rtos_api: none`.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
cmsis_rtos_api: none
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_frameworks.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.freertos-defaults`, `configure.freertos-gcs-v2`, `configure.freertos-demo-heap2`, `configure.freertos-v1`, `configure.freertos-disabled`, `configure.freertos-ioc-f4-v2`, `configure.freertos-ioc-f1-v1`, `configure.freertos-ioc-profile-precedence`, `configure.freertos-ioc-yaml-precedence`, `configure.freertos-ioc-empty-fallback`, `configure.freertos-ioc-override-disable`, `configure.freertos-ioc-reconfigure`, `configure.stm32f0-ioc-freertos`, `configure.stm32f3-ioc-freertos`, `configure.stm32f7-ioc-freertos`, `configure.stm32g4-ioc-freertos`, `configure.freertos-unknown-enums`, `configure.empty-and-null-defaults`, `configure.freertos-external-kernel`, `configure.h7-freertos-cube`, `configure.h5-cmsis-hal-freertos-external`. [Test manifest](../../../../tests/cases.json).
