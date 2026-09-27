# Project and version

[Documentation](../../index.md) → [Reference 0.9.2](index.md) → Project and version · [Русский](../../../ru/reference/0.9.2/project.md)

Shared rules: [semantics](semantics.md). Baseline: `f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0`. Introduction history before 0.9.2 is not established; presence is confirmed in this baseline. Unless stated otherwise, configuration happens at Configure/Generate and actual commands execute at Build/Post-build.

<a id="stm32-cmake-yml-version"></a>
## `stm32_cmake_yml_version`

`CFG-STM32-CMAKE-YML-VERSION` · **Type:** string · **Default:** —

Version the YAML targets. Set it explicitly; it does not select framework code. Missing/mismatched versions produce warnings, not a configuration prohibition.

**Change in 0.9.3** (`d8708b4`; spec 4.2.3): the parameter is recommended: a missing or empty value warns that the recommended parameter is not set, not that a mandatory one is missing. The "What is new in 0.9" note is removed from the older-config warning.

**Processing order:** version comparison runs immediately after YAML loading, **before** profiles and `STM32_YML_OVERRIDE_*`. Changing these two options through a profile/override cannot change diagnostics already emitted. Set them at the YAML root. Missing or empty versions warn when checking is enabled; configuration continues. An omitted or empty switch defaults to `true` (the empty switch is not separately tested).

```yaml
stm32_cmake_yml_version: 0.9.2
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_config.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.version-equal`, `configure.version-missing`, `configure.version-empty`, `configure.version-older`, `configure.version-newer`, `configure.version-disabled`, `configure.version-before-profile`, `configure.version-before-override`. [Test manifest](../../../../tests/cases.json).

<a id="stm32-cmake-yml-version-check"></a>
## `stm32_cmake_yml_version_check`

`CFG-STM32-CMAKE-YML-VERSION-CHECK` · **Type:** boolean · **Default:** true

Enables configuration-version warnings. false disables comparison; the framework banner remains.

**Processing order:** version comparison runs immediately after YAML loading, **before** profiles and `STM32_YML_OVERRIDE_*`. Changing these two options through a profile/override cannot change diagnostics already emitted. Set them at the YAML root. Missing or empty versions warn when checking is enabled; configuration continues. An omitted or empty switch defaults to `true` (the empty switch is not separately tested).

```yaml
stm32_cmake_yml_version_check: true
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_config.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.version-equal`, `configure.version-missing`, `configure.version-empty`, `configure.version-older`, `configure.version-newer`, `configure.version-disabled`, `configure.version-before-profile`, `configure.version-before-override`. [Test manifest](../../../../tests/cases.json).

<a id="toolchain-backend"></a>
## `toolchain_backend`

`CFG-TOOLCHAIN-BACKEND` · **Type:** string: stm32-cmake / arduino · **Default:** stm32-cmake

Selects CMSIS/HAL/FreeRTOS or Arduino wrappers. The consumer sets the toolchain before project(). In 0.9.2 an unknown nonempty string falls through to stm32-cmake; it is not another supported backend.

**Change in 0.9.3** (`b9a6cd3`; spec 3.7.3, 4.1.6): an unknown non-empty value warns with the known values (`stm32-cmake`, `arduino`) and `stm32-cmake` applies. An empty value still means `stm32-cmake` without a warning.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
toolchain_backend: stm32-cmake
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_config.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.arduino-defaults`, `configure.baremetal-no-cube`, `configure.enum-unknown-values`, `configure.empty-and-null-defaults`. [Test manifest](../../../../tests/cases.json).

<a id="ioc-file"></a>
## `ioc_file`

`CFG-IOC-FILE` · **Type:** string: relative path · **Default:** —

Path relative to the project root. IOC supplies MCU, name, heap/stack, Cube FW and FreeRTOS data only where YAML/profile/override values are absent. A missing file fails. Arduino ignores IOC. It does not generate clocks or sources from IOC.

**Change in 0.9.3** (`d8708b4`; spec 3.6.5, 4.4.6): the IOC file is registered as a Configure dependency: changing it re-runs Configure on the next build. When the IOC has no project name, `HeapSize` or `StackSize` and YAML, profile and overrides do not set them, the manual-mode values `auto`, 512 and 1024 apply.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
ioc_file: bluepill-hsi.ioc
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_config.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.ioc-bluepill-defaults`, `configure.yaml-over-ioc`, `configure.missing-ioc`, `configure.freertos-ioc-f4-v2`, `configure.freertos-ioc-f1-v1`, `configure.freertos-ioc-profile-precedence`, `configure.freertos-ioc-yaml-precedence`, `configure.freertos-ioc-empty-fallback`, `configure.freertos-ioc-override-disable`, `configure.freertos-ioc-reconfigure`, `configure.stm32f0-ioc-freertos`, `configure.stm32f3-ioc-freertos`, `configure.stm32f7-ioc-freertos`, `configure.stm32g4-ioc-freertos`, `configure.ioc-missing-values-defaults`, `configure.configure-depends`. [Test manifest](../../../../tests/cases.json).

