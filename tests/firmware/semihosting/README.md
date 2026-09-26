# Semihosting smoke fixture / Первый тест прошивки

Adapted from the author's [02-semihosting example](https://github.com/ViacheslavMezentsev/demo-stm32-cmake/tree/main/stm32f1xx/02-semihosting).
The original local project was read only. [source-hashes.json](source-hashes.json)
records input hashes before adaptation; it does not claim a matching remote commit.
ST copyright/license notices in copied files are retained.

Inputs with unchanged logic (whitespace normalized): system_stm32f1xx.c, stm32f1xx_hal_conf.h, version.h. The test
CMakeLists accepts external framework/toolchain paths. YAML is reduced to the
same essential settings, explicitly selects framework 0.9.3 and CubeF1 1.8.7,
and adds success/failure/hang profiles. main.cpp retains formatted semihosting output,
HAL_Init, version and CPUID output. Its endless HAL_Delay loop is replaced with
immediate SYS_WRITE0 protocol markers and SYS_EXIT_EXTENDED, or an intentional hang.

The MCU build target is STM32F103C8T6 (64 KiB FLASH, 20 KiB RAM). netduino2 models
STM32F205/Cortex-M3; this test does not validate F1 peripheral behavior. The
supplied SystemInit does not configure PLL in this configuration. Its software
SystemCoreClock value is 16 MHz; no clock frequency or HAL tick accuracy is asserted.
CRC is enabled with a test-local linker script; metadata, initial memory and loaded FLASH CRC are checked.

Адаптировано из примера автора; исходный проект не изменялся. Хеши входных файлов
сохранены до адаптации. system_stm32f1xx.c, stm32f1xx_hal_conf.h и version.h
скопированы без изменения логики; нормализованы пробелы и окончания строк.
CMake получает пути извне, YAML закрепляет версии и три профиля. main.cpp сохраняет
форматированный вывод через SYS_WRITE0, HAL_Init, версии и CPUID; бесконечный цикл заменён
маркерами и управляемым выходом либо намеренным зависанием.

Собирается STM32F103C8T6, запускается на netduino2 (F205/Cortex-M3). Периферия F1
не проверяется. PLL в выбранном пути SystemInit не настраивается; программное
SystemCoreClock равно 16 МГц, точность частоты и HAL tick не проверяется. CRC
включён с тестовым скриптом линкера; проверяются метаданные, начальное состояние памяти и CRC загруженной FLASH. Подробный контракт запуска: [RU](../../../docs/ru/firmware-testing.md) /
[EN](../../../docs/en/firmware-testing.md).

Matrix compatibility: C11 for CMake 3.19; C++17 retained.
Совместимость матрицы: C11 для CMake 3.19; C++17 сохранён.

Metadata fields come from a generated build_metadata.h and runtime library macros.
expected-metadata.json pins the reviewed library versions and probe values. nm
addresses are compared with runtime output. Git revision/dirty are diagnostic
provenance, not a digest of the full source tree.

Поля метаданных получаются из build_metadata.h и макросов библиотек. Версии и
значения переменных закреплены в expected-metadata.json; адреса nm сравниваются
с выводом прошивки. Git revision/dirty не заменяют хеш всего дерева исходников.

The same ELF runs on QEMU and Renode; the Renode exit hook is a test adapter, not peripheral emulation.
Один ELF запускается в QEMU и Renode; hook выхода Renode — адаптер теста, не эмуляция периферии.

Build-mode profiles / Профили режимов сборки:

- `bare`, `bareTemplate`: test-owned `bare_startup.S`, no CMSIS/HAL, explicit CPU
  flags; собственный startup без CMSIS/HAL и явные флаги ядра.
- `cmsis`, `cmsisTemplate`: CMSIS startup, no HAL; startup CMSIS без HAL.
- `Template`: auto discovery of `.ld.in`, heap=0, stack=2K; автопоиск `.ld.in`.
  Other profiles use explicit `.ld`, heap=512, stack=1K; остальные — явный `.ld`.

The startup assembly and linker template are test-owned additions, not copied
inputs covered by source-hashes.json. HAL_Init and HAL version output are now
conditional; all profiles retain data/constructor/CRC and semihosting checks.
Ассемблерный startup и шаблон линкера добавлены для теста, не входят в исходные
хеши source-hashes.json. HAL_Init и версии HAL теперь условные; проверки памяти,
конструктора, CRC и semihosting сохранены для всех профилей.

Library profiles / Библиотечные профили:

`cmsisLibrary` runs a test-owned mixed C/C++ static library. `cmsisEtl` adds
vector/string operations using pinned ETL. Their code is new, not copied from the
demo inputs. Both use CMSIS without HAL and set language keys only in the profile (E008 fixed). Details:
[EN](../../../docs/en/firmware-testing.md) / [RU](../../../docs/ru/firmware-testing.md).

`cmsisLibrary` запускает новую тестовую C/C++-библиотеку, `cmsisEtl` добавляет
операции vector/string закреплённой ETL. Код написан для теста, не скопирован из
исходного demo. Оба профиля используют CMSIS без HAL и задают языковые ключи только в профиле (E008 исправлена); подробности по ссылкам выше.

`arduinoString` builds original WString.cpp/itoa.c from pinned Arduino Core 2.12.0
with a consumer-owned wrapper and standalone toolchain. It uses own main/startup,
a bounded heap and the existing semihosting protocol; it is not a full board core.
`arduinoString` собирает настоящие WString.cpp/itoa.c из Core 2.12.0 через свою
обёртку и отдельный toolchain: собственные main/startup, ограниченный heap,
прежний semihosting. Полное ядро платы не проверяется. See / см. контракт RU/EN выше.

`freertosQueue`: CubeF1 FreeRTOS V10.3.1, ARM_CM3, Heap::4; FIFO and memory
checks before scheduler startup. No HAL or CMSIS-RTOS wrapper. FreeRTOS owns a
4096-byte BSS heap, separate from newlib. See the firmware testing contract.

`freertosQueue`: FIFO и память FreeRTOS V10.3.1 из CubeF1, ARM_CM3, Heap::4 до
запуска планировщика. Без HAL и CMSIS-RTOS. Куча FreeRTOS — отдельные 4096 байт BSS.
Подробности — в контракте прошивочных тестов.

`freertosExternal`: the `freertosQueue` scenario with FreeRTOS-Kernel V11.3.1
from `FREERTOS_PATH` (`freertos_version: external`) instead of CubeF1.

`freertosExternal`: сценарий `freertosQueue` с FreeRTOS-Kernel V11.3.1 из
`FREERTOS_PATH` (`freertos_version: external`) вместо CubeF1.

`freertosTasks`: starter creates receiver/sender then deletes itself. Real
SysTick/PendSV/SVC, two queues, delayed sender, reply 46 and semihosting from a
task. No HAL; separate 8192-byte FreeRTOS heap. Vector padding is explicit so
ELF and binary CRC inputs match even with 16-byte-aligned port code.

`freertosTasks`: стартовая задача создаёт две тестовые и удаляет себя. Реальные
SysTick/PendSV/SVC, две очереди, задержка отправителя, ответ 46 и semihosting из
задачи. Без HAL; куча FreeRTOS 8192 байта. Padding после векторов задан явно для
совпадения CRC ELF и BIN при выравнивании кода порта на 16 байт.
