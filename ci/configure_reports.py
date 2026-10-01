"""Shard Configure by GCC and require the complete pinned matrix at the final gate."""

import argparse
import json
from pathlib import Path
import re
import tarfile

ROOT = Path(__file__).resolve().parent.parent

# Preserve the diagnostics previously uploaded directly by configure.yml.
DIAGNOSTICS = (
    "summary.json", "*/configure-tests.log", "*/ctest.log",
    "*/Testing/Temporary/*.log", "*/cases/*/step-*/*",
    "*/cases/*/step-*/observed/*.txt", "*/cases/*/build/CMakeCache.txt",
    "*/cases/*/build/build.ninja", "*/cases/*/build/compile_commands.json",
    "*/cases/*/build/observed/*.txt", "*/cases/*/build/*.ld",
    "*/cases/*/build/stm32_config.effective.json",
    "*/cases/*/build/CMakeFiles/CMakeConfigureLog.yaml",
    "*/cases/*/build/CMakeFiles/CMakeOutput.log",
    "*/cases/*/build/CMakeFiles/CMakeError.log",
)


def matrix(lock):
    for key in ("gcc_versions", "cmake_versions"):
        values = lock[key]
        if not values or len(values) != len(set(values)) or any(
                not isinstance(v, str) or not re.fullmatch(r"[A-Za-z0-9.+-]+", v) for v in values):
            raise ValueError(f"Invalid or duplicate {key}")
    return {"include": [{"gcc": version, "cache_writer": index == 0}
                        for index, version in enumerate(lock["gcc_versions"])]}


def collect(lock, cases, reports):
    matrix(lock)
    expected = {(gcc, cmake) for gcc in lock["gcc_versions"] for cmake in lock["cmake_versions"]}
    seen = {}
    for report in sorted(reports):
        rows = json.loads(report.read_text(encoding="utf-8"))
        if not isinstance(rows, list) or not rows:
            raise ValueError(f"Empty or invalid report: {report}")
        for row in rows:
            key = (row["gcc"], row["cmake"])
            if key not in expected or key in seen:
                raise ValueError(f"Unexpected or duplicate tool pair: {key}")
            if type(row["cases"]) is not int or row["cases"] != cases:
                raise ValueError(f"Incorrect case count for {key}: {row['cases']}")
            if type(row["returncode"]) is not int:
                raise ValueError(f"Invalid exit code for {key}")
            seen[key] = row
    missing = expected - seen.keys()
    if missing:
        raise ValueError(f"Missing tool pairs: {sorted(missing)}")
    return [seen[(gcc, cmake)] for gcc in lock["gcc_versions"] for cmake in lock["cmake_versions"]]


def pack(source, output):
    files = {p for pattern in DIAGNOSTICS for p in source.glob(pattern) if p.is_file()}
    output.parent.mkdir(parents=True, exist_ok=True)
    with tarfile.open(output, "w:gz") as archive:
        for path in sorted(files):
            archive.add(path, arcname=path.relative_to(source).as_posix(), recursive=False)
    return len(files)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("matrix")
    packing = commands.add_parser("pack")
    packing.add_argument("--source", type=Path, required=True)
    packing.add_argument("--output", type=Path, required=True)
    collecting = commands.add_parser("collect")
    collecting.add_argument("--source", type=Path, required=True)
    collecting.add_argument("--output", type=Path, required=True)
    collecting.add_argument("--job-result", required=True)
    args = parser.parse_args()
    lock = json.loads((ROOT / "ci/dependencies.lock.json").read_text(encoding="utf-8"))
    if args.command == "matrix":
        print(json.dumps(matrix(lock), separators=(",", ":")))
    elif args.command == "pack":
        print(f"Packed {pack(args.source, args.output)} diagnostic files into {args.output}")
    else:
        cases = json.loads((ROOT / "tests/cases.json").read_text(encoding="utf-8"))
        rows = collect(lock, len(cases), args.source.glob("configure-summary-*/summary.json"))
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(rows, indent=2) + "\n", encoding="utf-8")
        failed = [row for row in rows if row["returncode"] != 0]
        if failed or args.job_result != "success":
            raise ValueError(f"Configure failed: {len(failed)} pairs; matrix job result: {args.job_result}")
        print(f"PASS: {len(rows)} tool pairs, {len(rows) * len(cases)} Configure executions")


if __name__ == "__main__":
    main()
