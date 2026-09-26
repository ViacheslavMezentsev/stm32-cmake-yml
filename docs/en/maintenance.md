# Reference maintenance

[Documentation](index.md) → Maintenance · [Русский](../ru/maintenance.md)

Edit Markdown directly. No documentation generator is required;
`docs/reference-index.json` is a navigation/coverage index, not a YAML Schema
or a second set of defaults. RU/EN cards are the shared specification for people
and agents. The skill links to them rather than copying tables.

## Changing an option

1. Establish the baseline commit/version and inspect implementation, including cache.
2. State the intended contract; record observed defects separately in errata.
3. Update RU/EN cards with the same stable `CFG-*` ID and update the index.
4. Link tests that actually exist. One Configure test does not verify the entire
   contract. Use `tests: []` when no automated coverage exists.
5. Behavioral changes need a regression and compatibility/changelog entry.
   Do not silently change runtime code in a documentation PR.
6. Run `python ci/check_reference.py`.

`since: null` means introduction history is unknown; `verified_in` means presence
in the audited baseline. Do not conflate them. Add an index record and card with
each new YAML option; index validation does not prove that no undocumented
dynamic keys exist.

## Card template

```text
CFG-OPTION-ID / exact YAML key
Purpose and supported expected behavior
Type, supported values and conditional defaults
Missing / null / false / 0 / []
Precedence, profile, override and repeated Configure
Backend, dependencies, path base and application phase
YAML example; related options
Compatibility: audited commit, changes, unknown history
Implementation; tests and coverage limits; E* references
```

## Erratum template

```text
E<number> / title
Affected options and exact audited baseline
Conditions and minimal reproduction
Expected / actual result / impact
Workaround and its limitations
Evidence: reproduced or source-confirmed
Status: open / fix-prepared / merged / released
Fix commit, PR, release version (when established)
Regression test (when one exists)
```

Never reuse identifiers or delete fixed entries. The audit date bounds status
claims: after merging, update both languages and the index; a merge alone is
not a release. Keep unverified suspicions in discussions/issues until confirmed
rather than mixing them with confirmed errata.

## CI checks

`Documentation reference` checks new local page links, RU/EN anchors, unique
keys/IDs, references to existing tests and reciprocal errata mappings. It does
not check external networking or prove semantic correctness. New examples,
defect claims and contract changes require separate behavioral verification.

## Establishing expected behavior

Do not infer promised support from a single example, regex or failure. Compare
the user contract, implementation and function purpose first. When intent is
ambiguous, ask the author before declaring a defect or changing behavior.
Unsupported input does not imply a bug. `closed-by-design` preserves a previously
misclassified entry for stable links; it does not imply a released fix.

docs/ru/status.md and docs/en/status.md show validated suite size, not passed tests. When changing
`tests/cases.json` or the locked tool matrix, update `configure-counts`: the
validator checks scenarios, tool pairs and their product. Separate badges show
workflow status on main.

## Branches without pull requests

From 2026-09-24, create a `<agent>/<task>` branch from current main. The prefix
names the AI agent that creates the branch: `codex/` for Codex, `claude/` for
Claude. For a new agent, choose its prefix and add `<agent>/**` to the workflows'
`on.push.branches`, otherwise pushing the branch does not run CI. After local validation,
push the branch: Configure and documentation checks run on push; environment
checks run when their paths change. Match CI results to the branch's latest
commit. Update main and merge the tested branch with git merge, resolving
conflicts and rerunning affected checks if the resulting code changes. Push
main; its CI verifies the merge result.

No PR is required. Do not force push or treat old-commit results as validation
of new changes. Record branch, commit and status in TODO; preserve historical
PR links. If fetch/push is unavailable, an API check does not update local refs:
synchronization is still required before merging.

## Docker layer cache

