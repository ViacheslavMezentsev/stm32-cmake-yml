# Дорожная карта / Roadmap

[README](README.md) · [Документация RU](docs/ru/index.md) · [Documentation EN](docs/en/index.md)

## Русский

Состояние на 2026-09-25. Ниже работа сгруппирована в пять этапов; этапы могут
выполняться параллельно. Это план, а не обещание сроков или поддерживаемых функций.
Приоритет — Configure/Generate и совместимость существующих проектов.
Новый порядок: рабочая ветка → локальные проверки → push и CI → merge в main.
PR больше не требуются; старые ссылки остаются историей. [Порядок работы](docs/ru/maintenance.md).

`[x]` означает слито, `[ ]` — ещё не завершено. Подготовленный коммит и успешные
локальные проверки не означают слияния или выпуска. Обновляйте статусы и ссылки
на коммиты/ветки вместе с выполнением работы; подробности дефектов храните в errata.

### 1. Воспроизводимое окружение

- [x] Docker, закреплённые зависимости, выборочная загрузка STM32Cube, три версии
  xPack GCC и две версии CMake, включая 3.19.8 — [PR #1](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/1).

### 2. Конфигурационные тесты

- [x] CTest и GitHub Actions для Configure/Generate — [PR #2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/2).
- [x] Расширение до 33 сценариев: профили, IOC, bare metal без CMSIS, Arduino,
  linker templates, генерация CRC-команд и повторный Configure — [PR #3](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/3).

### 3. Исправления конфигурации — слито

- [x] Исправления MCU, heap/stack и внешнего list слиты в [PR #6](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/6).
- [x] GitHub: Configure tests и Documentation reference прошли на `48d8248`;
  набор содержит 36 сценариев / 216 запусков.
- [x] Статусы E001/E002 и индекс обновлены в [PR #7](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/7).
  Совместимость `STM32_YML_OVERRIDE_*` описана в документации тестирования и errata.

### 4. Эталон поведения и документация — параллельно

- [x] Справочник, навигация RU/EN, индекс покрытия, CI и навык —
  [PR #4](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/4).
- [x] Дорожная карта — [PR #5](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/5).
- [ ] Поддерживать карточки, тесты и errata согласованными при изменении поведения.
  Это постоянное правило сопровождения, а не разовая проверка полноты покрытия.

- [x] Сократить README и вынести подключение/сценарии в RU/EN-документацию;
  показывать статусы CI и проверяемый численный объём набора — слито в [PR #8](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/8).
- [x] Поэтапно пересмотреть навыки: сначала `stm32-simple-sources` (источники и
  флаги языков), затем `stm32-module-creator` (зависимости и флаги библиотек),
  затем `stm32-build-helper` (раздельные стадии диагностики). Для каждого
  утверждения указывать существующий тест или сначала добавлять необходимую проверку.

### 5. Расширение проверок — после стабилизации Configure

- [x] Регрессии `Rev`/`RevB`, пустого override и сброса внешнего профиля слиты
  в [PR #7](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/7): 39 сценариев / 234 запуска.
- [x] Навык simple-sources и три проверки подключения исходников слиты в main
  (`8e7411b`); 42 сценария / 252 запуска, CI main прошёл.
- [x] Процесс без PR слит: `main` на `12cdd56`, проверки CI успешны.
- [x] `codex/module-creator-skill` слита в main (`7b197ce`): навык и три проверки
  библиотек; 45 сценариев / 270 запусков.
- [x] `codex/build-helper-skill` слита в main (`c92d786`), CI успешен:
  диагностика по стадиям; 48 сценариев / 288 запусков.
- [x] Проверки версии YAML слиты в main (`9bc165f`), CI успешен:
  56 сценариев / 336 запусков.
- [x] Компоненты FreeRTOS и CMSIS-RTOS слиты в main (`8663c51`), CI успешен:
  65 сценариев / 390 запусков.
- [x] Ветка `codex/configure-freertos-ioc` слита в main (`d12c542`): семь проверок IOC,
  приоритетов и повторной настройки; 72 сценария / 432 запуска.
- [x] Ветка `codex/freertos-external-errata` слита в main (`477fe95`): две
  регрессии известной ошибки E007; 74 сценария / 444 запуска. Исправление
  external отложено по решению автора от 2026-09-25.
- [x] `codex/configure-mcu-families` слита в main (`477fe95`):
  F0/F3/F7/G4; 84 сценария / 504 запуска.
- [x] `codex/configure-system-libraries` слита в main (`ae25a70`):
  системные библиотеки и параметры линковки; 89 сценариев / 534 запуска.
- [x] `codex/configure-cppcheck` слита в main (`0a8b89b`):
  94 сценария / 564 запуска.
- [x] `codex/configure-build-artifacts` слита в main (`fa95034`):
  100 сценариев / 600 запусков.
- [x] `codex/configure-custom-libraries` слита в main (`16e54d9`):
  105 сценариев / 630 запусков; CI прошёл.
- [x] `codex/configure-arduino-libraries` слита в main (`09f5629`):
  110 сценариев / 660 запусков.
- [x] `codex/configure-arduino-custom-wrappers` слита в main (`a36aa77`):
  115 сценариев / 690 запусков.
- [x] `codex/emulation-environment` слита в main (`3f1c589`): локальная проверка программ,
  отдельный образ QEMU 11.0.0 / Renode 1.16.1 и CI без запуска прошивок.
  [Порядок дальнейших этапов и ограничения](docs/ru/emulation.md).
- [x] `codex/firmware-semihosting-smoke` слита в main (`c25f7b1`): F1 02-semihosting,
  три профиля сборки и запуска netduino2; GCC 14.2 / CMake 3.28.
  [Контракт и ограничения](docs/ru/firmware-testing.md).
- [x] `codex/firmware-toolchain-matrix` слита в main (`5548735`): 18 сборок и
  18 запусков QEMU, три профиля на шести парах инструментов.
- [x] `codex/firmware-metadata` слита в main (`833aed7`): метаданные, .data/.bss и C++-конструктор;
  тот же набор из 18 сборок/запусков.
- [x] `codex/firmware-crc` слита в main (`0ae6613`): CRC FLASH и повреждённый образ; 18 сборок / 24 запуска.
- [ ] Текущая ветка `codex/readme-overview`: вводный README RU/EN, отдельные страницы статуса, навыки и дружественные проекты.
- [ ] Далее Renode по согласованному плану. Новые сценарии
  выбирать с автором.
- [ ] По индексу выбрать следующие пробелы покрытия: отсутствующие/пустые значения,
  приоритеты и ошибки входных данных. Каждый новый контракт — отдельный сценарий.
- [ ] В отдельных ветках разобрать [E004 и E006](docs/ru/errata/index.md):
  выбор алгоритма CRC и обработку ошибок CRC.
  Для каждого исправления сначала зафиксировать ожидаемое поведение и регрессию.
- [x] Уточнить контракт с автором: E003/E005 закрыты как ограничения по замыслу.
  Дробные K/M и `_` в именах профилей не поддерживаются; расширение не планируется.
- [x] Автор выбрал доработанный F1 `02-semihosting` и netduino2 для первого
  теста сборки/запуска. Другие сценарии требуют отдельного уточнения.
- [x] Отдельное окружение эмуляции: QEMU 11.0.0 из закреплённых исходников
  и Renode 1.16.1; слито в main (`3f1c589`).
- [ ] Добавить минимальные прошивки: semihosting, bare metal и blink на HSI без PLL.
  Выбрать поддерживаемые модели по фактическим возможностям эмуляторов;
  BluePill/BlackPill — кандидаты, а не обещание полной эмуляции плат.
- [ ] Для запуска в GitHub задать таймаут, проверяемый результат и диагностические
  артефакты; документировать ограничения. Затем добавить команды VS Code.

Сборки и эмуляция дополняют конфигурационные тесты. Изменение публичных путей или
обязательная реструктуризация проектов-потребителей в этот план не входят.

## English

Status as of 2026-09-25. Work is grouped into five stages, which may overlap.
The priority is Configure/Generate and compatibility with existing consumers.
New workflow: working branch → local checks → push and CI → merge into main.
PRs are no longer required; old links remain historical. [Workflow](docs/en/maintenance.md).
This roadmap does not promise delivery dates or unsupported features.

`[x]` means merged; `[ ]` means incomplete. A prepared commit or a passing local
run does not mean merged or released. Update statuses and commit/branch links as work lands;
keep defect details in errata.

### 1. Reproducible environment

- [x] Docker, pinned dependencies, selective STM32Cube checkout, three xPack GCC
  versions and two CMake versions including 3.19.8 — [PR #1](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/1).

### 2. Configure tests

- [x] CTest and GitHub Actions for Configure/Generate — [PR #2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/2).
- [x] Expand to 33 scenarios: profiles, IOC, bare metal without CMSIS, Arduino,
  linker templates, CRC command generation and repeated Configure — [PR #3](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/3).

### 3. Configuration fixes — merged

- [x] MCU, heap/stack and external listing fixes merged in [PR #6](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/6).
- [x] GitHub Configure tests and Documentation reference passed on `48d8248`;
  36 scenarios / 216 executions.
- [x] E001/E002 statuses and index updated in [PR #7](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/7).
  `STM32_YML_OVERRIDE_*` compatibility is documented in testing and errata.

### 4. Behavior contract and documentation — in parallel

- [x] Reference, RU/EN navigation, coverage index, CI and skill —
  [PR #4](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/4).
- [x] Roadmap — [PR #5](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/5).
- [ ] Keep cards, tests and errata aligned as behavior changes. This is an ongoing
  maintenance rule, not a one-time claim of complete coverage.

- [x] Shorten README and move setup/scenarios to RU/EN docs; show CI status and
  validated suite counts — merged in [PR #8](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/8).
- [x] Review skills incrementally: `stm32-simple-sources` (sources/language flags),
  then `stm32-module-creator` (library dependencies/flags), then `stm32-build-helper`
  (phase-specific diagnostics). Tie each claim to an existing test or add the
  required check before claiming verified behavior.

### 5. Further checks — after Configure stabilizes

- [x] `Rev`/`RevB`, empty override and external profile reset regressions merged
  in [PR #7](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/7): 39 scenarios / 234 executions.
- [x] Simple-sources skill and three source integration checks merged into main
  (`8e7411b`); 42 scenarios / 252 executions, main CI passed.
- [x] Branch workflow without PRs merged: main `12cdd56`, CI successful.
- [x] `codex/module-creator-skill` merged into main (`7b197ce`): skill and three
  library checks; 45 scenarios / 270 executions.
- [x] `codex/build-helper-skill` merged into main (`c92d786`), CI passed:
  phase-specific diagnostics; 48 scenarios / 288 executions.
- [x] YAML version checks merged into main (`9bc165f`), CI passed:
  56 scenarios / 336 executions.
- [x] FreeRTOS and CMSIS-RTOS components merged into main (`8663c51`), CI passed:
  65 scenarios / 390 executions.
- [x] Branch `codex/configure-freertos-ioc` merged into main (`d12c542`): seven IOC, precedence
  and reconfiguration cases; 72 scenarios / 432 executions.
- [x] Branch `codex/freertos-external-errata` merged into main (`477fe95`):
  two known-failure E007 regressions; 74 scenarios / 444 executions.
  The author deferred the external fix on 2026-09-25.
- [x] `codex/configure-mcu-families` merged into main (`477fe95`):
  F0/F3/F7/G4; 84 scenarios / 504 executions.
- [x] `codex/configure-system-libraries` merged into main (`ae25a70`):
  system libraries and linker options; 89 scenarios / 534 executions.
- [x] `codex/configure-cppcheck` merged into main (`0a8b89b`):
  94 scenarios / 564 executions.
- [x] `codex/configure-build-artifacts` merged into main (`fa95034`):
  100 scenarios / 600 executions.
- [x] `codex/configure-custom-libraries` merged into main (`16e54d9`):
  105 scenarios / 630 executions; CI passed.
- [x] `codex/configure-arduino-libraries` merged into main (`09f5629`):
  110 scenarios / 660 executions.
- [x] `codex/configure-arduino-custom-wrappers` merged into main (`a36aa77`):
  115 scenarios / 690 executions.
- [x] `codex/emulation-environment` merged into main (`3f1c589`): local executable checks,
  separate QEMU 11.0.0 / Renode 1.16.1 image and CI without firmware execution.
  [Next stages and limitations](docs/en/emulation.md).
- [x] `codex/firmware-semihosting-smoke` merged into main (`c25f7b1`): F1 02-semihosting,
  three build/run profiles on netduino2; GCC 14.2 / CMake 3.28.
  [Contract and limitations](docs/en/firmware-testing.md).
- [x] `codex/firmware-toolchain-matrix` merged into main (`5548735`): 18 builds
  and 18 QEMU runs, three profiles across six tool pairs.
- [x] `codex/firmware-metadata` merged into main (`833aed7`): metadata, .data/.bss and C++ constructor;
  the same 18 builds/runs.
- [x] `codex/firmware-crc` merged into main (`0ae6613`): FLASH CRC and corrupted image; 18 builds / 24 runs.
- [ ] Current branch `codex/readme-overview`: introductory RU/EN READMEs, separate status pages, skills and related projects.
- [ ] Next: Renode following the agreed plan. Select new
  scenarios with the author.
- [ ] Use the index to prioritize coverage gaps: missing/empty values, precedence
  and invalid input. Give each new contract a dedicated scenario.
- [ ] Address [E004 and E006](docs/en/errata/index.md) in separate branches:
  CRC algorithm selection and CRC error handling. Establish expected
  behavior and a regression before each fix.
- [x] Clarify the contract with the author: E003/E005 are closed by design.
  Fractional K/M and `_` in profile names are unsupported; expansion is not planned.
- [x] The author selected the modified F1 `02-semihosting` with netduino2 for
  the first build/run test. Other scenarios need separate guidance.
- [x] Separate emulation environment: QEMU 11.0.0 from pinned sources and
  Renode 1.16.1; merged into main (`3f1c589`).
- [ ] Add minimal firmware: semihosting, bare metal and blink using HSI without
  PLL. Select models based on actual emulator support; BluePill/BlackPill are
  candidates, not promises of complete board emulation.
- [ ] Define a timeout, observable result and diagnostic artifacts for GitHub
  runs; document limitations. Then add VS Code commands.

Builds and emulation supplement configure tests. Public path changes or mandatory
restructuring of consumer projects are outside this plan.
