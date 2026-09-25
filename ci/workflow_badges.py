"""Publish compact Shields endpoints for the latest completed main workflows."""
import argparse
import json
import os
from pathlib import Path
from urllib.request import Request, urlopen

from publish_firmware_badge import publish_files

WORKFLOWS = {'configure.yml': ('Configure', 'configure'),
             'firmware.yml': ('Firmware', 'firmware'),
             'documentation.yml': ('Docs', 'docs')}


def endpoint(label, run):
    conclusion = run['conclusion'] if run else None
    message, color = {
        'success': ('PASS', '238636'),
        'failure': ('FAIL', 'b62324'),
        'timed_out': ('FAIL', 'b62324'),
        'action_required': ('FAIL', 'b62324'),
        'startup_failure': ('FAIL', 'b62324'),
        'cancelled': ('CANCEL', '777777'),
        'skipped': ('SKIP', '777777'),
    }.get(conclusion, ('N/A', '777777'))
    return {'schemaVersion': 1, 'label': label, 'message': message,
            'color': color, 'style': 'flat-square'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--publish', action='store_true')
    args = parser.parse_args()
    repository = os.environ['GITHUB_REPOSITORY']
    args.output.mkdir(parents=True, exist_ok=True)
    names = []
    report = {}
    for workflow, (label, stem) in WORKFLOWS.items():
        url = f'https://api.github.com/repos/{repository}/actions/workflows/{workflow}/runs?branch=main&status=completed&per_page=1'
        headers = {'Accept': 'application/vnd.github+json'}
        if os.environ.get('GH_TOKEN'):
            headers['Authorization'] = 'Bearer ' + os.environ['GH_TOKEN']
        request = Request(url, headers=headers)
        with urlopen(request, timeout=30) as response:
            runs = json.load(response)['workflow_runs']
        run = runs[0] if runs else None
        if run and (run['head_branch'] != 'main' or run['status'] != 'completed'
                    or run['repository']['full_name'] != repository):
            raise ValueError('Unexpected workflow provenance')
        report[label] = {'run_url': run['html_url'] if run else None,
                         'revision': run['head_sha'] if run else None,
                         'conclusion': run['conclusion'] if run else None}
        name = stem + '-status.json'
        (args.output / name).write_text(json.dumps(endpoint(label, run)) + '\n', encoding='utf-8')
        names.append(name)
    (args.output / 'workflow-status-report.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    names.append('workflow-status-report.json')
    if args.publish:
        if os.environ.get('GITHUB_REF') != 'refs/heads/main':
            raise ValueError('Only main can publish badges')
        publish_files(args.output, names, 'Refresh completed main workflow badges')


if __name__ == '__main__':
    main()
