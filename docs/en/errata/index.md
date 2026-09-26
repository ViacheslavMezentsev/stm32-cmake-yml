# Errata 0.9.2

[Documentation](../index.md) → Errata · [Русский](../../ru/errata/index.md)

Applies to baseline `f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0`. Status audited 2026-09-23. Fixed in a prepared commit does not mean merged or released. Entries remain after fixes.

| ID | Deviation | Status |
| --- | --- | --- |
| [E001](E001.md) | Derived values remain stale in cache | [PR #6](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/6), merged; release unknown |
| [E002](E002.md) | list does not read external profiles | [PR #6](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/6), merged; release unknown |
| [E003](E003.md) | Integer sizes only | Closed: by design |
| [E004](E004.md) | crc_algorithm does not select an algorithm | Fix prepared (`4cd3404`); not merged |
| [E005](E005.md) | Profile names without `_` | Closed: by design |
| [E006](E006.md) | CRC failure can exit successfully with a stub | Fix prepared (`4cd3404`); not merged |
| [E007](E007.md) | External FreeRTOS target namespace mismatch | Open; fix deferred |
| [E008](E008.md) | Profile-only language settings are not exported | Fix prepared (`d8708b4`); not merged |

[Reference](../reference/0.9.2/index.md) · [Maintenance](../maintenance.md)
