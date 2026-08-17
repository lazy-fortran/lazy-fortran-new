# D0151. Twenty-fifth M3 slice uses C745 SEQUENCE component-presence relation

Date: 2026-08-17
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

<!-- Optional headers, one per line, when they apply:
Supersedes: D####
Amends: D####
Retracts: D####
-->

## Context

The post-C744 reconciliation leaves 147 outside-promoted witness rows; C745@1
is first. Its pinned normative occurrence is J3-24-007, clause 7, canonical
lines 3665--3667, printed page 89, byte span `232141:276`. The first C745
obligation says that when SEQUENCE appears, the type has at least one
component.

The reusable StandardIR shapes are R726 (`derived-type-def`), R731
(`sequence-stmt`) and R735 (`component-part`). The retained C745 model row is
unwitnessed input, not evidence and not a source for the relation.

## Decision

Define the twenty-fifth bounded M3 delivery contract as a relation over three
typed candidate fields:

```text
sequence-presence: absent | present | unknown
component-presence: zero | one-or-more | unknown
context: derived-type-def | other | unknown
```

The deterministic oracle is:

```text
sequence absent, context=derived-type-def                    ACCEPTED
sequence present and component one-or-more, context=derived-type-def
                                                              ACCEPTED
sequence present and component zero, context=derived-type-def
                                                              REJECTED
otherwise                                                     UNRESOLVED
```

The fixture shall cover the complete 3-by-3-by-3 state product, with positive
vacuous and satisfied witnesses, one negative neighbour, unresolved controls
and source, page, StandardIR and contract-identity mutations. No model output
can promote a semantic fact.

This slice checks only the first C745 component-presence obligation. It does
not check the remaining requirements about data-component type, type
parameters or type-bound procedures.

## Rejected

* Implementing all four C745 obligations in one contract. That would mix
  independent semantic properties and require additional represented shapes.
* Parsing a derived-type definition to count components or determine their
  types. The bounded contract only consumes typed presence fields.
* Treating the retained model-origin C745 row as evidence or running another
  model experiment.

## Reversal condition

Write a successor if canonical lines 3665--3667, page 89, byte span
`232141:276`, or the R726/R731/R735 StandardIR bindings do not hold, or if an
independent replay cannot distinguish the typed states without parsing,
model output or semantic promotion.

## Evidence

* `research/runs/2026-08.jsonl#R000540` and the post-C744 partition command in
  `TASK_POOL.yaml`.
* `.cache/runs/E0001/R000003/j3-24-007.canonical.txt`, lines 3665--3667, and
  `.cache/runs/E0001/R000003/j3-24-007.pages.index`, page 89.
* `.cache/runs/E0171/R000433-provenance-replay/standardir.sx`, rows R726, R731
  and R735.
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
