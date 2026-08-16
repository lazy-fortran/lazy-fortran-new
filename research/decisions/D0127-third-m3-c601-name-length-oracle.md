# D0127. Third M3 slice uses C601 name-length legality

Date: 2026-08-16
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

The bounded C1106 associate-name and C702 type-parameter-colon slices are
promoted, but full M3/Core 0 remains open. The pinned StandardIR already
represents the name shape in R603 and its `alphanumeric-character` components
in R601 and R602. The normative C601 text is one explicit maximum-length
restriction on that shape. Historical E0090 reports a related generated
checker, but it is not a current central M3 verifier and is not reused as
promotion evidence.

## Decision

Define the third M3 delivery slice as the C601 name-length oracle. Its typed
candidate is a raw spelling for an already identified name. The deterministic
oracle first checks the bounded R601--R603 ASCII name shape, then counts its
characters and applies C601:

```text
non-name spelling                              → UNRESOLVED
valid name with length at most 63              → ACCEPTED
valid name with length greater than 63         → REJECTED
```

The source binding is J3/24-007 C601 at canonical-text line 2809, printed page
67, with StandardIR rows R601, R602 and R603. The contract carries the
normative PDF hash, canonical-text hash, StandardIR hash and exact row
metadata. It includes a one-character positive witness, the 63-character
boundary, a 64-character negative neighbour, an invalid-spelling unresolved
control, and source/rule mutation controls.

Only this bounded spelling property is evaluated. Full source parsing, name
resolution, case folding beyond the ASCII source shape, Unicode name rules,
diagnostics and compiler wiring remain outside this contract. Candidate facts
are human-authored and no model output can promote a semantic fact.

## Rejected

* Resuming E0172 or another broad semantic/model experiment: the missing
  delivery artifact is a deterministic verifier, not a larger proposal set.
* Treating a generated checker or gfortran comparison from E0090 as the
  current M3 verifier: those records are historical evidence, not this
  source-pinned replay gate.
* Evaluating declaration or scope semantics with C601: the restriction can be
  checked from the represented name shape and spelling alone.

## Reversal condition

Write a successor if the C601 candidate cannot bind the spelling to R603 and
the R601/R602 character shape, or if its independent oracle requires parsing,
name resolution or another semantic property outside this bounded contract.

## Evidence

* `.cache/runs/E0001/R000003/j3-24-007.canonical.txt` line 2809.
* `.cache/runs/E0171/R000433-provenance-replay/standardir.sx` rows R601,
  R602 and R603.
* `research/experiments/E0090-can-accepted-predicates-generate-a-seman/`,
  retained as historical evidence only.
* `artifacts/standards/j3-24-007.toml` and its pinned PDF hash.
