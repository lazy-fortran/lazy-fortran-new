# D0149. Twenty-third M3 slice uses C743 private-or-sequence uniqueness states

Date: 2026-08-17
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

<!-- Optional headers, one per line, when they apply:
Supersedes: D####
Amends: D####
Retracts: D####
-->

## Context

Post-C735 reconciliation R000529 leaves 149 outside-promoted witness rows;
`C743@1` is first. The pinned normative occurrence is J3-24-007, clause 7,
canonical line 3637, printed page 89, byte span `230736:105`. It states that
the same `private-or-sequence` shall not appear more than once in a given
`derived-type-def`.

The reusable StandardIR shapes are R726 (`derived-type-def`) on page 88 and
R729 (`private-or-sequence`) on page 89. R726 contains a zero-or-more repeat
of R729. The retained C743 model observation is not evidence and is not used
to infer the relation.

## Decision

Define the twenty-third bounded M3 delivery contract as a relation over two
explicit typed candidate fields:

```text
private-or-sequence-occurrence:
  none | single | duplicate | unknown

context:
  derived-type-def | other | unknown
```

The deterministic oracle is:

```text
none or single, context=derived-type-def  ACCEPTED
duplicate, context=derived-type-def       REJECTED
otherwise                                 UNRESOLVED
```

The fixture shall include no-occurrence and single-occurrence positive
neighbours, a duplicate negative neighbour, unresolved state/context controls,
and source, page, StandardIR and contract identity mutations. No model output
can promote a semantic fact.

This slice checks only the typed uniqueness relation. It does not parse a
derived-type definition, distinguish the meaning of PRIVATE from SEQUENCE,
validate the R729 alternatives, resolve type names, or claim full C743 or M3
semantics.

## Rejected

* Parsing a derived-type definition to discover repeated PRIVATE or SEQUENCE
  statements. That requires the broader statement and semantic layers.
* Validating the meaning or legality of PRIVATE and SEQUENCE, or their
  interaction with EXTENDS and BIND. Those are separate properties.
* Treating the retained model-origin C743 row as evidence or running another
  model experiment.

## Reversal condition

Write a successor if canonical line 3637, page 89, byte span `230736:105`, or
the R726/R729 StandardIR bindings do not hold, or if an independent replay
cannot distinguish the typed states without parsing, name resolution or
semantic promotion.

## Evidence

* `research/runs/2026-08.jsonl#R000529` and
  `artifacts/reports/M3/m3-core0-next-property-selection-v10.md`.
* `.cache/runs/E0001/R000003/j3-24-007.canonical.txt`, line 3637, and
  `.cache/runs/E0001/R000003/j3-24-007.pages.index`, page 89.
* `.cache/runs/E0171/R000433-provenance-replay/standardir.sx`, rows R726 and
  R729.
* Pinned canonical text SHA-256
  `1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e`, page
  index SHA-256 `49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929`,
  and normative PDF SHA-256
  `7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2`.

<!--
This body is immutable once the status is `accepted`. To change a decision,
write a new record that names this one in its Supersedes, Amends or Retracts
header and says what the old reasoning got wrong. Only the Status line of this
file may then be edited, to point at the successor.

Rewriting the reasoning destroys the thing that makes a reversal condition
checkable later: what was actually believed at the time.
-->
