# Adding sources to the main target

[Documentation](index.md) · [Русский](../ru/simple-sources.md)

Use this for existing Core/User sources that do not need a standalone library.
YAML options are described in the [reference](reference/0.9.2/sources.md).

## File or directory

```yaml
sources: [main.c, Core]
```

An ordinary file is added to the main target. A directory uses add_subdirectory;
provide Core/CMakeLists.txt:

```cmake
target_sources(${PROJECT_NAME} PRIVATE Src/app.c Src/helper.cpp)
target_include_directories(${PROJECT_NAME} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/Inc")
```

Use existing files. Enable CXX in languages for helper.cpp. These paths are relative
to Core; YAML paths are relative to the project source directory. The framework
creates the main target before processing sources inside setup. Do not call
project() again or defer directory registration until after setup.

PRIVATE makes the include directory available to all sources of the target,
including root main.c, without exporting it to consumers. Common target settings
apply to added files, but C/C++/ASM may have different standards and flags.
Sharing one target does not guarantee ABI compatibility.

## Startup and backend

CMSIS startup/system filename interception operates on direct YAML sources entries.
Files added inside Core/CMakeLists.txt do not pass through that loop again. Check
the target and its dependencies before adding custom startup to avoid duplicates.
Without CMSIS the programmer provides startup and flags; Arduino uses Core and
wrappers. See [development](development.md).

## Checks and limits

| Test | Observable result |
| --- | --- |
| `configure.source-directory-target` | Nested C/C++ and root C belong to the main target; all three receive the common include path; C/C++ flags do not leak between languages. |
| `configure.source-missing-warning` | A missing file warns and is excluded from the existing source set. |
| `configure.source-directory-requires-cmake` | An existing directory without CMakeLists.txt fails Configure for the expected reason. |

[Manifest](../../tests/cases.json) · [Fixture](../../tests/fixtures/project/SourceGroup/CMakeLists.txt)

These tests inspect Configure/Generate and compile_commands.json. They do not
compile headers, link firmware, validate CMSIS startup or run code. Fix warnings
about required missing sources even when Configure succeeds. Main-target tests
do not replace checks of dependency/flag propagation into standalone libraries.

CMake 3.19 semantics: [target_sources](https://cmake.org/cmake/help/v3.19/command/target_sources.html),
[target_include_directories](https://cmake.org/cmake/help/v3.19/command/target_include_directories.html).
[Agent skill](../../skills/stm32-simple-sources/SKILL.md).
