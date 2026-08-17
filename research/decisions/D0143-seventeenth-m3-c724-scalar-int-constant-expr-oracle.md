# D0143. Seventeenth M3 slice uses C724 scalar-int-constant-expr legality

Date: 2026-08-17
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

The post-C722 residual selection verifier reports C724@1 as the first
outside-promoted row. The pinned source occurrence is C724 on canonical lines
3450--3451 and page 83. Its already represented syntax shape is StandardIR
R721, `char-selector`, on page 84. C724 requires the value of
`scalar-int-constant-expr` to be nonnegative and to specify a representation
method that exists on the processor.

## Decision

Define the next bounded M3 delivery slice as a typed C724 legality oracle. Its
candidate carries two source-backed states:

```text
value_sign: negative | nonnegative | unknown
representation_method: absent | present | unknown
```

The deterministic oracle uses known-violation precedence:

```text
value_sign=negative OR representation_method=absent  REJECTED
value_sign=nonnegative AND representation_method=present  ACCEPTED
otherwise  UNRESOLVED
```

The exact source binding is J3-24-007 C724, canonical lines 3450--3451, page
83, with StandardIR R721 at page 84, byte-start 217200, byte-length 251 and
occurrence 71. The normative PDF, canonical text, page index and StandardIR
source remain pinned to the existing J3-24-007 hashes.

The fixture must cover the complete nine-state product of the two typed
states, with positive, negative-neighbour and unresolved witnesses. Source,
page-index, StandardIR, semantic-item and contract-identity mutations must
fail closed. No model output can promote a semantic fact.

This slice checks only the relation over typed candidate states. It does not
evaluate scalar-int-constant-expr, compute numeric values, discover processor
representation methods, parse Fortran or claim full C724 or M3 semantics.

## Rejected

* Evaluating constant expressions or integer values. That would require a
  semantic evaluator outside this bounded source-backed oracle.
* Inspecting processor capabilities. The candidate state remains an explicit
  input and the oracle only checks its typed presence.
* Combining C724 with C720, C721 or C725. Those constraints remain separately
  auditable.
* Starting another model experiment or reviving E0172.

## Reversal condition

Write a successor if canonical lines 3450--3451, StandardIR R721 or the
pinned page metadata do not bind to C724, or if an independent replay cannot
distinguish the nine typed states without expression evaluation or processor
introspection.

## Evidence

* `research/runs/2026-08.jsonl#R000493` and
  `artifacts/reports/M3/m3-core0-next-property-selection-v4.md`.
* `.cache/runs/E0001/R000003/j3-24-007.canonical.txt`, lines 3450--3451.
* `.cache/runs/E0171/R000433-provenance-replay/standardir.sx`, row R721.