<a id="project-name"></a>
## `project_name`

`CFG-PROJECT-NAME` · **Type:** string · **Default:** auto (manual); IOC (ioc_file)

Name for project() and the target in a typical consumer. auto means the root folder name. In the IOC branch a missing IOC project name does not receive the general auto fallback; set it explicitly for incomplete IOC files.

**Change in 0.9.3** (`d8708b4`; spec 4.4.6): an IOC without a project name yields `auto` (the project directory name) instead of an empty value.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
project_name: bluepill
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_config.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.ioc-bluepill-defaults`, `configure.yaml-over-ioc`, `configure.ioc-missing-values-defaults`. [Test manifest](../../../../tests/cases.json).

<a id="mcu"></a>
## `mcu`

`CFG-MCU` · **Type:** string: STM32 part name · **Default:** IOC / required manually

For example STM32F103C8T6. IOC DeviceId loses only a trailing x. The stm32-cmake backend requires a name supported by its MCU database. Arduino uses it for auto linker-template lookup; the consumer supplies chip defines. Derived MCU is stale across changes in baseline 0.9.2.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
mcu: STM32F103C8T6
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_config.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.yaml-over-ioc`, `configure.bluepill`, `configure.reconfigure-mcu`, `configure.stm32f0-cmsis-hal`, `configure.stm32f3-cmsis-hal`, `configure.stm32f7-cmsis-hal`, `configure.stm32g4-cmsis-hal`. [Test manifest](../../../../tests/cases.json).

**Errata:** [E001](../../errata/E001.md).

<a id="mcu-core"></a>
## `mcu_core`

`CFG-MCU-CORE` · **Type:** string: upstream core identifier · **Default:** empty

Core suffix for CMSIS/HAL/FreeRTOS components and linker targets, e.g. M7 or M4 for a supported multicore MCU. Not required for every STM32; identifiers come from stm32-cmake. Arduino does not use this branch.

**Change in 0.9.3** (`3c6bfa3`; spec 4.7.8): the core follows the stm32-cmake list (`stm32_get_cores`): a single-core MCU gets its core automatically (every H7, including single-core ones, gets `M7`; WB and MP1 get `M4`) with a log message; dual-core MCUs (H745, WL55) require `mcu_core`; a value outside the list and a core for an MCU without cores (e.g. F4) are Configure errors listing the valid values. The core applies to the CMSIS, HAL, FreeRTOS and CMSIS-RTOS wrapper targets, startup/system files and RAM/Flash queries.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
mcu_core: M4
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_config.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.h7-single-core-default`, `configure.h7-dual-core`, `configure.mcu-core-invalid`, `configure.h7-freertos-cube`. [Test manifest](../../../../tests/cases.json).

<a id="languages"></a>
## `languages`

`CFG-LANGUAGES` · **Type:** list of CMake languages · **Default:** [C, CXX, ASM]

Passed by the consumer to project(). An empty value or [] selects the default. stm32-cmake CMSIS startup targets need ASM. Languages must match the sources.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
languages: [C, CXX, ASM]
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_config.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.defaults-blackpill`, `configure.ioc-bluepill-defaults`. [Test manifest](../../../../tests/cases.json).
