"""Install the reviewed lockfile into a disposable Linux image."""

import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

LOCK = Path(__file__).with_name("dependencies.lock.json")


def run(*args):
    subprocess.run(args, check=True)


def install_archive(item):
    print(f"Installing {item['name']}", flush=True)
    with tempfile.TemporaryDirectory() as temp:
        archive = Path(temp) / "download"
        run("curl", "--fail", "--location", "--retry", "3", "--connect-timeout", "30",
            "--max-time", "1800", "--output", str(archive), item["url"])
        with archive.open("rb") as stream:
            digest = hashlib.file_digest(stream, "sha256").hexdigest()
        if digest != item["sha256"]:
            raise ValueError(f"SHA-256 mismatch for {item['name']}: {digest}")
        destination = Path(item["destination"])
        if item["kind"] == "executable":
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(archive, destination)
            destination.chmod(0o755)
        else:
            destination.mkdir(parents=True, exist_ok=True)
            if item["kind"] == "tar":
                run("tar", "-xzf", str(archive), "--strip-components=1", "-C", str(destination))
            elif item["kind"] == "zip":
                run("unzip", "-q", str(archive), "-d", str(destination))
            else:
                raise ValueError(f"Unknown archive kind: {item['kind']}")


def install_source(item):
    print(f"Installing {item['name']} at {item['commit']}", flush=True)
    destination = Path(item["destination"])
    destination.mkdir(parents=True, exist_ok=True)
    git = ("git", "-C", str(destination))
    run(*git, "init", "--quiet")
    run(*git, "remote", "add", "origin", item["url"])
    run(*git, "fetch", "--depth=1", "origin", item["commit"])
    run(*git, "checkout", "--quiet", "--detach", "FETCH_HEAD")
    actual = subprocess.check_output((*git, "rev-parse", "HEAD"), text=True).strip()
    if actual != item["commit"]:
        raise ValueError(f"Unexpected commit for {item['name']}: {actual}")
    if item["submodules"]:
        # No --remote: gitlinks in the pinned parent commit select exact revisions.
        run(*git, "submodule", "update", "--init", "--recursive", "--depth=1",
            "--", *item["submodules"])
    for filename in item["required_files"]:
        if not (destination / filename).is_file():
            raise FileNotFoundError(destination / filename)


if __name__ == "__main__":
    lock = json.loads(LOCK.read_text())
    if sys.argv[1:] == ["archives"]:
        for item in lock["archives"]:
            install_archive(item)
    elif sys.argv[1:] == ["sources"]:
        for item in lock["sources"]:
            install_source(item)
    else:
        sys.exit("Usage: install.py archives|sources")
