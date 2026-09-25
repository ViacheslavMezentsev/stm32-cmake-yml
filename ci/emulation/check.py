"""Check emulator executables without loading or building any firmware."""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys


def executable(explicit, name, fallback=None):
    candidate = explicit or shutil.which(name) or fallback
    if candidate and Path(candidate).is_file():
        return str(Path(candidate).resolve())
    raise ValueError(f"Executable not found: {candidate or name}; supply --{name.split('-')[0]}")


def run(path, *args):
    result = subprocess.run([path, *args], capture_output=True, text=True,
                            encoding="utf-8", errors="replace", timeout=30)
    output = result.stdout + result.stderr
    if result.returncode:
        raise ValueError(f"{path} {args}: exit {result.returncode}\n{output}")
    return output.strip()


def version(output, tool, expected, locked):
    pattern = r"QEMU emulator version (\d+)\.(\d+)\.(\d+)" if tool == "qemu" else r"Renode v(\d+)\.(\d+)\.(\d+)"
    match = re.search(pattern, output)
    if not match:
        raise ValueError(f"Unrecognized {tool} version: {output}")
    actual = tuple(map(int, match.groups()))
    wanted = tuple(map(int, expected.split('.')))
    if (locked and actual != wanted) or (not locked and actual < wanted):
        raise ValueError(f"{tool}: expected {'exactly' if locked else 'at least'} {expected}, got {match.group(0)}")
    return '.'.join(map(str, actual))


def machines(output, required):
    available = {line.split()[0] for line in output.splitlines() if line.strip()}
    missing = set(required) - available
    if missing:
        raise ValueError(f"Missing QEMU machines: {', '.join(sorted(missing))}")
    return required


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--qemu', help='Explicit executable path (or QEMU_BINARY)')
    parser.add_argument('--renode', help='Explicit executable path (or RENODE_BINARY)')
    parser.add_argument('--locked', action='store_true', help='Require locked release versions')
    parser.add_argument('--output', type=Path, help='Save JSON report, including failures')
    args = parser.parse_args()
    report = {'status': 'failed', 'locked': args.locked, 'firmware_executed': False}
    try:
        lock = json.loads(Path(__file__).with_name('versions.lock.json').read_text(encoding='utf-8'))
        fallback = str(Path(os.environ.get('ProgramFiles', 'C:/Program Files')) / 'Renode/renode.exe') if os.name == 'nt' else None
        for tool, binary in [('qemu', 'qemu-system-arm'), ('renode', 'renode')]:
            path = executable(getattr(args, tool) or os.environ.get(tool.upper() + '_BINARY'),
                              binary, fallback if tool == 'renode' else None)
            output = run(path, '--version')
            report[tool] = {'path': path, 'version_output': output,
                            'version': version(output, tool, lock[tool]['version'], args.locked)}
        report['machines'] = machines(run(report['qemu']['path'], '-machine', 'help'), lock['qemu']['machines'])
        report['status'] = 'passed'
    except (OSError, ValueError, subprocess.TimeoutExpired) as error:
        report['error'] = str(error)
    content = json.dumps(report, ensure_ascii=False, indent=2)
    print(content)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(content + '\n', encoding='utf-8')
    return 0 if report['status'] == 'passed' else 1


if __name__ == '__main__':
    sys.exit(main())
