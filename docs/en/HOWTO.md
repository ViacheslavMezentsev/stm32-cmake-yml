# How-to: frequent commands and problems

[Documentation](index.md) · [Русский](../ru/HOWTO.md)

Short recipes for recurring situations. A new solution to a frequent problem is
recorded here (RU and EN) in the same commit that finds it. The overall procedure is
in [maintenance](maintenance.md#working-with-the-project).

## Git: workflow without PRs

A `<agent>/<task>` branch is created from a fresh main and, after checks, is merged
into main by fast-forward, with no merge commit. GitHub's web interface cannot merge
without a PR, and GitHub branch auto-deletion only works for PRs, so merging and
cleanup are done locally. Pushes, tags and releases are done by the repository owner.

```
git switch main
git pull --ff-only
git switch -c claude/<task>            # new branch
# … commits …
git push -u origin claude/<task>       # CI: wait for green Docs and Configure
git land claude/<task>                 # fast-forward main, push, delete the branch
```

A fast-forward creates no merge commit: main gets the same signed commits, and GitHub
shows them as Verified. If the branch is behind main, `git land` stops at
`--ff-only` without changing anything. Rebase the branch onto a fresh main and sign
again:

```
git switch claude/<task>
git rebase -S origin/main              # conflicts: fix, git add, git rebase --continue
git push --force-with-lease            # only for your own unmerged branch
```

Force pushes to main and to other people's branches are forbidden. Links to PR #1…#46
in the history stay as they are.

### Agent workflows

Each agent has its own workflow, described separately and not generalized. A new agent
adds its own subsection once its workflow has been verified in practice.

#### Codex on Windows

Verified on 2026-10-01 while preparing YAML includes for 0.10.0.

- Codex uses the local Windows working tree through PowerShell and Windows git,
  creates `codex/<task>` from current main and preserves line endings according
  to `.gitattributes`. Local checks precede push; full L0–L5 runs at stage completion.
- The owner creates the signed commit on Windows (`git commit -S`), pushes and
  runs `git land` after green CI. Conventional Commit messages are in English
  without references to agent sessions. Signing configuration stays unchanged.
- The GitHub connector reads REST API without manually extracting tokens.
  Check `actions/runs?head_sha=<SHA>` for `git rev-parse HEAD`, then
  `actions/runs/<ID>/jobs` and `actions/runs/<ID>/artifacts`. All expected
  workflows need `status: completed` and `conclusion: success`; a missing run
  or one green job does not establish success of the whole check.
- API reads do not update local Git references: `git fetch origin` is a separate
  step. If Git is unavailable, reading `branches/main` through the connector
  allows comparing SHAs but does not synchronize the working tree.
  Commit `verification.verified` confirms its signature, not CI results.

#### Claude in Cowork (a cloud session linked to the owner's computer)

Verified on 2026-09-30 during stage 0 of the 0.10.0 plan.

- Claude's commands on the owner's computer run in an isolated Linux machine with only
  the repository folder mounted. It has no owner's `~/.gitconfig` or `~/.ssh`, and its
  git sees the CRLF line endings of the Windows working tree as changes.
- Claude creates a `claude/<task>` branch from `origin/main` and edits the files of the
  working tree directly, preserving their line endings (CRLF, or LF for `eol=lf`
  paths). It does not commit and runs no git commands in that tree that change the
  index or history.
- Claude puts the commit message into `.git/<NAME>_MSG` (outside tracked files) and
  gives the commands `git add <paths>` and `git commit -F .git/<NAME>_MSG`. The owner
  commits from Windows, so the owner's key signs the commit, then runs
  `git push -u origin <branch>`.
- Claude checks CI through the public GitHub API (runs, steps, annotations, commit
  signature) and says when to run `git land`; afterwards it checks CI on main and
  removes its temporary files in `.git`.
- If Claude's git leaves `.git/index.lock` (deleting in the mounted folder needs
  permission), git on Windows stops working: Claude asks for delete permission and
  removes the file, or the owner deletes it manually.

#### Ready commits without access to the working tree