The `ci/emulation` image (QEMU from the [tools/qemu](../../tools/qemu/README.md) archive, Renode) is built with BuildKit and the
GitHub Actions layer cache (`type=gha`, scope `stm32-yml-emulation`). A layer key
is the Dockerfile instruction plus the content of copied files, so a lock file,
install script or Dockerfile change rebuilds that layer and later ones. Downloads
are SHA-256 pinned, so caching does not change image contents.

Firmware reads and updates the cache. Emulation environment builds from scratch
(`no-cache`) and only writes a fresh cache, proving the pinned downloads remain
available and buildable. A branch cache is visible to that branch and its
descendants; branches read main's cache, main does not read branch caches.
Entries unused for 7 days are evicted; a miss builds from scratch as before.

The `ci/docker` image (about 8 GB: three GCCs, two CMakes, Cube/Arduino/ETL
sources) is not cached. Measurements on branch `claude/docker-image-cache`:

| Image | No cache | Build and write cache | From cache |
| --- | ---: | ---: | ---: |
| emulation | 3:08 | 6:16 | 0:12 |
| ci/docker | 2:55–3:01 | 9:02–10:37 | 2:35–2:38 |

For compilers, downloading the cache and loading 8 GB into Docker nearly equals
building from fast release downloads, while every cache write adds 6–7 minutes.
Firmware with all images cached took 5:34 instead of 10:04. QEMU compilation in
the image was later replaced by the prebuilt [tools/qemu](../../tools/qemu/README.md)
archive, so uncached emulator image builds no longer compile QEMU either.

## CI speed-up: options considered

Adopted (measured on GitHub jobs): one Renode process per pair (3:42 → 0:33), the
layer cache for the emulator image only, prebuilt QEMU in `tools/qemu`, parallel
dependency installation and Cube without `Projects`/`Utilities`. The compiler
image build dropped from ~2:45 to 1:09–1:29; Configure takes about 4:47 and
Firmware 4:39 (branch `claude/faster-ci-image`, `f3f1309`).

Little headroom remains inside a job: `ctest -j 4` and `cmake --build --parallel 4`
already use the runner's 4 cores. The next option is **not adopted** and kept for
later:

- Split GCC/CMake pairs across jobs (`strategy.matrix`): 6 Configure and 6
  Firmware jobs, one pair each; summary jobs `configure` and `smoke` check matrix
  completeness and assemble `matrix-summary.json` and the badge; a `pairs` job
  derives the matrix from `ci/dependencies.lock.json`. 15 jobs instead of 2.
- Estimate: Configure ~2:00, Firmware ~2:45 instead of ~4:45. The floor is the
  image build in every job.
- Cost: runner time per push grows from ~9.5 to ~25 minutes (the image builds in
  12 jobs); pair selection in `run_configure_tests.py` and `firmware_matrix.py`,
  report merging and reworked workflows and badge.

Revisit when the matrix grows (new GCC/CMake versions or families) or push time
becomes the bottleneck. Shrink the compiler image first, since its build repeats
in every job.

## Documentation-only pushes

Pushes that change only `.md` files at any depth run Docs, skipping Configure,
Firmware and CI environment. A mixed Markdown/code push still triggers the
relevant heavy workflows. Environment and firmware retain their existing positive
path filters, with the Markdown exclusion last. `workflow_dispatch` still allows
manual runs. A workflow/filter change itself is not documentation-only.

The Firmware counter retains the last successful tested revision when a docs-only
commit skips firmware CI; it does not claim the newer documentation commit was built.
README workflow badges use Shields.io `flat-square` with no logo; the generated
`Builds (Checks)` SVG uses the same rectangular form. Counts remain computed from
validated reports, not entered into README manually.

[GitHub path filters](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onpushpull_requestpull_request_targetpathspaths-ignore)
explain mixed changes, pattern ordering and skipped required checks. If branch
protection requires an omitted workflow, adjust that policy before relying on
MD-only merges. No protection setting is changed by this branch.
