# Sources and libraries

[Documentation](../../index.md) → [Reference 0.9.2](index.md) → Sources and libraries · [Русский](../../../ru/reference/0.9.2/sources.md)

Shared rules: [semantics](semantics.md). Baseline: `f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0`. Introduction history before 0.9.2 is not established; presence is confirmed in this baseline. Unless stated otherwise, configuration happens at Configure/Generate and actual commands execute at Build/Post-build.

<a id="sources"></a>
## `sources`

`CFG-SOURCES` · **Type:** list of relative paths · **Default:** []

Files are added to the target; directories use add_subdirectory and need CMakeLists.txt. Paths are relative to the current source directory, normally the root. ../ modules are supported. Missing paths warn and are skipped; a target with no sources can then fail Generate. With CMSIS/HAL, startup/system files override upstream sources.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
sources: [main.c, helper.cpp]
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_sources.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.profile-append`, `configure.profile-replace-and-append`, `configure.reconfigure-profile-lists`, `configure.source-directory-target`, `configure.source-missing-warning`, `configure.source-directory-requires-cmake`, `configure.module-explicit-link`, `configure.module-not-auto-linked`, `configure.module-missing-target`. [Test manifest](../../../../tests/cases.json).

<a id="include-directories"></a>
## `include_directories`

`CFG-INCLUDE-DIRECTORIES` · **Type:** list of paths · **Default:** []

PRIVATE target include paths: CMake resolves relative paths from the source directory; absolute paths are passed through. use_hal needs stm32<family>xx_hal_conf.h directly in one of these directories; absence fails Configure. An empty list stays empty.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
include_directories: [include]
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/stm32_yml.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.defaults-blackpill`, `configure.baremetal-empty-list`, `configure.diagnostics-missing-hal-conf`. [Test manifest](../../../../tests/cases.json).

<a id="custom-libraries"></a>
## `custom_libraries`

`CFG-CUSTOM-LIBRARIES` · **Type:** list of relative file paths · **Default:** []

Existing library files, e.g. .a archives, are resolved from the project root and linked PRIVATE. Missing files warn and are skipped. Use link_libraries for CMake targets.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
custom_libraries: [lib/device.a]
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/stm32_yml.cmake) · [Index](index.md)

**Checks (partial coverage):** no automated check of this contract. [Test manifest](../../../../tests/cases.json).

<a id="link-libraries"></a>
## `link_libraries`

`CFG-LINK-LIBRARIES` · **Type:** list of targets or library names · **Default:** []

Passed to target_link_libraries PRIVATE without file existence checks. The project or dependency must create named targets such as Arduino::Core. An unknown :: target usually fails Generate; a plain name may fail only at link time.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
link_libraries: [Arduino::Core, Arduino::Probe]
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/stm32_yml.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.arduino-defaults`, `configure.module-explicit-link`, `configure.module-not-auto-linked`, `configure.module-missing-target`. [Test manifest](../../../../tests/cases.json).
