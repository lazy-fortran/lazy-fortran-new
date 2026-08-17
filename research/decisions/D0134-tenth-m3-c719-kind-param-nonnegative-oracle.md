# D0134. Tenth M3 slice uses C719 kind-parameter nonnegative legality

Date: 2026-08-17
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

The nine bounded M3 slices are promoted, but full M3/Core 0 remains open
under the E0181 ledger gate. Its retained audit has four hard failures and two
unresolved rows. C719 is one of the hard-failure rows (`C719@1`) and its
constraint is a small bound over the already represented StandardIR `R709`
`kind-param` shape.

## Decision

Define the tenth bounded M3 delivery slice as the C719 kind-parameter
nonnegative oracle. The typed candidate carries only kind-parameter presence
and a value-state enum:

```text
kind-param absent                         → ACCEPTED
kind-param present + nonnegative value   → ACCEPTED
kind-param present + negative value      → REJECTED
unknown kind-param or value state        → UNRESOLVED
```

The source binding is J3-24-007 C719 at canonical-text line 3297, printed
page 80, with StandardIR R709 occurrence 59 and its exact byte span. The
contract includes the normative PDF hash, canonical-text hash, StandardIR
hash, semantic-item provenance and five source/rule identity mutation
controls. Candidate facts are human-authored; no model output can promote a
semantic fact.

Only this bounded nonnegative predicate is evaluated. The oracle does not
parse numeric literals, evaluate constant expressions, inspect processor
representation methods, resolve names, perform type checking, diagnose source
or wire compiler semantics.

## Rejected

* Restarting E0172 or another broad model comparison.
* Reusing the historical E0091 generated evaluator as the current oracle;
  it is comparison evidence, while this slice owns an independent typed
  candidate and fail-closed source gate.
* Selecting C738, C704, C1579 or C1586 before their wider type-definition or
  statement-context facts have bounded representations.

## Reversal condition

Write a successor if C719 cannot bind to R709 and line 3297 without numeric
literal parsing or constant evaluation, or if a clean replay contradicts the
pinned source identity or independent oracle outcomes.

## Evidence

* `.cache/runs/E0001/R000003/j3-24-007.canonical.txt` line 3297.
* `.cache/runs/E0171/R000433-provenance-replay/standardir.sx` R709.
* `.cache/runs/E0181/R000001/analysis/merged/selected-rows.jsonl` C719@1,
  retained as historical hard-failure evidence.
* `artifacts/standards/j3-24-007.toml` and its pinned PDF hash.
* `research/decisions/D0133-ninth-m3-c729-optional-comma-oracle.md`.
