"""Validate reference navigation and links to actual tests without third-party packages."""

import json
from pathlib import Path
import re
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parent.parent


def require(ok, message):
    if not ok:
        raise ValueError(message)


def link_exists(origin, target):
    if re.match(r"^[a-zA-Z][a-zA-Z0-9+.-]*:", target):
        return  # External links are not probed by this offline check.
    path, _, anchor = unquote(target).partition("#")
    resolved = (origin.parent / path).resolve() if path else origin
    require(resolved.is_relative_to(ROOT), f"Link escapes repository: {origin}: {target}")
    require(resolved.is_file(), f"Missing link: {origin}: {target}")
    if anchor and resolved.suffix == ".md":
        content = resolved.read_text(encoding="utf-8")
        anchors = set(re.findall(r'<a id="([^"]+)"', content))
        for heading in re.findall(r"^#{1,6} (.+)$", content, re.M):
            # Current documentation uses simple GitHub heading anchors.
            anchors.add(re.sub(r"[^\w\- ]", "", heading.lower()).replace(" ", "-"))
        require(anchor in anchors, f"Missing anchor: {origin}: {target}")


def main():
    data = json.loads((ROOT / "docs/reference-index.json").read_text(encoding="utf-8"))
    tests = {"configure." + c["name"] for c in json.loads((ROOT / "tests/cases.json").read_text(encoding="utf-8"))}
    lock = json.loads((ROOT / "ci/dependencies.lock.json").read_text(encoding="utf-8"))
    pairs = len(lock["gcc_versions"]) * len(lock["cmake_versions"])
    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    count = f"**{len(tests)} scenarios × {pairs} tool pairs = {len(tests) * pairs} configure executions**"
    block = re.search(r"<!-- configure-counts -->\s*(.*?)\s*<!-- /configure-counts -->", readme, re.S)
    require(block is not None and block.group(1) == count, "Update README configure counts from tests/cases.json and the dependency lock")
    options = {o["key"]: o for o in data["options"]}
    errata = {e["id"]: e for e in data["errata"]}
    require(len(options) == len(data["options"]) > 0, "Empty/duplicate option keys")
    require(len(errata) == len(data["errata"]), "Duplicate errata IDs")
    require(len({o["requirement"] for o in options.values()}) == len(options), "Duplicate contract IDs")
    for key, option in options.items():
        require(set(option["pages"]) == {"ru", "en"}, f"Translation missing: {key}")
        require((ROOT / option["source"]).is_file(), f"Source missing: {key}")
        require(key.split('.')[-1] in (ROOT / option["source"]).read_text(encoding="utf-8"), f"Check source attribution: {key}")
        require(set(option["tests"]) <= tests, f"Unknown test referenced by {key}")
        for language, target in option["pages"].items():
            link_exists(ROOT / "index", target)
            text = (ROOT / target.split('#')[0]).read_text(encoding="utf-8")
            require(option["requirement"] in text, f"Missing ID in {language} card: {key}")
        for issue in option["errata"]:
            require(issue in errata and key in errata[issue]["options"], f"Errata mismatch: {key}/{issue}")
    for issue, entry in errata.items():
        require(set(entry["pages"]) == {"ru", "en"}, f"Translation missing: {issue}")
        for key in entry["options"]:
            require(key in options and issue in options[key]["errata"], f"Reverse errata mismatch: {issue}/{key}")
        for target in entry["pages"].values():
            link_exists(ROOT / "index", target)
    pages = []
    for language in ("ru", "en"):
        base = ROOT / "docs" / language
        pages += list((base / "reference").rglob("*.md"))
        pages += list((base / "errata").glob("*.md"))
        pages += [base / "index.md", base / "maintenance.md"]
        pages += [base / name for name in ("getting-started.md", "scenarios.md", "development.md", "repository.md", "simple-sources.md", "modules.md", "troubleshooting.md", "testing.md", "emulation.md")]
    pages += [ROOT / "skills/stm32-config-manager/SKILL.md"]
    pages += [ROOT / "skills/stm32-simple-sources/SKILL.md"]
    pages += [ROOT / "skills/stm32-module-creator/SKILL.md"]
    pages += [ROOT / "skills/stm32-build-helper/SKILL.md"]
    pages += [ROOT / "TODO.md"]
    pages += [ROOT / "README.md"]
    for page in pages:
        for target in re.findall(r"\]\(([^)]+)\)", page.read_text(encoding="utf-8")):
            link_exists(page, target)
    print(f"PASS: {len(options)} bilingual option cards, {len(errata)} errata, {len(pages)} pages and test mappings")


if __name__ == "__main__":
    main()
