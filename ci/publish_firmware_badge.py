"""Publish two generated files to ci-badges without switching or changing main."""
import argparse
import json
import os
from pathlib import Path
import subprocess


def git(*args, text=None):
    # mktree treats CR as part of the filename; do not translate LF on Windows.
    data = text.encode('utf-8') if text is not None else None
    return subprocess.check_output(['git', *args], input=data, timeout=60).decode('utf-8').strip()


def publish(directory, revision):
    result = json.loads((directory / 'firmware.json').read_text(encoding='utf-8'))
    if result['revision'] != revision:
        raise ValueError('Badge revision does not match workflow revision')
    current = git('ls-remote', 'origin', 'refs/heads/main').split()[0]
    if current != revision:
        print('main advanced; skip publishing an older result')
        return
    previous = git('ls-remote', 'origin', 'refs/heads/ci-badges')
    parent = []
    if previous:
        git('fetch', '--no-tags', 'origin', 'refs/heads/ci-badges')
        parent = ['-p', git('rev-parse', 'FETCH_HEAD')]
    entries = []
    for name in ('firmware.json', 'firmware.svg'):
        blob = git('hash-object', '-w', str(directory / name))
        entries.append(f'100644 blob {blob}\t{name}\n')
    tree = git('mktree', text=''.join(entries))
    commit = git('-c', 'user.name=github-actions[bot]', '-c',
                 'user.email=41898282+github-actions[bot]@users.noreply.github.com',
                 'commit-tree', tree, *parent, text=f'Firmware checks for {revision}\n')
    git('push', 'origin', f'{commit}:refs/heads/ci-badges')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--directory', type=Path, required=True)
    args = parser.parse_args()
    if os.environ.get('GITHUB_REF') != 'refs/heads/main':
        raise SystemExit('Badge publication is restricted to main')
    publish(args.directory, os.environ['GITHUB_SHA'])
