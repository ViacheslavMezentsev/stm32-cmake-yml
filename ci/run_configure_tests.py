"""Run the configured GCC/CMake matrix inside the pinned Linux container."""

import argparse
import json
import os
from pathlib import Path
import subprocess
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    lock = json.loads((root / "ci/dependencies.lock.json").read_text())
    cases = json.loads((root / "tests/cases.json").read_text())
    if not cases or len({case["name"] for case in cases}) != len(cases):
        raise ValueError("Test cases must have unique names and must not be empty")
    args.output.mkdir(parents=True, exist_ok=True)
    summary = []
    for gcc in lock["gcc_versions"]:
        for cmake in lock["cmake_versions"]:
            build = (args.output / f"gcc-{gcc}_cmake-{cmake}").resolve()
            build.mkdir(parents=True, exist_ok=True)
            env = dict(os.environ, GCC_VERSION=gcc, CMAKE_VERSION=cmake)
            entrypoint = "/usr/local/bin/stm32-yml-env"
            print(f"\nGCC {gcc}, CMake {cmake}: {len(cases)} cases", flush=True)
            with (build / "configure-tests.log").open("w") as log:
                configured = subprocess.run([entrypoint, "cmake", "-S", str(root / "tests"),
                    "-B", str(build), "-G", "Ninja"], env=env, stdout=log, stderr=subprocess.STDOUT)
            status = configured.returncode
            if status == 0:
                # Verify discovery too: CTest must not silently pass an empty suite.
                discovered = subprocess.check_output([entrypoint, "ctest", "--show-only=json-v1"],
                    cwd=build, env=env, text=True)
                names = {test["name"] for test in json.loads(discovered)["tests"]}
                if names != {f"configure.{case['name']}" for case in cases}:
                    raise RuntimeError(f"Unexpected CTest discovery: {names}")
                with (build / "ctest.log").open("w") as log:
                    tested = subprocess.run([entrypoint, "ctest", "--output-on-failure", "-j", "4"],
                        cwd=build, env=env, stdout=log, stderr=subprocess.STDOUT)
                status = tested.returncode
                print((build / "ctest.log").read_text(), flush=True)
            else:
                print((build / "configure-tests.log").read_text(), flush=True)
            summary.append({"gcc": gcc, "cmake": cmake, "cases": len(cases), "returncode": status})
            (args.output / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    failed = [pair for pair in summary if pair["returncode"] != 0]
    print(f"\n{len(summary) - len(failed)}/{len(summary)} tool pairs passed; logs: {args.output}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
