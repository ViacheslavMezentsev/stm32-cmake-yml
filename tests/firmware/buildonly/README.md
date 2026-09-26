# Build-only firmware / Прошивки только для сборки

Minimal CMSIS firmware for families that QEMU and Renode do not model (spec 8.8.5,
TC-57): `h7` (STM32H743ZI, core M7, stm32-cmake linker script) and `h5`
(STM32H563ZI, local template). `h503` and `h503bkp` (STM32H503CB) check the CRC image
with and without initialized data in backup SRAM (spec 4.15.9, TC-63). The templates
are test-local, derived from `../semihosting/STM32F103C8_FLASH.ld.in`, and define
`_sstack`, which the CubeH5 startup needs. `ci/build_firmware_smoke.py` builds them
on every tool pair; nothing here is executed.

Минимальные прошивки CMSIS для семейств без моделей QEMU и Renode (ТЗ 8.8.5, TC-57):
`h7` (STM32H743ZI, ядро M7, скрипт stm32-cmake) и `h5` (STM32H563ZI, локальный шаблон).
`h503` и `h503bkp` (STM32H503CB) проверяют образ CRC без инициализированных данных в
резервной SRAM и с ними (ТЗ 4.15.9, TC-63). Шаблоны тестовые, получены из
`../semihosting/STM32F103C8_FLASH.ld.in` и определяют `_sstack`, которого требует
startup CubeH5. `ci/build_firmware_smoke.py` собирает их на каждой паре; здесь ничего
не запускается.
