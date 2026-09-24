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
- [ ] Текущая ветка `codex/configure-cppcheck`: пять конфигурационных
  сценариев Cppcheck; 94 сценария / 564 запуска.
- [ ] Следующий шаг согласовать по пробелам покрытия; к прошивкам переходить
  только после уточнений автора, как указано ниже.
- [ ] По индексу выбрать следующие пробелы покрытия: отсутствующие/пустые значения,
  приоритеты и ошибки входных данных. Каждый новый контракт — отдельный сценарий.
- [ ] В отдельных ветках разобрать [E004 и E006](docs/ru/errata/index.md):
  выбор алгоритма CRC и обработку ошибок CRC.
  Для каждого исправления сначала зафиксировать ожидаемое поведение и регрессию.
- [x] Уточнить контракт с автором: E003/E005 закрыты как ограничения по замыслу.
  Дробные K/M и `_` в именах профилей не поддерживаются; расширение не планируется.
- [ ] Перед подготовкой и сборкой тестовых прошивок уведомить автора и дождаться
  его уточнений по сценариям и заведомо рабочим примерам. До этого — Configure/Generate.
- [ ] Подготовить отдельное окружение эмуляции: сборка QEMU 11 из закреплённых
  исходников и закреплённая версия Renode. Проверить доступность версий при реализации.
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
- [ ] Current branch `codex/configure-cppcheck`: five Cppcheck configuration
  cases; 94 scenarios / 564 executions.
- [ ] Agree the next coverage priority; defer firmware work until the author
  supplies scenario guidance as required below.
- [ ] Use the index to prioritize coverage gaps: missing/empty values, precedence
  and invalid input. Give each new contract a dedicated scenario.
- [ ] Address [E004 and E006](docs/en/errata/index.md) in separate branches:
  CRC algorithm selection and CRC error handling. Establish expected
  behavior and a regression before each fix.
- [x] Clarify the contract with the author: E003/E005 are closed by design.
  Fractional K/M and `_` in profile names are unsupported; expansion is not planned.
- [ ] Before preparing or building test firmware, notify the author and wait for
  scenario guidance and known-working examples. Until then, stay with Configure/Generate.
- [ ] Prepare a separate emulation environment: QEMU 11 built from pinned sources
  and a pinned Renode version. Verify version availability at implementation time.
- [ ] Add minimal firmware: semihosting, bare metal and blink using HSI without
  PLL. Select models based on actual emulator support; BluePill/BlackPill are
  candidates, not promises of complete board emulation.
- [ ] Define a timeout, observable result and diagnostic artifacts for GitHub
  runs; document limitations. Then add VS Code commands.

Builds and emulation supplement configure tests. Public path changes or mandatory
restructuring of consumer projects are outside this plan.
