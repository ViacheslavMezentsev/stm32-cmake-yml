"""Run one configure-only contract case against the mounted framework checkout."""

import argparse
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def verify(case, build, source):
    for filename in ("build.ninja", "CMakeCache.txt", "compile_commands.json"):
        require((build / filename).is_file(), f"Missing generated {filename}")

    def observed(key):
        return (build / "observed" / f"{key}.txt").read_text(encoding="utf-8")

    for key, expected in case.get("observed", {}).items():
        actual = observed(key)
        require(actual == expected, f"{key}: expected {expected!r}, got {actual!r}")
    for key, values in case.get("properties", {}).items():
        actual = observed(key).split(";")
        for value in values:
            require(value in actual, f"{key}: missing {value!r} in {actual!r}")
    for key, values in case.get("absent_properties", {}).items():
        actual = observed(key).split(";")
        for value in values:
            require(value not in actual, f"{key}: unexpected {value!r}")
    if "sources" in case:
        actual = [Path(p).relative_to(source).as_posix() for p in observed("SOURCES").split(";")]
        require(actual == case["sources"], f"Sources: {actual!r} != {case['sources']!r}")
    if "link_options_contain" in case:
        require(case["link_options_contain"] in observed("LINK_OPTIONS"), "Explicit linker script not linked")
    if "linker" in case:
        linker = build / case["linker"].get("file", "STM32F411CE_FLASH.ld")
        require(linker.is_file(), "Template was not generated")
        content = linker.read_text(encoding="utf-8")
        for token in (f"_Min_Heap_Size = {case['linker']['heap']};",
                      f"_Min_Stack_Size = {case['linker']['stack']};",
                      ".text (READONLY)", "KEEP(*(.checksum))", "_estack = ORIGIN(RAM) + LENGTH(RAM);"):
            require(token in content, f"Generated linker script missing {token!r}")
        require("@" not in content, "Unresolved linker template substitution")
        require(str(linker) in observed("LINK_OPTIONS"), "Generated linker script not linked")

    ninja = (build / "build.ninja").read_text(encoding="utf-8")
    if "generated_link_flags" in case:
        # These fixtures have one executable; inspect generated flags, not the
        # CMake LINK_OPTIONS property alone (which omits transitive options).
        lines = [line.strip().split(" = ", 1)[1] for line in ninja.splitlines()
                 if line.strip().startswith("LINK_FLAGS = ")]
        require(len(lines) == 1, f"Expected one executable link flag line, got {len(lines)}")
        flags = shlex.split(lines[0])
        for token in case["generated_link_flags"].get("present", []):
            require(token in flags, f"Generated link flags missing {token!r}")
        for token in case["generated_link_flags"].get("absent", []):
            require(token not in flags, f"Generated link flags unexpectedly contain {token!r}")

    if "crc_command" in case:
        require(("stm32_crc.py" in ninja) == case["crc_command"], "Incorrect CRC command presence")
        if case["crc_command"]:
            for token in ("--remove-section=.checksum", "--update-section", "524288"):
                require(token in ninja, f"CRC command missing {token!r}")

    commands = json.loads((build / "compile_commands.json").read_text(encoding="utf-8"))
    if case.get("no_st_dependencies"):
        for value in (observed("LINK_LIBRARIES"), json.dumps(commands), ninja):
            for token in ("CMSIS::", "HAL::", "FreeRTOS::", "/Drivers/", "USE_HAL_DRIVER"):
                require(token not in value, f"Bare-metal configuration unexpectedly uses {token}")

    def command_for(path):
        matches = [entry["command"] for entry in commands if Path(entry["file"]) == path]
        require(len(matches) == 1, f"Expected one compile command for {path}, got {len(matches)}")
        return shlex.split(matches[0])

    if case.get("language_flags"):
        for filename, present, absent in (
            ("main.c", ["-Wall", "-Wstrict-prototypes", "-DONLY_C=1"], ["-fno-exceptions", "-DONLY_CXX=1"]),
            ("helper.cpp", ["-Wall", "-fno-exceptions", "-DONLY_CXX=1"], ["-Wstrict-prototypes", "-DONLY_C=1"]),
        ):
            command = command_for(source / filename)
            for token in present:
                require(token in command, f"{filename}: missing {token}")
            for token in absent:
                require(token not in command, f"{filename}: leaked {token}")
    for check in case.get("command_checks", []):
        command = command_for(source / check["file"])
        for token in check.get("present", []):
            require(token in command, f"{check['file']}: missing {token}")
        for token in check.get("absent", []):
            require(token not in command, f"{check['file']}: leaked {token}")
        for directory in check.get("includes", []):
            token = "-I" + str(source / directory)
            require(token in command, f"{check['file']}: missing include {directory}")
        for directory in check.get("absent_includes", []):
            token = "-I" + str(source / directory)
            require(token not in command, f"{check['file']}: leaked include {directory}")
        if "target" in check:
            require("-o" in command, f"{check['file']}: missing object output")
            output = command[command.index("-o") + 1]
            require(f"CMakeFiles/{check['target']}.dir/" in output,
                    f"{check['file']}: unexpected owning target: {output}")
    if "arduino_definitions" in case:
        # Check propagation through Arduino::Definitions into both wrappers.
        for path in (source / "modules/Arduino_Core_STM32/cores/arduino/wiring_digital.c",
                     source / "libraries/probe/probe.cpp"):
            command = command_for(path)
            for definition in case["arduino_definitions"]:
                require(f"-D{definition}" in command, f"{path}: missing {definition}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--case", required=True)
    parser.add_argument("--cmake", required=True)
    parser.add_argument("--framework", type=Path, required=True)
    parser.add_argument("--work-dir", type=Path, required=True)
    args = parser.parse_args()
    tests = Path(__file__).resolve().parent
    cases = json.loads((tests / "cases.json").read_text(encoding="utf-8"))
    case = next(c for c in cases if c["name"] == args.case)
    args.work_dir.mkdir(parents=True, exist_ok=True)
    # Cases are isolated; steps within one case deliberately reuse the same cache.
    run = Path(tempfile.mkdtemp(prefix=f"{args.case}-", dir=args.work_dir)).resolve()
    source, build = run / "source", run / "build"
    shutil.copytree(tests / "fixtures/project", source)
    if case.get("backend") == "arduino":
        core = Path("/opt/Arduino_Core_STM32/2.12.0")
        require((core / "cores/arduino/wiring_digital.c").is_file(), "Pinned Arduino core missing")
        (source / "modules").mkdir()
        (source / "modules/Arduino_Core_STM32").symlink_to(core, target_is_directory=True)
        toolchain = tests / "toolchains/arduino.cmake"
        config_args = ["-DPROJECT_CONFIG_FILE=arduino.yml"]
    else:
        toolchain = Path(os.environ.get("MODULES_DIR", "/opt/modules")) / "stm32-cmake/cmake/stm32_gcc.cmake"
        config_args = []
    command = [args.cmake, "-S", str(source), "-B", str(build), "-G", "Ninja",
               f"-DSTM32_YML_FRAMEWORK_DIR={args.framework.resolve()}",
               f"-DCMAKE_TOOLCHAIN_FILE={toolchain}", "-DCMAKE_BUILD_TYPE=Debug",
               "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON", *config_args, *case.get("args", [])]
    env = dict(os.environ, **case.get("env", {}))
    for index, step in enumerate(case.get("steps", [{}]), start=1):
        expectation = dict(case, **step)
        step_command = command + step.get("args", [])
        # Preserve outputs for every step, including intermediate generated .ld.
        report = run / f"step-{index}"
        report.mkdir()
        log_path = report / "configure.log"
        print(f"Case: {args.case}, step {index}\nLog: {log_path}", flush=True)
        with log_path.open("w", encoding="utf-8") as log:
            log.write(shlex.join(step_command) + "\n\n")
            log.flush()
            result = subprocess.run(step_command, env=env, stdout=log, stderr=subprocess.STDOUT, timeout=100)
        for filename in ("CMakeCache.txt", "build.ninja", "compile_commands.json"):
            if (build / filename).is_file():
                shutil.copy2(build / filename, report)
        for linker in build.glob("*.ld"):
            shutil.copy2(linker, report)
        if (build / "observed").is_dir():
            shutil.copytree(build / "observed", report / "observed")
        output = log_path.read_text(encoding="utf-8")
        normalized = " ".join(output.split())
        try:
            if "error" in expectation:
                require(result.returncode != 0, "Invalid configuration unexpectedly succeeded")
                require(expectation["error"] in normalized, f"Failure had wrong cause: expected {expectation['error']!r}")
            else:
                require(result.returncode == 0, f"CMake returned {result.returncode}")
                verify(expectation, build, source)
            for message in expectation.get("log_contains", []):
                require(message in normalized, f"Missing diagnostic {message!r}")
            for message in expectation.get("log_absent", []):
                require(message not in normalized, f"Unexpected diagnostic {message!r}")
        except AssertionError:
            print(output, flush=True)
            raise
    print(f"PASS {args.case}")


if __name__ == "__main__":
    main()
