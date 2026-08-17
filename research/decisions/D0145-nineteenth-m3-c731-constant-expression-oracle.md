# D0145. Nineteenth M3 slice uses C731 constant-expression length states

Date: 2026-08-17
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

The post-C726 residual selection replay `R000507` identifies `C731@1` as the
next bounded property. The pinned normative occurrence is J3-24-007, clause 7,
page 85, canonical lines 3469--3470, byte span `219036:167`. It says that the
length specified for a character statement function or for a statement
function dummy argument of type character shall be a constant expression.

The already represented StandardIR shape is `R721`, `char-selector`, on page
84. The source occurrence and the StandardIR occurrence are therefore pinned
separately; the latter is reusable grammar evidence, not a second semantic
source. The retained C731 model proposal is not evidence and its page value is
not reused.

## Decision

Define the nineteenth bounded M3 delivery contract as a relation over two
explicit typed candidate fields:

```text
length_form:
  constant-expression | non-constant-expression | unknown

context:
  character-statement-function
  statement-function-dummy-argument
  other
  unknown
```

The deterministic oracle is:

```text
length_form=constant-expression and context is source-named  ACCEPTED
length_form=non-constant-expression and context is source-named REJECTED
otherwise                                                       UNRESOLVED
```

The fixture covers the complete 3-by-4 typed product: twelve cases, two
positive witnesses, two negative neighbours, and unresolved context/form
controls. The source span, page identity, source rule, StandardIR identity,
semantic-item identity and contract identity each have fail-closed mutation
controls. No model output can promote a semantic fact. The fixture's
`resolution` remains `disputed`; the bounded result is an executable oracle,
not a promotion of the retained residual row.

This slice checks only the relation over typed states. It does not parse
Fortran expressions, decide whether an expression is constant, infer a
statement-function context, resolve names, type-check a procedure, or claim
full C731 or M3 semantics.

## Rejected

* Evaluating or parsing arbitrary Fortran expressions. The
  `constant-expression` and `non-constant-expression` values are supplied
  typed states, not conclusions of a new semantic analyser.
* Inferring either context from source text. That would require the broader
  statement-function and declaration machinery outside this slice.
* Treating the retained model-origin proposal as an accepted fact or running
  another model experiment.
* Binding the contract to page 84 because the reusable R721 StandardIR row is
  on page 84. C731 itself is on page 85 in the pinned page index.

## Reversal condition

Write a successor if canonical lines 3469--3470, page 85, byte span
`219036:167`, or StandardIR R721 do not bind as recorded, or if an independent
replay cannot distinguish the twelve typed states without expression parsing,
context inference or semantic promotion.

## Evidence

* `research/runs/2026-08.jsonl#R000507` and
  `artifacts/reports/M3/m3-core0-next-property-selection-v6.md`.
* `.cache/runs/E0001/R000003/j3-24-007.canonical.txt`, lines 3469--3470;
  `.cache/runs/E0001/R000003/j3-24-007.pages.index`, page 85.
* `.cache/runs/E0171/R000433-provenance-replay/standardir.sx`, row R721.
* `artifacts/standards/j3-24-007.toml` and its pinned PDF hash.
