# D0159. Thirtieth M3 slice selects C750 component-array deferred shape

Date: 2026-08-17
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

After the corrected C749 replay, the retained E0181 witness ledger has 142
unpromoted rows: 82 `disputed` and 60 `unwitnessed`. The deterministic
post-C749 partition selects `C750@1` first. C750 is J3-24-007 clause 7,
canonical lines 3838--3839, printed page 79, and byte span `241058:135`:

```text
24 C750 (R737) If the POINTER or ALLOCATABLE attribute is specified, each component-array-spec shall be
25 a deferred-shape-spec-list.
```

The span is contained by canonical page-index record 93. Existing StandardIR
provides R737 (`data-component-def-stmt`) and R740 (`component-array-spec`)
with the same pinned source document.

## Decision

Define the thirtieth bounded M3 delivery contract over:

```text
pointer-or-allocatable-attribute: absent | present | unknown
component-array-spec: deferred-shape-list | explicit-shape-list | unknown
context: component-def-stmt | other | unknown
```

The deterministic oracle shall be:

```text
context=component-def-stmt, attribute=present,
  array-spec=deferred-shape-list                         ACCEPTED
context=component-def-stmt, attribute=present,
  array-spec=explicit-shape-list                        REJECTED
otherwise                                                 UNRESOLVED
```

The implementation must retain the complete typed product, positive and
negative neighbours, unresolved states, source/page/rule/identity mutation
controls, and an independently authored expected-outcome table. No model
output can promote a semantic fact.

This selection does not implement C750, parse component declarations, decide
whether a real component array is deferred, resolve names, diagnose arbitrary
Fortran or close full M3.

## Rejected

* Combining C750 with C751 or C754; these are separate obligations.
* Treating the retained model-origin C750 row as semantic evidence.
* Using compiler behavior or a model to decide whether an actual array shape
  is deferred.

## Reversal condition

Write a successor if the pinned C750 source span, page-index containment or
R737/R740 StandardIR witnesses fail independent replay, or if the selected
typed relation cannot be checked without parsing, model output or semantic
promotion.

## Evidence

* `research/runs/2026-08.jsonl#R000594` records the corrected deterministic
  post-C749 selection.
* `artifacts/reports/M3/m3-core0-next-property-selection-v19.md` records the
  exact partition and source inspection.
* `.cache/runs/E0001/R000003/j3-24-007.canonical.txt`, lines 3838--3839, and
  `.cache/runs/E0001/R000003/j3-24-007.pages.index`, canonical page 93.
* `.cache/runs/E0171/R000433-provenance-replay/standardir.sx`, rows R737 and
  R740.
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
