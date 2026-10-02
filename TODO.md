# Дорожная карта / Roadmap

[README](README.md) · [Документация RU](docs/ru/index.md) · [Documentation EN](docs/en/index.md)

## Русский

Состояние на 2026-09-27. Ниже работа сгруппирована в пять этапов; этапы могут
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
  external было отложено 2026-09-25 и выполнено в 0.9.3 (`3c6bfa3`).
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
- [x] `codex/readme-overview` слита в main (`0940142`): вводный README RU/EN, отдельные страницы статуса, навыки и дружественные проекты.
- [x] `codex/firmware-count-badge` слита в main (`23a6d67`): бейдж подтверждённых сборок и QEMU-проверок.
- [x] `codex/renode-firmware-smoke` слита в main (`493771d`): 18 сборок, 24 QEMU + 24 Renode; общий SYS_WRITE0 и адаптер выхода.
- [x] `codex/firmware-build-modes` слита в main (`ba9bde7`): bare metal/CMSIS без HAL, `.ld`/`.ld.in`; 42 сборки и 96 проверок QEMU+Renode.
- [x] `codex/firmware-libraries` слита в main (`a53f809`): C/C++ и ETL, 54 сборки / 120 проверок; E008 без исправления (исправлена позже, в 0.9.3).
- [x] `codex/badges-docs-ci` слита в main (`a3015d9`): прямоугольные бейджи без иконок, `Builds (Checks)`, пропуск тяжёлого CI для MD-only push.
- [x] `codex/firmware-arduino-string` слита в main (`5743602`): собственный main, реальный String из Core 2.12.0, 60 сборок / 132 проверки.
- [x] `codex/firmware-freertos-queue` слита в main (`4109bc8`): очереди и Heap::4 без планировщика; 66 сборок / 144 проверки.
- [x] `codex/firmware-freertos-tasks` слита в main (`f16eb09`): starter, обмен двух задач, SysTick без HAL; 72 сборки / 156 проверок, единый цвет бейджев.
- [x] `codex/badge-status-and-timings` слита в main (`7246a2c`): единые Shields-бейджи, PASS/FAIL, цвет #238636; QEMU hang 2 с и измерение длительностей.
- [x] `claude/renode-batch` слита в main (`aa58116`): один процесс Renode на пару GCC/CMake, `Clear` между сценариями, синхронный лог; Renode в CI 3:42 → 0:33.
- [x] `claude/docker-image-cache` слита в main (`c65a7ed`): кэш слоёв BuildKit (`type=gha`) только для образа эмуляторов (3:08 → 0:12); образ компиляторов без кэша — выигрыша нет.
- [x] `claude/qemu-prebuilt` слита в main (`5fade06`): готовый QEMU 11.0.0 в `tools/qemu` (3,7 МБ, скрипт сборки, SHA-256 в lock) вместо компиляции в образе; Windows — scoop/установщик.
- [x] Ветка `claude/release-0.9.3` слита в main ([PR #41](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/41), merge `29e64a4`) (ТЗ 1.2): в lock и образ CI добавлены STM32CubeH7 1.13.0, STM32CubeH5 1.7.0, FreeRTOS-Kernel 11.3.1 (ТЗ 8.8.1); ТЗ 1.5: CRC по секциям Flash (TC-63, TC-64), Arduino Core напрямую и CMake 3.21 — в 0.10.x; `AGENTS.md`. Группа CRC (`4cd3404`): образ по секциям Flash, провал сборки при сбое (E006), проверка секции на Configure, предупреждение `crc_algorithm` (E004). Группа 1 (`d8708b4`): ключи только из профиля (E008), только `profiles:` из `profiles_file`, зависимости Configure, текст о версии, значения для неполного IOC, формат и неприменённые размеры heap/stack, подсказка `hal_conf.h`; 125 сценариев × 6 = 750. Вопрос 10.2.16 решён: только внешние профили и предупреждение о встроенных (закрыть в ревизии ТЗ). Группа 2 (`b9a6cd3`): предупреждения о неизвестных значениях перечислимых ключей и элементов `build_artifacts`, артефакт `srec`; 127 × 6 = 762. Имена `lss`/`map`: решено оставить как в 0.9.2 (по имени цели); в ревизии ТЗ уточнить п. 4.14.2, выбор имён артефактов по итоговому имени ELF — на будущее, с учётом нескольких backend. Группа 3, уровень Configure (`3c6bfa3`): ядро MCU (H7), external FreeRTOS (E007), ранние проверки компонентов HAL/FreeRTOS и обёртки CMSIS-RTOS, таблица портов, проверка RAM с CCRAM/RAM_SHARE; TC-22, TC-54…TC-56, TC-58, TC-60, TC-61; 139 × 6 = 834. Прошивки (`422cef1`): `freertosExternal` в QEMU/Renode (TC-59), H7/H5 build-only (TC-57), образ CRC H503 с резервной SRAM (TC-63), сравнение с `--gap-fill` (TC-64); 102 сборки, 84 + 84 запуска. Решено и сделано (`2625f19`): предупреждение о `_sstack` (п. 1, вариант «в»), BIN из секций FLASH (п. 2). Примеры demo-stm32-cmake/stm32h5xx собираются без CRC; с CRC — после добавления секции `.checksum` в шаблон. Группа 4: прошивки H7/H5 запускаются в Renode на минимальных моделях (QEMU для них не применим), версия 0.9.3, ТЗ ревизии 1.6 (10.2.16 закрыт, 4.11.10, 4.14.2, 8.8.5, TC-65, TC-66), полный локальный прогон L0–L5 на итоговом коммите. ТЗ 1.7 (`d40f23d`): баннер, TC-52 в сборщике, п. 3.6.6, 4.10.2. Этап 5 (ТЗ 1.8, п. 8.8.8, TC-67): матрица прошивок по целям с полным набором профилей, по одному семейству. F0 `STM32F030R8T6` — сделано: QEMU `netduino2` (ядро M3), Renode `f030-smoke` (cortex-m0); `portasm.c` для `ARM_CM0` FreeRTOS-Kernel 11; 180 сборок, 168 + 192 запуска. F4 `STM32F411CEU6`, `STM32F401CCU6` — сделано: QEMU `netduinoplus2`, Renode `f4-smoke` (cortex-m4); 336 сборок, 336 + 360 запусков. G4 `STM32G431CBU6`, `STM32G474CEU6` — сделано: только Renode `g4-smoke`; 492 сборки, 336 + 528 запусков. F7 `STM32F746ZGT6` — сделано: только Renode `f7-smoke`; 570 сборок, 336 + 612 запусков. Подготовка выпуска (ТЗ 1.9): CHANGELOG на русском и английском в едином формате, описание эмуляторов по семействам и их особенностей, уровней проверок и расположения тестов, статусы errata; полный локальный прогон L0–L5 на итоговом коммите. Тег `v0.9.3` ставится на merge-коммит ветки `claude/docs-0.9.3-review`, чтобы выпуск включал согласованную документацию.
- [x] Ветка `claude/docs-0.9.3-review` слита в main (PR #42, #43); выпуск [v0.9.3](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/releases/tag/v0.9.3) опубликован, тег на `67562c0`. Только документация: сверка документации 0.9.3 с кодом и тестами — статусы errata `released` и `docs/reference-index.json`, отметки 0.9.3 в карточках, руководство пользователя, сценарии, диагностика, навыки, счётчики прошивочной матрицы, порядок выпуска в `maintenance.md`.
- [x] Ветка `claude/ci-filters-support` слита в main (PR #45): Configure не запускается при изменении только `.github/FUNDING.yml` или `LICENSE`; Emulation environment пропускает правки `.md`; в README — Telegram-канал техподдержки [MCU CI/CD & HIL](https://t.me/mcu_cicd_hil).
- [x] Ветка `claude/issue-templates` слита в main (PR #46): форма Issue `.github/ISSUE_TEMPLATE/bug_report.yml` (версия, стадия, backend, МК и плата, ОС, версии инструментов, команда, `stm32_config.yml`, полный лог) и ссылки на Telegram-канал и диагностику; Configure не запускается при изменении только шаблонов.
- [x] `claude/faster-ci-image` слита в main (`955b09b`): параллельная установка и Cube без `Projects`/`Utilities` (3,9 → 1,3 ГБ); образ компиляторов в CI 2:45 → 1:09–1:29, Configure 4:47, Firmware 4:39. Разнесение пар по job — не принято, см. [сопровождение](docs/ru/maintenance.md).
- [ ] Затем оценить ограниченное распараллеливание.
- [ ] Далее согласовать полный Arduino runtime; ядра/ABI F0, F1, F4, G4, F7 проверяются с 0.9.3 — [план](docs/ru/firmware-plan.md).
- [ ] По индексу выбрать следующие пробелы покрытия: отсутствующие/пустые значения,
  приоритеты и ошибки входных данных. Каждый новый контракт — отдельный сценарий.
- [x] [E004 и E006](docs/ru/errata/index.md) (выбор алгоритма CRC и обработка ошибок
  CRC) исправлены в 0.9.3 с регрессиями.
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

### План 0.10.0

Предварительный план от 2026-09-30; состав версии утверждается ревизией ТЗ 2.0.
Firmware на GitHub запускается вручную на границах этапов; полный прогон L0–L5 —
локально в конце каждого этапа. Ветки сливаются перемоткой (`git land`).

- [x] **Этап 0. Технический долг 0.9.3** — слит в main перемоткой (ветки `claude/stage0-tech-debt`, `claude/howto-agent-schemes`):
  ТЗ 1.10 (слияние перемоткой, схема CI, запись вопроса 10.2.16), Firmware вручную и
  на тегах `v*`, Configure не запускается от `docs/reference-index.json`, повтор
  загрузок curl при любых ошибках, `actions/checkout` и `actions/upload-artifact` v7.0.1
  (Node 24), префиксы веток `gemini/`, `dev/`, памятка `docs/ru|en/HOWTO.md`,
  изменения 0.9.3 в навыках, устаревшие комментарии H7/H5. Код фреймворка не меняется.
- [x] **Этап 1. Решения и ТЗ 2.0–2.4** — ветки `claude/spec-*`: ТЗ 2.0 — CMake ≥ 3.21, режимы Arduino `wrappers` и `native`, выбор платы, источник CMSIS (вопросы 10.2.20, 10.2.21, прототип п. 10.3.6); ТЗ 2.1 — коды сообщений, каталог RU/EN, файлы сообщений (10.2.22, 10.2.23, п. 10.3.7); ТЗ 2.2 — каталоги сборки `_deps/…` и артефакты по имени ELF (10.2.24, п. 10.3.8); ТЗ 2.3 — `include:`, TOML, имена по умолчанию, итоговая конфигурация, пример пресета, JSON Schema, версии компонентов, `system_library: none` (10.2.25, п. 10.3.9); ТЗ 2.4 — задание CI на Windows, пример `.gitlab-ci.yml`, справочник продолжает существующий, `arduino.use_core_main` в режиме `native` (10.2.26–10.2.28, п. 10.3.10). Все вопросы состава 0.10.0 закрыты.
- [x] **Этап 2. Основа** — ветки `claude/msg-*`, `claude/versions-syslib`, `claude/stage2-tests`, ТЗ 2.5:
  коды сообщений и каталог RU/EN (183 кода), выбор языка, файлы сообщений Configure и
  сборки, перечень кодов в справочнике, поле в форме Issue; версии компонентов;
  `system_library: none`; TC-41, TC-42, TC-45; ошибка `SCY-E415` для отсутствующей версии
  STM32Cube. 163 сценария / 978 запусков.
- [x] **Этап 3. Изменения для пользователей** — ветки `claude/cmake-3.21`, `claude/build-dirs`,
  `claude/artifacts`, `claude/arduino-wrappers`, `claude/arduino-native`, `claude/arduino-docs`,
  `claude/arduino-mcu-target`, ТЗ 2.6: CMake ≥ 3.21; каталоги сборки по пути, внешние в `_deps/`;
  артефакты по итоговому имени ELF рядом с ELF; режим Arduino `wrappers` с целями
  `Arduino::Options` и `Arduino::Platform`, режим `native`, `arduino.use_core_main`,
  руководство по backend Arduino; прошивки `native` в матрице L4 (сборка). 207 сценариев /
  1242 запуска, 618 сборок. Полный L0–L5 и Firmware на `main` @ `d3cb266`.
- [x] `codex/config-include` слита: `main` @ `c77eebd`, Docs/Configure PASS; YAML include, effective.json и 16 новых сценариев.
- [x] `codex/configure-ci-speedup` слита: `7628218`, все CI PASS; первый Configure 10:23 вместо 17:55, тесты 2:38 вместо 8:06.
- [x] `codex/config-formats` слита: `753b5bc`, TOML, автовыбор файла, 19 новых сценариев; 1452 Configure PASS, Docs/Configure для отправленного коммита PASS.
- [x] `codex/config-schema-presets` слита в main (`e5d93c6`): Schema и совместный пример Presets + YAML. Полный локальный L0–L5 PASS: 1452 Configure, 618 сборок, 336 QEMU + 612 Renode; Docs, Configure, CI environment и ручной [Firmware](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/actions/runs/36925400885) для этого SHA PASS.
- [x] `codex/migration-guide` слита в main (`e5e7b3f`): руководство перехода RU/EN, навигация, итоги этапа 4; Docs/Configure/CI environment на коммите ветки PASS.
- [x] `codex/release-docs-review` слита в main (`2810579`): README, статус, границы версий справочника.
- [x] `codex/release-0.10.0` слита; [v0.10.0](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/releases/tag/v0.10.0) опубликована 02.10.2026, подписанный тег на `02b335e`. Полный локальный L0–L5 и CI на том же SHA PASS: 1452 Configure, 618 сборок, 336 QEMU + 612 Renode.
- [x] `codex/release-0.10.0-close` слита (`0500b68`): выпуск и полная приёмка зафиксированы, ТЗ 2.13.
- [x] **Этап 4. Расширения конфигурации:** `include:`, TOML, имена файла по умолчанию,
  итоговая конфигурация, JSON Schema, пример пресета в документации.
- [ ] **Этап 5. Тесты и CI — перенесён на версию после 0.10.0** (решение заказчика, ТЗ 2.6):
  периферия в эмуляторах (группа 5), модели RCC/PWR для запуска прошивок Arduino `native`
  (TC-86), задание CI на Windows (TC-44), пример `.gitlab-ci.yml` (TC-53),
  распараллеливание при необходимости.
- [x] **Этап 6. Выпуск 0.10.0:** руководство по переходу с 0.9.x (в том числе таблица
  путей артефактов и фрагменты из CHANGELOG), карточки справочника
  с отметками 0.10.0, CHANGELOG, ТЗ к выпуску, L0–L5, Firmware в CI, тег `v0.10.0`.

### Предлагаемый состав 0.10.1 — на согласование

План подготовлен в `codex/plan-0.10.1`. Это предложение состава, не утверждение
о реализованных исправлениях; требования 0.10.0 и опубликованный тег не меняются.
Фокус — переносимость диагностики и Windows, без расширения матрицы MCU.

| Шаг / будущая ветка | Объём | Условие завершения |
| --- | --- | --- |
| 1. `codex/utf8-diagnostics` | Контракт UTF-8 для stdout и stderr CLI-скрипта, регрессия, errata, карточка диагностики, CHANGELOG RU/EN и ревизия ТЗ | Тест сначала воспроизводит дефект 0.10.0, затем проходит; тексты, коды, код возврата и бинарный результат не меняются |
| 2. `codex/windows-ci` | Быстрая проверка кодировок на Windows/Linux на релевантные push; отдельное нативное Windows-задание по TC-44 на одной закреплённой паре инструментов | Кодировки, CRLF, пути с обратной косой чертой/другим диском, выбор языка, версии компонентов, минимальная Configure/Build проверены; TC-44 закрывается только при полном выполнении п. 8.5.7 |
| 3. `codex/gitlab-example` | Отложенный пример GitLab CI (TC-53) в документации RU/EN: Configure, артефакты, закреплённое окружение | Команды проверены локально; запуск на GitLab не объявляется проверенным без реального конвейера |
| 4. `codex/release-0.10.1` | Согласование версий и документации, приёмка и компактная релизная страница | Полный локальный L0–L5 на итоговом подписанном SHA, CI/Firmware на том же SHA, land, тег и публикация владельцем |

Шаги 1–2 — рекомендуемый обязательный состав исправительного выпуска. Шаг 3 —
дополнительный небольшой объём: он не должен задерживать исправление кодировки.
Полные Linux-матрицы не дублируются на Windows; тяжёлое Windows-задание запускается
вручную на границах этапов и на тегах вместе с Firmware. Правила фильтрации
изменений сохраняются. Длительность новых jobs измеряется до принятия решения
о расширении матрицы; обещания фиксированного времени пока нет.

**План проверки кодировок:**

- Читать stdout/stderr дочернего процесса как байты и строго декодировать UTF-8;
  сравнивать точный русский/английский текст и коды, а не только отсутствие исключения.
- Перед запуском процесса принудительно задавать `PYTHONIOENCODING=cp1251`, `cp866`
  и `utf-8`, отключать автоматический UTF-8 mode; проверить также обычное окружение.
  Проверка должна обнаруживать проблему и на runner с английской локалью.
- Проверять успешный вывод, ошибки в stderr, pipe, файл, кириллицу в сообщениях
  и путях, UTF-8 JSONL, коды завершения; сохранить проверку английского fallback.
- Проверять отсутствие изменения глобальных потоков при импорте Python-модуля.
  Настройка кодировки выполняется на входе CLI, не на уровне импорта.
- Минимальная CMake/Ninja-проверка захватывает фактические байты POST_BUILD без
  подключения к устройствам. Настройки VS Code и интерактивную консоль проверять
  отдельно: зелёный тест pipe не доказывает правильную настройку любого декодера IDE.

**Вариант реализации для исследования:** предпочесть `TextIOWrapper.reconfigure`
для существующих stdout/stderr. Предложенный `open(1, ..., closefd=False)` фиксирует
кодировку stdout, но создаёт новую обёртку и не покрывает stderr; не применять его
без проверки буферизации, перенаправления и подменённых потоков. Отдельно определить
поведение для `StringIO`/отсутствующего потока и политику ошибок кодирования.
Не маскировать ошибку декодирования заменой символов. Python 3.7+ поддерживает
[reconfigure](https://docs.python.org/3/library/io.html#io.TextIOWrapper.reconfigure).
У CMake Tools есть настройка
[cmake.outputLogEncoding](https://github.com/microsoft/vscode-cmake-tools/blob/main/docs/cmake-settings.md);
её влияние описать в HOWTO, а не пытаться менять настройки IDE из фреймворка.

**Дополнительные наблюдения из пользовательского лога 0.10.0:**

- Русские сообщения Configure читаются корректно, искажается Python POST_BUILD;
  сборка завершилась кодом 0. Регрессия должна отдельно покрыть успешные CRC/BIN
  сообщения stdout, а не только ошибки stderr.
- `Stack Size: 1K байт` — неоднозначная подпись до нормализации; ниже в том же
  логе значение правильно преобразовано в 1024. Кандидат: помечать исходную
  запись или показывать нормализованные байты без изменения порядка обработки.
- Строка «Порт» содержит также Heap и Timers. Кандидат: уточнить название строки
  как перечня компонентов, сохранив значения и стабильный код сообщения.
- `stm32-cmake: v2.1.0+` — существующий fallback из CHANGELOG при недоступном
  git describe, не подтверждение конкретного checkout и не доказательство ошибки.
  Пояснить в диагностической памятке; не менять глобальный git safe.directory.
- Версии CMake/yq из лога новее закреплённой матрицы. Успех одного проекта не
  расширяет заявленное покрытие; дополнительную совместимость планировать отдельно.
- Предупреждение VS Code о переопределениях пресета и строка поиска FreeRTOS
  по /opt — не ошибки сами по себе; далее в логе зависимость успешно найдена.

Исправления подписей включать после уточнения контракта в ТЗ, с регрессией
RU/EN. Не добавлять новые ветки тестирования прошивок ради изменения текста.

**Дополнение: локализация CRC и описание формата образа (согласовано по направлению):**

- После исправления UTF-8 выделить `codex/crc-diagnostics`: сообщения начала,
  успешного завершения и ошибки внедрения через общий каталог RU/EN и JSONL.
  Префикс `[STM32 CRC32]` относится к операциям CRC; отдельное создание BIN
  сохраняет `[STM32 BIN]`. Значение CRC и диагностические коды не локализуются.
- Имя секции берётся из эффективного `crc_section_name` (включая alias
  `crc.section_name`, профиль и override), а не из литерала `.checksum`.
  В сообщениях показать секцию, алгоритм и понятное описание текущего способа
  размещения. Успех выводить только после успешного objcopy; при его отказе
  сохранить stderr/код возврата и добавить контекст секции/ELF. Проверить
  отсутствие ложного сообщения успеха при любой ошибке.
- Ветка `codex/crc-layout-docs`: отдельная страница RU/EN со ссылками из справочника
  и HOWTO. Различать алгоритм, диапазон данных, размещение CRC и формат метаданных.
  CRC — контроль целостности, не криптографическая подпись и не аутентификация.
- Описать предложенную схему как соглашение linker template: все секции с LMA
  во FLASH, включая загрузочную копию .data, предшествуют слову CRC; после
  таблицы векторов записан LONG(__checksum_size) с предварительным ALIGN(4).
  __checksum_start должен совпадать с началом рассчитанного образа;
  __checksum_end указывает на начало CRC, размер исключает четыре байта CRC.
  LONG(0) в секции CRC — резерв до post-build, не поле длины.
- Нулевой остаток подтверждён локально на трёх синтетических наборах существующим
  stm32_crc32 при дописывании CRC как little-endian слова. Регрессии должны
  проверять кратность длины четырём, заполнение промежутков 0xFF, диапазон LMA,
  произвольное имя секции и отсутствие FLASH-данных после CRC. Только при
  совпадающем образе свойство нулевого остатка применимо к полному файлу.
- Пример считывания — на нейтральном синтетическом образе: проверить границы и
  длину, прочитать поле длины и CRC в установленном порядке байтов, сравнить
  расчёт с сохранённым значением либо проверить остаток полного образа.
  Не фиксировать универсальное смещение поля после векторов: оно зависит от
  таблицы и выравнивания. Исходные проекты пользователя не изменять.
- Зарезервировать `crc_method` (alias `crc.method`) отдельно от `crc_algorithm`:
  отсутствие/пустое значение/`none` сохраняют текущее поведение и не отключают
  CRC; включением управляет `crc_enable`. Имена будущих методов пока не вводить.
  Предложение для контракта: другие непустые значения отклонять с понятной
  диагностикой, чтобы не создавать видимость реализованного метода.
- Резервирование ключа само по себе не делает предложенную раскладку обязательной
  для всех существующих проектов. Не объявлять наличие проверок расположения
  CRC или символов, которых код пока не выполняет. Новый контракт, карточка,
  индекс/Schema, CHANGELOG и тесты ключа оформляются в соответствующей ветке.

**За пределами 0.10.1:** модели RCC/PWR и периферия эмуляторов (TC-86),
запуск Arduino native в эмуляторах, USBDevice/VirtIO/CMSIS_DSP и расширение
матрицы семейств. Это самостоятельные функциональные этапы с большей
неопределённостью, а не условие исправления консольного вывода.

### Предложения для 0.10.x — на рассмотрение

В ТЗ не внесены; решение принимается при планировании 0.10.x.

Прежние предложения (коды сообщений, локализация, TOML, имена каталогов в build и
артефактов) приняты в 0.10.0 ревизиями ТЗ 2.1–2.3; генератор CMakePresets отклонён (п. 5.1.4 ТЗ).

- [ ] Библиотеки ядра Arduino с дополнительными зависимостями в режиме `native`: USBDevice,
  VirtIO, CMSIS_DSP (вопрос 10.2.28 ТЗ; после стабилизации 0.10.0).

## English

Status as of 2026-09-27. Work is grouped into five stages, which may overlap.
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
  The external fix was deferred on 2026-09-25 and done in 0.9.3 (`3c6bfa3`).
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
- [x] `codex/readme-overview` merged into main (`0940142`): introductory RU/EN READMEs, separate status pages, skills and related projects.
- [x] `codex/firmware-count-badge` merged into main (`23a6d67`): confirmed build and QEMU check badge.
- [x] `codex/renode-firmware-smoke` merged into main (`493771d`): 18 builds, 24 QEMU + 24 Renode; shared SYS_WRITE0 and exit adapter.
- [x] `codex/firmware-build-modes` merged into main (`ba9bde7`): bare metal/CMSIS without HAL, `.ld`/`.ld.in`; 42 builds and 96 QEMU+Renode checks.
- [x] `codex/firmware-libraries` merged into main (`a53f809`): C/C++ and ETL, 54 builds / 120 checks; E008 without a fix (fixed later, in 0.9.3).
- [x] `codex/badges-docs-ci` merged into main (`a3015d9`): rectangular badges without icons, `Builds (Checks)`, skip heavy CI for MD-only pushes.
- [x] `codex/firmware-arduino-string` merged into main (`5743602`): own main, real String from Core 2.12.0, 60 builds / 132 checks.
- [x] `codex/firmware-freertos-queue` merged into main (`4109bc8`): queues and Heap::4 before scheduler startup; 66 builds / 144 checks.
- [x] `codex/firmware-freertos-tasks` merged into main (`f16eb09`): starter, two-task exchange, SysTick without HAL; 72 builds / 156 checks, shared badge color.
- [x] `codex/badge-status-and-timings` merged into main (`7246a2c`): shared Shields rendering, PASS/FAIL, #238636; QEMU hang 2 s and per-case timings.
- [x] `claude/renode-batch` merged into main (`aa58116`): one Renode process per GCC/CMake pair, `Clear` between cases, synchronous logging; Renode in CI 3:42 → 0:33.
- [x] `claude/docker-image-cache` merged into main (`c65a7ed`): BuildKit layer cache (`type=gha`) for the emulator image only (3:08 → 0:12); the compiler image stays uncached — no gain.
- [x] `claude/qemu-prebuilt` merged into main (`5fade06`): prebuilt QEMU 11.0.0 in `tools/qemu` (3.7 MB, build script, SHA-256 in the lock) instead of compiling it in the image; Windows via scoop/installer.
- [x] Branch `claude/release-0.9.3` merged into main ([PR #41](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/pull/41), merge `29e64a4`) (spec 1.2): STM32CubeH7 1.13.0, STM32CubeH5 1.7.0 and FreeRTOS-Kernel 11.3.1 added to the lock and CI image (spec 8.8.1); spec 1.5: CRC from FLASH sections (TC-63, TC-64), direct Arduino Core and CMake 3.21 in 0.10.x; `AGENTS.md`. CRC group (`4cd3404`): image from FLASH sections, build failure on errors (E006), Configure section check, `crc_algorithm` warning (E004). Group 1 (`d8708b4`): profile-only keys (E008), only `profiles:` from `profiles_file`, Configure dependencies, version wording, incomplete-IOC defaults, heap/stack format and unapplied-size warning, `hal_conf.h` hint; 125 scenarios × 6 = 750. Question 10.2.16 decided: external profiles only, with a warning about inline ones (close in the spec revision). Group 2 (`b9a6cd3`): warnings for unknown enumerated values and `build_artifacts` elements, `srec` artifact; 127 × 6 = 762. `lss`/`map` names: decided to keep the 0.9.2 behaviour (target name); clarify spec 4.14.2 in the revision; naming all artifacts after the final ELF name is deferred, considering several backends. Group 3, Configure level (`3c6bfa3`): MCU core (H7), external FreeRTOS (E007), early HAL/FreeRTOS component and CMSIS-RTOS wrapper checks, port table, RAM check with CCRAM/RAM_SHARE; TC-22, TC-54…TC-56, TC-58, TC-60, TC-61; 139 × 6 = 834. Firmware (`422cef1`): `freertosExternal` in QEMU/Renode (TC-59), H7/H5 build-only (TC-57), H503 CRC image with backup SRAM (TC-63), `--gap-fill` comparison (TC-64); 102 builds, 84 + 84 runs. Decided and done (`2625f19`): `_sstack` warning (item 1, option c), BIN from FLASH sections (item 2). The demo-stm32-cmake/stm32h5xx examples build without CRC, and with CRC once the template has a `.checksum` section. Group 4: H7/H5 firmware runs in Renode on minimal models (QEMU has no matching machine), version 0.9.3, spec revision 1.6 (10.2.16 closed, 4.11.10, 4.14.2, 8.8.5, TC-65, TC-66), full local L0–L5 run on the final commit. Spec 1.7 (`d40f23d`): banner, TC-52 in the builder, items 3.6.6, 4.10.2. Stage 5 (spec 1.8, item 8.8.8, TC-67): per-target firmware matrix with the full profile set, one family at a time. F0 `STM32F030R8T6` done: QEMU `netduino2` (M3 core), Renode `f030-smoke` (cortex-m0); `portasm.c` for `ARM_CM0` in FreeRTOS-Kernel 11; 180 builds, 168 + 192 runs. F4 `STM32F411CEU6`, `STM32F401CCU6` done: QEMU `netduinoplus2`, Renode `f4-smoke` (cortex-m4); 336 builds, 336 + 360 runs. G4 `STM32G431CBU6`, `STM32G474CEU6` done: Renode `g4-smoke` only; 492 builds, 336 + 528 runs. F7 `STM32F746ZGT6` done: Renode `f7-smoke` only; 570 builds, 336 + 612 runs. Release preparation (spec 1.9): Russian and English CHANGELOG in one format, emulators per family and their specifics, test levels and test locations, errata statuses; full local L0–L5 run on the final commit. Tag `v0.9.3` goes on the merge commit of `claude/docs-0.9.3-review`, so the release includes the aligned documentation.
- [x] Branch `claude/docs-0.9.3-review` merged into main (PR #42, #43); release [v0.9.3](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/releases/tag/v0.9.3) published, tag on `67562c0`. Documentation only: 0.9.3 documentation checked against code and tests — errata statuses `released` and `docs/reference-index.json`, 0.9.3 notes in the cards, user manual, scenarios, troubleshooting, skills, firmware-matrix counts, release procedure in `maintenance.md`.
- [x] Branch `claude/ci-filters-support` merged into main (PR #45): Configure is skipped when only `.github/FUNDING.yml` or `LICENSE` changes; Emulation environment skips `.md` edits; the README links the Telegram support channel [MCU CI/CD & HIL](https://t.me/mcu_cicd_hil).
- [x] Branch `claude/issue-templates` merged into main (PR #46): issue form `.github/ISSUE_TEMPLATE/bug_report.yml` (version, stage, backend, MCU and board, OS, tool versions, command, `stm32_config.yml`, full log) with links to the Telegram channel and troubleshooting; Configure is skipped when only templates change.
- [x] `claude/faster-ci-image` merged into main (`955b09b`): parallel installation and Cube without `Projects`/`Utilities` (3.9 → 1.3 GB); compiler image in CI 2:45 → 1:09–1:29, Configure 4:47, Firmware 4:39. Splitting pairs across jobs — not adopted, see [maintenance](docs/en/maintenance.md).
- [ ] Then evaluate bounded parallelism.
- [ ] Next agree full Arduino runtime; F0, F1, F4, G4 and F7 cores/ABI are checked since 0.9.3 — [plan](docs/en/firmware-plan.md).
- [ ] Use the index to prioritize coverage gaps: missing/empty values, precedence
  and invalid input. Give each new contract a dedicated scenario.
- [x] [E004 and E006](docs/en/errata/index.md) (CRC algorithm selection and CRC error
  handling) are fixed in 0.9.3 with regressions.
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

### 0.10.0 plan

Preliminary plan of 2026-09-30; the version scope is approved by spec revision 2.0.
Firmware on GitHub runs manually at stage boundaries; a full L0–L5 run is done locally
at the end of each stage. Branches are merged by fast-forward (`git land`).

- [x] **Stage 0. 0.9.3 technical debt** — fast-forwarded into main (branches `claude/stage0-tech-debt`, `claude/howto-agent-schemes`):
  spec 1.10 (fast-forward merges, CI scheme, question 10.2.16 record), Firmware manual
  and on `v*` tags, Configure not triggered by `docs/reference-index.json`, curl retries
  on any error, `actions/checkout` and `actions/upload-artifact` v7.0.1 (Node 24),
  `gemini/` and `dev/` branch prefixes, the `docs/ru|en/HOWTO.md` how-to, 0.9.3 changes
  in the skills, stale H7/H5 comments. Framework code is unchanged.
- [x] **Stage 1. Decisions and spec 2.0–2.4** — branches `claude/spec-*`: spec 2.0 — CMake ≥ 3.21, Arduino `wrappers` and `native` modes, board selection, CMSIS source (questions 10.2.20, 10.2.21, prototype 10.3.6); spec 2.1 — message codes, RU/EN catalog, message files (10.2.22, 10.2.23, 10.3.7); spec 2.2 — `_deps/…` build directories and artifacts named after the ELF (10.2.24, 10.3.8); spec 2.3 — `include:`, TOML, default file names, effective configuration, preset example, JSON Schema, component versions, `system_library: none` (10.2.25, 10.3.9); spec 2.4 — a Windows CI job, a `.gitlab-ci.yml` example, the existing reference continues, `arduino.use_core_main` in `native` mode (10.2.26–10.2.28, 10.3.10). All 0.10.0 scope questions are closed.
- [x] **Stage 2. Groundwork** — branches `claude/msg-*`, `claude/versions-syslib`, `claude/stage2-tests`, spec 2.5:
  message codes and the RU/EN catalog (183 codes), language choice, Configure and build
  message files, the code list in the reference, the issue form field; component versions;
  `system_library: none`; TC-41, TC-42, TC-45; `SCY-E415` for a missing STM32Cube
  version. 163 cases / 978 runs.
- [x] **Stage 3. User-facing changes** — branches `claude/cmake-3.21`, `claude/build-dirs`,
  `claude/artifacts`, `claude/arduino-wrappers`, `claude/arduino-native`, `claude/arduino-docs`,
  `claude/arduino-mcu-target`, spec 2.6: CMake ≥ 3.21; build directories by path, out-of-tree
  ones in `_deps/`; artifacts named after the final ELF next to it; the Arduino `wrappers`
  mode with the `Arduino::Options` and `Arduino::Platform` targets, the `native` mode,
  `arduino.use_core_main`, the Arduino backend guide; `native` firmware in the L4 matrix
  (build). 207 cases / 1242 runs, 618 builds. Full L0–L5 and Firmware on `main` @ `d3cb266`.
- [x] `codex/config-include` merged: `main` @ `c77eebd`, Docs/Configure PASS; YAML includes, effective.json and 16 new cases.
- [x] `codex/configure-ci-speedup` merged: `7628218`, all CI PASS; first Configure 10:23 vs 17:55, tests 2:38 vs 8:06.
- [x] `codex/config-formats` merged: `753b5bc`, TOML, file discovery, 19 new cases; 1452 Configure PASS, Docs/Configure for the pushed commit PASS.
- [x] `codex/config-schema-presets` merged into main (`e5d93c6`): Schema and paired Presets + YAML example. Full local L0–L5 PASS: 1452 Configure, 618 builds, 336 QEMU + 612 Renode; Docs, Configure, CI environment and manual [Firmware](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/actions/runs/36925400885) for that SHA PASS.
- [x] `codex/migration-guide` merged into main (`e5e7b3f`): RU/EN migration guide, navigation, stage 4 results; Docs/Configure/CI environment for the branch commit PASS.
- [x] `codex/release-docs-review` merged into main (`2810579`): README, status and reference version boundaries.
- [x] `codex/release-0.10.0` merged; [v0.10.0](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/releases/tag/v0.10.0) published on 2026-10-02, signed tag at `02b335e`. Full local L0–L5 and CI for the same SHA PASS: 1452 Configure, 618 builds, 336 QEMU + 612 Renode.
- [x] `codex/release-0.10.0-close` merged (`0500b68`): published release and full acceptance recorded, specification 2.13.
- [x] **Stage 4. Configuration extensions:** `include:`, TOML, default file names,
  effective configuration, JSON Schema, a preset example in the documentation.
- [ ] **Stage 5. Tests and CI — moved to the version after 0.10.0** (customer decision,
  spec 2.6): peripherals in emulators (group 5), RCC/PWR models to run Arduino `native`
  firmware (TC-86), a Windows CI job (TC-44), a `.gitlab-ci.yml` example (TC-53),
  parallelism if needed.
- [x] **Stage 6. 0.10.0 release:** migration guide from 0.9.x (including the artifact
  path table and snippets from the CHANGELOG), reference cards marked
  0.10.0, CHANGELOG, release spec, L0–L5, Firmware in CI, tag `v0.10.0`.

### Proposed 0.10.1 scope — for agreement

Prepared in `codex/plan-0.10.1`. This is a scope proposal, not a claim that fixes
exist; the 0.10.0 requirements and published tag remain unchanged. Focus:
diagnostic portability and Windows, without expanding the MCU matrix.

| Step / future branch | Scope | Completion condition |
| --- | --- | --- |
| 1. `codex/utf8-diagnostics` | UTF-8 CLI stdout/stderr contract, regression, errata, diagnostic card, RU/EN changelogs and spec revision | Test reproduces 0.10.0 failure before the fix; text, codes, exit status and binary results remain unchanged |
| 2. `codex/windows-ci` | Fast Windows/Linux encoding checks on relevant pushes; separate native Windows TC-44 job on one pinned tool pair | Encoding, CRLF, backslash/cross-drive paths, language selection, component versions and minimal Configure/Build verified; close TC-44 only after all of spec 8.5.7 passes |
| 3. `codex/gitlab-example` | Deferred GitLab CI documentation example (TC-53), RU/EN: Configure, artifacts and pinned environment | Commands tested locally; do not claim GitLab execution without a real pipeline |
| 4. `codex/release-0.10.1` | Version/documentation alignment, acceptance and compact release notes | Full local L0–L5 on the final signed SHA, CI/Firmware on that SHA, owner performs land, tag and publication |

Steps 1–2 are the recommended required patch-release scope. Step 3 is a small
optional addition and must not delay the encoding fix. Do not duplicate the full
Linux matrices on Windows. Run the heavier Windows job manually at stage boundaries
and on tags alongside Firmware. Preserve change filtering. Measure new job duration
before expanding coverage; no fixed runtime is promised yet.

**Encoding test plan:**

- Capture child stdout/stderr as bytes, strictly decode UTF-8 and compare exact
  Russian/English text and codes, rather than merely checking for no exception.
- Start children with `PYTHONIOENCODING=cp1251`, `cp866` and `utf-8`, disabling
  automatic UTF-8 mode; also test the default environment. The regression must
  detect the defect on an English-locale runner too.
- Cover successful stdout, error stderr, pipes, files, Cyrillic text and paths,
  UTF-8 JSONL and exit status; retain the English fallback check.
- Verify that importing the module does not change global streams. Configure
  encoding at CLI entry, not at import time.
- A minimal CMake/Ninja check captures actual POST_BUILD bytes without device
  access. Verify VS Code settings and an interactive console separately: a green
  pipe test does not establish correct configuration of every IDE decoder.

**Implementation candidate:** prefer `TextIOWrapper.reconfigure` on existing
stdout/stderr. The proposed `open(1, ..., closefd=False)` fixes stdout encoding but
creates a new wrapper and does not cover stderr; check buffering, redirection and
replaced streams before using it. Define behaviour for `StringIO`/missing streams
and encoding errors separately. Do not hide decode errors with replacement characters.
Python 3.7+ provides
[reconfigure](https://docs.python.org/3/library/io.html#io.TextIOWrapper.reconfigure).
CMake Tools exposes
[cmake.outputLogEncoding](https://github.com/microsoft/vscode-cmake-tools/blob/main/docs/cmake-settings.md);
document its effects in HOWTO instead of changing IDE settings from the framework.

**Additional observations from a user-provided 0.10.0 log:**

- Russian Configure output is readable; Python POST_BUILD output is corrupted;
  the build exits with code 0. Cover successful CRC/BIN stdout as well as stderr
  failures in the encoding regression.
- `Stack Size: 1K bytes` is an ambiguous pre-normalization label; the same log
  later correctly normalizes it to 1024. Candidate: label the original notation
  or print normalized bytes without changing processing order.
- The “Port” line also lists Heap and Timers. Candidate: label it as a component
  list while retaining its values and stable message code.
- `stm32-cmake: v2.1.0+` is the existing CHANGELOG fallback when git describe is
  unavailable, not confirmation of an exact checkout or proof of an error.
  Explain it in HOWTO; do not change global git safe.directory.
- Logged CMake/yq versions are newer than the pinned matrix. One successful
  project does not extend verified coverage; plan extra compatibility separately.
- VS Code preset overrides and a FreeRTOS search under /opt are not failures
  by themselves; the dependency is subsequently found successfully in the log.

Change labels only after documenting the contract in the spec, with RU/EN
regression coverage. Do not add firmware matrix branches for wording changes.

**Addition: CRC localization and image layout documentation (direction agreed):**

- After UTF-8, use `codex/crc-diagnostics` for injection start/success/failure
  messages through the RU/EN catalog and JSONL. `[STM32 CRC32]` labels CRC
  operations; separate BIN creation retains `[STM32 BIN]`. CRC values and
  diagnostic codes are not localized.
- Read the effective `crc_section_name` (including `crc.section_name`, profiles
  and overrides), never a hardcoded `.checksum`. Report section, algorithm and
  a description of the current placement convention. Success follows successful
  objcopy only; on failure preserve stderr/exit status and add section/ELF context.
  Check that no failure path reports success.
- `codex/crc-layout-docs`: a dedicated RU/EN page linked from reference/HOWTO.
  Distinguish algorithm, data range, CRC location and metadata format. CRC checks
  integrity; it is not a cryptographic signature or authentication mechanism.
- Describe the proposed linker-template convention: all FLASH LMA sections,
  including the .data load image, precede CRC. LONG(__checksum_size) follows the
  vector table with ALIGN(4) before it. __checksum_start matches the calculated
  image start; __checksum_end points to CRC, and size excludes its four bytes.
  LONG(0) in the CRC section reserves storage before post-build, not the length field.
- Zero residue was checked locally on three synthetic inputs using the existing
  stm32_crc32 with the CRC appended as a little-endian word. Regressions must
  cover word-aligned length, 0xFF gap fill, LMA ranges, a custom section name and
  no FLASH data following CRC. The full-file zero residue requires identical bytes.
- Use a neutral synthetic image for the reading example: validate bounds/length,
  read length and CRC in the defined byte order, compare calculated/stored values
  or check the complete image residue. Do not assume a universal length-field
  offset after vectors; vector size and alignment determine it. Do not modify
  the user's application projects.
- Reserve `crc_method` (alias `crc.method`) separately from `crc_algorithm`:
  missing/empty/`none` retains current behavior and does not disable CRC;
  `crc_enable` controls activation. Introduce no future method names yet.
  Proposed contract: reject other nonempty values clearly instead of suggesting
  that an unimplemented method was selected.
- Reserving the key does not enforce this layout on all existing projects.
  Do not claim CRC-position/symbol checks that the implementation does not perform.
  Add the contract, reference card, index/Schema, changelogs and key tests in the
  corresponding implementation branch.

**Outside 0.10.1:** RCC/PWR and peripheral emulator models (TC-86), Arduino native
execution, USBDevice/VirtIO/CMSIS_DSP and more MCU families. These are independent
feature stages with greater uncertainty, not prerequisites for fixing console output.

### Proposals for 0.10.x — for consideration

Not in the spec; to be decided when 0.10.x is planned.

Earlier proposals (message codes, localization, TOML, build folder and artifact names)
were accepted into 0.10.0 by spec revisions 2.1–2.3; the CMakePresets generator was rejected (spec 5.1.4).

- [ ] Arduino core libraries with extra dependencies in `native` mode: USBDevice, VirtIO,
  CMSIS_DSP (spec question 10.2.28; after 0.10.0 is stabilized).
