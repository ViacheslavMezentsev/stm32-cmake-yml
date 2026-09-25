"""Publish generated files to ci-badges without switching or changing main."""
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
    publish_files(directory, ('firmware.json', 'firmware.svg', 'counts.json'), f'Firmware checks for {revision}')


def publish_files(directory, names, message):
    # All workflow publishers share the ci-badges concurrency group.
    previous = git('ls-remote', 'origin', 'refs/heads/ci-badges')
    parent = []
    entries = {}
    if previous:
        git('fetch', '--no-tags', 'origin', 'refs/heads/ci-badges')
        parent = ['-p', git('rev-parse', 'FETCH_HEAD')]
        entries = {line.split('\t', 1)[1]: line for line in git('ls-tree', 'FETCH_HEAD').splitlines()}
    for name in names:
        blob = git('hash-object', '-w', str(directory / name))
        entries[name] = f'100644 blob {blob}\t{name}'
    tree = git('mktree', text='\n'.join(entries[name] for name in sorted(entries)) + '\n')
    commit = git('-c', 'user.name=github-actions[bot]', '-c',
                 'user.email=41898282+github-actions[bot]@users.noreply.github.com',
                 'commit-tree', tree, *parent, text=message + '\n')
    git('push', 'origin', f'{commit}:refs/heads/ci-badges')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--directory', type=Path, required=True)
    args = parser.parse_args()
    if os.environ.get('GITHUB_REF') != 'refs/heads/main':
        raise SystemExit('Badge publication is restricted to main')
    publish(args.directory, os.environ['GITHUB_SHA'])
