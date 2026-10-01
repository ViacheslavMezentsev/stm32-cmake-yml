# Formats and file selection — 0.10.0

[Reference](index.md) · [Русский](../../../ru/reference/0.9.2/formats.md)

<a id="project-config-file"></a>
## `PROJECT_CONFIG_FILE`

A CMake control variable, not a YAML key. **Type:** path; **default since 0.10.0:**
empty string (discovery).

Without an explicit path, only `stm32_config.yml`, `stm32_config.yaml` and
`stm32_config.toml` in the project root are considered. One file selects it;
multiple files produce `SCY-E016` with their names; none produces `SCY-E017`.
There is no extension priority. Adding or removing a candidate triggers
reconfiguration on the next build (CMake `CONFIGURE_DEPENDS`); changes to the
selected file are tracked as well.

```powershell
cmake -S . -B build -DPROJECT_CONFIG_FILE=config/application.toml
```

An explicit nonempty path bypasses discovery even with several root candidates.
Relative paths start at the project root; absolute paths are also supported.
A missing explicitly selected file produces `SCY-E004`.

The discovered name is not cached: discovery repeats on each Configure.
An explicit cached path persists under normal CMake rules. To restore discovery:

```powershell
cmake -S . -B build -DPROJECT_CONFIG_FILE=
```

Alternatively use `-UPROJECT_CONFIG_FILE` or clear the cache.
**Upgrading from 0.9.3:** an old cached `stm32_config.yml` counts as explicit;
clear it to discover `.yaml`/`.toml`. A normal variable assigned by the caller's
`set(PROJECT_CONFIG_FILE ...)` is respected too.

## YAML and TOML

The main file, each include and `profiles_file` select their parser by their own
extension: `.yml`/`.yaml` for YAML, `.toml` for TOML. Other extensions, including
`.json`, `.cfg` and uppercase variants, fail with `SCY-E015`. This differs from
0.9.3, where yq could read files with arbitrary extensions.
Invalid TOML syntax produces `SCY-E005` with yq diagnostics. Tested with Mike Farah yq 4.44.3.

```toml
include = "common.yml"
project_name = "telemetry"
mcu = "STM32F103C8T6"
sources = ["main.c"]
use_cmsis = false
use_hal = false

[profiles.Debug]
stack_size = "2K"
compile_definitions_append = ["TRACE=1"]
```

Formats may be mixed in an include chain. Both convert to JSON and share
[merge rules](includes.md), profiles and overrides. TOML strings require quotes;
`[profiles.Debug]` corresponds to a nested YAML object.
TOML has no `null`: empty strings and arrays follow the
[common rules](semantics.md#empty-values), rather than being universal null substitutes.
In particular, an empty `_append` array does not clear accumulated profile additions.

An external `profiles_file` may be TOML; only `profiles` is read, with all other
keys (including `include`) ignored. Existing limits on flattening, profile names,
flags and integer memory sizes apply. Changing format does not enable CMSIS,
HAL or another backend by itself.

**Spec:** 3.1.5, 3.8, TC-80/TC-81. **Checks:** 19 `configure.formats-*` cases in the
[manifest](../../../../tests/cases.json): YAML/TOML equivalence, profiles, external
list, mixed chains, empty values, invalid formats and syntax, discovery, explicit
selection, cache handling and Ninja regeneration without firmware compilation.
