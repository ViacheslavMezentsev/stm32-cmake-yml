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
