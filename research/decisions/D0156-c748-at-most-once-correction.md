# D0156. C748 is an at-most-once, not exact-once, constraint

Date: 2026-08-17
Status: accepted
Amends: D0155
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

D0155 selected C748's source correctly but described its typed relation as
exact-once. The normative text at J3-24-007 clause 7, canonical line 3834,
printed page 79, says:

```text
20 C748 (R737) No component-attr-spec shall appear more than once in a given component-def-stmt.
```

That is an at-most-once constraint. Zero occurrences do not violate it. The
first replay R000577 passed its self-consistent table, but focused semantic
review R000578 found that it rejected the valid `present + zero` state. The
failed review is retained; the v0 result is not promotable.

## Decision

Amend D0155's property and oracle to `component-def-stmt-component-attr-spec-at-most-once`:

```text
attribute-name-presence: absent | present | unknown
definition-occurrence-cardinality: zero | one | many | unknown
context: component-def-stmt | other | unknown
```

The deterministic oracle is:

```text
context=component-def-stmt and attribute name absent       ACCEPTED
context=component-def-stmt and occurrence zero or one     ACCEPTED
context=component-def-stmt and occurrence many            REJECTED
otherwise                                                  UNRESOLVED
```

The corrected contract is version 1. It preserves the same source binding,
R737 witness, complete typed product and mutation controls, but has 6
`ACCEPTED`, 1 `REJECTED` and 29 `UNRESOLVED` states. It remains bounded-only;
no model output can promote a semantic fact.

## Rejected

* Treating “no more than once” as “exactly once”. This rejects a valid absence
  state and is not supported by C748.
* Promoting the v0 replay because its expected table matched its own oracle.
  Self-consistency is not an independent semantic oracle.
* Broadening the slice into component parsing, attribute-name resolution or
  C749--C751.

## Reversal condition

Write a successor if the pinned C748 text, source span, page-index containment,
R737 witness or at-most-once outcome relation is contradicted by an
independent source-backed replay.

## Evidence

* `research/runs/2026-08.jsonl#R000578` records the failed semantic review of
  v0; the corrected replay is recorded by `#R000579`.
* `artifacts/reports/M3/m3-c748-focused-review-v0.md` records the defect.
* `artifacts/reports/M3/m3-c748-source-backed-v1.md` records the corrected
  contract and replay.
* `.cache/runs/E0001/R000003/j3-24-007.canonical.txt`, line 3834, and
  `.cache/runs/E0001/R000003/j3-24-007.pages.index`, record 93.
* Pinned canonical text SHA-256
  `1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e`, page
  index SHA-256 `49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929`,
  StandardIR SHA-256
  `106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2` and
  normative PDF SHA-256
  `7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2`.

<!--
This body is immutable once the status is `accepted`. To change a decision,
write a new record that names this one in its Supersedes, Amends or Retracts
header and says what the old reasoning got wrong. Only the Status line of this
file may then be edited, to point at the successor.
-->
