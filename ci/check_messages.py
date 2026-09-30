"""L1 check of framework messages against the catalog (spec 4.16.6, 4.16.8, 4.16.13; TC-76)."""

import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from messages_catalog import CatalogError, load, params  # noqa: E402

MODULE = "cmake/stm32_yml_messages.cmake"
CATALOG = "cmake/stm32_yml_messages_catalog.cmake"
USE = re.compile(r"(?<![\w])stm32_yml_msg\s*\(\s*([^\s)]+)")
DIRECT = re.compile(r"^\s*message\s*\(", re.M)

# Direct message() calls not yet moved to the catalog during stage 2 of the
# 0.10.0 plan. The numbers must match exactly: lower one when converting a
# module; the list must be empty for the 0.10.0 release.
LEGACY_DIRECT_MESSAGES = {
    "stm32_yml.cmake": 7,
    "cmake/stm32_yml_arduino.cmake": 13,
    "cmake/stm32_yml_code_quality.cmake": 4,
    "cmake/stm32_yml_config.cmake": 18,
    "cmake/stm32_yml_diagnostics.cmake": 21,
    "cmake/stm32_yml_frameworks.cmake": 23,
    "cmake/stm32_yml_linker.cmake": 13,
    "cmake/stm32_yml_postbuild.cmake": 13,
    "cmake/stm32_yml_profiles.cmake": 12,
    "cmake/stm32_yml_sources.cmake": 3,
    "cmake/stm32_yml_utils.cmake": 21,
}


def sources(root):
    files = [root / "stm32_yml.cmake"] + sorted((root / "cmake").glob("*.cmake"))
    return [path for path in files if path.relative_to(root).as_posix() != CATALOG]


def check(root, release=False, legacy=None):
    """Return (errors, summary) for the framework tree at root."""
    legacy = LEGACY_DIRECT_MESSAGES if legacy is None else legacy
    errors = []
    try:
        catalog = load(root / CATALOG)
    except (CatalogError, OSError) as error:
        return [str(error)], ""

    missing_en = []
    for code, entry in catalog.items():
        where = f"{CATALOG}:{entry['line']}: {code}"
        if code[1] == "9":
            errors.append(f"{where}: codes 9xx are reserved for tests")
        if not entry["ru"].strip():
            errors.append(f"{where}: empty Russian text")
        for language in ("ru", "en"):
            if "${" in entry[language]:
                errors.append(f"{where}: CMake variable in the {language.upper()} text; use {{n}}")
        numbers = params(entry["ru"])
        if numbers != list(range(1, len(numbers) + 1)):
            errors.append(f"{where}: parameters must be {{1}}..{{n}} without gaps, got {numbers}")
        if entry["en"]:
            if params(entry["en"]) != numbers:
                errors.append(f"{where}: RU and EN parameters differ: {numbers} != {params(entry['en'])}")
        else:
            missing_en.append(code)
    if release and missing_en:
        errors.append(f"{CATALOG}: no English text for {', '.join(missing_en)}")

    used = {}
    for path in sources(root):
        relative = path.relative_to(root).as_posix()
        # Full-line comments may mention calls; blank them, keeping line numbers.
        text = re.sub(r"^[ \t]*#.*$", "", path.read_text(encoding="utf-8"), flags=re.M)
        for match in USE.finditer(text):
            code = match.group(1)
            line = text.count("\n", 0, match.start()) + 1
            if code not in catalog:
                errors.append(f"{relative}:{line}: unknown or non-literal message code {code}")
            elif catalog[code]["retired"]:
                errors.append(f"{relative}:{line}: retired message code {code}")
            used.setdefault(code, f"{relative}:{line}")
        if relative == MODULE:
            continue
        direct = len(DIRECT.findall(text))
        allowed = legacy.get(relative, 0)
        if direct != allowed:
            errors.append(f"{relative}: {direct} direct message() calls, expected {allowed}; "
                          "print user messages with stm32_yml_msg() and update LEGACY_DIRECT_MESSAGES")

    for code, entry in catalog.items():
        if code not in used and not entry["retired"]:
            errors.append(f"{CATALOG}:{entry['line']}: {code} is not used; remove it or mark it RETIRED")

    summary = (f"{len(catalog)} catalog codes, {len(used)} used, {len(missing_en)} without English text, "
               f"{sum(legacy.values())} legacy direct message() calls")
    return errors, summary


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument("--release", action="store_true", help="require English texts (spec 4.16.8)")
    args = parser.parse_args()
    errors, summary = check(args.root, args.release)
    for error in errors:
        print(f"ERROR: {error}")
    if errors:
        return 1
    print(f"PASS: {summary}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
