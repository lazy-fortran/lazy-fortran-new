# D0129. Fifth M3 slice uses C721 exponent-letter legality

Date: 2026-08-17
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

The bounded C1106, C702, C601 and C603 M3 slices are promoted, but full
M3/Core 0 remains open. The pinned StandardIR already represents the
`real-literal-constant` shape in R714 and its `exponent-letter` alternative in
R716. C721 is one explicit conditional restriction over that shape and can be
checked without evaluating a constant, resolving a name or selecting a
processor representation.

Historical E0095 evaluated C721 through an older generated predicate table. It
is retained as context only; the current M3 slice must bind directly to the
pinned canonical source, StandardIR rows and central verifier.

## Decision

Define the fifth M3 delivery slice as the C721 exponent-letter oracle. Its
typed candidate carries two already-classified fields: whether a kind
parameter is present and the exponent-letter state. The deterministic oracle
returns:

```text
unknown field state                                → UNRESOLVED
kind parameter present and exponent letter E       → ACCEPTED
kind parameter present and exponent letter D       → REJECTED
kind parameter absent, with no or D exponent      → ACCEPTED
```

The source binding is J3/24-007 C721 at canonical-text line 3355, printed page
81, with StandardIR rows R714 and R716. The contract carries the normative PDF
hash, canonical-text hash, StandardIR hash and exact row metadata. It includes
an accepted constrained witness, an accepted vacuous neighbour, the rejected
D-letter neighbour, an unresolved unknown-state control and source/rule
identity mutation controls.

Only this bounded implication is evaluated. Real-literal spelling, exponent
syntax, constant evaluation, kind-value validity, processor representation,
diagnostics and compiler wiring remain outside this contract. Candidate facts
are human-authored and no model output can promote a semantic fact.

## Rejected

* Resuming E0172 or another broad semantic/model experiment: the next
  delivery artifact is still a deterministic verifier, not a proposal set.
* Treating E0095 or gfortran comparison as the current M3 verifier: those
  records are historical evidence, not this source-pinned replay gate.
* Evaluating real-literal parsing or kind availability with C721: the bounded
  implication can be checked from the represented R714/R716 relation alone.

## Reversal condition

Write a successor if the C721 candidate cannot bind the implication to the
R714/R716 source occurrences, or if its independent oracle requires parsing,
constant evaluation, processor facts or another semantic property outside this
bounded contract.

## Evidence

* `.cache/runs/E0001/R000003/j3-24-007.canonical.txt` line 3355.
* `.cache/runs/E0171/R000433-provenance-replay/standardir.sx` rows R714 and
  R716.
* `research/experiments/E0095-can-one-generic-evaluator-execute-a-nest/`,
  retained as historical evidence only.
* `artifacts/standards/j3-24-007.toml` and its pinned PDF hash.
