"""Run one configure-only contract case against the mounted framework checkout."""

import argparse
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
import tempfile
import time

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "ci"))
import messages_catalog  # noqa: E402


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
    if "library_inputs" in case:
        expected = [str(source / path) for path in case["library_inputs"]["files"]]
        names = case["library_inputs"].get("names", [])
        actual = observed("LINK_LIBRARIES")
        actual = [] if actual in ("", "VALUE-NOTFOUND") else actual.split(";")
        require(actual == expected + names,
                f"Library inputs: expected {expected + names!r}, got {actual!r}")
        lines = [line.strip().split(" = ", 1)[1] for line in ninja.splitlines()
                 if line.strip().startswith("LINK_LIBRARIES = ")]
        require(len(lines) <= 1, "Expected at most one executable library line")
        generated = shlex.split(lines[0].replace("$ ", " ")) if lines else []
        require(generated == expected + ["-l" + name for name in names],
                f"Unexpected generated library inputs: {generated!r}")

    if "generated_artifacts" in case:
        selected = set(case["generated_artifacts"])
        target = observed("PROJECT_NAME")
        post = "\n".join(line for line in ninja.splitlines()
                         if line.strip().startswith("POST_BUILD = "))
        # ТЗ 4.14.2: BIN строится из секций FLASH скриптом, а не objcopy -O binary.
        require("arm-none-eabi-objcopy -O binary" not in post, "BIN must not use objcopy -O binary")
        for extension, command in (("bin", f"--image {target}.bin"),
                                   ("hex", "arm-none-eabi-objcopy -O ihex"),
                                   ("srec", "arm-none-eabi-objcopy -O srec"),
                                   ("lss", "arm-none-eabi-objdump -h -S")):
            require((command in post) == (extension in selected),
                    f"Incorrect {extension} conversion command presence")
            require((f"{target}.{extension}" in post) == (extension in selected),
                    f"Incorrect {extension} command output presence")
        require(f"{target}_always_display_size" in ninja and "arm-none-eabi-size" in ninja,
                "Size reporting command missing")
        require(f"{target}.elf" in ninja, "Primary ELF target missing")
        for extension in ("elf", "bin", "hex", "srec", "map", "lss"):
            require(not (build / f"{target}.{extension}").exists(),
                    f"Unexpected built artifact: {target}.{extension}")

    if "configure_depends" in case:
        # ТЗ 3.6.5: изменение YAML, IOC и файла профилей перезапускает Configure.
        rerun = ninja[ninja.index("build build.ninja"):].split("\n\n", 1)[0]
        for filename in case["configure_depends"]:
            path = source / filename
            require(str(path) in rerun, f"{filename} is not a Configure dependency")
            stat = path.stat()
            try:
                os.utime(path, (stat.st_atime, time.time() + 3600))
                plan = subprocess.run(["ninja", "-C", str(build), "-n", "build.ninja"],
                                      capture_output=True, text=True, timeout=60)
            finally:
                os.utime(path, (stat.st_atime, stat.st_mtime))
            require("Re-running CMake" in plan.stdout, f"Changing {filename} does not re-run Configure")

    if "cppcheck_rules" in case:
        rules = (build / "CMakeFiles/rules.ninja").read_text(encoding="utf-8")
        require(("--cppcheck=" in (rules + ninja)) == case["cppcheck_rules"],
                "Incorrect Cppcheck rule presence")

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
        # BIN также строится stm32_crc.py (--image), поэтому признак CRC — --exclude.
        require(("--exclude" in ninja) == case["crc_command"], "Incorrect CRC command presence")
        if case["crc_command"]:
            # ТЗ 4.15.9: образ из секций ELF в регионе FLASH скрипта, без gap-fill.
            for token in ("--elf", "--flash 0x08000000:524288", "--exclude .checksum",
                          "--update-section", " 524288"):
                require(token in ninja, f"CRC command missing {token!r}")
            require("--gap-fill" not in ninja, "CRC image must not use objcopy --gap-fill")

    commands = json.loads((build / "compile_commands.json").read_text(encoding="utf-8"))
    for filename in case.get("absent_commands", []):
        require(not any(Path(entry["file"]) == source / filename for entry in commands),
                f"Unexpected compile command for {filename}")
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


