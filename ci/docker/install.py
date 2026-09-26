"""Install the reviewed lockfile into a disposable Linux image."""

from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import threading

LOCK = Path(__file__).with_name("dependencies.lock.json")


# Items install in parallel threads; each thread collects its own log and prints
# it as one block, so parallel downloads do not interleave in the build log.
LOG = threading.local()
PARALLEL = 4


def say(text):
    LOG.lines.append(text)


def run(*args):
    result = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    say(f"$ {' '.join(args)}\n{result.stdout}".rstrip())
    if result.returncode:
        raise subprocess.CalledProcessError(result.returncode, args)


def install_archive(item):
    say(f"Installing {item['name']}")
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
    say(f"Installing {item['name']} at {item['commit']}")
    destination = Path(item["destination"])
    destination.mkdir(parents=True, exist_ok=True)
    git = ("git", "-C", str(destination))
    run(*git, "init", "--quiet")
    run(*git, "remote", "add", "origin", item["url"])
    excluded = item.get("sparse_exclude", [])
    if excluded:
        # Partial clone + sparse checkout: only blobs outside the excluded top-level
        # directories (examples, utilities) are downloaded and checked out.
        run(*git, "fetch", "--depth=1", "--filter=blob:none", "origin", item["commit"])
        run(*git, "sparse-checkout", "set", "--no-cone", "/*", *(f"!/{name}/" for name in excluded))
    else:
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
    for name in excluded:
        if (destination / name).exists():
            raise ValueError(f"Sparse checkout kept {destination / name}")


def install_all(install, items):
    """Install items concurrently; print each log as a block and fail on any error."""
    def task(item):
        LOG.lines = []
        try:
            install(item)
            return True, LOG.lines
        except Exception as error:  # reported after the item's own log
            return False, LOG.lines + [f"FAILED {item['name']}: {error}"]
    with ThreadPoolExecutor(PARALLEL) as pool:
        results = list(pool.map(task, items))
    for _, lines in results:
        print("\n".join(lines), flush=True)
    if not all(ok for ok, _ in results):
        sys.exit("Installation failed")


if __name__ == "__main__":
    lock = json.loads(LOCK.read_text())
    if sys.argv[1:] == ["archives"]:
        install_all(install_archive, lock["archives"])
    elif sys.argv[1:] == ["sources"]:
        install_all(install_source, lock["sources"])
    else:
        sys.exit("Usage: install.py archives|sources")
