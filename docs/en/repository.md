# Repository structure and skills

[Documentation](index.md) · [Русский](../ru/repository.md)

`stm32_yml.cmake` is the consumer entry point. The cmake/ modules handle configuration,
profiles, Arduino integration, dependencies, sources, linking, post-build actions,
diagnostics and code quality. scripts/stm32_crc.py computes CRC data for post-build
processing. tests/ holds configure fixtures and CTest; ci/ holds Docker and checks.

Documentation lives under docs/ru and docs/en. docs/reference-index.json maps
options to their reference cards, tests and errata. The existing Russian scenario
manual remains at [docs/user_manual.md](../user_manual.md).

## Agent skills

| Skill | Scope |
| --- | --- |
| [stm32-config-manager](../../skills/stm32-config-manager/SKILL.md) | YAML configuration guided by the shared reference and errata |
| [stm32-simple-sources](../../skills/stm32-simple-sources/SKILL.md) | Source integration verified through compile commands; [guide](simple-sources.md) |
| [stm32-module-creator](../../skills/stm32-module-creator/SKILL.md) | Consumer libraries verified through dependency/flag scenarios; [guide](modules.md) |
| [stm32-build-helper](../../skills/stm32-build-helper/SKILL.md) | Phase-specific diagnostics and tested Configure messages; [guide](troubleshooting.md) |

Pass the relevant SKILL.md to an assistant using the mechanism supported by your
tool. Reading instructions does not guarantee tool compatibility or correct code.
All four skills are aligned with the reference within their documented coverage. Update them incrementally using demonstrated behavior; current Configure
tests do not establish ABI compatibility, successful linking or runtime correctness.
See the [roadmap](../../TODO.md) and [maintenance rules](maintenance.md).

## Acknowledgements

CMake module architecture and codebase refactoring were developed together with
AI assistants (Google Gemini and Anthropic Claude).
