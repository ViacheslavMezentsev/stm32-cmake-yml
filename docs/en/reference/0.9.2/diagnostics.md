# Diagnostics

[Documentation](../../index.md) → [Reference 0.9.2](index.md) → Diagnostics · [Русский](../../../ru/reference/0.9.2/diagnostics.md)

Shared rules: [semantics](semantics.md). Baseline: `f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0`. Introduction history before 0.9.2 is not established; presence is confirmed in this baseline. Unless stated otherwise, configuration happens at Configure/Generate and actual commands execute at Build/Post-build.

<a id="validate-linker-script"></a>
## `validate_linker_script`

`CFG-VALIDATE-LINKER-SCRIPT` · **Type:** boolean · **Default:** true

At Configure, prints the recognized RAM-section sum compared with the MCU database. Size mismatch itself is not an error. Unrecognized sections warn; Arduino is skipped. Does not validate overlaps, stack, CRC or actual linking.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
validate_linker_script: true
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_diagnostics.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.linker-template`, `configure.diagnostics-toggle`, `configure.diagnostics-unrecognized-ram`. [Test manifest](../../../../tests/cases.json).

<a id="log-target-properties"></a>
## `log_target_properties`

`CFG-LOG-TARGET-PROPERTIES` · **Type:** boolean · **Default:** false

Prints target properties and the available STM32 interface target during Configure. Does not replace inspecting generated commands.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
log_target_properties: false
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_diagnostics.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.diagnostics-toggle`. [Test manifest](../../../../tests/cases.json).

<a id="verbose-build"></a>
## `verbose_build`

`CFG-VERBOSE-BUILD` · **Type:** boolean · **Default:** false

Forces CMAKE_VERBOSE_MAKEFILE ON/OFF. Command visibility also depends on the generator; Ninja can use ninja -v.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
verbose_build: false
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/stm32_yml.cmake) · [Index](index.md)

**Checks (partial coverage):** no automated check of this contract. [Test manifest](../../../../tests/cases.json).

<a id="cppcheck-enable"></a>
## `cppcheck_enable`

`CFG-CPPCHECK-ENABLE` · **Type:** boolean · **Default:** false

Finds cppcheck at Configure and sets C_CPPCHECK/CXX_CPPCHECK for build-time execution. A missing executable warns and leaves analysis disabled. The current test image does not install cppcheck.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
cppcheck_enable: false
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_code_quality.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.cppcheck-defaults`, `configure.cppcheck-custom`, `configure.cppcheck-empty-fallback`, `configure.cppcheck-unavailable`, `configure.cppcheck-reconfigure`. [Test manifest](../../../../tests/cases.json).

<a id="cppcheck-args"></a>
## `cppcheck_args`

`CFG-CPPCHECK-ARGS` · **Type:** list of arguments · **Default:** built-in argument list

A nonempty list replaces defaults: --enable=warning,performance,portability,style; --inline-suppr; --suppress=missingInclude; --suppress=unmatchedSuppression. An empty list selects defaults rather than removing them. cppcheck_ignores is appended separately.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
cppcheck_args: [--enable=warning]
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_code_quality.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.cppcheck-defaults`, `configure.cppcheck-custom`, `configure.cppcheck-empty-fallback`, `configure.cppcheck-reconfigure`. [Test manifest](../../../../tests/cases.json).

<a id="cppcheck-ignores"></a>
## `cppcheck_ignores`

`CFG-CPPCHECK-IGNORES` · **Type:** list of path fragments · **Default:** [STM32Cube/Repository, Drivers, Middlewares]

Each item adds --suppress=*:*<item>/*. These are path fragments, not directories to delete. Missing values or [] restore defaults; an empty list cannot disable them.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
cppcheck_ignores: [Drivers]
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_code_quality.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.cppcheck-defaults`, `configure.cppcheck-custom`, `configure.cppcheck-empty-fallback`, `configure.cppcheck-reconfigure`. [Test manifest](../../../../tests/cases.json).
