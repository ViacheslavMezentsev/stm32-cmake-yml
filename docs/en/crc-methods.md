# CRC32 method and image layout

[Documentation](index.md) · [Русский](../ru/crc-methods.md) · [CRC options](reference/0.9.2/postbuild.md#crc-method)

For 0.10.1, `crc_method: auto` preserves existing calculation and injection.
A method combines the algorithm, protected range and result placement;
`crc_algorithm` selects only the algorithm and `crc_section_name` names the section.
Missing, null, empty and none methods mean auto. Disable CRC with `crc_enable: false`.

## Algorithm

| Property | Value |
| --- | --- |
| Polynomial | `0x04C11DB7` |
| Initial register | `0xFFFFFFFF` for each independent calculation |
| Input | 32-bit words assembled from four little-endian bytes |
| Processing | Most significant bit first, no input/output reflection |
| Final XOR | None |
| Stored CRC | Four little-endian bytes |

This is `STM32_HW_DEFAULT`, not zlib's standard CRC32. Bytes `78 56 34 12`
form the word `0x12345678`; its CRC is `0xDF8A8A2B`, stored as `2B 8A 8A DF`.
For word zero the result is `0xC704DD7B`; for words `0x12345678`, `0x9ABCDEF0`
it is `0x7D24A31B`. Host tests and firmware static assertions check these vectors.

A hardware peripheral must process these exact words and parameters. Where
configurable, select the default polynomial and initial value, no inversion or
reflection, and word input. The application supplies clocking and initialization.
Reset CRC state before an independent calculation; an API accepting a word count
needs byte length / 4. Simulator checks use a software equivalent, not a CRC peripheral.

## Sections and length field

Recommended layout for auto:

```text
image start = __checksum_start
  vector table
  align to 4 → LONG(__checksum_size)
  code, constants, init arrays and other FLASH content
  .data load copy (RAM VMA, FLASH LMA)
  metadata, including .fw_version if needed
  align to 4
protected range end = __checksum_end
  four CRC bytes in crc_section_name
image end = __checksum_end + 4
```

This is **load address (LMA)** order, not merely VMA or linker script line order.
Place CRC after every section occupying FLASH, including `.data` with `AT> FLASH`.
A content-free `.bss` is not part of the image. Further loadable FLASH sections
after CRC violate this layout.

User linker script excerpts (not a complete script):

```ld
.isr_vector :
{
  . = ALIGN(4);
  __checksum_start = .;
  KEEP(*(.isr_vector))
  . = ALIGN(4);
  __checksum_length_field = .;
  LONG(__checksum_size)
} >FLASH

/* All remaining FLASH LMA sections here, including .data AT> FLASH. */
.checksum :
{
  . = ALIGN(4);
  __checksum_end = .;
  LONG(0)
} >FLASH
__checksum_size = __checksum_end - __checksum_start;
```

`__checksum_length_field` is an example/test symbol, not a framework requirement.
The field contains the **value** of `__checksum_size`, not its own address or a
placeholder. The length field itself is protected. The length excludes the four
CRC bytes; total image length is `__checksum_size + 4`.

There is no universal offset from image start: vector table sizes depend on MCU
and startup. Define field discovery explicitly for your image format; tests obtain
its address from the ELF symbol. Additional code alignment, such as ALIGN(16), goes
**after** LONG. Test scripts materialize padding before FreeRTOS port code this way;
that alignment is not a CRC algorithm requirement.

## Build-time range

The script reads ELF sections with content whose LMA is in the final linker
script's FLASH region, excluding `crc_section_name`. The range extends from the
lowest LMA to the end of the last selected section; gaps are filled with `0xFF`.
A partial final word is padded with `0xFF` too. For this layout the range must equal
`[__checksum_start, __checksum_end)` and contain whole words.

Linker symbols alone do not control the Python script's range. Inspect the memory
map, ELF sections, `*_no_crc.bin` and final BIN: bytes read from FLASH gaps must
match those used for calculation. Load image holes and linker-generated fill are
not necessarily equivalent.

`crc_method: auto` does not move sections, insert the length field or validate
the entire layout contract. Configure's reminder is not an ELF validation result.
Existing projects without a length field still build; the field belongs to the
user-defined image format. Custom section names work when YAML and linker script
agree; these have separate post-build checks.

## Reading and two checks

For this layout firmware can access section addresses and the stored length:

```cpp
extern "C" uint32_t __checksum_start[], __checksum_end[];
extern "C" uint32_t __checksum_length_field[];

const uintptr_t begin = reinterpret_cast<uintptr_t>(__checksum_start);
const uintptr_t end = reinterpret_cast<uintptr_t>(__checksum_end);
const uint32_t length = __checksum_length_field[0];
const uint32_t stored = __checksum_end[0];
// First validate bounds, alignment and length == end - begin.
```

`__checksum_size` is an absolute linker symbol, not a memory variable. When declared
as an external symbol, its numeric value is obtained from its address; dereferencing
that address does not read the length. For a received image, validate buffer bounds
before reading fields; an untrusted length must not drive an unbounded read.

With matching ranges there are two equivalent criteria:

1. CRC of `length / 4` words starting from `0xFFFFFFFF` equals `stored`.
2. CRC of those words **plus the following stored word**, using the same initial
   value and algorithm, equals zero.

The second follows from the algorithm step: XOR of the current register with an
identical word produces zero. Read the stored little-endian bytes back as the same
32-bit word. A zero-residue check does not automatically apply to other algorithms,
byte orders or peripheral settings. CRC detects corruption; it is not a cryptographic signature.

## Coverage

Existing semihosting firmware for F0/F1/F4/G4/F7 (seven targets) includes the length
field in both `.ld` and `.ld.in`. The host independently checks the field, CRC
placement, ELF/BIN bytes and residue. Firmware checks the length, CRC and zero
residue in software; QEMU/Renode runners compare these metadata values. A corrupted
`.fw_version` must produce a nonzero residue and the existing controlled failure.
A host regression also rejects a wrong length even after CRC is recomputed.

Build/run counts stay unchanged. H5/H7 build-only and native scenarios do not gain
this field; their formats and earlier checks remain separate. These tests do not
validate a hardware CRC block, peripherals or a bootloader. Actual run status is
in the [roadmap](../../TODO.md); see [firmware testing](firmware-testing.md) for methodology.
