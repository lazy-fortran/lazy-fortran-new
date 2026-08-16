# D0130. Sixth M3 slice uses C725 int-literal kind legality

Date: 2026-08-17
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

The bounded C1106, C702, C601, C603 and C721 M3 slices are promoted, but full
M3/Core 0 remains open. The pinned StandardIR already represents `char-length`
in R723 and `int-literal-constant` in R708. C725 is a direct exclusion over
that represented shape and can be checked without parsing a literal, evaluating
its value or consulting processor facts.

Historical E0083, E0087, E0090 and E0120 record earlier predicate and table
interpretations of C725. They remain context only. The current slice binds
directly to the pinned canonical source, StandardIR rows and central verifier.

## Decision

Define the sixth M3 delivery slice as the C725 int-literal kind oracle. Its
typed candidate carries the already-classified `kind_param` state for an
`int-literal-kind-use` fact. The deterministic oracle returns:

```text
kind parameter absent       → ACCEPTED
kind parameter present      → REJECTED
kind parameter unknown      → UNRESOLVED
```

The source binding is J3/24-007 C725 at canonical-text line 3452, printed page
83, with StandardIR rows R723 and R708. The contract carries the normative PDF
hash, canonical-text hash, StandardIR hash and exact row metadata. It includes
two accepted no-kind witnesses, a rejected kind-parameter neighbour, an
unknown-state control and five source/rule identity mutation controls.

Only this bounded exclusion is evaluated. Integer spelling, kind-value
validity, constant evaluation, processor representation, character length
semantics, diagnostics and compiler wiring remain outside this contract.
Candidate facts are human-authored and no model output can promote a semantic
fact.

## Rejected

* Resuming E0172 or another broad semantic/model experiment: the missing
  delivery artifact is a deterministic verifier, not another proposal set.
* Treating historical C725 predicates or compiler comparison as the current
  M3 verifier: those records are context, not this source-pinned replay gate.
* Evaluating integer literal spelling, kind availability or `char-length` with
  C725: the exclusion is decidable from the represented kind-parameter state.

## Reversal condition

Write a successor if the C725 candidate cannot bind the exclusion to the
R723/R708 source occurrences, or if the oracle requires parsing, value
evaluation, processor facts or another semantic property outside this bounded
contract.

## Evidence

* `.cache/runs/E0001/R000003/j3-24-007.canonical.txt` line 3452.
* `.cache/runs/E0171/R000433-provenance-replay/standardir.sx` rows R723 and
  R708.
* `research/experiments/E0083-can-deterministic-predicate-patterns-for`,
  `E0087-can-one-composite-semantic-ledger-preser`,
  `E0090-can-accepted-predicates-generate-a-seman` and
  `E0120-can-deterministic-normative-constraint-f`, retained as historical
  evidence only.
* `artifacts/standards/j3-24-007.toml` and its pinned PDF hash.
