# Памятка: частые команды и проблемы

[Документация](index.md) · [English](../en/HOWTO.md)

Короткие рецепты для повторяющихся ситуаций. Новое решение частой проблемы
записывается сюда (RU и EN) в том же коммите, где оно найдено. Порядок работы в целом —
[сопровождение](maintenance.md#порядок-работы-с-проектом).

## Git: рабочий цикл без PR

Ветка `<агент>/<задача>` создаётся от свежего main и после проверок сливается в main
перемоткой (fast-forward), без merge-коммита. Слить без PR в веб-интерфейсе GitHub
нельзя, а автоудаление веток GitHub работает только для PR, поэтому слияние и уборка
делаются локально. Push, теги и релизы выполняет владелец репозитория.

```
git switch main
git pull --ff-only
git switch -c claude/<задача>          # новая ветка
# … коммиты …
git push -u origin claude/<задача>     # CI: дождаться зелёных Docs и Configure
git land claude/<задача>               # перемотать main, отправить, удалить ветку
```

Перемотка не создаёт merge-коммит: в main попадают те же подписанные коммиты, и
GitHub показывает их Verified. Если ветка отстала от main, `git land` остановится на
`--ff-only`, ничего не изменив. Тогда ветку переносят на свежий main и снова
подписывают:

```
git switch claude/<задача>
git rebase -S origin/main              # конфликты: исправить, git add, git rebase --continue
git push --force-with-lease            # только для своей неслитой ветки
```

Force push в main и в чужие ветки запрещён. Ссылки PR #1…#46 в истории остаются как есть.

### Схемы работы агентов

Каждый агент работает по своей схеме; здесь она описана отдельно для каждого и не
обобщается. Новый агент добавляет свой подраздел, когда его схема проверена на практике.

#### Codex в Windows

Проверено 2026-10-01 при подготовке YAML include к 0.10.0.

- Codex работает в локальной копии Windows через PowerShell и git Windows,
  создаёт ветку `codex/<задача>` от актуального main и сохраняет концы строк
  согласно `.gitattributes`. Локальные проверки выполняются до отправки ветки;
  полный L0–L5 — на завершении этапа.
- Владелец создаёт подписанный коммит из Windows (`git commit -S`), выполняет
  push и после зелёного CI — `git land`. Сообщение Conventional Commits — на
  английском, без ссылок на сессии агентов. Схема подписи не меняется.
- GitHub-коннектор позволяет прочитать REST API без извлечения токенов вручную.
  Проверяйте `actions/runs?head_sha=<SHA>` именно для `git rev-parse HEAD`, затем
  `actions/runs/<ID>/jobs` и `actions/runs/<ID>/artifacts`. Требуются все ожидаемые
  workflow со `status: completed` и `conclusion: success`; отсутствие запуска
  или зелёный отдельный job не означает успех всей проверки.
- Чтение API не обновляет локальные Git-ссылки: `git fetch origin` — отдельный
  шаг. Если Git недоступен, чтение `branches/main` через коннектор позволяет
  сравнить SHA, но не заменяет синхронизацию рабочей копии. Подпись коммита
  `verification.verified` подтверждает подпись, а не результат CI.

#### Claude в Cowork (облачная сессия, связанная с компьютером владельца)

Проверено 2026-09-30 на этапе 0 плана 0.10.0.

- Команды Claude на компьютере владельца выполняются в изолированной Linux-машине,
  куда подключена только папка репозитория. В ней нет `~/.gitconfig` и `~/.ssh`
  владельца, а концы строк CRLF рабочей копии Windows её git видит как изменения.
- Claude создаёт ветку `claude/<задача>` от `origin/main` и вносит правки прямо в файлы
  рабочей копии, сохраняя их концы строк (CRLF, а для путей с `eol=lf` — LF). Он не
  коммитит и не выполняет в этой копии git-команд, меняющих индекс или историю.
- Сообщение коммита Claude кладёт в `.git/<ИМЯ>_MSG` (вне отслеживаемых файлов) и даёт
  команду: `git add <пути>` и `git commit -F .git/<ИМЯ>_MSG`. Владелец коммитит из
  Windows — коммит подписывается его ключом, затем `git push -u origin <ветка>`.
- Claude проверяет CI через открытый API GitHub (запуски, шаги, аннотации, подпись
  коммита) и сообщает, когда делать `git land`; после него проверяет CI на main и
  удаляет свои временные файлы в `.git`.
- Если git Claude оставил `.git/index.lock` (удаление в подключённой папке требует
  разрешения), git в Windows перестанет работать: Claude запрашивает разрешение на
  удаление и убирает файл сам, либо владелец удаляет его вручную.

#### Готовые коммиты без доступа к рабочей копии

Если агент передаёт готовые коммиты (например, через `git bundle`), они не подписаны.
Перед push их переподписывают командой `git rebase -S origin/main`; хэши при этом
меняются, поэтому в документации не ссылаются на хэши коммитов той же неслитой ветки.

### Псевдоним `git land`

Установка — одинарные кавычки обязательны: в PowerShell внутри двойных кавычек `$`
подставляется самим PowerShell, а `\"` не экранирует кавычку.

```powershell
git config --global --unset-all alias.land   # если уже был; ошибка «no such section» не страшна
git config --global alias.land '!f() { b=${1:-$(git branch --show-current)}; git fetch origin && git switch main && git merge --ff-only origin/main && git merge --ff-only $b && git push --atomic origin main :$b && git branch -d $b; }; f'
git config --global --get-all alias.land     # ровно одна строка с b=${1:-$(git branch --show-current)}
```

Ту же команду в sh можно выполнить без изменений. Что делает `git land <ветка>`:
`fetch` → перемотка main до `origin/main` → перемотка main до ветки → одним атомарным
push отправка main и удаление ветки на GitHub → удаление локальной ветки.

| Проблема | Решение |
| --- | --- |
| `syntax error: unexpected end of file`, в ошибке `b=;` | Псевдоним записан в двойных кавычках из PowerShell. Удалить (`--unset-all`) и записать заново в одинарных |
| `warning: alias.land has multiple values` | `git config --global --unset-all alias.land`, затем записать заново; либо `git config --global --edit` и удалить лишние строки `land = …` |
| `fatal: Not possible to fast-forward` | Ветка отстала от main: `git rebase -S origin/main` (выше) |
| Push отклонён: protected branch, required pull request | В Settings → Rules снять требование PR для main или разрешить себе обход (bypass) |

Вернуть как было: удалить псевдоним — `git config --global --unset-all alias.land`.

### Уборка веток

```
git fetch --prune                                  # убрать ссылки на удалённые на GitHub ветки
git branch -r --merged origin/main                 # слитые ветки на GitHub
git push origin --delete <ветка> [<ветка> …]       # удалить на GitHub
git branch -vv                                     # локальные; [gone] — на GitHub уже нет
git branch -d <ветка>                              # удалить слитую локальную
git branch -D <ветка>                              # удалить, если хэш отличается, а содержимое уже в main
```

### Как вернуть состояние

| Ситуация | Команда |
| --- | --- |
| Отменить незакоммиченные правки в файлах | `git restore <файл>` или `git restore .` |
| Убрать файл из индекса, сохранив правки | `git restore --staged <файл>` |
| Удалить неотслеживаемые файлы | сначала `git clean -n` (что удалится), затем `git clean -f`; не используйте `-x` |
| Отменить последний неотправленный коммит, сохранив правки | `git reset --soft HEAD~1` |
| Локальный main испорчен, но ещё не отправлен | `git switch main && git reset --hard origin/main` |
| Удалили ветку по ошибке | `git reflog` → найти хэш → `git branch <ветка> <хэш>`; на GitHub вернуть: `git push origin <ветка>` |
| Отменить коммит, уже отправленный в main | `git revert <хэш>` новым подписанным коммитом, затем обычный цикл; историю main не переписывать |
| Прервать неудачный rebase или merge | `git rebase --abort` / `git merge --abort` |

### Подпись и Verified

```
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519_signing.pub
git config --global commit.gpgsign true
git log --show-signature -1            # проверить подпись последнего коммита
```

Ключ добавляется в GitHub как **Signing Key** (отдельно от Authentication Key), email
автора должен быть подтверждённым адресом аккаунта. Unverified означает: коммит не
подписан, подписан другим ключом или email не совпадает. Исправление для неотправленных
коммитов — `git commit --amend -S --no-edit` (последний) или `git rebase -S origin/main`
(все коммиты ветки). Вернуть: `git config --global --unset commit.gpgsign`.

`git log --show-signature` пишет `gpg.ssh.allowedSignersFile needs to be configured`
и «No signature» — коммит может быть подписан, но git не знает, каким ключам доверять
при локальной проверке (GitHub проверяет по своему списку Signing Keys). Проверить
наличие подписи: `git cat-file -p HEAD` показывает заголовок `gpgsig`. Настроить
локальную проверку один раз (PowerShell):

```powershell
$pub = Get-Content ~/.ssh/id_ed25519_signing.pub
"<email автора> $pub" | Out-File -Encoding ascii ~/.ssh/allowed_signers
git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
```

### Концы строк

- На Windows `core.autocrlf=true`: в рабочей копии CRLF, в репозитории LF. Файлы
  `ci/**`, `tests/**`, `tools/**`, `.github/workflows/**` всегда LF (`.gitattributes`).
- Все файлы показаны изменёнными без реальной правки — концы строк. Так бывает, если
  рабочую копию Windows открыть git из Linux или WSL: проверьте
  `git diff --ignore-cr-at-eol --stat` (пусто — изменений нет) и работайте с этой
  копией из git для Windows. Не делайте `git commit -a` из такого окружения.
- `fatal: Unable to create '…/.git/index.lock': File exists` — убедиться, что git не
  запущен (IDE, другой терминал), затем удалить `.git/index.lock`.

## CI на GitHub

- На push запускаются Docs и Configure; Firmware — вручную: Actions → Firmware →
  Run workflow → ветка main. Схема — [сопровождение](maintenance.md#схема-проверок-на-github).
- Упал шаг `Build test environment` или загрузка архивов — сначала «Re-run failed jobs»:
  архивы закреплены SHA-256, повторная загрузка не меняет образ. Повторная ошибка —
  смотрите, какой архив не скачался.
- Полный лог job без входа в GitHub недоступен (API отвечает 403); артефакты
  диагностики хранятся 14 дней.

### Отмена Firmware после публикации тега

Push тега `v*` автоматически запускает Firmware. Не запускайте одновременно
ручной Firmware для того же тега: `concurrency.group: firmware-${{ github.ref }}`
и `cancel-in-progress: true` отменяют предыдущий запуск для этого ref.
`Cancelled` не означает ошибку теста или тега. Проверьте SHA заменяющего запуска,
дождитесь `completed` / `success`, проверьте jobs и артефакты.
Если замены нет или она завершилась ошибкой, разберите причину и повторите
Firmware на том же теге; пересоздавать тег из-за отмены не нужно.

## Локальные Configure-тесты в Docker Desktop

Большое количество мелких файлов в Windows bind mount замедляет копирование
fixtures и Configure. Для полного набора размещайте снимок исходников и временные
каталоги тестов на файловой системе Linux-контейнера. На Windows сохраняйте отчёты
одним архивом. Проверено на матрице include: типовой сценарий сократился примерно
с 7–9 с до 0,4–0,8 с; это измерение конкретного окружения, не обещание времени CI.
Контейнер должен использовать актуальный `ci/dependencies.lock.json`.

Пример PowerShell (из корня репозитория, после сборки `stm32-yml-ci:local`):

```powershell
New-Item -ItemType Directory -Force build/configure-local | Out-Null
docker run --rm --network none --mount "type=bind,source=$($PWD.Path),target=/workspace,readonly" --mount "type=bind,source=$($PWD.Path)/build/configure-local,target=/reports" stm32-yml-ci:local sh -c '
set -eu
mkdir /tmp/source /tmp/results
cp -a /workspace/ci /workspace/tests /workspace/cmake /workspace/scripts /workspace/stm32_yml.cmake /tmp/source/
result=0
python3 /tmp/source/ci/run_configure_tests.py --output /tmp/results || result=$?
tar -czf /reports/configure-results.tar.gz -C /tmp/results .
exit "$result"
'
```

Код выхода тестов сохраняется; архив включает `summary.json`, CTest и диагностику
каждого сценария. Не изменяйте исходники во время создания снимка.

`tests/test_component_versions.py` пока ориентирован на Linux: на Windows он
записывает в пробный CMake-скрипт путь с `\` и может получить `Invalid character
escape '\g'`. Это ограничение тестового harness, а не результат проверки версии
библиотеки. Проверка, совпадающая с Docs CI:

```powershell
docker run --rm --network none --mount "type=bind,source=$($PWD.Path),target=/workspace,readonly" stm32-yml-ci:local python3 -m unittest discover -s /workspace/tests -p test_component_versions.py
```

## Диагностика Configure после разделения CI

- `configure-summary` — общий `summary.json`; `configure-summary-<GCC>` — две пары одной версии GCC.
- `configure-diagnostics-<GCC>` — архив логов, снимков шагов, кэша, Ninja и наблюдаемых свойств. После скачивания распакуйте `configure-diagnostics.tar.gz`.
- Пропавшее задание или неполный отчёт — ошибка итогового `configure`, даже если другие задания зелёные.
- Для отдельной версии локально: `python3 /workspace/ci/run_configure_tests.py --output /results --gcc-version 14.2.1-1.1` внутри закреплённого контейнера; без последнего аргумента — полная матрица.
- Для сброса слоёв при устаревших пакетах Ubuntu: Actions → Configure → Run workflow → `rebuild_environment`. Результаты тестов никогда не кэшируются.

## Установка зависимостей проверки схемы

Используйте отдельный venv по [инструкции](schema.md); для проектов пользователей
эти пакеты не нужны. Если Windows pip не соединяется с PyPI, повторите проверку
в доступном Linux-контейнере с Python 3.11+, pip, CMake и Ninja. В контейнере
можно установить зависимости в временный каталог без изменения системного Python:

```sh
python3 -m pip install --target /tmp/schema-deps -r ci/schema-requirements.txt
PYTHONPATH=/tmp/schema-deps python3 ci/check_schema.py
PYTHONPATH=/tmp/schema-deps python3 -m unittest discover -s tests -p test_config_schema.py
```

## Кодировка CRC/BIN

Исправление E009 к 0.10.1 задаёт UTF-8 stdout/stderr Python CLI. Для старой
версии временный обход — `PYTHONIOENCODING=utf-8` в окружении процесса сборки.
Если байты уже UTF-8, но IDE показывает искажения, проверьте
`cmake.outputLogEncoding` в CMake Tools: декодирование должно быть UTF-8.
Удаление кэша не исправляет кодировку потоков. [Подробности](errata/E009.md).

## Windows-пути в тестовых CMake-файлах

При генерации CMake из Python используйте `Path.as_posix()` и кавычки:
обратный слеш в строке CMake интерпретируется как начало escape (`\g` даёт
Invalid character escape). Не заменяйте PATH тестового Git на /usr/bin:/bin:
сохраняйте окружение Windows, а настройки автора/подписи изолируйте через
GIT_CONFIG_GLOBAL и GIT_CONFIG_NOSYSTEM только для временных тестовых репозиториев.
Правила подписи коммитов рабочего репозитория не меняются.

## Загрузка закреплённых Windows-инструментов

Если прямой HTTPS из Windows сбрасывается, архивы можно заранее получить
через готовый Linux-контейнер в локальный каталог кэша. Используйте точные
URL и filename из ci/windows.lock.json; затем передайте этот каталог в
`python ci/install_windows.py --cache <каталог> --output build/windows-tools`.
Установщик повторно проверяет SHA-256 перед извлечением. Копирование файлов
без проверки хэша или отключение TLS не требуется. Сам Configure/Build TC-44
запускается нативно на Windows, даже если скачивание выполнено контейнером.

## Медленный локальный Docker-прогон на Windows

Перед полным локальным прогоном прочитайте [техническое руководство L0–L5
в Docker](local-docker-testing.md): команды, снимок рабочей копии, зависимости
L1/L2, параллельный запуск, отчёты и очистка.

Для Windows рекомендован Docker volume **для исходников и результатов**.
При CRC-приёмке первая сборочная пара ускорилась с 917 до 117 с; прежний
bind mount на третьей паре превысил общий лимит 1200 с. Таймауты симуляторов
и состав проверок менять не потребовалось. Точные замеры и ограничения —
в руководстве. Передавайте большой набор артефактов одним архивом.

## Политики CMake в самостоятельных тестах

Генерируемый для `cmake -P` тест начинайте с
`cmake_minimum_required(VERSION 3.21)`, как точку входа фреймворка.
Без этого CMake 3.x может применить старые политики CMP0012/CMP0130:
`while(TRUE)` не выполнит инициализацию каталога сообщений и последующий
вывод завершится рекурсией. Успех на более новом CMake не подтверждает
совместимость тестового скрипта с минимальной версией.

## Windows CI: Host упал после успешных Configure/Build

Строка `TC-44 incomplete (E010)` выводится и при успехе: это известное
ограничение абсолютных `sources` на другом диске, не причина любого сбоя.
Смотрите `windows-configure-build/windows-checks/host/tests.log` и
`host/summary.json` внутри артефакта; ZIP «Download logs» содержит журнал
Actions, а не эти файлы. Host теперь выводит traceback в Actions, Windows
runner пересылает его из host.log; ненулевой код остаётся блокирующим.

На Windows runner TEMP может иметь короткое имя `RUNNER~1`. Git возвращает
длинный путь, а CMake 3.21 `file(REAL_PATH)` может сохранить короткое имя.
Сравнение таких строк ошибочно отбрасывало Git SHA. TC-94 воспроизводит
это через GetShortPathNameW; после проверки собственной `.git` пустой
`git rev-parse --show-prefix` проверяет корень без сравнения строк путей.
Локально используйте закреплённый CMake из build/windows-tools, а не только
системный: новый CMake может скрыть несовместимость со старым.

## Текст GitHub Release

Берите оба текста из [docs/releases](../releases/README.md), включённых в тег.
Русский вставляйте первым, English — в `<details>` по шаблону там же.
Перед тегом нужны локальная приёмка и CI на итоговом подписанном SHA;
статус E009 меняется с merged на released после публикации.

## Чистый релизный коммит: перенос Windows → Linux

Для приёмки **уже закоммиченного чистого дерева** упаковывайте версию из Git:
`git -c core.autocrlf=false archive --format=tar --output=build/release-source.tar HEAD`.
В этот архив добавьте каталог `.git`, как в рецепте снимка. Это отдельный режим:
он не подходит для незакоммиченных изменений. Перед упаковкой проверьте пустой
`git status --porcelain` и сохраните полный SHA.

После извлечения **только во временный Docker volume** пересоздайте индекс:

```sh
git -C /work/source read-tree HEAD
git -C /work/source status --porcelain
git -C /work/source rev-parse HEAD
```

Windows-индекс содержит stat-данные другого checkout и может показывать ложные
изменения после переноса. `read-tree HEAD` пересоздаёт индекс временной копии,
не меняя её файлы или историю. Не выполняйте эту команду в пользовательской
рабочей копии: она сбрасывает состав staged-изменений. Перед тестами требуйте
пустой status и ожидаемый SHA, не подавляйте dirty и не исправляйте отчёт вручную.
Рецепт проверен при подготовке 0.10.1. Основной [снимок рабочего дерева](local-docker-testing.md)
по-прежнему нужен для тестирования незакоммиченных изменений.
