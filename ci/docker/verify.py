"""Offline environment smoke check; project configuration tests come separately."""

import json
import os
from pathlib import Path
import subprocess
import tempfile


def output(*args):
    return subprocess.check_output(args, text=True, stderr=subprocess.STDOUT).strip()


def main():
    lock = json.loads(Path(__file__).with_name("dependencies.lock.json").read_text())
    print(f"Selected GCC={os.environ['GCC_VERSION']} CMake={os.environ['CMAKE_VERSION']}", flush=True)
    assert Path(output("which", "arm-none-eabi-gcc")).parent == Path(os.environ["STM32_TOOLCHAIN_PATH"]) / "bin"
    assert output("cmake", "--version").splitlines()[0] == f"cmake version {os.environ['CMAKE_VERSION']}"
    assert output("ninja", "--version") == "1.12.1"
    assert output("yq", "--version").endswith("version v4.44.3")

    for source in lock["sources"]:
        destination = Path(source["destination"])
        assert output("git", "-c", f"safe.directory={destination}", "-C", str(destination), "rev-parse", "HEAD") == source["commit"]
        for filename in source["required_files"]:
            assert (destination / filename).is_file(), str(destination / filename)

    with tempfile.TemporaryDirectory(prefix="stm32-env-") as temp:
        root = Path(temp)
        config = root / "config.yml"
        config.write_text("enabled: false\nheap: 0\nflags: [Wall, Wextra]\n")
        assert json.loads(output("yq", "-o=json", ".", str(config))) == {
            "enabled": False, "heap": 0, "flags": ["Wall", "Wextra"]}
        src = root / "src"
        src.mkdir()
        # The empty library has no headers or firmware dependencies. CMake's own
        # compiler checks compile static objects; the firmware is never built.
        (src / "CMakeLists.txt").write_text(
            'cmake_minimum_required(VERSION 3.19)\n'
            'project(environment_probe LANGUAGES C CXX ASM)\n'
            'add_library(probe STATIC probe.c probe.cpp)\n')
        (src / "probe.c").write_text("void c_probe(void) {}\n")
        (src / "probe.cpp").write_text("void cpp_probe() {}\n")
        for gcc in lock["gcc_versions"]:
            toolchain = Path(f"/opt/xpack-arm-none-eabi-gcc-{gcc}/bin")
            for tool in ("gcc", "g++", "objcopy", "objdump", "size", "ld"):
                print(output(str(toolchain / f"arm-none-eabi-{tool}"), "--version").splitlines()[0], flush=True)
            assert output(str(toolchain / "arm-none-eabi-gcc"), "-dumpfullversion") == gcc.split("-")[0]
            for cmake in lock["cmake_versions"]:
                build = root / f"build-{gcc}-{cmake}"
                command = f"/opt/cmake-{cmake}/bin/cmake"
                assert output(command, "--version").splitlines()[0] == f"cmake version {cmake}"
                subprocess.run([command, "-S", str(src), "-B", str(build), "-G", "Ninja",
                    "-DCMAKE_SYSTEM_NAME=Generic", "-DCMAKE_SYSTEM_PROCESSOR=arm",
                    "-DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY",
                    f"-DCMAKE_C_COMPILER={toolchain}/arm-none-eabi-gcc",
                    f"-DCMAKE_CXX_COMPILER={toolchain}/arm-none-eabi-g++",
                    f"-DCMAKE_ASM_COMPILER={toolchain}/arm-none-eabi-gcc"], check=True)
                assert (build / "build.ninja").is_file()
                print(f"PASS configure: GCC {gcc}, CMake {cmake}", flush=True)
    print("PASS environment: tools, sources and six Configure/Generate combinations", flush=True)


if __name__ == "__main__":
    main()