def verify_messages(expectation, build, catalog, normalized):
    """Spec 4.16.10, 4.16.12: records of the message file plus the catalog text in the log."""
    path = build / "stm32_yml_messages.jsonl"
    require(path.is_file(), "Missing stm32_yml_messages.jsonl")
    records = [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines()]
    for record in records:
        code = record["code"].removeprefix("SCY-")
        require(code in catalog, f"Message file has a code missing from the catalogs: {code}")
        require(record["level"] == messages_catalog.level(code), f"{code}: wrong level {record['level']}")
        text = messages_catalog.render(catalog[code], record["lang"], record["args"])
        require(record["text"] == text, f"{code}: text {record['text']!r} != catalog {text!r}")
        shown = f"[SCY-{code}] {text}" if expectation.get("message_codes") else text
        require(" ".join(shown.split()) in normalized, f"{code}: text is not in the log: {shown!r}")
    codes = [record["code"].removeprefix("SCY-") for record in records]

    def matches(record, expected):
        # "args": null elements match any value (absolute paths, tool lists).
        args = expected.get("args")
        return (record["code"] == "SCY-" + expected["code"]
                and (args is None or (len(record["args"]) == len(args)
                     and all(e is None or e == a for e, a in zip(args, record["args"])))))

    for expected in expectation.get("messages", []):
        require(any(matches(record, expected) for record in records),
                f"Missing message {expected} in {[(r['code'], r['args']) for r in records]}")
    for code in expectation.get("messages_absent", []):
        require(code not in codes, f"Unexpected message {code}")
    if "message_lang" in expectation:
        langs = {record["lang"] for record in records}
        require(langs == {expectation["message_lang"]}, f"Message language {langs}")
    if "message_codes" in expectation:
        require(("[SCY-" in normalized) == expectation["message_codes"], "Incorrect code prefix presence")
    if isinstance(expectation.get("error"), dict):
        require(records and matches(records[-1], expectation["error"]),
                f"The last message is not {expectation['error']}")


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
        if case.get("arduino_library_fixture"):
            (source / "arduino-library-core/cores").symlink_to(core / "cores", target_is_directory=True)
        toolchain = tests / "toolchains/arduino.cmake"
        config_args = ["-DPROJECT_CONFIG_FILE=arduino.yml"]
    else:
        toolchain = Path(os.environ.get("MODULES_DIR", "/opt/modules")) / "stm32-cmake/cmake/stm32_gcc.cmake"
        config_args = []
    command = [args.cmake, "-S", str(source), "-B", str(build), "-G", "Ninja",
               f"-DSTM32_YML_FRAMEWORK_DIR={args.framework.resolve()}",
               f"-DCMAKE_TOOLCHAIN_FILE={toolchain}", "-DCMAKE_BUILD_TYPE=Debug",
               "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON", *config_args,
               # Spec 4.16.12: L3 runs in English unless a case selects a language.
               f"-DSTM32_YML_LANG={case.get('lang', 'en')}", *case.get("args", [])]
    catalog = messages_catalog.load(args.framework / "cmake/stm32_yml_messages_catalog.cmake")
    catalog.update(messages_catalog.load(source / "test_messages.cmake"))
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
        if (build / "stm32_yml_messages.jsonl").is_file():
            shutil.copy2(build / "stm32_yml_messages.jsonl", report)
        if (build / "observed").is_dir():
            shutil.copytree(build / "observed", report / "observed")
        output = log_path.read_text(encoding="utf-8")
        normalized = " ".join(output.split())
        try:
            if "error" in expectation:
                require(result.returncode != 0, "Invalid configuration unexpectedly succeeded")
                if isinstance(expectation["error"], str):
                    require(expectation["error"] in normalized,
                            f"Failure had wrong cause: expected {expectation['error']!r}")
            else:
                require(result.returncode == 0, f"CMake returned {result.returncode}")
                verify(expectation, build, source)
            verify_messages(expectation, build, catalog, normalized)
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
