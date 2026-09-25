# Project and test status

[Documentation](index.md) · [README](../../README.en.md) · [Русский](../ru/status.md)

The reference and regressions describe **version 0.9.2**. This page records the
suite in this checkout and its scope. See [GitHub Actions](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/actions?query=branch%3Amain)
for current `main` results. The three status badges show latest completed workflows; Builds (Checks) shows the verified firmware matrix size.

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

A separate matrix contains **72 builds, 78 QEMU runs and 78 Renode runs**: twelve profiles across
six tool pairs, plus one corrupted ELF copy per pair. It checks ELF layout,
initial data, C++ construction, metadata, software CRC and controlled termination;
negative cases distinguish guest failure from timeout.

The firmware targets STM32F103C8T6 and runs on QEMU 11.0.0 `netduino2`
(Cortex-M3/F205). This checks the selected startup path and image contents,
not F1 peripheral emulation. Renode checks the same ELFs on the f103-smoke CPU/NVIC/SysTick/memory model
with RCC/FLASH controller stubs and a semihosting exit adapter. [Firmware contract](firmware-testing.md) ·
[QEMU/Renode environment](emulation.md).

## Documentation and further work

The validator checks links, bilingual option cards, errata and test mappings.
An option-to-test mapping identifies documented coverage, not proof of every
possible use. [Machine-readable index](../reference-index.json).

[Errata](errata/index.md) records limitations and workarounds; E004 (CRC algorithm
selection), E006 (CRC errors), E007 (external FreeRTOS) and E008 (profile-only language settings) remain open.
[TODO](../../TODO.md) tracks planned work and completed stages;
[maintenance rules](maintenance.md) explain how to update documentation and checks.
Public framework entry paths remain stable; tests are added without requiring
consumer projects to be restructured.

## Confirmed build badge

The README `Builds (Checks)` badge reports built configurations and completed checks from the
last successful Firmware run on main. A full run currently gives
`Builds (Checks): 72 (156)`. Expected failure, timeout and CRC rejection count as
successful contract checks; this does not mean 156 normally exiting firmwares
or 72 different MCUs. Builds are counted once; QEMU and Renode checks are added (78 + 78).

Counts come from complete matching build/QEMU/Renode reports, checked for clean checkout
SHA, matrix membership, results and metadata. Codex branches produce a preview
artifact but do not update the public badge. After main succeeds, a separate job
with contents: write publishes SVG and JSON to the dedicated ci-badges branch.
It does not change sources or main. No extra PAT or Pages setup is needed.

Failures/cancellations retain the last successful result; the adjacent Firmware
badge shows current workflow status. Clicking the counter opens JSON containing
SHA, time and a run link. GitHub image caching may delay refreshes. The image is
unavailable until the first successful main run with this workflow. Branch rules
must allow GITHUB_TOKEN writes to ci-badges. Runs for an older main are skipped.

[E008](errata/E008.md) records profile-only language settings; firmware tests verify the root-key workaround and reproduce the limitation.

All four README badges use [Shields endpoints](https://shields.io/badges/endpoint-badge), sharing font, 20 px height and padding. Green PASS and the counter use #238636, matching the GitHub Code button in the supplied image. Errors show red FAIL; cancellation is CANCEL, skipping is SKIP and missing results are N/A.

Status badges show the latest **completed** run of each workflow on main. A lightweight Badges workflow refreshes JSON after Configure/Firmware/Docs completes; follow the badge link to inspect a currently running job. counts.json contains only the verified count from the last successful Firmware run. Status run URLs and SHAs are saved in workflow-status-report.json. Both publishers share the ci-badges concurrency group and preserve each other's files. No extra PAT is needed.
