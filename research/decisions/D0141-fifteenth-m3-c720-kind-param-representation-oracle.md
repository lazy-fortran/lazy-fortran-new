# D0141. Fifteenth M3 slice uses C720 kind-param representation legality

Date: 2026-08-17
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

Post-promotion reconciliation `R000482` applies the fourteen promoted
contracts to the retained E0181 witness ledger. Its exact verifier leaves 157
outside-promoted rows: 90 `disputed` and 67 `unwitnessed`. C720 is the first
remaining row in normative order. Its source occurrence binds to the already
represented StandardIR R708 `int-literal-constant` shape.

C720 states that the value of `kind-param` shall specify a representation
method that exists on the processor. The processor fact is a typed candidate
state. The oracle classifies that state and does not discover processor
capabilities.

## Decision

Define the next bounded M3 delivery contract as the C720 kind-param
representation-method oracle. Its typed candidate represents a `kind-param`
occurrence and carries this state:

```text
representation_method: absent | present | unknown
```

The deterministic outcome is:

```text
representation_method=present  ACCEPTED
representation_method=absent   REJECTED
representation_method=unknown  UNRESOLVED
```

The exact source binding is J3-24-007 C720, canonical-text line 3298 on
printed/page-index page 80. The represented syntax shape is StandardIR R708,
`int-literal-constant`, with this source metadata:

```text
canonical text: .cache/runs/E0001/R000003/j3-24-007.canonical.txt
canonical SHA-256: 1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e
PDF SHA-256: 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2
page index: .cache/runs/E0001/R000003/j3-24-007.pages.index
page-index SHA-256: 49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929
page 80: start 204806 length 2920
C720 line: 3298
StandardIR: .cache/runs/E0171/R000433-provenance-replay/standardir.sx
StandardIR SHA-256: 106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2
R708: lhs int-literal-constant, page 80, byte-start 207585, byte-length 61, occurrence 58
standard-new: f94c4c51b51fce22b533b7eeda08741970320913
```

The fixture must contain one positive witness, one absent-method negative
neighbour and one unknown-state control. Source/PDF, canonical-line,
StandardIR-row, semantic-item and contract-identity mutations must fail
closed. No model output can promote a semantic fact.

This contract covers the C720 representation-method relation over an already
represented `kind-param` occurrence. It does not evaluate kind expressions,
discover processor methods, enforce C719 nonnegativity, parse Fortran or claim
the surrounding literal-constant semantics.

## Rejected

* Combining C719 nonnegativity with C720 representation support. C719 is a
  separate promoted contract and its conjunction would enlarge this slice.
* Selecting C722 before C720. C722 has the same processor-state boundary for
  real-literal approximation methods and follows C720 in normative order.
* Selecting C724, C726, C731 or C735. Those rows require a second relation,
  context sets or constant-expression handling.
* Starting another model experiment or reviving E0172.

## Reversal condition

Write a successor if canonical line 3298, StandardIR R708 or the pinned page
metadata do not bind to the selected relation, or if an independent replay
cannot distinguish present, absent and unknown method states without processor
introspection or expression evaluation.

## Evidence

* `research/runs/2026-08.jsonl#R000482` and
  `artifacts/reports/M3/m3-core0-witness-coverage-v2.md`.
* `.cache/runs/E0181/R000002/analysis/merged/selected-rows.jsonl`, `C720@1`.
* `.cache/runs/E0001/R000003/j3-24-007.canonical.txt`, line 3298.
* `.cache/runs/E0171/R000433-provenance-replay/standardir.sx`, row R708.
