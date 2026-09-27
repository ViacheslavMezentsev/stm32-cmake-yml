# H7/H5 firmware (Renode only) / Прошивки H7/H5 (только Renode)

Minimal CMSIS firmware for families without the F103 smoke model (spec 8.8.5,
TC-57): `h7` (STM32H743ZI, core M7, stm32-cmake linker script) and `h5`
(STM32H563ZI, local template). `h503` and `h503bkp` (STM32H503CB) have the same
code and check the CRC image without and with initialized data in backup SRAM
(spec 4.15.9, TC-63). The templates are test-local, derived from
`../semihosting/STM32F103C8_FLASH.ld.in`, and define `_sstack`, which the CubeH5
startup needs. `ci/build_firmware_smoke.py` builds them on every tool pair, and
`ci/run_renode_smoke.py` runs them on the minimal `../renode/h7-smoke.repl` and
`../renode/h5-smoke.repl` models. QEMU has no machine with these cores and Flash
at `0x08000000`. Output uses semihosting SYS_WRITE0 and SYS_EXIT_EXTENDED.

Минимальные прошивки CMSIS для семейств без модели F103 (ТЗ 8.8.5, TC-57): `h7`
(STM32H743ZI, ядро M7, скрипт stm32-cmake) и `h5` (STM32H563ZI, локальный шаблон).
`h503` и `h503bkp` (STM32H503CB) имеют одинаковый код и проверяют образ CRC без
инициализированных данных в резервной SRAM и с ними (ТЗ 4.15.9, TC-63). Шаблоны
тестовые, получены из `../semihosting/STM32F103C8_FLASH.ld.in` и определяют
`_sstack`, которого требует startup CubeH5. `ci/build_firmware_smoke.py` собирает их
на каждой паре, `ci/run_renode_smoke.py` запускает на минимальных моделях
`../renode/h7-smoke.repl` и `../renode/h5-smoke.repl`. В QEMU нет машины с такими
ядрами и Flash по адресу `0x08000000`. Вывод — через semihosting SYS_WRITE0 и
SYS_EXIT_EXTENDED.
