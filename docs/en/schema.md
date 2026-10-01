# Configuration JSON Schema

[Documentation](index.md) · [Русский](../ru/schema.md)

Starting with 0.10.0, the repository provides a
[schema](../../schema/stm32-config.schema.json) for configuration structure checks.
It uses JSON Schema [Draft 2020-12](https://json-schema.org/draft/2020-12/json-schema-validation).
The framework does not run it during Configure or require schema Python packages
in consumer projects. Editor integration is left to the developer.

The schema checks known types and enumerations, integer memory sizes, `arduino`,
`stm32_cmake_yml`, `crc`, `cppcheck`, profile names without `_`, `include` and
`_append` values. Nested and flattened forms of known keys are explicit.
Unknown keys remain allowed for project-specific settings, so passing validation
does not guarantee that key names contain no typos.

Missing keys, `null`, empty strings and empty arrays are allowed; no defaults
are inserted. Included files may contain partial configurations. Validation does
not merge includes, activate profiles, apply overrides or read IOC. It does not
check file existence, MCU/library availability, flattened-name collisions, linker
scripts, compilers or build success. Configure/Generate and firmware tests remain
responsible for those checks.

The schema describes supported values: an unknown backend fails L1 even when
Configure can warn and use a default. These are different checks. Regression
fixtures for such behavior get an exception for the specific key, without
disabling validation of the entire file.

## Source and generation

The [reference index](../reference-index.json) is the source. `yaml_paths` lists
paths through the YAML tree; `schema` provides types and constraints. The `type`
description remains human-readable text; the generator does not infer enums
from that prose. Do not edit the generated file manually.

```sh
python ci/config_schema.py
python ci/config_schema.py --check
```

Generation uses the Python standard library. L1 validation requires Python 3.11+
and the packages in [schema-requirements.txt](../../ci/schema-requirements.txt):

```sh
python -m venv build/schema-venv
# Windows:
build/schema-venv/Scripts/python.exe -m pip install -r ci/schema-requirements.txt
build/schema-venv/Scripts/python.exe ci/check_schema.py
build/schema-venv/Scripts/python.exe -m unittest discover -s tests -p test_config_schema.py
# Linux: use build/schema-venv/bin/python instead of build/schema-venv/Scripts/python.exe
```

The checker reads YAML 1.2 with ruamel.yaml and TOML with `tomllib`. Configure
continues to use pinned yq; L1 does not replace framework parser tests.
Preset tests also require CMake >= 3.21 and Ninja.

## CI coverage

The Docs workflow checks schema/index consistency, validates the schema against
its meta-schema, and validates:

- YAML/TOML under `tests/fixtures` and `tests/firmware`;
- YAML/TOML content written through `write_files` in reconfiguration scenarios;
- YAML in the [paired presets example](presets.md).

[schema-exceptions.json](../../tests/schema-exceptions.json) records deliberately
invalid values by file and JSON Pointer, with a reason. Syntax errors use
`<parse>`. Unexpected errors, expected errors that no longer occur, and exceptions
for deleted files fail L1. Other values in the same file remain checked.
Command-line cache overrides and configurations generated programmatically by
the firmware runner are outside this file-validation pass.

The preset example is also tested with CMake on a small language-free project:
all four variants select the expected YAML profile, configuration and build
directory. This checks preset wiring; it is not an Arduino firmware build.
