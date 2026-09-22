# Artifacts and CRC

[Documentation](../../index.md) → [Reference 0.9.2](index.md) → Artifacts and CRC · [Русский](../../../ru/reference/0.9.2/postbuild.md)

Shared rules: [semantics](semantics.md). Baseline: `f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0`. Introduction history before 0.9.2 is not established; presence is confirmed in this baseline. Unless stated otherwise, configuration happens at Configure/Generate and actual commands execute at Build/Post-build.

<a id="build-artifacts"></a>
## `build_artifacts`

`CFG-BUILD-ARTIFACTS` · **Type:** list: bin / hex / map / lss · **Default:** []

bin/hex/lss add post-build conversions; map adds a linker flag. An empty list does not disable the main target or size output. Unknown items are ignored. The toolchain must provide bin/hex/size helpers and required utilities.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
build_artifacts: [bin, hex, map, lss]
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_postbuild.cmake) · [Index](index.md)

**Checks (partial coverage):** no automated check of this contract. [Test manifest](../../../../tests/cases.json).

<a id="crc-enable"></a>
## `crc_enable`

`CFG-CRC-ENABLE` · **Type:** boolean · **Default:** false

Configures CRC-section removal from an intermediate BIN, Python computation and ELF update-section after linking. Needs Python3, objcopy, the CRC script and a suitable .ld. Missing prerequisites can disable CRC with a warning. Configure success does not prove CRC correctness or that the ELF contains the section.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
crc_enable: false
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_postbuild.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.crc-command-generation`, `configure.defaults-blackpill`. [Test manifest](../../../../tests/cases.json).

**Errata:** [E006](../../errata/E006.md).

<a id="crc-section-name"></a>
## `crc_section_name`

`CFG-CRC-SECTION-NAME` · **Type:** string: section name · **Default:** .checksum when CRC enabled

Section removed from the BIN and updated in the ELF. It must actually exist and hold four bytes; the framework neither creates it nor validates placement. Exclude it from the computed region.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
crc_section_name: .checksum
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_postbuild.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.crc-command-generation`. [Test manifest](../../../../tests/cases.json).

<a id="crc-algorithm"></a>
## `crc_algorithm`

`CFG-CRC-ALGORITHM` · **Type:** string: STM32_HW_DEFAULT · **Default:** STM32_HW_DEFAULT when CRC enabled

In 0.9.2 this is only printed in the log. It is not passed to Python and does not select an algorithm; another name does not implement another CRC. The script is fixed: poly 0x04C11DB7, init 0xFFFFFFFF, little-endian words, partial words padded with FF, no final XOR.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
crc_algorithm: STM32_HW_DEFAULT
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_postbuild.cmake) · [Index](index.md)

**Checks (partial coverage):** no automated check of this contract. [Test manifest](../../../../tests/cases.json).

**Errata:** [E004](../../errata/E004.md).

<a id="flash-size"></a>
## `flash_size`

`CFG-FLASH-SIZE` · **Type:** integer bytes / string K or M / auto · **Default:** auto

With CRC, limits intermediate BIN size. auto uses the MCU database or a FLASH...LENGTH line in the Arduino .ld. This is a guard, not a MEMORY change or padding length. Suffixes are uppercased; use nonnegative integer sizes.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
flash_size: 64K
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_postbuild.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.crc-command-generation`. [Test manifest](../../../../tests/cases.json).

**Errata:** [E006](../../errata/E006.md).
