# D0142. Sixteenth M3 slice uses C722 approximation-method legality

Date: 2026-08-17
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

C720 is promoted only as a bounded representation-method oracle. The
post-C720 residual verifier `R000488` leaves 156 rows, with C722@1 first in
normative order. The pinned StandardIR already represents the
`real-literal-constant` shape in R714, so C722 has the same small processor-fact
boundary as C720 without requiring real-literal evaluation.

## Decision

Define the next bounded M3 delivery slice as the C722 kind-param
approximation-method oracle. Its typed candidate carries:

```text
approximation_method: absent | present | unknown
```

The deterministic outcome is:

```text
approximation_method=present  ACCEPTED
approximation_method=absent   REJECTED
approximation_method=unknown  UNRESOLVED
```

The exact source binding is J3-24-007 C722, canonical-text line 3356, printed
and page-index page 82. The represented syntax shape is StandardIR R714,
`real-literal-constant`, with page-index start 209809 and length 2554, and
byte-start 211120, byte-length 151, occurrence 64.

The fixture must contain one positive witness, one absent-method negative
neighbour and one unknown-state control. Source/PDF, canonical-line,
StandardIR-row, semantic-item and contract-identity mutations must fail
closed. No model output can promote a semantic fact.

This slice covers only the C722 approximation-method relation over an already
represented R714 occurrence. It does not evaluate real literals or kind
expressions, discover processor methods, enforce C719 or C721, parse Fortran,
or claim surrounding literal-constant semantics.

## Rejected

* Combining C720 and C722 into one processor-method contract. The two
  constraints concern different representation methods and remain separately
  auditable.
* Adding C721 exponent-letter legality. C721 is already promoted as a
  different relation over R714/R716.
* Evaluating real-literal spelling, kind values or processor capabilities.
* Starting another model experiment or reviving E0172.

## Reversal condition

Write a successor if canonical line 3356, StandardIR R714 or the pinned page
metadata do not bind to C722, or if an independent replay cannot distinguish
the three approximation-method states without expression evaluation or
processor introspection.

## Evidence

* `research/runs/2026-08.jsonl#R000488` and the C720 promotion record
  `#R000487`.
* `.cache/runs/E0181/R000002/analysis/merged/selected-rows.jsonl`, `C722@1`.
* `.cache/runs/E0001/R000003/j3-24-007.canonical.txt`, line 3356.
* `.cache/runs/E0171/R000433-provenance-replay/standardir.sx`, row R714.
