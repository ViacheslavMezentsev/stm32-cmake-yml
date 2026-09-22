# Дорожная карта / Roadmap

[README](README.md) · [Документация RU](docs/ru/index.md) · [Documentation EN](docs/en/index.md)

## Русский

Состояние на 2026-09-22. Ниже работа сгруппирована в пять этапов; этапы могут
выполняться параллельно. Это план, а не обещание сроков или поддерживаемых функций.
Приоритет — Configure/Generate и совместимость существующих проектов.

`[x]` означает слито, `[ ]` — ещё не завершено. Подготовленный коммит и успешные
локальные проверки не означают слияния или выпуска. Обновляйте статусы и ссылки
на PR вместе с выполнением работы; подробности дефектов храните в errata.

### 1. Воспроизводимое окружение

- [x] Docker, закреплённые зависимости, выборочная загрузка STM32Cube, три версии
  xPack GCC и две версии CMake, включая 3.19.8 — [PR #1](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/1).

### 2. Конфигурационные тесты

- [x] CTest и GitHub Actions для Configure/Generate — [PR #2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/2).
- [x] Расширение до 33 сценариев: профили, IOC, bare metal без CMSIS, Arduino,
  linker templates, генерация CRC-команд и повторный Configure — [PR #3](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/3).

### 3. Исправления конфигурации — следующий PR

- [ ] Слить подготовленные исправления в `codex/configure-profile-fixes`
  (коммит `858013a`): обновление MCU и heap/stack при повторной настройке,
  вывод профилей из внешнего файла; см. [E001](docs/ru/errata/E001.md) и [E002](docs/ru/errata/E002.md).
- [ ] Проверить в GitHub расширенный набор из 36 сценариев для шести пар GCC/CMake.
  Локально 216 запусков уже прошли; статус GitHub проверяется отдельно.
- [ ] При слиянии обновить errata RU/EN и индекс, описать совместимость прямых
  `-DMCU`/`-DHEAP_SIZE`/`-DSTACK_SIZE` с `STM32_YML_OVERRIDE_*`.

### 4. Эталон поведения и документация — параллельно

- [ ] Слить `codex/configuration-reference` (`5f47d66`): навигация RU/EN,
  55 карточек опций 0.9.2, шесть errata, индекс покрытия, CI и обновлённый навык.
  По сообщению владельца, проверка и слияние находятся в процессе.
- [ ] Поддерживать карточки, тесты и errata согласованными при изменении поведения.
  Это постоянное правило сопровождения, а не разовая проверка полноты покрытия.

### 5. Расширение проверок — после стабилизации Configure

- [ ] По индексу выбрать следующие пробелы покрытия: отсутствующие/пустые значения,
  приоритеты и ошибки входных данных. Каждый новый контракт — отдельный сценарий.
- [ ] Отдельными PR разобрать [E003–E006](docs/ru/errata/index.md): размеры,
  имена профилей, выбор алгоритма CRC и обработка ошибок CRC.
  Для каждого исправления сначала зафиксировать ожидаемое поведение и регрессию.
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

Status as of 2026-09-22. Work is grouped into five stages, which may overlap.
The priority is Configure/Generate and compatibility with existing consumers.
This roadmap does not promise delivery dates or unsupported features.

`[x]` means merged; `[ ]` means incomplete. A prepared commit or a passing local
run does not mean merged or released. Update statuses and PR links as work lands;
keep defect details in errata.

### 1. Reproducible environment

- [x] Docker, pinned dependencies, selective STM32Cube checkout, three xPack GCC
  versions and two CMake versions including 3.19.8 — [PR #1](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/1).

### 2. Configure tests

- [x] CTest and GitHub Actions for Configure/Generate — [PR #2](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/2).
- [x] Expand to 33 scenarios: profiles, IOC, bare metal without CMSIS, Arduino,
  linker templates, CRC command generation and repeated Configure — [PR #3](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/3).

### 3. Configuration fixes — next PR

- [ ] Merge prepared `codex/configure-profile-fixes` (`858013a`): refresh MCU and
  heap/stack on reconfiguration and list external profiles; see
  [E001](docs/en/errata/E001.md) and [E002](docs/en/errata/E002.md).
- [ ] Verify 36 scenarios across six GCC/CMake pairs in GitHub. All 216 local runs
  passed; the GitHub result must be checked separately.
- [ ] On merge, update RU/EN errata and the index; explain compatibility of direct
  `-DMCU`/`-DHEAP_SIZE`/`-DSTACK_SIZE` with `STM32_YML_OVERRIDE_*`.

### 4. Behavior contract and documentation — in parallel

- [ ] Merge `codex/configuration-reference` (`5f47d66`): RU/EN navigation,
  55 option cards for 0.9.2, six errata, coverage index, CI and updated skill.
  The owner reports that testing and merging are in progress.
- [ ] Keep cards, tests and errata aligned as behavior changes. This is an ongoing
  maintenance rule, not a one-time claim of complete coverage.

### 5. Further checks — after Configure stabilizes

- [ ] Use the index to prioritize coverage gaps: missing/empty values, precedence
  and invalid input. Give each new contract a dedicated scenario.
- [ ] Address [E003–E006](docs/en/errata/index.md) in separate PRs: sizes, profile
  names, CRC algorithm selection and CRC error handling. Establish expected
  behavior and a regression before each fix.
- [ ] Prepare a separate emulation environment: QEMU 11 built from pinned sources
  and a pinned Renode version. Verify version availability at implementation time.
- [ ] Add minimal firmware: semihosting, bare metal and blink using HSI without
  PLL. Select models based on actual emulator support; BluePill/BlackPill are
  candidates, not promises of complete board emulation.
- [ ] Define a timeout, observable result and diagnostic artifacts for GitHub
  runs; document limitations. Then add VS Code commands.

Builds and emulation supplement configure tests. Public path changes or mandatory
restructuring of consumer projects are outside this plan.