If an agent hands over ready commits (for example through `git bundle`), they are
unsigned. Re-sign them before pushing with `git rebase -S origin/main`; this changes the
hashes, so documentation does not reference hashes of commits from the same unmerged
branch.

### The `git land` alias

Install it with single quotes: in PowerShell, `$` inside double quotes is expanded by
PowerShell itself, and `\"` does not escape a quote.

```powershell
git config --global --unset-all alias.land   # if it existed; "no such section" is harmless
git config --global alias.land '!f() { b=${1:-$(git branch --show-current)}; git fetch origin && git switch main && git merge --ff-only origin/main && git merge --ff-only $b && git push --atomic origin main :$b && git branch -d $b; }; f'
git config --global --get-all alias.land     # exactly one line with b=${1:-$(git branch --show-current)}
```

The same command works unchanged in sh. `git land <branch>` does: `fetch` →
fast-forward main to `origin/main` → fast-forward main to the branch → one atomic push
of main plus deletion of the branch on GitHub → deletion of the local branch.

| Problem | Solution |
| --- | --- |
| `syntax error: unexpected end of file`, the error shows `b=;` | The alias was written in double quotes from PowerShell. Remove it (`--unset-all`) and write it again in single quotes |
| `warning: alias.land has multiple values` | `git config --global --unset-all alias.land`, then write it again; or `git config --global --edit` and delete the extra `land = …` lines |
| `fatal: Not possible to fast-forward` | The branch is behind main: `git rebase -S origin/main` (above) |
| Push rejected: protected branch, required pull request | In Settings → Rules remove the PR requirement for main or allow yourself to bypass it |

To revert: remove the alias with `git config --global --unset-all alias.land`.

### Branch cleanup

```
git fetch --prune                                  # drop refs to branches deleted on GitHub
git branch -r --merged origin/main                 # merged branches on GitHub
git push origin --delete <branch> [<branch> …]     # delete on GitHub
git branch -vv                                     # local; [gone] means no longer on GitHub
git branch -d <branch>                             # delete a merged local branch
git branch -D <branch>                             # delete when the hash differs but the content is in main
```

### Restoring state

| Situation | Command |
| --- | --- |
| Discard uncommitted changes in files | `git restore <file>` or `git restore .` |
| Unstage a file, keeping the changes | `git restore --staged <file>` |
| Delete untracked files | first `git clean -n` (what will be deleted), then `git clean -f`; do not use `-x` |
| Undo the last unpushed commit, keeping the changes | `git reset --soft HEAD~1` |
| Local main is broken but not pushed | `git switch main && git reset --hard origin/main` |
| A branch was deleted by mistake | `git reflog` → find the hash → `git branch <branch> <hash>`; restore on GitHub: `git push origin <branch>` |
| Undo a commit already pushed to main | `git revert <hash>` as a new signed commit, then the normal cycle; never rewrite main's history |
| Abort a failed rebase or merge | `git rebase --abort` / `git merge --abort` |

### Signing and Verified

```
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519_signing.pub
git config --global commit.gpgsign true
git log --show-signature -1            # check the signature of the last commit
```

Add the key to GitHub as a **Signing Key** (separate from the Authentication Key); the
author email must be a verified address of the account. Unverified means the commit is
unsigned, signed with another key, or the email does not match. For unpushed commits,
fix it with `git commit --amend -S --no-edit` (last commit) or `git rebase -S origin/main`
(all branch commits). To revert: `git config --global --unset commit.gpgsign`.

`git log --show-signature` prints `gpg.ssh.allowedSignersFile needs to be configured`
and "No signature" — the commit may be signed, but git does not know which keys to trust
for local verification (GitHub verifies against its own Signing Keys). To check that a
signature exists: `git cat-file -p HEAD` shows a `gpgsig` header. Set up local
verification once (PowerShell):

```powershell
$pub = Get-Content ~/.ssh/id_ed25519_signing.pub
"<author email> $pub" | Out-File -Encoding ascii ~/.ssh/allowed_signers
git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
```

### Line endings

- On Windows `core.autocrlf=true`: CRLF in the working tree, LF in the repository.
  `ci/**`, `tests/**`, `tools/**`, `.github/workflows/**` are always LF (`.gitattributes`).
