# D0155. Twenty-eighth M3 slice uses C748 component-attribute exact-once

Date: 2026-08-17
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

After promotion of the corrected C747 bounded oracle, the post-C747 residual
partition has 144 rows: 83 `disputed` and 61 `unwitnessed`, with `C748@1`
first. C748 is J3-24-007 clause 7, canonical line 3834, printed page 79, and
UTF-8 byte span `240727:97`:

```text
20 C748 (R737) No component-attr-spec shall appear more than once in a given component-def-stmt.
```

The reusable StandardIR shape is R737 (`data-component-def-stmt`). The retained
C748 model row is an unwitnessed input and is not evidence for the relation.

## Decision

Define the twenty-eighth bounded M3 delivery contract as a relation over three
typed candidate fields:

```text
attribute-name-presence: absent | present | unknown
definition-occurrence-cardinality: zero | one | many | unknown
context: component-def-stmt | other | unknown
```

The deterministic oracle is:

```text
attribute name absent, context=component-def-stmt                 ACCEPTED
attribute name present and occurrence=one,
  context=component-def-stmt                                     ACCEPTED
attribute name present and occurrence=zero or many,
  context=component-def-stmt                                     REJECTED
otherwise                                                        UNRESOLVED
```

The fixture shall cover the complete typed product with vacuous and satisfied
positive witnesses, zero/many negative neighbours, unresolved controls and
source, page, rule, StandardIR and contract-identity mutations. No model
output can promote a semantic fact.

This selection checks only C748's no-duplicate component-attribute obligation.
It does not parse component definitions, resolve attribute names, check C749
through C751, diagnose arbitrary Fortran or close full M3.

## Rejected

* Implementing C748 through C751 as one contract. The constraints cover
  distinct obligations and must remain independently witnessed.
* Parsing a component definition or resolving actual names. The bounded
  contract consumes typed presence and occurrence fields.
* Treating the retained model-origin C748 row as evidence or running another
  model experiment.

## Reversal condition

Write a successor if canonical line 3834, printed page 79, byte span
`240727:97`, or the R737 StandardIR binding does not hold, or if an independent
replay cannot distinguish the typed states without parsing, model output or
semantic promotion.

## Evidence

* `research/runs/2026-08.jsonl#R000576` and
  `artifacts/reports/M3/m3-core0-next-property-selection-v17.md`.
* `.cache/runs/E0001/R000003/j3-24-007.canonical.txt`, line 3834, and
  `.cache/runs/E0001/R000003/j3-24-007.pages.index`, canonical page 93.
* `.cache/runs/E0171/R000433-provenance-replay/standardir.sx`, row R737.
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
