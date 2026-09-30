# Configuration semantics 0.9.2

[Documentation](../../index.md) → [Reference](index.md) → Semantics · [Русский](../../../ru/reference/0.9.2/semantics.md)

## Version and contract boundary

This reference records version 0.9.2 as implemented in commit
`f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0`. This identifies the audited code;
it does not assert that a release tag exists. Audit date: 2026-09-22.
Status on 2026-09-27: E001/E002 fixes ([PR #6](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/6), merge `5711ec6`) and
E004, E006–E008 fixes ([PR #41](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/41), merge `29e64a4`) are part of release 0.9.3.
The reference baseline is unchanged; 0.9.3 differences are marked "Changed in 0.9.3"
in the cards. Version string `0.9.3` distinguishes the fixed implementation from the
0.9.2 baseline.

Cards describe supported intent and observed baseline behavior. Errata separately
records departures from expected results. Fixes do not rewrite 0.9.2 history.
Update the compatibility record for a new implementation; do not invent an
option's introduction version without historical evidence.

## Loading and precedence

The consumer includes `stm32_yml.cmake`, calls `stm32_yml_prepare_project_data`,
then `project()` with the returned name/languages, then `stm32_yml_setup_project`.
The project chooses its toolchain before `project()`. `yq` converts YAML to JSON;
CMake 3.19+ parses it. Card examples are fragments, not standalone firmware.

Precedence: defaults → IOC → YAML → selected profile → `STM32_YML_OVERRIDE_*`.
Implementation applies profiles and overrides before IOC; IOC fills remaining
undefined/empty values. Some defaults exist only in specific modes or when a
feature is enabled; there is no universal complete default configuration.

A profile key replaces its value; `<key>_append` extends the list after replacement.
The mechanism is not restricted to four list names and does not validate types.
Avoid ambiguous scalar-to-list transformations. An external profile file is a
profile source, not a promise of deep merging arbitrary configurations.

<a id="empty-values"></a>
## Missing, null, false, zero and empty lists

- Missing keys are not created by the parser. `key:` and `key: null` produce empty values.
- `false` and `0` survive and do not receive defaults merely because they are false-like.
- `[]` becomes an empty CMake list. For compile_definitions this clears the list;
  for languages and cppcheck_args/ignores it selects defaults. Behavior is option-specific.
- `key: auto` is special only where its consumer implements it.
- An empty `STM32_YML_OVERRIDE_*` is ignored; it is not a clearing operation.

Leave simple MCU names, paths and sizes unquoted: `mcu: STM32F103C8T6`,
`heap_size: 1K`. Quote values when YAML syntax or preserving a string type requires
it. Quotes do not disable subsequent CMake normalization.

## Types, names and validation

Card types describe the recommended input contract, not an already enforced
JSON Schema. Baseline has no general unknown-key or enum validation. In 0.9.3
unknown values of `toolchain_backend`, `system_library`, `cmsis_rtos_api`,
`freertos_version`, `crc_algorithm` and `build_artifacts` items warn (see cards);
unknown keys are still not checked. An unknown
key may be exported and ignored; Configure success does not detect every typo.
`arduino.core_path` denotes a nested `arduino:` YAML mapping, not a literal dotted
key. Objects flatten using `_`: `arduino: {core_path: ...}` becomes
`arduino_core_path`. Avoid nested/flat key collisions. Prefer lists of scalars.

Use ASCII letters/digits in profile names. `_` is outside the contract (E005), while
regex characters may alter selection because names are interpolated into a regex.
Flag strings are split on spaces and become CMake lists. Arbitrary shell quoting,
space escaping or semicolon escaping is not promised.

## Paths and phases

Most framework-owned file inputs are relative to the project root; sources use
the current source directory; include_directories follows CMake rules. The YAML
file's directory is not automatically the path base. Configure/Generate creates
the graph, `.ld` and commands. Compilation, linking, objcopy, Cppcheck and CRC run
later. IOC clocks, peripheral setup and hardware correctness are not established
by these configure tests.

## Cache and external controls

| Control (not a YAML option) | Contract |
| --- | --- |
| `PROJECT_CONFIG_FILE` | CACHE STRING, default `stm32_config.yml`; root-relative path |
| `STM32_YML_PROFILE` | CACHE STRING, empty = base; `list` prints names and ends Configure with an error |
| `STM32_YML_OVERRIDE_<param>` | Nonempty CACHE STRING scalar overriding the profile; nested names use `_` |
| `CMAKE_USER_HOME` | Environment variable locating STM32Cube/Repository |
| `CMAKE_TOOLCHAIN_FILE`, `STM32_TOOLCHAIN_PATH` | Consumer/toolchain inputs, not framework YAML options |
| `MCU`, `HEAP_SIZE`, `STACK_SIZE` | Derived cache entries; stale in 0.9.2 (E001), refreshed on every Configure since 0.9.3 (`HEAP_SIZE`/`STACK_SIZE` only for a `.ld.in` template) |
| `FREERTOS_PATH` | CMake or environment variable: FreeRTOS directory for `freertos_version: external` (0.9.3) |
| `ARDUINO_CORE_DIR`, `MCU_TARGET`, `USE_CORE_MAIN` | Outputs for Arduino wrappers; see cards for omission behavior |
| `STM32_YML_LANG` | CACHE STRING, default `auto`: message language `auto`, `ru`, `en` (synonyms `rus`, `eng`, case-insensitive). `auto` uses the first non-empty of `LC_ALL`, `LC_MESSAGES`, `LANG` except `C`/`POSIX`, on Windows the registry `LocaleName`; `ru…` selects Russian, anything else English. An unknown value warns and acts as `auto`. Change in 0.10.0 (spec 4.16.7) |
| `STM32_YML_MESSAGE_CODES` | CACHE BOOL, default `OFF`: `ON` starts every message line with its `[SCY-<code>]` code. Regardless of it, every Configure message is written to `stm32_yml_messages.jsonl` in the build directory (`code`, `level`, `lang`, `args`, `text`); CRC script messages at build time go to `stm32_yml_build_messages.jsonl` (texts for the script: `stm32_yml_build_messages.json`). [Code list](messages.md). Change in 0.10.0 (spec 4.16.9–4.16.11) |

Omitting `-D` on the next command does not delete the cache entry. Remove one with
`-USTM32_YML_OVERRIDE_stack_size`; reset the profile with `-DSTM32_YML_PROFILE=`.
Baseline 0.9.2 needs a fresh build tree when MCU/memory values change (E001).
Even with the fixes, toolchain changes require a separate build directory.

## Compatibility and evidence

Automated tests cover specific scenarios, not every sentence of a card. Mappings
are in the [machine-readable index](../../../reference-index.json). No test means
no automated coverage, not a known defect. Errata separately states its evidence.
Target names, MCU families and library versions also depend on pinned external
dependencies; this reference does not promise arbitrary Cube/Arduino/stm32-cmake
combinations will work.
