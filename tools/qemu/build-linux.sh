#!/usr/bin/env bash
# Build the pinned QEMU for the emulator image: arm-softmmu, TCG only, system libfdt.
# Run on Ubuntu 24.04 (amd64), the base of ci/emulation/Dockerfile. Needs:
#   build-essential ninja-build python3 python3-venv python3-setuptools python3-wheel
#   python3-pip libglib2.0-dev libpixman-1-dev zlib1g-dev libfdt-dev xz-utils
# Usage: tools/qemu/build-linux.sh <qemu-X.Y.Z.tar.xz> <output-directory>
set -euo pipefail
source_archive=$(realpath "$1")
output=$(realpath -m "$2")
version=$(basename "$source_archive" .tar.xz); version=${version#qemu-}
lock=$(dirname "$(realpath "$0")")/../../ci/emulation/versions.lock.json
expected=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['qemu']['sha256'])" "$lock")
actual=$(sha256sum "$source_archive" | cut -d' ' -f1)
[ "$actual" = "$expected" ] || { echo "SHA-256 mismatch: $actual != $expected" >&2; exit 1; }
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
tar -xf "$source_archive" --strip-components=1 -C "$work"
mkdir "$work/build" && cd "$work/build"
../configure --prefix=/opt/qemu --target-list=arm-softmmu \
  --without-default-features --enable-tcg --enable-fdt=system --disable-docs --disable-tools \
  --disable-guest-agent --disable-werror --disable-download
ninja -j"$(nproc)"
DESTDIR="$work/stage" ninja install
# Ship only what the netduino2/netduinoplus2 smoke tests use: the stripped emulator and
# the QEMU licenses. share/qemu holds firmware for other machines (~316 MB unpacked).
package="$work/package/qemu"
mkdir -p "$package/bin" "$package/share/doc/qemu"
strip -o "$package/bin/qemu-system-arm" "$work/stage/opt/qemu/bin/qemu-system-arm"
cp "$work/COPYING" "$work/COPYING.LIB" "$work/LICENSE" "$package/share/doc/qemu/"
mkdir -p "$output"
name="qemu-$version-linux-x86_64-ubuntu24.04"
# Deterministic archive: sorted names, fixed owner and mtime (release date of the source).
mtime=$(tar -tvf "$source_archive" --full-time | awk 'NR==1{print $4" "$5}')
tar -C "$work/package" --sort=name --owner=0 --group=0 --numeric-owner \
    --mtime="$mtime" -cf - qemu | xz -9 -T1 > "$output/$name.tar.xz"
(cd "$output" && sha256sum "$name.tar.xz" > "$name.tar.xz.sha256")
"$package/bin/qemu-system-arm" --version | head -1
cat "$output/$name.tar.xz.sha256"
