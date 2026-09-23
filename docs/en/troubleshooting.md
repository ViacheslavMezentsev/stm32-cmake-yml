# Phase-specific troubleshooting

[Documentation](index.md) · [Русский](../ru/troubleshooting.md)

Find the first meaningful error and its command, then identify the phase.
A warning and a nonzero exit code are different observations. Preserve versions,
backend, profile, source/build paths and overrides. Do not change the toolchain
without reason when reproducing a failure.

| Phase | Inspect | Success does not prove |
| --- | --- | --- |
| Configure | YAML/IOC, paths, components, cache and CMake messages | Successful Ninja graph generation |
| Generate | Targets, generator expressions, properties and graph | Compilable sources |
| Compile | The specific C/C++/ASM command, includes, defines and CPU/ABI | Symbol resolution at link time |
| Link | Startup/ENTRY, symbols, archives, linker script and MEMORY | Correct MCU startup |
| Post-build | objcopy, CRC command, input/output files | Agreement with the bootloader's CRC check |
| Run | SP/PC, vectors, memory map and available core fault registers | A root cause without observations |

## Cache and reproduction

The author normally deletes the cache and reconfigures in VS Code after YAML
changes. This is a valid workflow. For stale-cache investigation, first preserve
the original command/log, then compare with a fresh build directory. Omitting -D
does not clear its value. Do not assume IDE file watchers are configured; run
Configure explicitly. See [development](development.md) and [semantics](reference/0.9.2/semantics.md).

## RAM and diagnostic switches

`validate_linker_script` sums recognized .ld RAM regions and compares them with
the MCU database. In 0.9.2 a mismatch does not stop Configure or establish that
heap+stack caused it. The check does not validate overlaps or SP. If RAM regions
are not recognized, it warns and skips the check; subsequent equality in the log
is not proof of script correctness. Arduino skips this mechanism.

`log_target_properties` prints properties, not every resolved compiler command.
`verbose_build` does not run a build. Inspect compile_commands.json for the
specific file, language and target. See [reference](reference/0.9.2/diagnostics.md).

## Specific messages

- Missing hal_conf.h at Configure: check use_hal/backend, family filename and target
  include paths. A compiler error about that file is Compile: inspect the actual
  command, including when it belongs to a separate library.
- Unresolved Reset_Handler at Link: inspect startup, ENTRY, symbols and link inputs.
  Do not enable CMSIS blindly or add a duplicate startup; bare metal may provide
  custom reset/vector code.
- FindFreeRTOS failure: investigate the exact line, arguments and versions. Windows
  backslashes are one hypothesis, not a universal diagnosis.
- HardFault needs execution evidence; Configure RAM output cannot establish its
  cause. Do not change heap/stack or MEMORY without evidence.
- CRC: read [E004](errata/E004.md) and [E006](errata/E006.md). A generated command
  does not prove successful execution; zero CRC alone is not an error.

## Automated coverage

| CTest (configure. prefix) | Expected result |
| --- | --- |
| diagnostics-toggle | Target-property output and the 128K > 20K comparison enable, disable and re-enable on repeated Configure; all three steps succeed. |
| diagnostics-unrecognized-ram | No recognized RAM regions: warning and successful Configure. |
| diagnostics-missing-hal-conf | HAL enabled without the configuration header in include paths: Configure fails for the expected reason. |

[Manifest](../../tests/cases.json) · [Running tests](testing.md).
Linker fixtures are synthetic configuration inputs, not firmware. Compile/Link/Run
advice above describes investigation directions, not automated coverage. Before
preparing or building firmware in this work, obtain the author's scenario guidance
as recorded in the [roadmap](../../TODO.md).
[Agent skill](../../skills/stm32-build-helper/SKILL.md).