- Every file shows as modified without a real change — line endings. This happens when
  a Windows working tree is opened by git from Linux or WSL: check
  `git diff --ignore-cr-at-eol --stat` (empty means no changes) and use git for Windows
  with that working tree. Never run `git commit -a` from such an environment.
- `fatal: Unable to create '…/.git/index.lock': File exists` — make sure git is not
  running (IDE, another terminal), then delete `.git/index.lock`.

## CI on GitHub

- Pushes run Docs and Configure; Firmware is manual: Actions → Firmware → Run workflow
  → branch main. See [GitHub checks](maintenance.md#github-checks).
- `Build test environment` or an archive download failed — first use "Re-run failed
  jobs": archives are pinned by SHA-256, so a new download does not change the image.
  If it fails again, find which archive did not download.
- The full job log is not available without signing in to GitHub (the API returns
  403); diagnostic artifacts are kept for 14 days.

## Local Configure tests in Docker Desktop

Many small files on a Windows bind mount slow fixture copies and Configure.
For a full run, place a source snapshot and temporary test directories on the
Linux container filesystem, then save diagnostics to Windows as one archive.
In the include matrix, a typical case dropped from roughly 7–9 s to 0.4–0.8 s;
this is a measurement of one environment, not a CI timing guarantee.
Use an image matching the current `ci/dependencies.lock.json`.

PowerShell example (repository root, after building `stm32-yml-ci:local`):

```powershell
New-Item -ItemType Directory -Force build/configure-local | Out-Null
docker run --rm --network none --mount "type=bind,source=$($PWD.Path),target=/workspace,readonly" --mount "type=bind,source=$($PWD.Path)/build/configure-local,target=/reports" stm32-yml-ci:local sh -c '
set -eu
mkdir /tmp/source /tmp/results
cp -a /workspace/ci /workspace/tests /workspace/cmake /workspace/scripts /workspace/stm32_yml.cmake /tmp/source/
result=0
python3 /tmp/source/ci/run_configure_tests.py --output /tmp/results || result=$?
tar -czf /reports/configure-results.tar.gz -C /tmp/results .
exit "$result"
'
```

The test exit code is preserved; the archive contains `summary.json`, CTest logs
and per-case diagnostics. Do not edit sources while creating the snapshot.

`tests/test_component_versions.py` currently targets Linux: on Windows its probe
CMake script uses paths with `\` and may fail with `Invalid character escape
'\g'`. This is a test harness limitation, not a library version check result.
To match Docs CI:

```powershell
docker run --rm --network none --mount "type=bind,source=$($PWD.Path),target=/workspace,readonly" stm32-yml-ci:local python3 -m unittest discover -s /workspace/tests -p test_component_versions.py
```

## Configure diagnostics after CI sharding

- `configure-summary` contains the combined `summary.json`; `configure-summary-<GCC>` contains both pairs for one GCC version.
- `configure-diagnostics-<GCC>` contains logs, step snapshots, cache, Ninja files and observed properties. Extract `configure-diagnostics.tar.gz` after downloading.
- Missing jobs or incomplete reports fail the final `configure` job even when other jobs are green.
- To run one version locally inside the pinned container: `python3 /workspace/ci/run_configure_tests.py --output /results --gcc-version 14.2.1-1.1`. Omit the last argument for the full matrix.
- To refresh Ubuntu packages: Actions → Configure → Run workflow → `rebuild_environment`. Test results are never cached.

## Installing schema-check dependencies

Use a separate venv as [documented](schema.md); consumer projects do not need
these packages. If Windows pip cannot reach PyPI, run the check in an available
Linux container with Python 3.11+, pip, CMake and Ninja. Install dependencies
into a temporary directory without changing the container system Python:

```sh
python3 -m pip install --target /tmp/schema-deps -r ci/schema-requirements.txt
PYTHONPATH=/tmp/schema-deps python3 ci/check_schema.py
PYTHONPATH=/tmp/schema-deps python3 -m unittest discover -s tests -p test_config_schema.py
```
