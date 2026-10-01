"""The Configure gate must not accept a partial, duplicated or failed matrix."""

import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tarfile
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("configure_reports", ROOT / "ci/configure_reports.py")
reports = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reports)


class ConfigureReportsTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)
        self.lock = {"gcc_versions": ["a", "b", "c"], "cmake_versions": ["x", "y"]}
        self.rows = [{"gcc": gcc, "cmake": cmake, "cases": 223, "returncode": 0}
                     for gcc in "abc" for cmake in "xy"]

    def write(self, name, rows):
        path = self.root / name / "summary.json"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(rows), encoding="utf-8")
        return path

    def test_matrix_single_writer_and_all_gcc(self):
        self.assertEqual(reports.matrix(self.lock)["include"], [
            {"gcc": "a", "cache_writer": True}, {"gcc": "b", "cache_writer": False},
            {"gcc": "c", "cache_writer": False}])

    def test_invalid_lock(self):
        for values in ([], ["a", "a"], ["bad version"]):
            with self.subTest(values=values), self.assertRaises(ValueError):
                reports.matrix(dict(self.lock, gcc_versions=values))

    def test_collect_complete_shards_in_lock_order(self):
        paths = [self.write(f"shard-{i}", self.rows[i:i+2]) for i in (4, 0, 2)]
        self.assertEqual(reports.collect(self.lock, 223, paths), self.rows)

    def test_missing_empty_duplicate_and_unexpected_pairs(self):
        variants = [[], self.rows[:-1], self.rows + self.rows[:1],
                    self.rows + [dict(self.rows[0], gcc="unknown")]]
        for rows in variants:
            with self.subTest(rows=rows), self.assertRaises(ValueError):
                reports.collect(self.lock, 223, [self.write("bad", rows)])
        with self.assertRaises(ValueError):
            reports.collect(self.lock, 223, [])

    def test_incorrect_count_or_status_type(self):
        for change in ({"cases": 222}, {"cases": True}, {"returncode": False}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                reports.collect(self.lock, 223, [self.write("bad", [dict(self.rows[0], **change)] + self.rows[1:])])

    def test_failed_pair_is_preserved_for_final_gate(self):
        self.rows[-1]["returncode"] = 8
        result = reports.collect(self.lock, 223, [self.write("failed", self.rows)])
        self.assertEqual(result[-1]["returncode"], 8)

    def test_cli_rejects_failed_or_cancelled_job_with_green_reports(self):
        lock = json.loads((ROOT / "ci/dependencies.lock.json").read_text(encoding="utf-8"))
        count = len(json.loads((ROOT / "tests/cases.json").read_text(encoding="utf-8")))
        rows = [dict(gcc=g, cmake=c, cases=count, returncode=0)
                for g in lock["gcc_versions"] for c in lock["cmake_versions"]]
        self.write("configure-summary-all", rows)
        for status in ("success", "failure", "cancelled", "skipped"):
            with self.subTest(status=status):
                result = subprocess.run([sys.executable, str(ROOT / "ci/configure_reports.py"), "collect",
                    "--source", str(self.root), "--output", str(self.root / "combined.json"),
                    "--job-result", status], capture_output=True, text=True)
                self.assertEqual(result.returncode == 0, status == "success")

    def test_cli_rejects_failed_pair_with_success_job(self):
        lock = json.loads((ROOT / "ci/dependencies.lock.json").read_text(encoding="utf-8"))
        count = len(json.loads((ROOT / "tests/cases.json").read_text(encoding="utf-8")))
        rows = [dict(gcc=g, cmake=c, cases=count, returncode=0)
                for g in lock["gcc_versions"] for c in lock["cmake_versions"]]
        rows[0]["returncode"] = 8
        self.write("configure-summary-all", rows)
        result = subprocess.run([sys.executable, str(ROOT / "ci/configure_reports.py"), "collect",
            "--source", str(self.root), "--output", str(self.root / "combined.json"),
            "--job-result", "success"], capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue((self.root / "combined.json").is_file())

    def test_archive_retains_diagnostics_without_source_copies(self):
        names = ["summary.json", "pair/ctest.log", "pair/cases/test/step-1/configure.log",
                 "pair/cases/test/step-1/observed/value.txt", "pair/cases/test/build/build.ninja",
                 "pair/cases/test/build/stm32_config.effective.json",
                 "pair/cases/test/build/CMakeFiles/CMakeConfigureLog.yaml"]
        for name in names + ["pair/cases/test/source/main.c"]:
            p = self.root / name
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(name, encoding="utf-8")
        archive = self.root / "diagnostics.tar.gz"
        self.assertEqual(reports.pack(self.root, archive), len(names))
        with tarfile.open(archive) as packed:
            self.assertEqual(set(packed.getnames()), set(names))
            for name in names:
                self.assertEqual(packed.extractfile(name).read().decode(), name)

    def test_runner_rejects_unknown_gcc_before_running_tools(self):
        result = subprocess.run([sys.executable, str(ROOT / "ci/run_configure_tests.py"),
            "--output", str(self.root), "--gcc-version", "unknown"], capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("not in dependencies.lock.json", result.stderr)


if __name__ == "__main__":
    unittest.main()
