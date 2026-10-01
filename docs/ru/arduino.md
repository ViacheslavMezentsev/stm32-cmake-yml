# Backend Arduino: режимы wrappers и native

[Документация](index.md) · [English](../en/arduino.md)

При `toolchain_backend: arduino` прошивка собирается с [Arduino_Core_STM32](https://github.com/stm32duino/Arduino_Core_STM32)
(проверяется версия 2.12.0). Ядро подключается одним из двух режимов, ключ
`arduino.integration` (ТЗ 4.9.8). Режимы независимы: ключи одного не влияют на другой.

| | `wrappers` (по умолчанию) | `native` |
| --- | --- | --- |
| Кто собирает ядро | CMake-обёртки проекта (`arduino.core_cmake_dir`, `arduino.custom_libraries`) | CMake-файлы самого ядра |
| Флаги платы | цель `Arduino::Platform` или вручную в обёртке | цель `board` ядра, создаёт фреймворк |
| Флаги YAML | исполняемой цели и цели `Arduino::Definitions`/`Arduino::Options` | через `user_settings` — и ядру, и проекту |
| Библиотеки ядра | свои обёртки (шаблон ниже) | `arduino.libraries` — их `CMakeLists.txt` |
| Скрипт компоновщика | шаблон `.ld.in` или `linker_script` (обязательно) | шаблон, `linker_script` или скрипт variant платы |
| Когда выбирать | изменённые копии ядра или библиотек, особая сборка ядра | ядро без изменений, минимум своих CMake-файлов |

Общие ключи: `arduino.core_path` (путь к ядру), `arduino.board` (плата, ТЗ 4.9.10),
`arduino.cmsis_path` и `arduino.cmsis_target` (CMSIS, ТЗ 4.9.14), `arduino.use_core_main`.
Точный смысл каждого ключа — в [справочнике](reference/0.9.2/arduino.md).

## Плата и CMSIS

Плата задаётся `arduino.board` — идентификатором из `boards.txt` ядра — или выбирается по
`mcu` (`auto`): `GENERIC_` + семь символов имени без `STM32` + `X`
(`STM32F103C8T6` → `GENERIC_F103C8TX`), иначе единственный идентификатор с одной буквой
суффикса (`STM32U575ZIT6Q` → `GENERIC_U575ZITXQ`). Для `auto` нужно полное имя MCU:
`STM32G431CB` слишком короткое, задайте `STM32G431CBU6` или `board: GENERIC_G431CBUX`.
Данные платы читаются из `cmake/boards_db.cmake` ядра без Python и сети.

CMSIS Core ищется по порядку: `arduino.cmsis_path`; Arduino IDE
(`%LOCALAPPDATA%\Arduino15`, `~/.arduino15`, `~/Library/Arduino15`, каталог
`packages/STMicroelectronics/tools/CMSIS/<версия>`); кэш загрузок ядра
(`~/.Arduino_Core_STM32_dl/*/dist/CMSIS6`); `Drivers` пакета STM32Cube семейства
(CMSIS 5 вместо ожидаемого ядром CMSIS 6 — для проверенных семейств сборка проходит).
Источник выводится в лог Configure.

## Режим wrappers

Поведение 0.9.3 сохраняется: фреймворк создаёт `Arduino::Definitions`, подключает
обёртку ядра из `arduino.core_cmake_dir` (по умолчанию `Arduino/Core`) и каталоги
`arduino.custom_libraries`; с исполняемой целью связывается то, что перечислено в
`link_libraries`. С 0.10.0 есть ещё две интерфейсные цели:

- `Arduino::Options` — общие и языковые `compile_options`;
- `Arduino::Platform` — флаги ядра и FPU, определения и include-каталоги выбранной
  платы (`system/<семейство>`, драйверы HAL, CMSIS device, variant), каталоги
  `cores/arduino` и `SrcWrapper`, CMSIS Core. Параметры компоновщика платы не входят:
  скрипт компоновщика в этом режиме задаёт фреймворк. Кэш `ARDUINO_VARIANT_PATH` —
  каталог variant, `ARDUINO_BOARD` — плата.

`Arduino::Platform` создаётся, если плату и CMSIS удалось определить. Если при
значениях по умолчанию это невозможно (короткое имя MCU, нет CMSIS), цель не
создаётся, а в лог выводится причина: обёртки 0.9.3, которые её не используют,
работают как раньше.

Обёртка, связанная с `Arduino::Platform`, не зависит от семейства MCU: один и тот же
`CMakeLists.txt` собирает ядро для F103 и G431. Шаблоны ниже проверены сборкой
прошивки для `STM32F103C8T6` и `STM32G431CBU6` (GCC 14.2.1, CMake 3.21.7) — их нужно
скопировать в проект и при необходимости изменить.

`stm32_config.yml`:

```yaml
toolchain_backend: arduino
mcu: STM32F103C8T6
languages: [C, CXX, ASM]
sources: [sketch.cpp]
compile_options: [Os]
link_options: [specs=nano.specs]
linker_directives: [--gc-sections]
linker_script_dir: linker          # шаблон STM32F103C8_FLASH.ld.in
arduino:
  core_path: modules/Arduino_Core_STM32
  custom_libraries: [Arduino/libraries/Wire]
link_libraries: [Arduino::Wire, Arduino::Core]
```

`Arduino/Core/CMakeLists.txt` — обёртка ядра:

```cmake
# Обёртка ядра Arduino для режима wrappers (ТЗ 4.9.15, 4.9.17).
# Не зависит от семейства MCU: флаги, определения и include-каталоги платы
# даёт цель Arduino::Platform.
set(_core "${ARDUINO_CORE_DIR}/cores/arduino")
set(_wrapper "${ARDUINO_CORE_DIR}/libraries/SrcWrapper/src")
file(GLOB _sources CONFIGURE_DEPENDS
    "${_core}/*.c" "${_core}/*.cpp" "${_core}/avr/*.c" "${_core}/stm32/*.c" "${_core}/stm32/*.S"
    "${_wrapper}/*.c" "${_wrapper}/*.cpp" "${_wrapper}/stm32/*.c" "${_wrapper}/stm32/*.cpp"
    "${_wrapper}/HAL/*.c" "${_wrapper}/LL/*.c"
    "${ARDUINO_VARIANT_PATH}/*.c" "${ARDUINO_VARIANT_PATH}/*.cpp")
if(DEFINED USE_CORE_MAIN AND NOT USE_CORE_MAIN)
    # main() проекта: main.cpp ядра не компилируется.
    list(FILTER _sources EXCLUDE REGEX "/cores/arduino/main\\.cpp$")
endif()
# OBJECT, а не STATIC: обработчики прерываний ядра попадают в образ, даже
# если на них нет явных ссылок (иначе остаются слабые заглушки startup).
add_library(ArduinoCore OBJECT ${_sources})
add_library(Arduino::Core ALIAS ArduinoCore)
target_link_libraries(ArduinoCore PUBLIC Arduino::Platform Arduino::Definitions)
```

`Arduino/libraries/Wire/CMakeLists.txt` — обёртка библиотеки ядра:

```cmake
# Обёртка библиотеки Wire ядра для режима wrappers (ТЗ 4.9.17).
set(_lib "${ARDUINO_CORE_DIR}/libraries/Wire/src")
add_library(ArduinoWire OBJECT "${_lib}/Wire.cpp" "${_lib}/utility/twi.c")
add_library(Arduino::Wire ALIAS ArduinoWire)
target_include_directories(ArduinoWire PUBLIC "${_lib}" "${_lib}/utility")
target_link_libraries(ArduinoWire PUBLIC Arduino::Core)
```

Объектные файлы OBJECT-библиотеки попадают только в цель, которая связана с ней
напрямую, поэтому в `link_libraries` перечисляются и `Arduino::Wire`, и `Arduino::Core`.
Флаги ядра и FPU приходят к исполняемой цели через `PUBLIC`-связь с
`Arduino::Platform`: задавать `-mcpu`, `-mfpu`, `-mfloat-abi` и определения платы в
YAML не нужно.

## Режим native

```yaml
toolchain_backend: arduino
mcu: STM32F103C8T6
languages: [C, CXX, ASM]
sources: [sketch.cpp]
arduino:
  integration: native
  core_path: modules/Arduino_Core_STM32
  libraries: [Wire]               # SrcWrapper подключается всегда
link_libraries: [Wire]            # имена целей ядра
```

Фреймворк подключает `cmake/environment.cmake`, `cmake/set_base_arduino_config.cmake`,
variant платы, `cores/arduino`, `libraries/SrcWrapper` и библиотеки `arduino.libraries`
(ТЗ 4.9.9). Функции ядра `set_board()`, `updatedb()`, `ensure_core_deps()` и
`overall_settings()` не вызываются: Configure не требует Python и сети и не меняет
файлы ядра. Фреймворк создаёт:

- `board` — цель платы с вариантами serial `generic`, USB `none`, VirtIO `disable`;
- `user_settings` — `-Os` и `--specs=nano.specs`, затем `compile_definitions` и
  `compile_options` из YAML (общие и языковые). Их получают и файлы ядра, и проект;
  `-O2` в YAML переопределяет `-Os`.

Исполняемая цель связывается с `stm32_runtime` ядра автоматически. Скрипт компоновщика:
шаблон `.ld.in` (размеры heap/stack, секция CRC) или `linker_script` заменяют
`--default-script` платы; без них используется скрипт variant платы, а heap/stack не
применяются. Ядро дополнительно передаёт `system/ldscript.ld`, который через `INSERT`
добавляет секцию `.noinit` после `.bss`; если такая секция есть в вашем скрипте, одну
из них нужно убрать. Цели проекта не должны называться как цели ядра (`core`,
`variant`, `board`, `base_config`, `user_settings`, `SrcWrapper`, `stm32_runtime`).
Ключи `arduino.core_cmake_dir` и `arduino.mcu_target` в этом режиме не действуют.
Библиотеки ядра, требующие дополнительных зависимостей (USBDevice, VirtIO,
CMSIS_DSP), в 0.10.0 не поддерживаются.

### Собственная main()

`arduino.use_core_main` (ТЗ 4.9.18) определяет, чья `main()` используется.

- `true` (по умолчанию в `native`): `main()` ядра (`cores/arduino/main.cpp`) вызывает
  `initVariant()`, затем `setup()` и в цикле `loop()`; конструктор `premain()` до
  `main()` вызывает `init()`, задаёт группу приоритетов NVIC и на Cortex-M7 включает
  кэши. Проект определяет `setup()` и `loop()`.
- `false`: фреймворк исключает `main.cpp` из цели ядра `core_bin` и добавляет
  `--undefined=_write`. Проект определяет `main()` и сам выполняет то, что делал
  `premain()`:

```cpp
#include <Arduino.h>

int main(void) {
#ifdef NVIC_PRIORITYGROUP_4
    HAL_NVIC_SetPriorityGrouping(NVIC_PRIORITYGROUP_4);  // как premain() ядра (FreeRTOS)
#endif
#if (__CORTEX_M == 0x07U)
    SCB_EnableICache();  // Cortex-M7: кэши, как premain() ядра
    SCB_EnableDCache();
#endif
    init();          // HAL, SysTick, тактирование (SystemClock_Config платы)
    initVariant();   // настройка платы
    for (;;) {
        // приложение
    }
}
```

`premain()` ядра — конструктор с приоритетом 101: он выполняется до статических объектов C++. Без него `init()` вызывается позже, из `main()`, поэтому глобальные объекты, конструкторы которых обращаются к HAL, нужно создавать после `init()`.

Признаки ошибки: `main()` проекта при `use_core_main: true` — ошибка компоновки
`undefined reference to '_write'` (или, при другом порядке библиотек, образ без
`premain()`, где `init()` не вызывается); `use_core_main: false` без `init()` —
прошивка не настраивает тактирование и SysTick, `delay()` и `millis()` не работают.

## CMSIS из проекта (external)

`arduino.cmsis_path: external` — фреймворк не добавляет путей CMSIS. С
`arduino.cmsis_target` цель проекта подключается к `Arduino::Platform` (`wrappers`)
или `user_settings` (`native`); цель можно определить и после вызова фреймворка:

```cmake
stm32_yml_setup_project(${PROJECT_NAME})
add_library(ProjectCmsis INTERFACE)
target_include_directories(ProjectCmsis INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/third_party/CMSIS/Core/Include")
```

```yaml
arduino:
  cmsis_path: external
  cmsis_target: ProjectCmsis
```

Для плат F0, F1, F4, G4 и F7 матрицы проверок достаточно 12 файлов CMSIS Core 6
(`CMSIS/Core/Include/…`): `cmsis_compiler.h`, `cmsis_gcc.h`, `cmsis_version.h`,
`core_cm0.h`, `core_cm3.h`, `core_cm4.h`, `core_cm7.h`, `core_cm33.h`,
`m-profile/cmsis_gcc_m.h`, `m-profile/armv7m_mpu.h`, `m-profile/armv8m_mpu.h`,
`m-profile/armv7m_cachel1.h`. С этим набором режим `native` собирает прошивки для
`STM32F103C8T6`, `STM32F030R8T6`, `STM32F411CEU6`, `STM32G474CEU6` и `STM32F746ZGT6`.
Для других ядер (M0+, M23, M55 и др.) добавьте соответствующие `core_*.h`.

## Проверки

Режимы проверяются сценариями L3 `arduino-*` ([тестирование](testing.md)), прошивки
режима `native` собираются для всех целей матрицы L4
([прошивки](firmware-testing.md)); запуск прошивок `native` в эмуляторах появится вместе
с моделями RCC/PWR.
