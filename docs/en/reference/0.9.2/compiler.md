# Compilation

[Documentation](../../index.md) → [Reference 0.9.2](index.md) → Compilation · [Русский](../../../ru/reference/0.9.2/compiler.md)

Shared rules: [semantics](semantics.md). Baseline: `f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0`. Introduction history before 0.9.2 is not established; presence is confirmed in this baseline. Unless stated otherwise, configuration happens at Configure/Generate and actual commands execute at Build/Post-build.

<a id="c-standard"></a>
## `c_standard`

`CFG-C-STANDARD` · **Type:** integer: CMake C_STANDARD · **Default:** not set by framework

C standard. Forwarded to CMake, e.g. 11 or 17; support depends on CMake and compiler versions. The framework does not set STANDARD_REQUIRED or EXTENSIONS, and does not promise default 17.

C17 (`c_standard: 17`) requires CMake 3.21 or later. Use C11 for the CMake 3.19 baseline. [CMake C_STANDARD](https://cmake.org/cmake/help/latest/prop_tgt/C_STANDARD.html).

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
c_standard: 17
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_config.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.defaults-blackpill`, `configure.module-explicit-link`. [Test manifest](../../../../tests/cases.json).

<a id="cpp-standard"></a>
## `cpp_standard`

`CFG-CPP-STANDARD` · **Type:** integer: CMake CXX_STANDARD · **Default:** not set by framework

C++ standard. Forwarded to CMake, e.g. 11 or 17; support depends on CMake and compiler versions. The framework does not set STANDARD_REQUIRED or EXTENSIONS, and does not promise default 17.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
cpp_standard: 17
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_config.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.defaults-blackpill`, `configure.module-explicit-link`. [Test manifest](../../../../tests/cases.json).

<a id="compile-options"></a>
## `compile_options`

`CFG-COMPILE-OPTIONS` · **Type:** list of flag strings · **Default:** []

PRIVATE flags for all languages. Items are split on spaces, with leading dashes added where needed; recognized flags with separate arguments preserve the next token. This is not a shell parser: YAML quotes do not protect a space inside an argument from normalization.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
compile_options: [Wall]
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/stm32_yml.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.defaults-blackpill`, `configure.source-directory-target`, `configure.module-explicit-link`. [Test manifest](../../../../tests/cases.json).

<a id="compile-definitions"></a>
## `compile_definitions`

`CFG-COMPILE-DEFINITIONS` · **Type:** list of definition strings · **Default:** []

PRIVATE definitions for all languages. Use NAME or NAME=value without -D; CMake adds -D. Strings are split on spaces. An empty list removes user definitions, not the automatic MCU define.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
compile_definitions: [FEATURE=1]
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/stm32_yml.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.defaults-blackpill`, `configure.baremetal-empty-list`, `configure.source-directory-target`, `configure.module-explicit-link`. [Test manifest](../../../../tests/cases.json).

<a id="compile-options-c"></a>
## `compile_options_c`

`CFG-COMPILE-OPTIONS-C` · **Type:** list of flag strings · **Default:** []

PRIVATE flags for C only. Items are split on spaces, with leading dashes added where needed; recognized flags with separate arguments preserve the next token. This is not a shell parser: YAML quotes do not protect a space inside an argument from normalization.

**Change in 0.9.3** (`d8708b4`; spec 3.4.9): a value set only in a profile is applied without declaring the key at the YAML root (E008).

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
compile_options_c: [Wstrict-prototypes]
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/stm32_yml.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.defaults-blackpill`, `configure.source-directory-target`, `configure.profile-only-keys`. [Test manifest](../../../../tests/cases.json).

<a id="compile-definitions-c"></a>
## `compile_definitions_c`

`CFG-COMPILE-DEFINITIONS-C` · **Type:** list of definition strings · **Default:** []

PRIVATE definitions for C only. Use NAME or NAME=value without -D; CMake adds -D. Strings are split on spaces. An empty list removes user definitions, not the automatic MCU define.

**Change in 0.9.3** (`d8708b4`; spec 3.4.9): a value set only in a profile is applied without declaring the key at the YAML root (E008).

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
compile_definitions_c: [FEATURE=1]
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/stm32_yml.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.defaults-blackpill`, `configure.source-directory-target`, `configure.profile-only-keys`. [Test manifest](../../../../tests/cases.json).

<a id="compile-options-cxx"></a>
## `compile_options_cxx`

`CFG-COMPILE-OPTIONS-CXX` · **Type:** list of flag strings · **Default:** []

PRIVATE flags for C++ only. Items are split on spaces, with leading dashes added where needed; recognized flags with separate arguments preserve the next token. This is not a shell parser: YAML quotes do not protect a space inside an argument from normalization.

**Change in 0.9.3** (`d8708b4`; spec 3.4.9): a value set only in a profile is applied without declaring the key at the YAML root (E008).

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
compile_options_cxx: [fno-exceptions]
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/stm32_yml.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.defaults-blackpill`, `configure.source-directory-target`, `configure.profile-only-keys`. [Test manifest](../../../../tests/cases.json).

<a id="compile-definitions-cxx"></a>
## `compile_definitions_cxx`

`CFG-COMPILE-DEFINITIONS-CXX` · **Type:** list of definition strings · **Default:** []

PRIVATE definitions for C++ only. Use NAME or NAME=value without -D; CMake adds -D. Strings are split on spaces. An empty list removes user definitions, not the automatic MCU define.

**Change in 0.9.3** (`d8708b4`; spec 3.4.9): a value set only in a profile is applied without declaring the key at the YAML root (E008).

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
compile_definitions_cxx: [FEATURE=1]
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/stm32_yml.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.defaults-blackpill`, `configure.source-directory-target`, `configure.profile-only-keys`. [Test manifest](../../../../tests/cases.json).

Profile-only language settings require root declarations: [E008](../../errata/E008.md).
