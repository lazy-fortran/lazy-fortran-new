# D0133. Ninth M3 slice uses C729 optional-comma legality

Date: 2026-08-17
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

The eight bounded M3 slices are promoted, but full M3/Core 0 remains open
under the E0181 ledger gate. Its retained witness analysis marks C729 as
unwitnessed. The C729 restriction is a small context implication over shapes
already represented in StandardIR: R722 `length-selector`, R703
`declaration-type-spec` and R801 `type-declaration-stmt`. It does not require
processor representation facts, expression evaluation or name resolution.

## Decision

Define the ninth bounded M3 delivery slice as the C729 optional-comma oracle.
Its typed candidate carries whether the optional comma is absent, present or
unknown and whether the enclosing context is the allowed
`declaration-type-spec` in a `type-declaration-stmt`, another known context or
unknown:

```text
comma absent                         → ACCEPTED
comma present + allowed context     → ACCEPTED
comma present + other context       → REJECTED
unknown comma or context             → UNRESOLVED
```

The source binding is J3-24-007 C729 at canonical-text line 3466, printed page
84, with StandardIR R722 occurrence 72 and the context rows R703 occurrence
53 and R801 occurrence 135. The contract carries the normative PDF hash,
canonical-text hash, StandardIR hash and exact row metadata. It includes
accepted present/allowed and absent/other witnesses, a rejected
present/other neighbour, an unresolved control and five source/rule identity
mutation controls.

Only this optional-comma context predicate is evaluated. Complete statement
parsing, declaration analysis, name resolution, type checking, diagnostics,
compiler wiring and model inference remain outside the contract. Candidate
facts are human-authored; no model output can promote a semantic fact.

## Rejected

* Resuming E0172 or another broad semantic/model experiment: the missing
  delivery artifact is still a deterministic verifier, not another proposal
  set.
* Selecting C724 before a deterministic processor-representation oracle
  exists; its value and representation-method restriction is outside this
  bounded context predicate.
* Selecting C726, whose allowed-star contexts require a broader declaration and
  allocation context than this slice.

## Reversal condition

Write a successor if C729 cannot bind to R722/R703/R801 without complete
statement parsing or declaration analysis, or if a clean replay contradicts
the pinned source identity or the independent oracle outcomes.

## Evidence

* `.cache/runs/E0001/R000003/j3-24-007.canonical.txt` line 3466.
* `.cache/runs/E0171/R000433-provenance-replay/standardir.sx` rows R703, R722
  and R801.
* `.cache/runs/E0123/R000001/analysis/witness/witnesses.jsonl` C729@1,
  retained as unwitnessed historical evidence.
* `artifacts/standards/j3-24-007.toml` and its pinned PDF hash.
* `research/decisions/D0132-seventh-m3-c723-complex-named-constant-oracle.md`.
