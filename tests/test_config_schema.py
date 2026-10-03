"""Advisory schema contracts and paired CMakePresets/YAML example (TC-82)."""

import copy
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "ci"))
import check_schema
import config_schema
from jsonschema import Draft202012Validator


class SchemaTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.index = json.loads(config_schema.INDEX.read_text(encoding="utf-8"))
        cls.schema = config_schema.generate(cls.index)
        cls.validator = Draft202012Validator(cls.schema)

    def test_generated_schema_and_metaschema(self):
        Draft202012Validator.check_schema(self.schema)
        self.assertEqual(config_schema.render(self.index), config_schema.OUTPUT.read_text(encoding="utf-8"))

    def test_every_index_option_and_yaml_alias(self):
        for option in self.index["options"]:
            for path in option["yaml_paths"]:
                node = self.schema["$defs"]["configuration"]
                for part in path[:-1]:
                    node = node["properties"][part]["anyOf"][0]
                self.assertIn(option["requirement"], node["properties"][path[-1]]["description"])

    def test_new_option_requires_explicit_metadata(self):
        index = copy.deepcopy(self.index)
        index["options"].append({"key": "future", "type": "string"})
        with self.assertRaises(KeyError):
            config_schema.generate(index)

    def test_custom_keys_and_nested_sections(self):
        self.validator.validate({"custom": {"whatever": [1, False, None]},
                                 "arduino": {"vendor_extension": "ok"},
                                 "profiles": {"RevB": {"custom": "override"}},
                                 "stm32_cmake_yml": {"version": "0.10.1", "version_check": True},
                                 "crc": {"enable": True, "algorithm": "STM32_HW_DEFAULT"}})

    def test_null_empty_and_zero(self):
        for option in self.index["options"]:
            for value in (None, "", []):
                for path in option["yaml_paths"]:
                    doc = value
                    for part in reversed(path):
                        doc = {part: doc}
                    with self.subTest(key=option["key"], value=value):
                        self.validator.validate(doc)
        self.validator.validate({"heap_size": 0, "use_hal": False, "use_cmsis": "OFF"})

    def test_supported_values(self):
        for value in (0, 512, "512", "1K", "2M"):
            self.validator.validate({"heap_size": value})
        self.validator.validate({"flash_size": "auto", "arduino": {"integration": "native"},
                                 "build_artifacts": ["bin", "hex", "srec", "map", "lss"]})

    def test_invalid_known_values(self):
        cases = [{"heap_size": "1.5K"}, {"stack_size": -1}, {"heap_size": "2k"},
                 {"use_hal": {"enabled": True}}, {"c_standard": "seventeen"},
                 {"toolchain_backend": "unknown"}, {"cmsis_rtos_api": "v3"},
                 {"arduino": {"integration": "bridge"}},
                 {"build_artifacts": ["bin", "nope"]},
                 {"build_artifacts_append": ["nope"]},
                 {"crc": {"algorithm": "CRC32"}},
                 {"stm32_cmake_yml": {"version_check": "sometimes"}},
                 {"profiles": {"G4_rev2": {}}}, {"profiles": {"": {}}},
                 {"include": ["base.yml", False]}, {"include": 42},
                 {"sources_append": 42}, {"custom_append": [{}]}, []]
        for doc in cases:
            with self.subTest(doc=doc):
                self.assertFalse(self.validator.is_valid(doc))

    def test_append_and_partial_configs(self):
        for doc in ({"include": ["base.yml", "more.toml"]},
                    {"sources_append": ["file.c"], "custom_append": [1, False]},
                    {"arduino": {"libraries_append": ["Wire"]}},
                    {"profiles": {"RevB": {"compile_definitions_append": ["B=1"]}}}, {}):
            self.validator.validate(doc)

    def test_yaml12_and_toml_parsing(self):
        self.assertEqual(check_schema.parse("custom: ON\nuse_hal: false\n", ".yml"),
                         {"custom": "ON", "use_hal": False})
        self.assertEqual(check_schema.parse("use_hal = false\n", ".toml"), {"use_hal": False})

    def test_fixtures_and_negative_expectations(self):
        exceptions = json.loads(check_schema.EXCEPTIONS.read_text(encoding="utf-8"))
        failures, count, negatives = check_schema.check(self.validator, exceptions)
        self.assertEqual(failures, [])
        self.assertGreater(count, 80)
        self.assertGreater(negatives, 0)

    def test_stale_exception_is_failure(self):
        exceptions = json.loads(check_schema.EXCEPTIONS.read_text(encoding="utf-8"))
        exceptions["missing.yml"] = {"/": "Deleted fixture"}
        exceptions["tests/fixtures/project/stm32_config.yml"] = {"/mcu": "Not an error"}
        failures, _, _ = check_schema.check(self.validator, exceptions)
        self.assertTrue(any("missing.yml" in line for line in failures))
        self.assertTrue(any("/mcu: stale exception" in line for line in failures))

    def test_negative_profile_does_not_hide_other_profiles(self):
        text = 'profiles:\n  Negative:\n    arduino:\n      integration: bridge\n  Positive:\n    heap_size: bad\n'
        errors = check_schema.issues(self.validator, text, ".yml")
        self.assertEqual(set(errors), {"/profiles/Negative/arduino/integration", "/profiles/Positive/heap_size"})


