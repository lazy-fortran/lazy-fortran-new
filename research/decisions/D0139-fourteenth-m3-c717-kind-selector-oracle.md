# D0139. Fourteenth M3 slice uses C717 kind-selector legality

Date: 2026-08-17
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

The E0181 witness-coverage reconciliation is recorded as R000076. Its exact
outside-promoted verifier leaves 158 retained rows: 91 disputed and 67
unwitnessed. C717 is the first outside-promoted row in normative order whose
syntax shape is already represented by StandardIR R706 and whose restriction
can be checked without parsing, name resolution or processor inference.

C717 states that the value of `scalar-int-constant-expr` in a kind-selector
shall be nonnegative and shall specify a representation method that exists on
the processor. This decision selects only that conjunction. The processor
fact is an input state to the oracle, not a fact inferred by the oracle.

## Decision

Define the next bounded M3 delivery contract as the C717 kind-selector
legality oracle. Its typed candidate carries only these states:

```text
kind_value: negative | nonnegative | unknown
representation_method: absent | present | unknown
```

The deterministic outcome is:

```text
kind_value=nonnegative and representation_method=present  ACCEPTED
kind_value=negative or representation_method=absent       REJECTED
either relevant state unknown                              UNRESOLVED
```

The exact source binding is J3-24-007 C717 (R706), canonical-text lines
3263--3264 on printed/page-index page 80. The represented syntax shape is
StandardIR R706, `kind-selector`, with the exact source metadata below:

```text
canonical text: .cache/runs/E0001/R000003/j3-24-007.canonical.txt
canonical SHA-256: 1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e
PDF SHA-256: 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2
page index: .cache/runs/E0001/R000003/j3-24-007.pages.index
page-index SHA-256: 49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929
page 80: start 204806 length 2920
C717 lines: 3263--3264
StandardIR: .cache/runs/E0171/R000433-provenance-replay/standardir.sx
StandardIR SHA-256: 106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2
R706: lhs kind-selector, page 80, byte-start 205461, byte-length 64, occurrence 56
standard-new: f94c4c51b51fce22b533b7eeda08741970320913
```

The fixture must contain positive witnesses for a nonnegative value with an
existing representation method, negative neighbours for a negative value and
an absent method, and unresolved controls for each unknown relevant state.
Source/PDF, canonical-line, StandardIR-row, semantic-item and contract
identity mutations must fail closed. No model output can promote a semantic
fact.

This contract does not evaluate integer expressions, discover processor
representation methods, parse kind-selectors, perform type checking or claim
the rest of C717's surrounding intrinsic-type semantics.

## Rejected

* Implementing all C717-adjacent kind semantics: C718, C719, C720, C722,
  C724, C732 and C733 require separate facts or broader processor relations.
* Selecting C726, C735, C743 or later residuals before this smaller R706-bound
  property; they require context sets, uniqueness or derived-type structure.
* Starting another model experiment or reviving E0172.
* Treating the retained E0123 proposal or its self-consistency status as
  semantic promotion.

## Reversal condition

Write a successor if the pinned C717 text cannot be shown on canonical lines
3263--3264, if R706 has different metadata, or if an independent replay cannot
distinguish the two rejecting states and the unknown states without adding
expression evaluation or processor analysis.

## Evidence

* E0181 outside-residual verifier and reconciliation:
  `research/runs/2026-08.jsonl#R000076` and
  `artifacts/reports/M3/m3-core0-witness-coverage-v1.md`.
* `.cache/runs/E0181/R000002/analysis/merged/selected-rows.jsonl`, `C717@1`.
* `.cache/runs/E0001/R000003/j3-24-007.canonical.txt`, lines 3263--3264.
* `.cache/runs/E0171/R000433-provenance-replay/standardir.sx`, row R706.
