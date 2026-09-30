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

### Работа с агентом через рабочую копию

Агент вносит правки прямо в файлы ветки `<агент>/<задача>` вашей рабочей копии и не
коммитит: его git работает без вашего ключа подписи и иначе видит концы строк Windows.

1. Проверьте правки: `git status`, `git diff`.
2. Закоммитьте их из Windows командой, которую даёт агент (`git add <файлы>` и
   `git commit -F <файл сообщения>`); коммит подписывается вашим ключом.
3. `git push -u origin <ветка>`. Агент проверяет CI через API GitHub и сообщает,
   когда делать `git land`.

Если агент работает без доступа к рабочей копии и передаёт готовые коммиты (например,
через `git bundle`), они не подписаны. Перед push их переподписывают командой
`git rebase -S origin/main`; хэши при этом меняются, поэтому в документации не
ссылаются на хэши коммитов той же неслитой ветки.

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
