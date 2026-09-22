# Development: cache and bare metal

[Documentation](index.md) · [Русский](../ru/development.md)

## VS Code and cache

The author's usual workflow is to delete the CMake cache and reconfigure after
editing stm32_config.yml. A fresh cache removes old cache entries, so repeated
configuration bugs may not appear in everyday use. This is a useful diagnostic
starting point; supply the required profile/toolchain settings again through the
project configuration or Configure command.

Tests retain two modes: independent scenarios with fresh caches and multi-step
scenarios intentionally reusing one build directory. The latter checks incremental
CLI/IDE behavior, retained -D values, override clearing and profile changes. It
complements the author's workflow. Use a separate build directory when changing
toolchains. See [semantics](reference/0.9.2/semantics.md).

## MCU startup responsibilities

| Mode | Responsibility |
| --- | --- |
| `use_cmsis: false`, `use_hal: false` | The programmer supplies or implements reset/startup, the vector table, necessary memory and C/C++ runtime initialization, linker script and CPU/ABI compiler/linker flags. HAL/LL integration is manual if needed. |
| `use_cmsis: true` with stm32-cmake | CMSIS/MCU targets provide part of the integration: appropriate startup/system sources and MCU settings according to the installed package and stm32-cmake selection/override mechanisms. Integrate custom files consistently without duplicate startup. HAL is a separate option. |
| Arduino backend | Startup depends on Core, variant, toolchain and consumer CMake wrappers; standard CMSIS backend rules do not apply automatically. |

CMSIS does not prove that custom vectors, clocks, memory or startup are correct.
Configure only creates the build graph. Bare-metal fixtures check dependency
isolation and graph settings; they are not runnable firmware. Before preparing or
building firmware in this work, notify the author and wait for scenario guidance,
as required by the [roadmap](../../TODO.md).
