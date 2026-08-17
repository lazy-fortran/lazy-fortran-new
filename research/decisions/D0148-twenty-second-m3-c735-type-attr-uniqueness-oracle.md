# D0148. Twenty-second M3 slice uses C735 type-attribute uniqueness states

Date: 2026-08-17
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

Post-C733 reconciliation `R000520` leaves 150 outside-promoted witness rows;
corrected selection replay `R000522` identifies `C735@1` as the first residual
row. The pinned normative occurrence is J3-24-007, clause 7, canonical line
3620, printed page 88, byte span `229534:101`. It states that the same
`type-attr-spec` shall not appear more than once in a given
`derived-type-stmt`.

The reusable StandardIR shapes are R727 (`derived-type-stmt`) and R728
(`type-attr-spec`), both on page 88 in the pinned StandardIR source. The
retained C735 model observation is not evidence and is not used to infer the
relation.

## Decision

Define the twenty-second bounded M3 delivery contract as a relation over two
explicit typed candidate fields:

```text
type-attr-occurrence:
  none | distinct | duplicate | unknown

context:
  derived-type-stmt | other | unknown
```

The deterministic oracle is:

```text
none or distinct, context=derived-type-stmt  ACCEPTED
duplicate, context=derived-type-stmt         REJECTED
otherwise                                    UNRESOLVED
```

The fixture includes no-attribute, one/multiple-distinct-attribute positive
neighbours, a repeated-attribute negative neighbour and unresolved controls.
Source, page, StandardIR, semantic-item and contract identity mutations must
fail closed. No model output can promote a semantic fact.

This slice checks only the typed uniqueness relation. It does not parse a
derived-type statement, resolve attribute names, validate individual
attribute alternatives, perform type checking or claim full C735 or M3
semantics.

## Rejected

* Parsing a derived-type statement to discover whether two attributes are the
  same. That requires the broader lexer, name and statement-semantics layers.
* Validating the meaning or availability of `ABSTRACT`, `BIND`, `EXTENDS` or
  access specifications. Those are separate properties over R728 and its
  referenced shapes.
* Treating the retained model-origin C735 row as accepted evidence or running
  another model experiment.

## Reversal condition

Write a successor if canonical line 3620, page 88, byte span `229534:101`, or
the R727/R728 StandardIR bindings do not hold, or if an independent replay
cannot distinguish the typed states without parsing, name resolution or
semantic promotion.

## Evidence

* `research/runs/2026-08.jsonl#R000522` and
  `artifacts/reports/M3/m3-core0-next-property-selection-v9.md`.
* `research/runs/2026-08.jsonl#R000524` and
  `.cache/runs/E0202/R000001/result.json`.
* `.cache/runs/E0001/R000003/j3-24-007.canonical.txt`, line 3620;
  `.cache/runs/E0001/R000003/j3-24-007.pages.index`, page 88.
* `.cache/runs/E0171/R000433-provenance-replay/standardir.sx`, rows R727 and
  R728.
