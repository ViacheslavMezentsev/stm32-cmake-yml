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

### Working with an agent through the working tree

The agent edits the files of the `<agent>/<task>` branch directly in your working tree
and does not commit: its git runs without your signing key and sees Windows line
endings differently.

1. Review the changes: `git status`, `git diff`.
2. Commit them from Windows with the command the agent gives (`git add <files>` and
   `git commit -F <message file>`); your key signs the commit.
3. `git push -u origin <branch>`. The agent checks CI through the GitHub API and tells
   you when to run `git land`.

If an agent works without access to the working tree and hands over ready commits
(for example through `git bundle`), they are unsigned. Re-sign them before pushing with
`git rebase -S origin/main`; this changes the hashes, so documentation does not
reference hashes of commits from the same unmerged branch.

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
