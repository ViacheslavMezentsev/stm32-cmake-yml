# Arduino native firmware

Firmware of the Arduino `native` mode (spec 4.9.9–4.9.13, 4.9.18): the core
CMake files of the locked Arduino_Core_STM32 are added directly, the board is
selected by `mcu` (`board: auto`), the board variant linker script is used.

- `native` — the core `main()` with `setup()` and `loop()` (TC-73), every target;
- `nativeOwnMain` — the project `main()` calling `init()` and `initVariant()`,
  `Wire` from the core (TC-85), F103.

`ci/build_firmware_smoke.py` builds both on every tool pair and checks the ELF:
vector table, FLASH and RAM use, `main()`, `premain()` and the board ID. The
firmware does not run in QEMU or Renode yet: the core clock setup needs RCC and
PWR models (TC-86, after 0.10.0).
