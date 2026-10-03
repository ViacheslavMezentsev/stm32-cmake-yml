"""TC-76: the L1 message check rejects catalog and source errors (spec 4.16.13)."""

import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "ci"))
import check_messages  # noqa: E402
import messages_catalog  # noqa: E402
import messages_reference  # noqa: E402

CATALOG = '''# comment with stm32_yml_msg(X000)
stm32_yml_msg_def(I001
    "Версия: {1}"
    "Version: {1}")
stm32_yml_msg_def(W002 "Путь \\"{1}\\" и {2}" "Path \\"{1}\\" and {2}")
stm32_yml_msg_def(E003 RETIRED "Старое" "Old")
'''
SOURCE = '''# stm32_yml_msg(<code>) in a comment is ignored
stm32_yml_msg(I001 "${V}")
stm32_yml_msg(W002 "a" "b")
'''


class CheckMessages(unittest.TestCase):
    def test_configuration_source_labels(self):
        # TC-96: I026 is retained in the catalog even when normal false uses I030.
        catalog = messages_catalog.load(ROOT / check_messages.CATALOG)
        for lang in ('ru', 'en'):
            with self.subTest(lang=lang):
                legend = messages_catalog.render(catalog['I020'], lang, [])
                disabled = messages_catalog.render(catalog['I026'], lang, [])
                self.assertIn('[cfg]', legend)
                self.assertIn('[cfg]', disabled)
                self.assertNotIn('[yml]', legend + disabled)
                self.assertNotIn('.yml', disabled)
                self.assertEqual(disabled.index('[cfg]'), 14)
                self.assertNotRegex(disabled, r'\{\d+\}')


    def tree(self, catalog=CATALOG, source=SOURCE, extra=None):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        root = Path(directory.name)
        (root / "cmake").mkdir()
        (root / check_messages.CATALOG).write_text(catalog, encoding="utf-8")
        (root / "stm32_yml.cmake").write_text(source, encoding="utf-8")
        for name, text in (extra or {}).items():
            if text is not None:
                (root / name).write_text(text, encoding="utf-8")
        return root

    def errors(self, root, release=False, legacy=None):
        return check_messages.check(root, release, {} if legacy is None else legacy)[0]

    def test_valid_tree(self):
        self.assertEqual(self.errors(self.tree()), [])

    def test_catalog_parsing(self):
        root = self.tree()
        catalog = messages_catalog.load(root / check_messages.CATALOG)
        self.assertEqual(catalog["W002"]["ru"], 'Путь "{1}" и {2}')
        self.assertTrue(catalog["E003"]["retired"])
        self.assertEqual(messages_catalog.render(catalog["W002"], "en", ["{2}", "x"]), 'Path "{2}" and x')
        self.assertEqual(messages_catalog.render(catalog["I001"], "de", ["1"]), "Версия: 1")

    def test_direct_message(self):
        root = self.tree(source=SOURCE + 'message(STATUS "text")\n')
        self.assertIn("direct message()", self.errors(root)[0])
        self.assertEqual(self.errors(root, legacy={"stm32_yml.cmake": 1}), [])

    def test_unknown_and_retired_codes(self):
        root = self.tree(source=SOURCE + "stm32_yml_msg(I404)\nstm32_yml_msg(E003)\nstm32_yml_msg(${CODE})\n")
        errors = "\n".join(self.errors(root))
        self.assertIn("unknown or non-literal message code I404", errors)
        self.assertIn("retired message code E003", errors)
        self.assertIn("non-literal message code ${CODE}", errors)

    def test_unused_code(self):
        root = self.tree(catalog=CATALOG + 'stm32_yml_msg_def(I010 "Не используется" "Unused")\n')
        self.assertIn("I010 is not used", self.errors(root)[0])

    def test_missing_english_text(self):
        root = self.tree(catalog=CATALOG.replace('\n    "Version: {1}"', ""))
        self.assertEqual(self.errors(root), [])
        self.assertIn("no English text for I001", self.errors(root, release=True)[0])

    def test_parameter_sets(self):
        root = self.tree(catalog=CATALOG.replace('"Version: {1}"', '"Version: {2}"'))
        self.assertIn("RU and EN parameters differ", self.errors(root)[0])
        root = self.tree(catalog=CATALOG.replace('"Версия: {1}"', '"Версия: {2}"')
                         .replace('"Version: {1}"', '"Version: {2}"'))
        self.assertIn("without gaps", self.errors(root)[0])

    def test_cmake_variable_and_test_codes(self):
        root = self.tree(catalog=CATALOG.replace('"Version: {1}"', '"Version: ${V}"'))
        self.assertIn("CMake variable in the EN text", "\n".join(self.errors(root)))
        root = self.tree(catalog=CATALOG + 'stm32_yml_msg_def(I901 "Тест" "Test")\n',
                         source=SOURCE + "stm32_yml_msg(I901)\n")
        self.assertIn("reserved for tests", self.errors(root)[0])

    def test_malformed_catalog(self):
        for catalog in ('stm32_yml_msg_def(X01 "a")\n', 'stm32_yml_msg_def(I001 "a" "b" "c")\n',
                        'stm32_yml_msg_def(I001 "a\\q")\n', CATALOG + 'stm32_yml_msg_def(I001 "a")\n'):
            with self.subTest(catalog=catalog):
                self.assertEqual(len(self.errors(self.tree(catalog=catalog))), 1)

    def test_script_messages(self):
        script = ('''FALLBACK = {\n    'E701': "Old",\n}\n\n'''
                  '''def main():\n    emit('E701')\n    raise CrcError('I001')\n''')
        catalog = CATALOG + 'stm32_yml_msg_def(E701 "Старый" "Old text")\n'
        root = self.tree(catalog=catalog, extra={"scripts": None})
        (root / "scripts").mkdir()
        (root / check_messages.SCRIPT).write_text(script, encoding="utf-8")
        errors = "\n".join(self.errors(root))
        self.assertIn("build-time messages use codes 7xx, got I001", errors)
        self.assertIn("FALLBACK codes ['I001'] differ", errors)
        self.assertIn("FALLBACK text of E701 differs", errors)

    def test_reference_pages(self):
        root = self.tree(extra={"docs": None})
        self.assertEqual(sorted(messages_reference.differences(root)),
                         sorted(messages_reference.PAGES.values()))
        for page in messages_reference.PAGES.values():
            (root / page).parent.mkdir(parents=True, exist_ok=True)
        catalog = messages_catalog.load(root / check_messages.CATALOG)
        for lang, page in messages_reference.PAGES.items():
            (root / page).write_text(messages_reference.render(catalog, lang), encoding="utf-8")
        self.assertEqual(messages_reference.differences(root), [])
        self.assertIn("| `SCY-W002` | WARNING | Path \"{1}\" and {2} |",
                      (root / messages_reference.PAGES["en"]).read_text(encoding="utf-8"))

    def test_repository(self):
        errors, summary = check_messages.check(ROOT)
        self.assertEqual(errors, [])
        self.assertIn("catalog codes", summary)


if __name__ == "__main__":
    unittest.main()
