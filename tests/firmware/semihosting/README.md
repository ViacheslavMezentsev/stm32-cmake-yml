# Semihosting smoke fixture / Первый тест прошивки

Adapted from the author's [02-semihosting example](https://github.com/ViacheslavMezentsev/demo-stm32-cmake/tree/main/stm32f1xx/02-semihosting).
The original local project was read only. [source-hashes.json](source-hashes.json)
records input hashes before adaptation; it does not claim a matching remote commit.
ST copyright/license notices in copied files are retained.

Inputs with unchanged logic (whitespace normalized): system_stm32f1xx.c, stm32f1xx_hal_conf.h, version.h. The test
CMakeLists accepts external framework/toolchain paths. YAML is reduced to the
same essential settings, explicitly selects framework 0.9.2 and CubeF1 1.8.7,
and adds success/failure/hang profiles. main.cpp retains semihosting printf,
HAL_Init, version and CPUID output. Its endless HAL_Delay loop is replaced with
flushed protocol markers and SYS_EXIT_EXTENDED, or an intentional hang.

The MCU build target is STM32F103C8T6 (64 KiB FLASH, 20 KiB RAM). netduino2 models
STM32F205/Cortex-M3; this test does not validate F1 peripheral behavior. The
supplied SystemInit does not configure PLL in this configuration. Its software
SystemCoreClock value is 16 MHz; no clock frequency or HAL tick accuracy is asserted.
CRC is disabled. Metadata and initial-memory probes are checked; CRC remains later work.

Адаптировано из примера автора; исходный проект не изменялся. Хеши входных файлов
сохранены до адаптации. system_stm32f1xx.c, stm32f1xx_hal_conf.h и version.h
скопированы без изменения логики; нормализованы пробелы и окончания строк.
CMake получает пути извне, YAML закрепляет версии и три профиля. main.cpp сохраняет
printf через semihosting, HAL_Init, версии и CPUID; бесконечный цикл заменён
маркерами и управляемым выходом либо намеренным зависанием.

Собирается STM32F103C8T6, запускается на netduino2 (F205/Cortex-M3). Периферия F1
не проверяется. PLL в выбранном пути SystemInit не настраивается; программное
SystemCoreClock равно 16 МГц, точность частоты и HAL tick не проверяется. CRC
отключён; проверяются метаданные и начальное состояние памяти. Подробный контракт запуска: [RU](../../../docs/ru/firmware-testing.md) /
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
