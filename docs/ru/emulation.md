# Окружение эмуляции

[Документация](index.md) · [English](../en/emulation.md) · [Дорожная карта](../../TODO.md)

Проверка окружения `ci/emulation/check.py` проверяет наличие программ, версии и машины
QEMU. Она не собирает и не запускает прошивки — это делают [тесты прошивок](firmware-testing.md).
Счётчик configure-тестов на [странице статуса](status.md) не включает проверки окружения.

## Локальная проверка

Из корня репозитория:

```powershell
python ci/emulation/check.py --output build/emulation/environment.json
python ci/emulation/check.py --qemu "C:/path/qemu-system-arm.exe" --renode "C:/Program Files/Renode/renode.exe"
python -m unittest discover -s ci/emulation -p test_check.py
```

В Windows QEMU удобно установить через `scoop install qemu`; точная 11.0.0 —
[установщик 20260422](https://qemu.weilnetz.de/w64/2026/qemu-w64-setup-20260422.exe)
([подробнее](../../tools/qemu/README.md)).

Приоритет: аргумент командной строки → QEMU_BINARY/RENODE_BINARY → PATH.
Для Renode в Windows дополнительно проверяется каталог Program Files/Renode.
Неверный явно заданный путь вызывает ошибку, а не незаметную подмену программы.
Аргументы передаются без shell; пробелы в путях поддерживаются. Каждая команда
ограничена 30 секундами. Ошибка запуска, неверная версия или отсутствие машины
дают ненулевой код и поле error в JSON. Проверка не устанавливает программы.

Локально допускаются версии не ниже закреплённых; это не обещание совместимости
всех новых версий. В отчёте сохраняется полный вывод версии, включая build ID.
Опция --locked требует совпадения номера релиза; происхождение контейнерных
бинарников дополнительно обеспечивается проверкой SHA-256 архивов.

## Linux CI

```sh
docker build --platform linux/amd64 -f ci/emulation/Dockerfile -t stm32-yml-emulation:local .
docker run --rm --network none stm32-yml-emulation:local
```

[Lock-файл](../../ci/emulation/versions.lock.json) закрепляет QEMU 11.0.0 и Renode
1.16.1. QEMU не компилируется при сборке образа: берётся заранее собранный архив
[tools/qemu](../../tools/qemu/README.md) (arm-softmmu без GUI, из официального
release-архива; SHA-256 обоих закреплён). Renode устанавливается из portable .NET-архива. Требуются netduino2 и
netduinoplus2. Образ Ubuntu закреплён digest, системные пакеты получают обновления;
их версии записаны в /opt/emulation/packages.txt. Это не побитово воспроизводимый
образ. Контекст сборки — корень репозитория; `.dockerignore` исключает `.git` и `build`.

[Workflow](../../.github/workflows/emulation.yml) собирает отдельный образ,
проверяет его без сети и сохраняет логи/JSON/список пакетов. Окружение компиляторов
остаётся отдельным. Сборка образа требует сети и может занять несколько минут.
Официальные источники: [QEMU](https://download.qemu.org/),
[Renode 1.16.1](https://github.com/renode/renode/releases/tag/v1.16.1).

## Эмуляторы по семействам

Каждая цель запускает все 13 профилей тестовой прошивки и повреждённую копию
(ТЗ 8.8.8, TC-67); H7 и H5 — отдельные минимальные прошивки (TC-57). Список целей —
`TARGETS` в [ci/firmware_cases.py](../../ci/firmware_cases.py), модели Renode —
`tests/firmware/renode/`.

| Семейство | MCU | Ядро | QEMU | Renode | Почему так |
| --- | --- | --- | --- | --- | --- |
| F1 | STM32F103C8T6 | Cortex-M3 | `netduino2` (STM32F205) | `f103-smoke` | Опорная цель; ядро и карта памяти совпадают |
| F0 | STM32F030R8T6 | Cortex-M0 | `netduino2` (ядро M3) | `f030-smoke` (`cortex-m0`) | Машины с M0 и Flash по `0x08000000` в QEMU нет; код Thumb-1 выполняется на M3, ядро M0 проверяет только Renode |
| F4 | STM32F411CEU6, STM32F401CCU6 | Cortex-M4F | `netduinoplus2` (STM32F405) | `f4-smoke` (`cortex-m4`) | FLASH и SRAM машины покрывают обе цели |
| G4 | STM32G431CBU6, STM32G474CEU6 | Cortex-M4F | — | `g4-smoke` (`cortex-m4`) | Машины G4 в QEMU нет |
| F7 | STM32F746ZGT6 | Cortex-M7F | — | `f7-smoke` (`cortex-m7`) | В QEMU нет машины с Cortex-M7 и Flash по `0x08000000` |
| H7 | STM32H743ZI | Cortex-M7 | — | `h7-smoke` | То же; только прошивка `h7` |
| H5 | STM32H563ZI, STM32H503CB | Cortex-M33 | — | `h5-smoke` | Машины с M33 и Flash по `0x08000000` в QEMU нет |

Модели проверяют ядро, FPU, NVIC/SysTick и карту памяти, но не периферию:
RCC и FLASH controller — заглушки в RAM, HAL_Init идёт по пути без PLL.

## Особенности QEMU

- **Команда.** `qemu-system-arm -M <машина> -nographic -monitor none -serial none
  -no-reboot -semihosting-config enable=on,target=native -kernel <elf>`
  ([run_qemu_smoke.py](../../ci/run_qemu_smoke.py)). `target=native` — semihosting
  обрабатывает сам QEMU, без GDB; `-no-reboot` — сброс гостя завершает процесс;
  `-serial none` и `-monitor none` оставляют в stdout только вывод semihosting.
- **Завершение.** SYS_EXIT_EXTENDED поддерживается: код процесса QEMU равен статусу
  гостя (0, 1 или 3 для crc-corrupt).
- **Таймауты.** 15 с на запуск, 2 с для профиля `hang`; таймаут других профилей —
  ошибка.
- **Ядро машины, а не MCU.** CPUID показывает ядро машины: для F030 на `netduino2` —
  Cortex-M3. Runner сравнивает строку ядра с `qemu_part` цели, а Renode — с
  `renode_part`.
- **Периферия.** Машины моделируют STM32F205/F405, а не MCU сборки; вывод
  `TEST_PLATFORM` (например, `cortex-m4-smoke`) называет тестовую платформу, а не плату.
- **Windows.** Локально проверен также QEMU 11.1.0; CI использует 11.0.0 из
  [tools/qemu](../../tools/qemu/README.md).

## Особенности Renode

- **Команда.** `renode --disable-gui --console --plain --config renode.config
  --execute "include <сценарий>.resc"` ([run_renode_smoke.py](../../ci/run_renode_smoke.py)).
  В `renode.config` заданы `use-synchronous-logging = True` и
  `collapse-repeated-log-entries = False`: асинхронный логгер 1.16.1 терял записи
  перед `Clear`. Маркеры сценариев пишутся командой `log`, а не `echo`.
- **Пакетный режим.** Все сценарии одной пары GCC/CMake идут в одном процессе;
  `Clear` пересоздаёт машину перед каждым. `--renode-mode process` запускает процесс
  на сценарий для диагностики, `--renode-shuffle <seed>` перемешивает порядок.
- **Semihosting.** `UART.SemihostingUart` обрабатывает SYS_WRITE0. SYS_EXIT_EXTENDED
  и newlib SYS_WRITE не поддерживаются, поэтому прошивка печатает через
  `vsnprintf` + SYS_WRITE0, а [exit_hook.py](../../tests/firmware/renode/exit_hook.py)
  (`sysbus.cpu AddHook` на `smoke_exit_trap`) читает R0/R1 и блок статуса из RAM
  цели и останавливает CPU.
- **Время.** `emulation RunFor "0.1"` — 0,1 с виртуального времени на сценарий,
  30 с на ПК. Для `hang` нужен полный вывод без выхода гостя.
- **Тип ядра.** `cpuType: "cortex-m4f"` в Renode 1.16.1 возвращает CPUID Cortex-M7
  (0x411FC272), поэтому модели F4 и G4 используют `cortex-m4`; FPU в нём есть, это
  подтверждают профили с аппаратной плавающей точкой и FreeRTOS `ARM_CM4F`.
- **NVIC.** `priorityMask: 0xC0` для Cortex-M0 (2 бита приоритета), `0xF0` для
  остальных ядер (4 бита). FreeRTOS при старте пишет 0xFF в приоритет IRQ 16, и
  Renode предупреждает о маске; runner разрешает ровно одно такое предупреждение и
  только в `freertosTasks`.
- **SysTick.** `systickFrequency`: 8 МГц для F0/F1, 16 МГц для F4/G4/F7, 32 МГц для
  H5, 64 МГц для H7; точность частоты не проверяется. После записи VAL = 0 Renode
  перезагружает счётчик прежним значением LOAD (после сброса 0xFFFFFF). Фикстура
  переопределяет слабый `vPortSetupTimerInterrupt` (LOAD, затем VAL, затем включение),
  а для порта `ARM_CM0` FreeRTOS V10.0.1 без этого хука записывает LOAD до запуска
  планировщика — иначе первый тик приходит примерно через 2 с.
- **Модели.** Штатные платформы Renode не используются: широкая карта памяти и
  загрузка SVD по сети тесту не нужны. Модель — `CPU.CortexM`, NVIC,
  `Memory.MappedMemory` для FLASH/SRAM и RAM-заглушки регистров, которых касается
  SystemInit/HAL_Init.

Подробности протокола и отчётов — [тесты прошивок](firmware-testing.md),
группы сценариев — [план](firmware-plan.md).
