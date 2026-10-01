# Project and test status

[Documentation](index.md) · [README](../../README.en.md) · [Русский](../ru/status.md)

This page describes the test suite being prepared for **0.10.0**, rather than
only the published 0.9.3 release. The reference retains its 0.9.2 directory and
historical baseline, with separate 0.9.3 and 0.10.0 change notes. Release 0.10.0
is not complete; see the [roadmap](../../TODO.md) and [migration guide](migration-0.10.md). See [GitHub Actions](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/actions?query=branch%3Amain)
for current `main` results. The three status badges show latest completed workflows; Builds (Checks) shows the verified firmware matrix size.

## Configuration

<!-- configure-counts -->
**242 scenarios × 6 tool pairs = 1452 configure executions**
<!-- /configure-counts -->

This is suite size, not the number of passing runs. CI verifies it against the
[manifest](../../tests/cases.json) and [lockfile](../../ci/dependencies.lock.json).
The matrix is xPack GCC 13.3.1-1.1, 14.2.1-1.1, 15.2.1-1.1 × CMake 3.21.7 and 3.28.3.

Checks cover Configure/Generate, profiles, precedence, IOC, components, sources
and diagnostics. Cases include F0/F1/F3/F4/F7/G4/H5/H7 (including MCU core selection), the FreeRTOS
port table for C0/U0/L5/U5/WL, bare metal and Arduino, but not
every MCU/option combination. Expected errors and known deviations are checked
explicitly. Successful configuration does not establish successful linking or
working firmware. [Coverage and commands](testing.md).

## Building and execution

A separate matrix contains **618 builds, 336 QEMU runs and 612 Renode runs**: thirteen profiles for each of the F103, F030, F411, F401, G431, G474 and F746 targets (G4 and F7 in Renode only)
four H7/H5 ones (Renode only) and eight Arduino `native` firmwares (build only) across six tool pairs, plus one corrupted ELF copy per target and pair. It checks ELF layout,
initial data, C++ construction, metadata, software CRC and controlled termination;
negative cases distinguish guest failure from timeout.

QEMU 11.0.0 checks only F103 and F030 on `netduino2` (Cortex-M3/F205),
and F411/F401 on `netduinoplus2` (Cortex-M4F/F405). This checks the selected
startup path and image contents: for example, F030 runs on M3 instead of M0.
It does not verify the original MCU's peripherals.

Renode checks F103, F030, F411/F401, G431/G474, F746, H743 and H503/H563
on minimal family-specific CPU/NVIC/SysTick/memory models, with selected
register stubs and a semihosting exit adapter. G4, F7, H7 and H5 are not run in
QEMU. Arduino `native` is currently build-only; execution requires RCC/PWR
models. [Firmware contract](firmware-testing.md) ·
[Environment and models per family](emulation.md).

## Documentation and further work

The validator checks links, bilingual option cards, errata and test mappings.
An option-to-test mapping identifies documented coverage, not proof of every
possible use. [Machine-readable index](../reference-index.json).

[Errata](errata/index.md) records limitations and workarounds; fixes for E004 (CRC algorithm
selection), E006 (CRC errors), E007 (external FreeRTOS) and E008 (profile-only language settings),
like E001 and E002, are part of 0.9.3 ([changelog](../../CHANGELOG.en.md)).
[TODO](../../TODO.md) tracks planned work and completed stages;
[maintenance rules](maintenance.md) explain how to update documentation and checks.
Public framework entry paths remain stable; tests are added without requiring
consumer projects to be restructured.

## Confirmed build badge

The README `Builds (Checks)` badge reports built configurations and completed checks from the
last successful Firmware run on main. A full run currently gives
`Builds (Checks): 618 (948)`. Expected failure, timeout and CRC rejection count as
successful contract checks; this does not mean 948 normally exiting firmwares
or 618 different MCUs. Builds are counted once; QEMU and Renode checks are added (336 + 612).

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

[E008](errata/E008.md) records profile-only language settings; it is fixed in 0.9.3, the workaround is removed and the library firmware profiles work without root keys.

All four README badges use [Shields endpoints](https://shields.io/badges/endpoint-badge), sharing font, 20 px height and padding. Green PASS and the counter use #238636, matching the GitHub Code button in the supplied image. Errors show red FAIL; cancellation is CANCEL, skipping is SKIP and missing results are N/A.

Status badges show the latest **completed** run of each workflow on main. A lightweight Badges workflow refreshes JSON after Configure/Firmware/Docs completes; follow the badge link to inspect a currently running job. counts.json contains only the verified count from the last successful Firmware run. Status run URLs and SHAs are saved in workflow-status-report.json. Both publishers share the ci-badges concurrency group and preserve each other's files. No extra PAT is needed.
