# Migrating from 0.9.x to 0.10.0

[Documentation](index.md) → Migration · [Русский](../ru/migration-0.10.md)

This guide describes migration to 0.10.0. See the [roadmap](../../TODO.md)
for its status, the [changelog](../../CHANGELOG.en.md)
for all changes, and section 7.9 of the [specification](../TECHNICAL_SPECIFICATION.md)
for compatibility requirements.

## Migration sequence

1. Preserve a working project revision and pinned dependencies. If starting from
   0.9.2, also read the 0.9.3 changes and [errata](errata/index.md): those fixes
   are part of the migration.
2. Check `cmake --version`: **CMake ≥ 3.21** is required. Also check the executable
   selected by VS Code and your CI container. The project matrix tests 3.21.7 and
   3.28.3; migration alone does not require changing the compiler.
3. Start with a new build directory, such as `build/migration-010`.
   VS Code's “Delete Cache and Reconfigure” does not remove every old library
   directory and artifact. Keep the old directory for comparison if needed.
4. Verify configuration file and profile selection, then run Configure/Generate.
5. Review artifact paths and their consumers: VS Code, flashing, debugging, CI
   and archiving. Then build the project and verify the firmware.
6. Match diagnostics by code and attach the build directory's JSONL files when
   reporting a failure. Successful Configure alone does not prove a build or device run.

Update `stm32_cmake_yml_version` together with the actual framework version after
release. Do not change it early merely to suppress a version mismatch message.

## Configuration file and cache

Keep your existing `stm32_config.yml`. Without an explicit `PROJECT_CONFIG_FILE`,
the framework selects the only `stm32_config.yml`, `stm32_config.yaml` or
`stm32_config.toml` in the project root. Multiple candidates produce `SCY-E016`;
no candidate produces `SCY-E017`. Only lowercase `.yml`, `.yaml` and `.toml`
extensions are accepted; another extension produces `SCY-E015`.

An old cache may contain an explicit `PROJECT_CONFIG_FILE=stm32_config.yml`.
A new build directory avoids that entry; when reconfiguring, remove it with
`-UPROJECT_CONFIG_FILE` or restore discovery with `-DPROJECT_CONFIG_FILE=`.
A preset or CMakeLists that sets the variable again still takes effect.
An explicit path bypasses discovery; relative paths start at the project root.
See [formats](reference/0.9.2/formats.md).

`include` and the `_append` suffix outside profiles are now reserved. Rename
custom project keys using them for an unrelated purpose. TOML and splitting files
are optional. `stm32_config.effective.json` records the merged tree **before**
profiles, overrides, IOC and defaults; it does not describe final CMake target
properties. See [merge rules](reference/0.9.2/includes.md).

## Build directories and artifacts

Paths below are relative to the build directory. `<…>` denotes a placeholder.

| Case | 0.9.x | 0.10.0 |
| --- | --- | --- |
| External `sources` directory | `external_<sanitized-path>` | `_deps/<path>` without leading `..`, for example `_deps/modules/etl` |
| Arduino Core wrapper | `arduino_core` | Wrapper path relative to the project root, for example `Arduino/Core` |
| Arduino library | `arduino_lib_<name>` | Connected directory path; external paths go under `_deps` |
| Custom Arduino library | `arduino_custom_<sanitized-path>` | Project-relative path, for example `Arduino/libraries/Wire` |
| Root target `app`, Ninja, no output-name customization | `app.elf`, `app.bin`, `app.hex`, `app.lss`, `app.map` | Same names |
| `OUTPUT_NAME`, `OUTPUT_NAME_<CONFIG>`, `<CONFIG>_POSTFIX` | In particular, `lss`/`map` retained the target name | All requested artifacts use the final ELF basename |
| `RUNTIME_OUTPUT_DIRECTORY`, subdirectory target, Multi-Config | Some artifact locations could differ from the ELF location | `bin`, `hex`, `srec`, `lss`, `map` next to ELF, respecting the configuration |

Directory collisions receive a `-<4 SHA1 characters>` suffix. An internal
`_deps/…` path with external dependencies present can produce `SCY-E302`;
rename that project directory. Old directories are not cleaned automatically.
Avoid depending on internal `.o` paths in custom commands.

In custom CMake commands, express the HEX path for target `app` as:

```cmake
"$<TARGET_FILE_DIR:app>/$<TARGET_FILE_BASE_NAME:app>.hex"
```

If an external tool temporarily needs the old fixed MAP path, add a copy after
target setup (the `map` artifact must be enabled):

```cmake
add_custom_command(TARGET app POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "$<TARGET_FILE_DIR:app>/$<TARGET_FILE_BASE_NAME:app>.map"
        "${CMAKE_BINARY_DIR}/app.map"
    VERBATIM)
```

Add the command in the CMake directory that creates the target. Use separate copy
paths for concurrent configurations so Debug and Release cannot overwrite them.

## Diagnostics and Arduino

Messages are localized. Automation should use message codes and process exit
status instead of Russian text or the old `[CRC ERROR]` marker.
`-DSTM32_YML_MESSAGE_CODES=ON` shows codes in the console;
`-DSTM32_YML_LANG=ru` or `en` fixes the language. `stm32_yml_messages.jsonl`
contains Configure messages; `stm32_yml_build_messages.jsonl` contains build-time
CRC script messages, including `SCY-E708` on processing failure. These are not
logs of all compiler diagnostics. See the [message catalog](reference/0.9.2/messages.md).

Arduino still defaults to `wrappers`; migration to `native` is optional.
`Arduino::Options` and `Arduino::Platform` provide shared options and board
settings to wrappers. Remove custom flags only after verifying that the wrapper
actually uses these targets. `native` connects libraries differently and does not
use `core_cmake_dir` or `mcu_target`. With `use_core_main: false`, the application
remains responsible for initial setup. See the [Arduino guide](arduino.md).

## Unchanged limits and verification

Profile names still exclude `_`. Memory sizes use integers and supported `K`/`M`
suffixes, not `1.5K`. In bare metal without CMSIS, the developer supplies startup,
the vector table and required flags.

[Presets](presets.md) are shown together with YAML and CMakeLists: a preset selects
the environment and profile, YAML describes the configuration, and CMake connects
targets. There is no preset generator. [JSON Schema](schema.md) is an additional
L1 check, not part of Configure. Because custom keys are allowed, schema validation
does not detect every typo or prove that dependencies are available.

At the end of stage 4 (`e5d93c6`), all local L0–L5 levels passed: 1452 Configure
runs, 618 builds, 336 QEMU runs and 612 Renode runs. Firmware CI passed for the
same commit. This covers the specific matrix, not every user firmware or peripheral.
Arduino `native` is built but not yet executed in emulators because of RCC/PWR
limitations. See the [test method](firmware-testing.md) and [emulation limits](emulation.md).
Checks are repeated on the final release commit before publication.
