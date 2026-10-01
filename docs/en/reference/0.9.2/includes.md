# Configuration includes — 0.10.0

[Reference](index.md) · [Русский](../../../ru/reference/0.9.2/includes.md)

<a id="include"></a>
## `include`

`CFG-INCLUDE` · **Type:** path or list of paths · **Default:** no includes

**Since 0.10.0 (unreleased).** YAML and TOML includes are supported, including mixed chains.
[Formats and file selection](formats.md).
In 0.9.2/0.9.3 this key does not load files.

```yaml
include:
  - config/common.yml
  - config/board.yml
project_name: telemetry
compile_definitions_append:
  - TELEMETRY=1
profiles:
  Debug:
    compile_definitions_append:
      - TRACE=1
```

Include paths are relative to the file declaring them. Other project paths
(`sources`, `linker_script`, `profiles_file`, etc.) retain their existing base,
the project root; the fragment directory does not become their base.
Included files can include other files. Their children are processed first,
then the file itself. Siblings follow list order; the main file is applied last.
Repeated includes outside the active chain are allowed and repeat operations,
including additions; duplicate values are retained.

Merge rules, before flattening into CMake variables:

- Objects merge recursively; profiles merge by their exact names.
- Scalars and lists replace existing values. `null` clears an inherited value.
- Outside `profiles`, `<key>_append` adds elements to the `<key>` list.
  Replacements precede additions within each file regardless of key order.
  The `_append` suffix is reserved for custom keys as well.
  Additions accept arrays; `null` and an empty string add nothing.
  The base must be an array, missing, `null`, or an empty string; other types fail with `SCY-E013`.
- Inside a profile, `_append` arrays accumulate across files and are applied
  only when that profile is activated. Replacing an ordinary profile list
  does not discard accumulated `_append`; use `_append: null` to clear it.
  An empty array does not discard accumulated additions.

Missing `include`, `null`, an empty string and `[]` mean no includes.
Each element of a nonempty list must be a nonempty string. Invalid types produce
`SCY-E012`, missing files `SCY-E010`, cycles `SCY-E011`; the latter two messages
include the file chain. Every file must contain a single configuration object
(`SCY-E014`). All files read are registered as Configure dependencies.

### What effective.json contains

`build/stm32_config.effective.json` is the merged tree **before** profile
selection, overrides, IOC processing and defaults. JSON preserves types,
`null`, empty arrays and all inline profiles. The top-level control key `include`
is removed; this is not a report of final target flags.
The file is rewritten on Configure; a loading failure removes the previous file.

`profiles_file` remains a separate mechanism: only its `profiles` section is read,
with existing rules for replacing inline profiles. Its `include` is ignored;
external profiles do not appear in effective.json. See [profiles](profiles.md).

**Contract:** spec 3.8; existing [flattening and value limitations](semantics.md) apply.
**Implementation:** [include module](../../../../cmake/stm32_yml_include.cmake).
**Checks:** 16 `configure.include-*` cases in the [manifest](../../../../tests/cases.json):
merge order, profiles and overrides, null, repeated includes, replace/append,
external profiles, Configure dependencies, reconfiguration and errors.
Mixed formats are covered by `configure.formats-mixed-profile` and
`configure.formats-toml-empty-reset` (TC-80/TC-81).
