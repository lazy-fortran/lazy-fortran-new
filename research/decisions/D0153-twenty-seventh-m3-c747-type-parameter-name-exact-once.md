# D0153. Twenty-seventh M3 slice uses C747 type-parameter-name exact-once

Date: 2026-08-17
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

The post-C746 residual partition has 145 rows, 84 `disputed` and 61
`unwitnessed`, with `C747@1` first. Recompute those values with the exact
selection command recorded in `TASK_POOL.yaml`.

C747 is J3-24-007 clause 7, canonical lines 3766--3767, printed page 77, and
UTF-8 byte span `237572:183`. It states that each type-param-name in a
derived-type-stmt in a derived-type-def shall appear exactly once as a
type-param-name in a type-param-def-stmt in that derived-type-def.

The reusable StandardIR shapes are R727 (`derived-type-stmt`), R732
(`type-param-def-stmt`) and R733 (`type-param-decl`). They are already pinned
by the C746 source-backed slice.

## Decision

Define the twenty-seventh bounded M3 delivery contract as a relation over three
typed candidate fields:

```text
derived-name-presence: absent | present | unknown
definition-occurrence-cardinality: zero | one | many | unknown
context: derived-type-def | other | unknown
```

The deterministic oracle is:

```text
derived name absent, context=derived-type-def       ACCEPTED
derived name present and occurrence=one,
  context=derived-type-def                          ACCEPTED
derived name present and occurrence=zero or many,
  context=derived-type-def                          REJECTED
otherwise                                            UNRESOLVED
```

The fixture shall cover vacuous and satisfied positive witnesses, missing and
duplicate negative neighbors, unresolved controls and source, page, rule,
StandardIR and contract-identity mutations. No model output can promote a
semantic fact.

This slice checks the C747 exactly-once relation for a selected derived
type-param-name. It does not check extra definition names, which belongs to
C746, parse a derived-type definition, compare real identifier spellings,
perform case-folding or name resolution, diagnose arbitrary Fortran, restart
E0172 or close full M3.

## Rejected

* Implementing C746 and C747 as one combined oracle. C746 covers membership;
  C747 covers occurrence cardinality for names supplied by the derived-type
  statement.
* Treating an extra definition name as a C747 failure. That is outside this
  leaf and remains covered by the C746 membership contract.
* Parsing a derived-type definition or resolving actual names. The bounded
  contract consumes typed presence and occurrence fields.
* Treating the retained model-origin C747 row as evidence or running another
  model experiment.

## Reversal condition

Write a successor if canonical lines 3766--3767, byte span `237572:183`, or
the R727/R732/R733 StandardIR bindings do not hold, or if an independent
replay cannot distinguish the typed states without parsing, model output or
semantic promotion.

## Evidence

* `research/runs/2026-08.jsonl#R000568` and
  `artifacts/reports/M3/m3-core0-next-property-selection-v16.md`.
* `.cache/runs/E0001/R000003/j3-24-007.canonical.txt`, lines 3766--3767, and
  `.cache/runs/E0001/R000003/j3-24-007.pages.index`, page 77.
* `.cache/runs/E0171/R000433-provenance-replay/standardir.sx`, rows R727,
  R732 and R733.
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
