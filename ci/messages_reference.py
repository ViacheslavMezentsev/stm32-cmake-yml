"""Build the message code reference pages from the catalog (spec 4.16.13).

python3 ci/messages_reference.py          # write docs/<lang>/reference/0.9.2/messages.md
python3 ci/messages_reference.py --check  # fail if the pages differ from the catalog
"""

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from messages_catalog import load  # noqa: E402

CATALOG = "cmake/stm32_yml_messages_catalog.cmake"
PAGES = {lang: f"docs/{lang}/reference/0.9.2/messages.md" for lang in ("ru", "en")}
GROUPS = {
    "ru": ["Ядро и чтение конфигурации", "Профили", "IOC", "Исходники и модули",
           "CMSIS, HAL, FreeRTOS", "Arduino", "Скрипт компоновщика", "Артефакты и CRC",
           "Диагностика"],
    "en": ["Core and configuration reading", "Profiles", "IOC", "Sources and modules",
           "CMSIS, HAL, FreeRTOS", "Arduino", "Linker script", "Artifacts and CRC",
           "Diagnostics"],
}
LEVELS = {"I": "STATUS", "W": "WARNING", "E": "FATAL_ERROR"}
TEXT = {
    "ru": {
        "title": "# Коды сообщений",
        "nav": "[Документация](../../index.md) → [Reference 0.9.2](index.md) → Коды сообщений · "
               "[English](../../../en/reference/0.9.2/messages.md)",
        "intro": "Перечень построен из каталога `cmake/stm32_yml_messages_catalog.cmake` "
                 "скриптом `ci/messages_reference.py`; вручную не редактируется. Код "
                 "`SCY-<класс><номер>`: класс `I` — `STATUS`, `W` — `WARNING`, `E` — "
                 "`FATAL_ERROR`. В выводе коды показываются при `STM32_YML_MESSAGE_CODES=ON`, "
                 "в файлах `stm32_yml_messages.jsonl` и `stm32_yml_build_messages.jsonl` — всегда. "
                 "`{1}`…`{n}` — параметры. Появилось в 0.10.0 (ТЗ 4.16.5–4.16.13).",
        "head": "| Код | Уровень | Текст |",
        "retired": " (исключён)",
    },
    "en": {
        "title": "# Message codes",
        "nav": "[Documentation](../../index.md) → [Reference 0.9.2](index.md) → Message codes · "
               "[Русский](../../../ru/reference/0.9.2/messages.md)",
        "intro": "The list is built from the `cmake/stm32_yml_messages_catalog.cmake` catalog by "
                 "`ci/messages_reference.py`; do not edit it by hand. A code is "
                 "`SCY-<class><number>`: class `I` is `STATUS`, `W` is `WARNING`, `E` is "
                 "`FATAL_ERROR`. The output shows codes with `STM32_YML_MESSAGE_CODES=ON`; the "
                 "`stm32_yml_messages.jsonl` and `stm32_yml_build_messages.jsonl` files always "
                 "contain them. `{1}`…`{n}` are parameters. New in 0.10.0 (spec 4.16.5–4.16.13).",
        "head": "| Code | Level | Text |",
        "retired": " (retired)",
    },
}


def cell(text):
    """Markdown table cell: catalog text shown literally."""
    for char in "\\`*_[]|":
        text = text.replace(char, "\\" + char)
    text = text.replace("<", "&lt;").replace(">", "&gt;")
    return text.replace("\n", "<br>").strip() or " "


def render(catalog, lang):
    words = TEXT[lang]
    lines = [words["title"], "", words["nav"], "", words["intro"]]
    for group in range(9):
        codes = sorted((code for code in catalog if int(code[1]) == group),
                       key=lambda code: ("EWI".index(code[0]), code))
        if not codes:
            continue
        lines += ["", f"## {group}xx — {GROUPS[lang][group]}", "", words["head"], "| --- | --- | --- |"]
        for code in codes:
            entry = catalog[code]
            text = entry["en"] if lang == "en" and entry["en"] else entry["ru"]
            retired = words["retired"] if entry["retired"] else ""
            lines.append(f"| `SCY-{code}`{retired} | {LEVELS[code[0]]} | {cell(text)} |")
    return "\n".join(lines) + "\n"


def differences(root):
    catalog = load(root / CATALOG)
    stale = []
    for lang, page in PAGES.items():
        path = root / page
        actual = path.read_text(encoding="utf-8").replace("\r\n", "\n") if path.is_file() else None
        if actual != render(catalog, lang):
            stale.append(page)
    return stale


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    args = parser.parse_args()
    if args.check:
        stale = differences(args.root)
        for page in stale:
            print(f"ERROR: {page} differs from the catalog; run python3 ci/messages_reference.py")
        return 1 if stale else 0
    catalog = load(args.root / CATALOG)
    for lang, page in PAGES.items():
        (args.root / page).write_text(render(catalog, lang), encoding="utf-8")
        print(f"Written {page}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
