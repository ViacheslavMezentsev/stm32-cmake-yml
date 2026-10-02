"""Install TC-44 tools from SHA-256-pinned archives; no global machine changes."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def install(output, cache):
    lock = json.loads((ROOT / 'ci/windows.lock.json').read_text(encoding='utf-8'))
    cache.mkdir(parents=True, exist_ok=True)
    for item in lock['archives']:
        archive = cache / item['filename']
        if not archive.exists():
            subprocess.run(['curl.exe', '-fL', '--retry', '3', '--connect-timeout', '30',
                            '--max-time', '1200', '-o', str(archive), item['url']], check=True)
        with archive.open('rb') as stream:
            digest = hashlib.file_digest(stream, 'sha256').hexdigest()
        if digest != item['sha256']:
            raise ValueError(f"SHA-256 mismatch: {item['name']}: {digest}")
        folder = output / ('modules/stm32-cmake' if item['name'] == 'stm32-cmake' else item['name'])
        folder.mkdir(parents=True, exist_ok=True)
        if archive.suffix == '.exe':
            shutil.copyfile(archive, folder / 'yq.exe')
        else:
            with zipfile.ZipFile(archive) as zipped:
                for member in zipped.infolist():
                    relative = Path(member.filename)
                    if item['name'] != 'ninja':
                        relative = Path(*relative.parts[1:])
                    target = (folder / relative).resolve()
                    if not target.is_relative_to(folder.resolve()):
                        raise ValueError('Archive path escapes destination')
                    if member.is_dir():
                        target.mkdir(parents=True, exist_ok=True)
                    else:
                        target.parent.mkdir(parents=True, exist_ok=True)
                        with zipped.open(member) as source, target.open('wb') as dest:
                            shutil.copyfileobj(source, dest)
        print(f"Verified and installed: {item['name']}", flush=True)
    (output / 'installed-lock.json').write_text(json.dumps(lock, indent=2) + '\n', encoding='utf-8')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--cache', type=Path, required=True)
    args = parser.parse_args()
    install(args.output.resolve(), args.cache.resolve())


if __name__ == '__main__':
    main()
