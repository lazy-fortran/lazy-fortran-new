# D0150. Twenty-fourth M3 slice uses C744 END TYPE name relation

Date: 2026-08-17
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

<!-- Optional headers, one per line, when they apply:
Supersedes: D####
Amends: D####
Retracts: D####
-->

## Context

The post-C743 reconciliation R000534 leaves 148 outside-promoted witness rows;
`C744@1` is first. Its pinned normative occurrence is J3-24-007, clause 7,
canonical lines 3639--3640, printed page 89, byte span `230888:137`. It
requires an END TYPE name, when present, to be the same as the name in the
corresponding derived-type-stmt.

The reusable StandardIR shapes are R727 (`derived-type-stmt`) on page 88 and
R730 (`end-type-stmt`) on page 89. The retained C744 model observation is not
evidence and is not used to define the relation.

## Decision

Define the twenty-fourth bounded M3 delivery contract as a relation over three
typed candidate fields:

```text
end-type-name-presence: absent | present | unknown
name-relation: same | different | unknown
context: derived-type-def | other | unknown
```

The deterministic oracle is:

```text
absent, context=derived-type-def                  ACCEPTED
present and same, context=derived-type-def        ACCEPTED
present and different, context=derived-type-def   REJECTED
otherwise                                         UNRESOLVED
```

The fixture shall cover the complete 3-by-3-by-3 state product, with the two
positive neighbours, one negative neighbour, unresolved controls and source,
page, rule, StandardIR and contract-identity mutations. No model output can
promote a semantic fact.

This slice checks only the typed END TYPE name relation. It does not parse
derived-type definitions, compare real identifier spellings, perform
case-folding or name resolution, match construct nesting, or claim full C744
or M3 semantics.

## Rejected

* Parsing a derived-type definition and matching its opening and closing
  statements. That requires the broader statement and semantic layers.
* Defining identifier equality, case folding, construct nesting or diagnostic
  behavior. Those are separate properties from the source relation.
* Treating the retained model-origin C744 row as evidence or running another
  model experiment.

## Reversal condition

Write a successor if canonical lines 3639--3640, page 89, byte span
`230888:137`, or the R727/R730 StandardIR bindings do not hold, or if an
independent replay cannot distinguish the typed states without parsing,
name resolution or semantic promotion.

## Evidence

* `research/runs/2026-08.jsonl#R000534` and
  `artifacts/reports/M3/m3-core0-next-property-selection-v11.md`.
* `.cache/runs/E0001/R000003/j3-24-007.canonical.txt`, lines 3639--3640, and
  `.cache/runs/E0001/R000003/j3-24-007.pages.index`, page 89.
* `.cache/runs/E0171/R000433-provenance-replay/standardir.sx`, rows R727 and
  R730.
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
