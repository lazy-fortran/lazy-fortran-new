# D0132. Eighth M3 slice uses C723 complex named-constant legality

Date: 2026-08-17
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

The seven bounded M3 slices are promoted, but full M3/Core 0 remains open
under the E0181 ledger gate. The next residual must bind to an already
represented StandardIR shape and be decidable by a small deterministic oracle.

The retained witness ledger marks C723 as disputed rather than independently
witnessed. Its source occurrence is a direct restriction on the named-constant
alternative already present in both R719 `real-part` and R720 `imag-part`,
which are referenced by R718 `complex-literal-constant`. C720 and C722 require
processor representation methods; C717 and C724 require value/representation
evaluation; C726, C729 and later residuals require broader declaration or
construct context. C723 is therefore the smallest next source-backed slice.

## Decision

Define the eighth bounded M3 delivery slice as the C723 complex named-constant
oracle. Its typed candidate represents one named constant used as a complex
literal part with two already-classified states:

```text
scalar shape and type integer or real → ACCEPTED
known non-scalar shape or other type  → REJECTED
unknown shape or type                 → UNRESOLVED
```

The source binding is J3-24-007 C723 at canonical-text line 3396, printed page
82, with StandardIR R718 occurrence 68 and the R719/R720 operand occurrences
69 and 70. The contract carries the normative PDF hash, canonical-text hash,
StandardIR hash and exact row metadata. It includes two accepted witnesses,
one rejected neighbour, one unresolved control and five source/rule identity
mutation controls.

Only the bounded named-constant shape/type predicate is evaluated. Name
resolution, expression parsing, literal evaluation, kind selection, processor
representation, diagnostics, compiler wiring and model inference remain
outside this contract. Candidate facts are human-authored; no model output can
promote a semantic fact.

## Rejected

* Resuming E0172 or another broad semantic/model experiment: the missing
  delivery artifact is still a deterministic verifier, not another proposal
  set.
* Treating the disputed C723 self-consistency witness as semantic evidence:
  the new oracle must compute outcomes from typed candidate state and retain
  the old disputed result as historical evidence.
* Evaluating processor kind availability or complex-literal conversion with
  C723: those facts are outside the bounded source restriction.
* Selecting C720/C722, whose predicates require processor representation
  facts, before a deterministic processor oracle exists.

## Reversal condition

Write a successor if C723 cannot bind to R718/R719/R720 without name
resolution, expression evaluation or processor facts, or if a clean replay
contradicts the pinned source identity or the independent oracle outcomes.

## Evidence

* `.cache/runs/E0001/R000003/j3-24-007.canonical.txt` line 3396.
* `.cache/runs/E0171/R000433-provenance-replay/standardir.sx` rows R718, R719
  and R720.
* `.cache/runs/E0123/R000001/analysis/witness/witnesses.jsonl` C723@1,
  retained as disputed historical evidence.
* `artifacts/standards/j3-24-007.toml` and its pinned PDF hash.
* `research/decisions/D0131-m3-core0-closure-after-six-bounded-slices.md`.
