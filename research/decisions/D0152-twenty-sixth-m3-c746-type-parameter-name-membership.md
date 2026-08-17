# D0152. Twenty-sixth M3 slice uses C746 type-parameter-name membership

Date: 2026-08-17
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

The post-C745 reconciliation leaves 146 residual rows: 84 `disputed` and 62
`unwitnessed`; `C746@1` is first. Its pinned normative occurrence is
J3-24-007, clause 7, canonical lines 3764--3765, printed page 77, UTF-8 byte
span `237401:171`. C746 says that a type-param-name in a type-param-def-stmt
in a derived-type-def shall be one of the type-param-names in that
derived-type-stmt.

The reusable StandardIR shapes are R727 (`derived-type-stmt`), R732
(`type-param-def-stmt`) and R733 (`type-param-decl`). The retained C746 model
row is an unwitnessed input and is not evidence for this relation.

## Decision

Define the twenty-sixth bounded M3 delivery contract as a relation over three
typed candidate fields:

```text
definition-name-presence: absent | present | unknown
declared-name-relation: member | not-member | unknown
context: derived-type-def | other | unknown
```

The deterministic oracle is:

```text
definition name absent, context=derived-type-def          ACCEPTED
definition name present and relation=member,
  context=derived-type-def                                ACCEPTED
definition name present and relation=not-member,
  context=derived-type-def                                REJECTED
otherwise                                                 UNRESOLVED
```

The fixture shall cover the complete 3-by-3-by-3 state product, with vacuous
and satisfied positive witnesses, one negative neighbour, unresolved
controls and source, page, rule, StandardIR and contract-identity mutations.
No model output can promote a semantic fact.

This slice checks only the C746 name-membership obligation. It does not parse
a derived-type definition, compare real identifier spellings, perform
case-folding or name resolution, check C747's exactly-once obligation, or
close full M3.

## Rejected

* Implementing C746 and C747 together. The two constraints are separate
  membership and cardinality properties.
* Parsing a derived-type definition or resolving actual names. The bounded
  contract consumes typed presence and relation fields.
* Treating the retained model-origin C746 row as evidence or running another
  model experiment.

## Reversal condition

Write a successor if canonical lines 3764--3765, page 77, byte span
`237401:171`, or the R727/R732/R733 StandardIR bindings do not hold, or if an
independent replay cannot distinguish the typed states without parsing, model
output or semantic promotion.

## Evidence

* `research/runs/2026-08.jsonl#R000561` and
  `artifacts/reports/M3/m3-core0-next-property-selection-v13.md`.
* `.cache/runs/E0001/R000003/j3-24-007.canonical.txt`, lines 3764--3765, and
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
