"""Check schema drift and all stored configuration fixtures (spec 6.6.4; TC-82)."""

import argparse
import json
from pathlib import Path
import tomllib

from jsonschema import Draft202012Validator
from ruamel.yaml import YAML
from ruamel.yaml.error import YAMLError

import config_schema

ROOT = config_schema.ROOT
EXCEPTIONS = ROOT / "tests/schema-exceptions.json"


def parse(text, suffix):
    if suffix == ".toml":
        return tomllib.loads(text)
    yaml = YAML(typ="safe", pure=True)
    yaml.version = (1, 2)
    return yaml.load(text)


def configurations(root=ROOT):
    """Also validate YAML/TOML written by reconfigure tests, not just disk files."""
    for directory in ("tests/fixtures", "tests/firmware", "examples/presets"):
        for path in sorted((root / directory).rglob("*")):
            if path.suffix in (".yml", ".yaml", ".toml"):
                yield path.relative_to(root).as_posix(), path.read_text(encoding="utf-8"), path.suffix
    cases = json.loads((root / "tests/cases.json").read_text(encoding="utf-8"))
    for case in cases:
        for i, step in enumerate(case.get("steps", [case])):
            for name, text in step.get("write_files", {}).items():
                suffix = Path(name).suffix
                if suffix in (".yml", ".yaml", ".toml"):
                    yield f'case:{case["name"]}:{i}:{name}', text, suffix


def issues(validator, text, suffix):
    try:
        value = parse(text, suffix)
    except (YAMLError, tomllib.TOMLDecodeError) as error:
        return {"<parse>": str(error).splitlines()[0]}
    result = {}
    for error in validator.iter_errors(value):
        # Profiles and sections are nullable; unpack that wrapper for precise
        # exceptions rather than exempting every profile in the same file.
        def unpack(item):
            if item.validator == "anyOf":
                nested = [child for child in item.context
                          if len(child.absolute_path) > len(item.absolute_path)]
                if nested:
                    for child in nested:
                        yield from unpack(child)
                    return
            yield item
        for item in unpack(error):
            pointer = "/" + "/".join(str(p).replace("~", "~0").replace("/", "~1")
                                        for p in item.absolute_path)
            result[pointer] = item.message
    return result


def check(validator, exceptions, root=ROOT):
    failures, seen = [], set()
    count = negative = 0
    for name, text, suffix in configurations(root):
        count += 1
        seen.add(name)
        actual = issues(validator, text, suffix)
        expected = exceptions.get(name, {})
        for pointer, reason in expected.items():
            if not isinstance(reason, str) or not reason.strip():
                failures.append(f"{name}:{pointer}: missing exception reason")
        for pointer in actual.keys() - expected.keys():
            failures.append(f"{name}:{pointer}: {actual[pointer]}")
        for pointer in expected.keys() - actual.keys():
            failures.append(f"{name}:{pointer}: stale exception (no validation error)")
        negative += len(expected)
    for name in exceptions.keys() - seen:
        failures.append(f"Stale exception: configuration no longer exists: {name}")
    return failures, count, negative


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.parse_args()
    index = json.loads(config_schema.INDEX.read_text(encoding="utf-8"))
    schema_text = config_schema.OUTPUT.read_text(encoding="utf-8")
    if schema_text != config_schema.render(index):
        parser.exit(1, "Schema is stale: run python ci/config_schema.py\n")
    schema = json.loads(schema_text)
    Draft202012Validator.check_schema(schema)
    exceptions = json.loads(EXCEPTIONS.read_text(encoding="utf-8"))
    failures, count, negative = check(Draft202012Validator(schema), exceptions)
    if failures:
        parser.exit(1, "\n".join(failures) + "\n")
    print(f"PASS: schema matches index; {count} configurations; {negative} explicit negative expectations")


if __name__ == "__main__":
    main()
