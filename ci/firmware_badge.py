"""Generate a last-success badge from complete build and QEMU reports."""
import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
from firmware_matrix import pairs, verify_build, verify_matrix


def read(path):
    return json.loads(path.read_text(encoding='utf-8'))


def collect(build, run, lock, revision, emulator="qemu"):
    combinations = pairs(lock)
    verify_matrix(read(build / 'matrix-summary.json'), combinations)
    matrix = read(run / 'matrix-summary.json')
    actual = [(p['gcc'], p['cmake']) for p in matrix['pairs']]
    if (matrix['status'] != 'passed' or matrix['phase'] != 'run'
            or len(actual) != len(combinations) or set(actual) != set(combinations)
            or any(p['status'] != 'passed' for p in matrix['pairs'])):
        raise ValueError(f'Incomplete {emulator} matrix')
    builds = checks = 0
    for gcc, cmake in combinations:
        name = f'gcc-{gcc}_cmake-{cmake}'
        compiled = read(build / name / 'build-summary.json')
        verify_build(compiled, gcc, cmake)
        if compiled['git_revision'] != revision or compiled['git_dirty'] != '0':
            raise ValueError('Build provenance differs from the clean CI checkout')
        executed = read(run / name / f'{emulator}-summary.json')
        expected = {c['profile']: c['metadata'] for c in compiled['cases'] + [compiled['crc_negative']]}
        cases = executed['cases']
        if (executed['status'] != 'passed' or len(cases) != len(expected)
                or sorted(c['profile'] for c in cases) != sorted(expected)
                or any(c['passed'] is not True or c['metadata_ok'] is not True
                       or c['expected_metadata'] != expected[c['profile']] for c in cases)):
            raise ValueError(f'Missing, failed or mismatched {emulator} cases')
        builds += len(compiled['cases'])
        checks += len(cases)
    return {'builds': builds, 'checks': checks, 'emulator': 'QEMU' if emulator == 'qemu' else 'Renode', 'revision': revision}


def svg(result):
    message = f'{result["builds"]} ({result["checks"]})'
    width = 14 + len(message) * 7
    label = 'Builds (Checks)'
    left = 14 + len(label) * 7
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{left + width}" height="20" role="img" aria-label="{label}: {message}">
<title>Last successful main run: {label}, {message}</title>
<rect width="{left}" height="20" fill="#555"/><rect x="{left}" width="{width}" height="20" fill="#6b9278"/>
<g fill="#fff" text-anchor="middle" font-family="Verdana,DejaVu Sans,sans-serif" font-size="11">
<text x="{left / 2}" y="14">{label}</text><text x="{left + width / 2}" y="14">{message}</text></g></svg>
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('build', 'run', 'output'):
        parser.add_argument('--' + name, type=Path, required=True)
    parser.add_argument('--renode-run', type=Path)
    parser.add_argument('--revision', required=True)
    parser.add_argument('--run-url', required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    result = collect(args.build, args.run, read(root / 'ci/dependencies.lock.json'), args.revision)
    result['checks_by_emulator'] = {'QEMU': result['checks']}
    if args.renode_run:
        renode = collect(args.build, args.renode_run, read(root / 'ci/dependencies.lock.json'), args.revision, 'renode')
        result['checks_by_emulator']['Renode'] = renode['checks']
        result['checks'] += renode['checks']
        result['emulator'] = 'QEMU+Renode'
    result.update(run_url=args.run_url, generated_at=datetime.now(timezone.utc).isoformat())
    args.output.mkdir(parents=True, exist_ok=True)
    (args.output / 'firmware.svg').write_text(svg(result), encoding='utf-8')
    (args.output / 'firmware.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(f'Confirmed: {result["builds"]} builds / {result["checks"]} simulator checks')


if __name__ == '__main__':
    main()
