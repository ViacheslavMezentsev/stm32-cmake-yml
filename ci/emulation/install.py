"""Verify and unpack emulator archives inside the disposable Docker builder.

A lock entry with "archive" uses the prebuilt file from the repository (copied
next to this script, verified with "archive_sha256"); otherwise "url" is
downloaded and verified with "sha256".
"""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile

item = json.loads(Path(__file__).with_name("versions.lock.json").read_text())[sys.argv[1]]
destination = Path(sys.argv[2])
destination.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory() as temp:
    if "archive" in item:
        archive, expected = Path(__file__).parent / item["archive"], item["archive_sha256"]
    else:
        archive, expected = Path(temp) / "archive", item["sha256"]
        subprocess.run(["curl", "-fL", "--retry", "3", "--connect-timeout", "30",
                        "--max-time", "1800", "-o", str(archive), item["url"]], check=True)
    with archive.open("rb") as stream:
        digest = hashlib.file_digest(stream, "sha256").hexdigest()
    if digest != expected:
        raise ValueError(f"SHA-256 mismatch: {digest}")
    subprocess.run(["tar", "-xf", str(archive), "--strip-components=1",
                    "-C", str(destination)], check=True)
