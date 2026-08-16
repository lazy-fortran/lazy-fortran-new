# D0128. Fourth M3 slice uses C603 label-digit legality

Date: 2026-08-16
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

The bounded C1106, C702 and C601 M3 slices are promoted, but full M3/Core 0
remains open. The pinned StandardIR already represents statement-label syntax
in R611. C603 is one explicit restriction over that shape: a label must have
at least one nonzero digit. Historical E0092 exercised a related generic
evaluator, but it is not current central M3 evidence and is not reused as
promotion evidence.

## Decision

Define the fourth M3 delivery slice as the C603 label-digit oracle. Its typed
candidate is a raw spelling for an already identified label. The deterministic
oracle first checks the bounded R611 shape—one to five ASCII digits—then
applies C603:

```text
non-label spelling                              → UNRESOLVED
valid label containing a nonzero digit         → ACCEPTED
valid all-zero label                            → REJECTED
```

The source binding is J3/24-007 C603 at canonical-text line 2878, printed page
69, with StandardIR row R611. The contract carries the normative PDF hash,
canonical-text hash, StandardIR hash and exact row metadata. It includes a
short positive witness, a five-digit positive boundary, an all-zero negative
neighbour, an invalid-spelling unresolved control, and source/rule identity
mutation controls.

Only this bounded label property is evaluated. Statement parsing, scope
uniqueness, label references, nonblank-statement requirements, processor limits,
diagnostics and compiler wiring remain outside this contract. Candidate facts
are human-authored and no model output can promote a semantic fact.

## Rejected

* Resuming E0172 or another broad semantic/model experiment: the missing
  delivery artifact is a deterministic verifier, not a larger proposal set.
* Treating E0092's generic evaluator or gfortran comparison as the current M3
  verifier: those records are historical evidence, not this source-pinned
  replay gate.
* Evaluating statement scope or label-reference semantics with C603: the
  restriction can be checked from the represented R611 spelling alone.

## Reversal condition

Write a successor if the C603 candidate cannot bind the spelling to R611 and
the C603 source occurrence, or if its independent oracle requires statement
parsing, scope analysis or another semantic property outside this bounded
contract.

## Evidence

* `.cache/runs/E0001/R000003/j3-24-007.canonical.txt` line 2878.
* `.cache/runs/E0171/R000433-provenance-replay/standardir.sx` row R611.
* `research/experiments/E0092-can-one-generic-evaluator-execute-three-/`,
  retained as historical evidence only.
* `artifacts/standards/j3-24-007.toml` and its pinned PDF hash.
