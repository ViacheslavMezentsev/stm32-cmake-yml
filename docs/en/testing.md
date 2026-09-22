# Test environment

[Русский](../ru/testing.md)

This first stage adds an isolated Linux environment. Existing `include(stm32_yml)`
projects do not need any changes. Firmware configuration fixtures and CTest will
be added separately; this stage checks the environment itself.

## Contents

| Component | Pinned versions |
| --- | --- |
| Platform | Linux amd64, Ubuntu 24.04 by image digest |
| Ubuntu packages | Ubuntu repositories; installed versions recorded in the image |
| xPack Arm GCC | 13.3.1-1.1, 14.2.1-1.1, 15.2.1-1.1 |
| CMake | 3.19.8 (minimum compatibility), 3.28.3 (reference environment) |
| Ninja / Mike Farah yq | 1.12.1 / 4.44.3 |
| stm32-cmake | Commit recorded in the lockfile |
| STM32Cube | F1 1.8.7, F4 1.28.3, G4 1.6.3 |
| Arduino Core STM32 / ETL | 2.12.0 / 20.47.1 |

[dependencies.lock.json](../../ci/dependencies.lock.json) records archive SHA-256
checksums and source commits. Selected Cube submodules (CMSIS device, HAL and
FreeRTOS where it is a submodule) use the gitlinks of those commits, never remote
branch heads. BSP and unrelated middleware submodules are not initialized.
Git metadata and licenses are retained for inspection. The image records Ubuntu
package versions in `/opt/stm32-yml-ci/packages.txt`.

QEMU **11.0.0**, built from source, and Renode are planned for the later emulation
stage; neither is installed in this image. Arduino projects still need their own
CMake core/library wrappers. The image does not contain a copy of stm32-cmake-yml.

## Build and verify

Requires Docker with Linux containers. Run from the repository root in either
PowerShell or a Linux shell:

```sh
docker build --platform linux/amd64 -f ci/docker/Dockerfile -t stm32-yml-ci:local .
docker run --rm --network none stm32-yml-ci:local
```

The initial build downloads three toolchains and Cube sources: allow several GB
of disk space and time for downloads. Subsequent builds reuse Docker layers.
The Dockerfile-specific ignore file sends only environment inputs to Docker.
Archives are verified before extraction. Installation failure stops the build.

The default command checks tool versions, YAML conversion, pinned source commits
and required dependency files. It then configures a tiny C/C++/ASM project with
each of the six GCC/CMake pairs and verifies that Ninja files were generated.
CMake performs its own compiler checks, but no `cmake --build` is invoked.
This verifies environment readiness, **not** framework behavior, firmware
linking, CRC correctness or MCU peripheral simulation. Verification works offline.

## Select tools and use the checkout

Defaults: GCC `14.2.1-1.1`, CMake `3.28.3`. `GCC_VERSION` and `CMAKE_VERSION` select
installed versions; unsupported or empty values fail immediately.

```sh
docker run --rm --network none -e GCC_VERSION=13.3.1-1.1 -e CMAKE_VERSION=3.19.8 stm32-yml-ci:local cmake --version
docker run --rm --network none -e GCC_VERSION=15.2.1-1.1 stm32-yml-ci:local arm-none-eabi-gcc --version
```

Open a shell with the current checkout mounted read-only. Use `/tmp/build/...`
for outputs, or mount a separate writable directory. Linux:

```sh
docker run --rm -it --network none --mount "type=bind,source=$(pwd),target=/workspace,readonly" stm32-yml-ci:local bash
```

PowerShell:

```powershell
docker run --rm -it --network none --mount "type=bind,source=$($PWD.Path),target=/workspace,readonly" stm32-yml-ci:local bash
```

Inside the container:

- Toolchain: `$STM32_TOOLCHAIN_PATH` (also selected on `PATH`).
- stm32-cmake: `/opt/modules/stm32-cmake`.
- Cube: `/opt/STM32Cube/Repository/STM32Cube_FW_<family>_V<version>`;
  `CMAKE_USER_HOME=/opt` enables the framework's existing lookup.
- Arduino Core: `/opt/Arduino_Core_STM32/2.12.0`.
- ETL: `/opt/etl/20.47.1`.
- Framework under test: `/workspace`, supplied by the caller.

Use separate build directories per project/profile/GCC/CMake/build type.
Preserve the selected environment when launching commands (use `bash`, not a
login shell which can reset `PATH`). The same Docker commands work in the VS Code
terminal. Interactive debugging and VS Code launch configurations come later.

## Updates and CI

The environment workflow builds the image and verifies it without network access.
It does not publish images or build firmware. Full configure-test workflows will
follow in a separate change.

Update versions and hashes together in the lockfile, review upstream sources,
then rebuild and verify. When changing Ubuntu, also update the Dockerfile digest
to match the lockfile. CMake 3.28.3 is a fixed reference, not a claim to be the
latest CMake. Runtime libraries and Python packages follow Ubuntu updates;
this image freezes the testing tools and source dependencies, not every OS
package or the resulting image bytes. Ubuntu snapshots are not required.
