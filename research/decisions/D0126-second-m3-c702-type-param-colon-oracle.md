# D0126. Second M3 slice uses C702 type-parameter colon legality

Date: 2026-08-16
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

The bounded C1106 associate-name slice is promoted, but full M3/Core 0 remains
open. The next slice must be source-backed, deterministic and small enough to
have an independent oracle. The pinned StandardIR already represents
`R701 type-param-value`, and it separately represents the `ALLOCATABLE` and
`POINTER` statement shapes in R832 and R856. The normative C702 text is a
single restriction on the colon alternative of R701.

## Decision

Define the second M3 delivery slice as the C702 type-parameter-colon oracle.
Its typed candidate represents a colon `type-param-value` plus one of four
attribute-context states: known pointer, known allocatable, known neither, or
unknown. The deterministic oracle is deliberately smaller than general type
checking:

```text
unknown attribute context                         → UNRESOLVED
known pointer or known allocatable attribute      → ACCEPTED
known context with neither attribute              → REJECTED
```

The source binding is J3/24-007 C702 at canonical-text lines 3096--3097,
printed page 62, with the already represented StandardIR rows R701, R832 and
R856. The contract carries the normative PDF hash, canonical-text hash,
StandardIR hash and exact row metadata. It includes positive pointer and
allocatable witnesses, a negative neither-attribute witness, an unresolved
unknown-context witness and source-hash/rule-identity mutation controls.

Only the bounded C702 property is evaluated. C701 constant-expression rules,
declaration typing, allocation semantics, name resolution, model proposals
and compiler wiring remain outside this contract. No model output can promote
a fact.

## Rejected

* Resuming E0172 or any broad semantic/model experiment: the missing delivery
  artifact is still a deterministic verifier, not a larger proposal corpus.
* Evaluating C701, abstract types, declaration typing or allocation behavior
  in the same slice: those properties require additional semantic evidence.
* Treating the presence of a `POINTER` or `ALLOCATABLE` syntax row as proof of
  a particular declaration context: the candidate records context explicitly,
  and unknown context remains `UNRESOLVED`.

## Reversal condition

Write a successor if the C702 candidate cannot bind the colon alternative and
the attribute-context witnesses to the pinned source and StandardIR rows, or
if its independent oracle requires declaration/type semantics outside this
bounded property.

## Evidence

* `.cache/runs/E0001/R000003/j3-24-007.canonical.txt` lines 3096--3097.
* `.cache/runs/E0171/R000433-provenance-replay/standardir.sx` rows R701,
  R832 and R856.
* `artifacts/standards/j3-24-007.toml` and its pinned PDF hash.
