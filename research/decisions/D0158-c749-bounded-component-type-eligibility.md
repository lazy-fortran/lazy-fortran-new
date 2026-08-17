# D0158. C749 bounded component-type eligibility oracle

Date: 2026-08-17
Status: proposed
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Decision needed

Accept this bounded leaf only after the fresh replay and focused independent
review both pass with the control-plane evidence recorded by E0216/R000589.

## Context

D0157 selected C749 as the next bounded source-backed property after the
corrected C748 oracle. The fresh E0216/R000006 replay now exercises the
selected relation over the exact pinned source span and existing StandardIR
witnesses.

## Decision

Promote only the bounded oracle leaf
`component-def-stmt-component-type-eligibility` if the focused independent
review remains PASS. Its candidate fields are:

```text
pointer-or-allocatable-attribute: absent | present | unknown
declaration-type-category: intrinsic | previously-defined-derived | enum |
  enumeration | other | unknown
context: component-def-stmt | other | unknown
```

The deterministic outcome rule is:

```text
component-def-stmt + absent + intrinsic|previously-defined-derived|enum|enumeration  ACCEPTED
component-def-stmt + absent + other                                             REJECTED
all other states                                                                UNRESOLVED
```

The complete 54-state table, twelve mutation controls, source binding and
semantic canonicalization are required evidence. No model output can promote
a semantic fact.

## Rejected

* Treating the C749 obligation as a parser or type-checker implementation.
* Resolving whether a named derived, enum or enumeration type was previously
  defined.
* Combining C749 with C750 or C751.
* Promoting the retained model-origin witness row or any semantic fact.

## Reversal condition

Write a successor if independent review finds a source-binding, outcome-table,
mutation, reproducibility or scope defect, or if a later source-backed replay
contradicts the selected bounded relation.

## Evidence

* `research/runs/2026-08.jsonl#R000582` selects C749.
* `research/runs/2026-08.jsonl#R000583`--`#R000588` retain failed replay
  attempts and bootstrap defects.
* `research/runs/2026-08.jsonl#R000589` records the passing E0216/R000006
  replay.
* `artifacts/reports/M3/m3-c749-source-backed-v0.md`.
* `.cache/runs/E0001/R000003/j3-24-007.canonical.txt`, lines 3835--3837,
  and `.cache/runs/E0001/R000003/j3-24-007.pages.index`, record 93.
* `.cache/runs/E0171/R000433-provenance-replay/standardir.sx`, rows R703
  and R737.
* Pinned canonical text SHA-256
  `1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e`,
  page-index SHA-256
  `49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929`,
  StandardIR SHA-256
  `106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2` and
  normative PDF SHA-256
  `7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2`.

<!--
This body is immutable once the status is accepted. To change a decision,
write a successor naming this one in Supersedes, Amends or Retracts.
-->
