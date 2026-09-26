# QEMU для CI / QEMU for CI

[Окружение эмуляции](../../docs/ru/emulation.md) · [Emulation environment](../../docs/en/emulation.md)

## Русский

`qemu-11.0.0-linux-x86_64-ubuntu24.04.tar.xz` — заранее собранный
`qemu-system-arm` 11.0.0 для образа [ci/emulation](../../ci/emulation/Dockerfile).
Образ больше не компилирует QEMU: он проверяет SHA-256 архива по
[lock-файлу](../../ci/emulation/versions.lock.json) (`archive_sha256`) и распаковывает его в `/opt/qemu`.

| Параметр | Значение |
| --- | --- |
| Исходники | официальный архив [qemu-11.0.0.tar.xz](https://download.qemu.org/qemu-11.0.0.tar.xz), SHA-256 `c04ca36012653f32d11c674d370cf52a710e7d3f18c2d8b63e4932052a4854d6` (`sha256` в lock-файле) |
| Платформа сборки | Ubuntu 24.04 amd64 — та же база, что у образа |
| Конфигурация | `--target-list=arm-softmmu --without-default-features --enable-tcg --enable-fdt=system`, без документации, утилит и загрузок |
| Состав архива | `qemu/bin/qemu-system-arm` (strip) и лицензии QEMU в `qemu/share/doc/qemu/` |
| Зависимости | `libglib2.0-0t64`, `zlib1g`, `libfdt1` |

`share/qemu` (прошивки для других машин, около 316 МБ) не включён: netduino2 и
netduinoplus2 их не используют. Проверено: `check.py --locked` и все 78 запусков
QEMU-матрицы прошивок.

Пересборка на Ubuntu 24.04 с пакетами из комментария скрипта:

```sh
tools/qemu/build-linux.sh qemu-11.0.0.tar.xz tools/qemu
```

Скрипт отказывается собирать архив с другим SHA-256 исходников. Архив создаётся
детерминированно (порядок файлов, владелец, время), но сам бинарник может
отличаться побайтно от сборки на другой машине: после пересборки обновите
`archive_sha256` в lock-файле и `.sha256` рядом с архивом.

Лицензия: QEMU распространяется под GPLv2 (`COPYING`, `LICENSE` в архиве).
Соответствующие исходники — официальный архив по ссылке выше с указанной
контрольной суммой; изменений в исходниках нет, способ сборки — этот скрипт.

Для Windows собственная сборка не хранится. Локально подходит `scoop install qemu`
(проверка без `--locked` требует версию не ниже 11.0.0). Точная 11.0.0 —
установщик Stefan Weil [qemu-w64-setup-20260422.exe](https://qemu.weilnetz.de/w64/2026/qemu-w64-setup-20260422.exe)
(контрольная сумма — [.sha512](https://qemu.weilnetz.de/w64/2026/qemu-w64-setup-20260422.sha512)).

## English

`qemu-11.0.0-linux-x86_64-ubuntu24.04.tar.xz` is a prebuilt `qemu-system-arm`
11.0.0 for the [ci/emulation](../../ci/emulation/Dockerfile) image. The image no
longer compiles QEMU: it verifies the archive SHA-256 against the
[lock file](../../ci/emulation/versions.lock.json) (`archive_sha256`) and unpacks it to `/opt/qemu`.

| Item | Value |
| --- | --- |
| Source | official [qemu-11.0.0.tar.xz](https://download.qemu.org/qemu-11.0.0.tar.xz), SHA-256 `c04ca36012653f32d11c674d370cf52a710e7d3f18c2d8b63e4932052a4854d6` (`sha256` in the lock file) |
| Build host | Ubuntu 24.04 amd64, the image base |
| Configuration | `--target-list=arm-softmmu --without-default-features --enable-tcg --enable-fdt=system`, no docs, tools or downloads |
| Contents | stripped `qemu/bin/qemu-system-arm` and QEMU licenses in `qemu/share/doc/qemu/` |
| Runtime packages | `libglib2.0-0t64`, `zlib1g`, `libfdt1` |

`share/qemu` (firmware for other machines, about 316 MB) is omitted: netduino2
and netduinoplus2 do not use it. Verified with `check.py --locked` and all 78
firmware-matrix QEMU runs.

Rebuild on Ubuntu 24.04 with the packages listed in the script header:

```sh
tools/qemu/build-linux.sh qemu-11.0.0.tar.xz tools/qemu
```

The script refuses a source archive with another SHA-256. The archive is
deterministic (file order, owner, time), but the binary may differ byte-for-byte
between machines: after a rebuild, update `archive_sha256` in the lock file and
the `.sha256` file next to the archive.

License: QEMU is GPLv2 (`COPYING`, `LICENSE` in the archive). The corresponding
source is the official archive above with the listed checksum, unmodified; this
script is the build method.

No Windows build is stored. Locally, `scoop install qemu` works (the unlocked
check needs at least 11.0.0). For exactly 11.0.0 use Stefan Weil's installer
[qemu-w64-setup-20260422.exe](https://qemu.weilnetz.de/w64/2026/qemu-w64-setup-20260422.exe)
(checksum: [.sha512](https://qemu.weilnetz.de/w64/2026/qemu-w64-setup-20260422.sha512)).
