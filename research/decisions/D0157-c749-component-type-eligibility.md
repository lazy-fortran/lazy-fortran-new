# D0157. Twenty-ninth M3 slice selects C749 component-type eligibility

Date: 2026-08-17
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

After promotion of the corrected C748 bounded oracle, the post-C748 residual
partition has 143 rows: 82 `disputed` and 61 `unwitnessed`, with `C749@1`
first. C749 is J3-24-007 clause 7, canonical lines 3835--3837, printed page
79, and UTF-8 byte span `240824:234`:

```text
21 C749 (R737) If neither the POINTER nor the ALLOCATABLE attribute is specified, the declaration-type-
22 spec in the component-def-stmt shall specify an intrinsic type, or a previously defined derived, enum, or
23 enumeration type.
```

The source span is contained by canonical page-index record 93. Existing
StandardIR provides R703 (`declaration-type-spec`) and R737
(`data-component-def-stmt`) with the same pinned source document.

## Decision

Define the twenty-ninth bounded M3 delivery contract over:

```text
pointer-or-allocatable-attribute: absent | present | unknown
declaration-type-category: intrinsic | previously-defined-derived | enum |
  enumeration | other | unknown
context: component-def-stmt | other | unknown
```

The deterministic oracle shall be:

```text
context=component-def-stmt, attribute=absent,
  type=intrinsic | previously-defined-derived | enum | enumeration  ACCEPTED
context=component-def-stmt, attribute=absent, type=other             REJECTED
otherwise                                                            UNRESOLVED
```

The implementation must retain the complete typed product, positive and
negative neighbours, unresolved controls, source/page/rule/identity mutation
controls, and an independently authored expected-outcome table. No model
output can promote a semantic fact.

This selection does not implement C749, parse component definitions, resolve
type names, validate actual POINTER or ALLOCATABLE declarations, check C750 or
C751, diagnose arbitrary Fortran or close full M3.

## Rejected

* Combining C749, C750 and C751 into one contract; they are separate obligations.
* Treating the retained model-origin C749 row as semantic evidence.
* Resolving whether a named derived, enum or enumeration type was previously
  defined; that belongs outside this bounded typed relation.

## Reversal condition

Write a successor if the pinned C749 source span, page-index containment or
R703/R737 StandardIR witnesses fail independent replay, or if the selected
typed relation cannot be checked without parsing, model output or semantic
promotion.

## Evidence

* `research/runs/2026-08.jsonl#R000581` records the failed verifier-path
  invocation; no selection evidence was produced by that attempt.
* `research/runs/2026-08.jsonl#R000582` records the corrected selection.
* `artifacts/reports/M3/m3-core0-next-property-selection-v18.md`.
* `.cache/runs/E0001/R000003/j3-24-007.canonical.txt`, lines 3835--3837, and
  `.cache/runs/E0001/R000003/j3-24-007.pages.index`, canonical page 93.
* `.cache/runs/E0171/R000433-provenance-replay/standardir.sx`, rows R703 and
  R737.
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
