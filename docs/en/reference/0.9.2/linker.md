# Linking and memory

[Documentation](../../index.md) → [Reference 0.9.2](index.md) → Linking and memory · [Русский](../../../ru/reference/0.9.2/linker.md)

Shared rules: [semantics](semantics.md). Baseline: `f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0`. Introduction history before 0.9.2 is not established; presence is confirmed in this baseline. Unless stated otherwise, configuration happens at Configure/Generate and actual commands execute at Build/Post-build.

<a id="heap-size"></a>
## `heap_size`

`CFG-HEAP-SIZE` · **Type:** integer bytes / string with K or M · **Default:** IOC / 512 manually

Size substituted into a local .ld.in. Use 0, integer bytes, or integer uppercase K/M. The IOC branch reads a HEX field; incomplete IOC files need explicit values. A ready .ld is not rewritten; the default stm32-cmake linker is not given these values through this branch. Fractional sizes are outside the supported contract (E003). Baseline 0.9.2 keeps stale cache values on reconfigure.

**Change in 0.9.3** (`d8708b4`; spec 4.11.4, 4.11.8, 4.11.9): the format is checked on every Configure, not only when a template is generated: an integer byte count or an integer with upper-case `K`/`M` (`0`, `1536`, `2K`, `1M`); `1k`, `1.5K`, `-1`, `0x200` are errors. A size set in YAML, a profile, an override or the IOC warns that it is not applied when the script comes from stm32-cmake or an explicit `linker_script` (for stm32-cmake the warning names its heap/stack sizes); defaults do not warn.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
heap_size: 1K
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_linker.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.linker-template`, `configure.baremetal-no-cube`, `configure.empty-and-null-defaults`, `configure.reconfigure-memory`, `configure.memory-size-format`, `configure.memory-size-unused-warning`, `configure.ioc-missing-values-defaults`. [Test manifest](../../../../tests/cases.json).

**Errata:** [E001](../../errata/E001.md), [E003](../../errata/E003.md).

<a id="stack-size"></a>
## `stack_size`

`CFG-STACK-SIZE` · **Type:** integer bytes / string with K or M · **Default:** IOC / 1024 manually

Size substituted into a local .ld.in. Use 0, integer bytes, or integer uppercase K/M. The IOC branch reads a HEX field; incomplete IOC files need explicit values. A ready .ld is not rewritten; the default stm32-cmake linker is not given these values through this branch. Fractional sizes are outside the supported contract (E003). Baseline 0.9.2 keeps stale cache values on reconfigure.

**Change in 0.9.3** (`d8708b4`; spec 4.11.4, 4.11.8, 4.11.9): the format is checked on every Configure, not only when a template is generated: an integer byte count or an integer with upper-case `K`/`M` (`0`, `1536`, `2K`, `1M`); `1k`, `1.5K`, `-1`, `0x200` are errors. A size set in YAML, a profile, an override or the IOC warns that it is not applied when the script comes from stm32-cmake or an explicit `linker_script` (for stm32-cmake the warning names its heap/stack sizes); defaults do not warn.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
stack_size: 1K
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_linker.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.linker-template`, `configure.baremetal-no-cube`, `configure.empty-and-null-defaults`, `configure.reconfigure-memory`, `configure.reconfigure-profile-name-boundaries`, `configure.reconfigure-empty-override`, `configure.memory-size-format`, `configure.memory-size-unused-warning`, `configure.ioc-missing-values-defaults`. [Test manifest](../../../../tests/cases.json).

**Errata:** [E001](../../errata/E001.md), [E003](../../errata/E003.md).

<a id="linker-script"></a>
## `linker_script`

`CFG-LINKER-SCRIPT` · **Type:** string: auto / relative .ld path · **Default:** auto

auto searches local .ld.in names: concrete MCU type, package replaced by X, then XX and xx. linker_script_dir precedes the root. A template produces a build-tree .ld with HEAP_SIZE, STACK_SIZE and USE_READONLY (GCC >=11). Without one, stm32-cmake uses a CMSIS target when use_cmsis; Arduino fails. Supply your own script/template for bare metal. A missing explicit .ld fails.

**Change in 0.9.3** (`d8708b4`; spec 4.11.9): with an explicit script or the stm32-cmake script, explicitly set `heap_size`/`stack_size` warn that they are not applied.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
linker_script: auto
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_linker.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.linker-template`, `configure.explicit-linker`, `configure.missing-linker`, `configure.memory-size-unused-warning`. [Test manifest](../../../../tests/cases.json).

<a id="linker-script-dir"></a>
## `linker_script_dir`

`CFG-LINKER-SCRIPT-DIR` · **Type:** string: relative directory · **Default:** project root only

Extra first search directory relative to the root. The root remains a fallback. Does not change the base of sources or include_directories.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
linker_script_dir: linker
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_linker.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.linker-template`, `configure.explicit-linker`. [Test manifest](../../../../tests/cases.json).

<a id="link-options"></a>
## `link_options`

`CFG-LINK-OPTIONS` · **Type:** list of flag strings · **Default:** []

PRIVATE link-driver options, normalized like compile_options. Use linker_directives for direct linker arguments.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
link_options: [nostartfiles]
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/stm32_yml.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.system-link-options`. [Test manifest](../../../../tests/cases.json).

<a id="linker-directives"></a>
## `linker_directives`

`CFG-LINKER-DIRECTIVES` · **Type:** list of linker arguments · **Default:** []

Each item becomes LINKER:<item>. No separate dash normalization occurs; provide complete directives.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
linker_directives: [--print-memory-usage]
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/stm32_yml.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.system-link-options`. [Test manifest](../../../../tests/cases.json).

<a id="use-newlib-nano"></a>
## `use_newlib_nano`

`CFG-USE-NEWLIB-NANO` · **Type:** boolean · **Default:** false

Links STM32::Nano; the toolchain must provide that target, including with Arduino. Does not automatically enable float printf.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
use_newlib_nano: false
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_frameworks.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.system-nosys-nano`, `configure.system-semihost-nano`, `configure.system-disabled`, `configure.system-reconfigure`. [Test manifest](../../../../tests/cases.json).

<a id="system-library"></a>
## `system_library`

`CFG-SYSTEM-LIBRARY` · **Type:** string: NoSys / Semihosting · **Default:** none

Links the matching STM32 target. Unknown/empty values add nothing. NoSys must come from the toolchain; Semihosting has a fallback. Execution needs debugger/simulator support (the QEMU example uses -semihosting).

**Change in 0.9.3** (`b9a6cd3`; spec 3.7.3): an unknown non-empty value (e.g. `nosys`) warns with the known values (`NoSys`, `Semihosting`); no library is linked. An empty value does not warn.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
system_library: NoSys
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_frameworks.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.defaults-blackpill`, `configure.system-nosys-nano`, `configure.system-semihost-nano`, `configure.system-disabled`, `configure.system-reconfigure`, `configure.enum-unknown-values`, `configure.empty-and-null-defaults`. [Test manifest](../../../../tests/cases.json).