class PresetTests(unittest.TestCase):
    def test_toml_preset_links(self):
        # TC-97: preset schema accepted by CMake; each build selects its configure.
        example = ROOT / "examples/presets/toml"
        presets = json.loads((example / "CMakePresets.json").read_text(encoding="utf-8"))
        expected = {f"{chip}-{mode}" for chip in ("f411ce", "g474re")
                    for mode in ("debug", "release")}
        visible = {p["name"] for p in presets["configurePresets"] if not p.get("hidden")}
        self.assertEqual(visible, expected)
        self.assertEqual({p["name"] for p in presets["buildPresets"]}, expected)
        for preset in presets["buildPresets"]:
            self.assertEqual(preset["name"], preset["configurePreset"])
        result = subprocess.run(["cmake", "--list-presets=all"], cwd=example,
                                capture_output=True, text=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stderr)
        for name in expected:
            self.assertIn(name, result.stdout)

    def test_documented_files_match_both_translations(self):
        for lang in ("ru", "en"):
            doc = (ROOT / f"docs/{lang}/presets.md").read_text(encoding="utf-8")
            for name in ("CMakePresets.json", "CMakeLists.txt", "stm32_config.yml"):
                block = re.search(r"### " + re.escape(name) + r"\s+```\w+\n(.*?)```", doc, re.S)
                self.assertIsNotNone(block, name)
                self.assertEqual(block[1], (ROOT / "examples/presets" / name).read_text(encoding="utf-8"))

    def test_cmake_preset_selection_matches_yaml(self):
        # Only exercise CMake's preset/cache wiring, not an Arduino firmware build.
        cmake = shutil.which("cmake")
        self.assertIsNotNone(cmake, "Install CMake >= 3.21 to validate presets")
        self.assertIsNotNone(shutil.which("ninja"), "Install Ninja to validate presets")
        yaml = check_schema.parse((ROOT / "examples/presets/stm32_config.yml").read_text(encoding="utf-8"), ".yml")
        presets = json.loads((ROOT / "examples/presets/CMakePresets.json").read_text(encoding="utf-8"))
        expected = {f"{mode}-{profile}" for mode in ("Debug", "Release") for profile in ("G431", "G474")}
        self.assertEqual({p["name"] for p in presets["buildPresets"]}, expected)
        for preset in presets["buildPresets"]:
            self.assertEqual(preset["name"], preset["configurePreset"])
        with tempfile.TemporaryDirectory() as temporary:
            source = Path(temporary)
            shutil.copy2(ROOT / "examples/presets/CMakePresets.json", source)
            shutil.copy2(ROOT / "examples/presets/stm32_config.yml", source)
            (source / "CMakeLists.txt").write_text(
                'cmake_minimum_required(VERSION 3.21)\nproject(preset_probe NONE)\n'
                'file(WRITE "${CMAKE_BINARY_DIR}/selection.txt" '
                '"${STM32_YML_PROFILE}\\n${CMAKE_BUILD_TYPE}\\n${PROJECT_CONFIG_FILE}\\n")\n', encoding="utf-8")
            for profile in ("G431", "G474"):
                for mode in ("Debug", "Release"):
                    name = f"{mode}-{profile}"
                    run = subprocess.run([cmake, "--preset", name], cwd=source,
                                         capture_output=True, text=True, timeout=30)
                    self.assertEqual(run.returncode, 0, run.stdout + run.stderr)
                    actual = (source / "build" / name / "selection.txt").read_text(encoding="utf-8").splitlines()
                    self.assertEqual(actual[:2], [profile, mode])
                    self.assertEqual(Path(actual[2]), source / "stm32_config.yml")
                    self.assertIn(actual[0], yaml["profiles"])


if __name__ == "__main__":
    unittest.main()
