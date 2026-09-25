# Project and test status

[Documentation](index.md) · [README](../../README.en.md) · [Русский](../ru/status.md)

The reference and regressions describe **version 0.9.2**. This page records the
suite in this checkout and its scope. See [GitHub Actions](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/actions?query=branch%3Amain)
for current `main` results. README badges show workflow status, not passed-test counts.

## Configuration

<!-- configure-counts -->
**115 scenarios × 6 tool pairs = 690 configure executions**
<!-- /configure-counts -->

This is suite size, not the number of passing runs. CI verifies it against the
[manifest](../../tests/cases.json) and [lockfile](../../ci/dependencies.lock.json).
The matrix is xPack GCC 13.3.1-1.1, 14.2.1-1.1, 15.2.1-1.1 × CMake 3.19.8 and 3.28.3.

Checks cover Configure/Generate, profiles, precedence, IOC, components, sources
and diagnostics. Cases include F0/F1/F3/F4/F7/G4, bare metal and Arduino, but not
every MCU/option combination. Expected errors and known deviations are checked
explicitly. Successful configuration does not establish successful linking or
working firmware. [Coverage and commands](testing.md).

## Building and execution

A separate matrix contains **18 builds and 24 QEMU runs**: three profiles across
six tool pairs, plus one corrupted ELF copy per pair. It checks ELF layout,
initial data, C++ construction, metadata, software CRC and controlled termination;
negative cases distinguish guest failure from timeout.

The firmware targets STM32F103C8T6 and runs on QEMU 11.0.0 `netduino2`
(Cortex-M3/F205). This checks the selected startup path and image contents,
not F1 peripheral emulation. Renode has environment checks so far; running these
firmwares is the next stage. [Firmware contract](firmware-testing.md) ·
[QEMU/Renode environment](emulation.md).

## Documentation and further work

The validator checks links, bilingual option cards, errata and test mappings.
An option-to-test mapping identifies documented coverage, not proof of every
possible use. [Machine-readable index](../reference-index.json).

[Errata](errata/index.md) records limitations and workarounds; E004 (CRC algorithm
selection), E006 (CRC errors) and E007 (external FreeRTOS) remain open.
[TODO](../../TODO.md) tracks planned work and completed stages;
[maintenance rules](maintenance.md) explain how to update documentation and checks.
Public framework entry paths remain stable; tests are added without requiring
consumer projects to be restructured.
