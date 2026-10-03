# Errata

[Documentation](../index.md) → Errata · [Русский](../../ru/errata/index.md)

Applies to baseline `f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0`. Status audited 2026-09-27 for the 0.9.3 release. Entries remain after fixes.

| ID | Deviation | Status |
| --- | --- | --- |
| [E001](E001.md) | Derived values remain stale in cache | Fixed in 0.9.3 ([PR #6](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/6)) |
| [E002](E002.md) | list does not read external profiles | Fixed in 0.9.3 ([PR #6](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/6)) |
| [E003](E003.md) | Integer sizes only | Closed: by design |
| [E004](E004.md) | crc_algorithm does not select an algorithm | Fixed in 0.9.3 ([PR #41](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/41), `4cd3404`) |
| [E005](E005.md) | Profile names without `_` | Closed: by design |
| [E006](E006.md) | CRC failure can exit successfully with a stub | Fixed in 0.9.3 ([PR #41](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/41), `4cd3404`) |
| [E007](E007.md) | External FreeRTOS target namespace mismatch | Fixed in 0.9.3 ([PR #41](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/41), `3c6bfa3`, `2f742ff`) |
| [E008](E008.md) | Profile-only language settings are not exported | Fixed in 0.9.3 ([PR #41](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/41), `d8708b4`) |

[Reference](../reference/0.9.2/index.md) · [Maintenance](../maintenance.md)

Addition for 0.10.0, checked 2026-10-02.

| ID | Issue | Status |
| --- | --- | --- |
| [E009](E009.md) | Python CRC/BIN diagnostic encoding | Fixed in 0.10.1 |
| [E010](E010.md) | Absolute sources on another drive | Fixed in main; intended for 0.10.2, not released |
