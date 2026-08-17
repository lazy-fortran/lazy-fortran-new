# D0144. Eighteenth M3 slice uses C726 type-param-value star-context legality

Date: 2026-08-17
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

Post-C724 selection replay `R000497` identifies C726@1 as the first residual
row. C726 states that a `type-param-value` of `*` shall be used only in five
source-named contexts. Its source occurrence begins on canonical line 3453,
continues through lines 3453--3457 and 3460--3461, and crosses the pinned
page-84/page-85 boundary. The retained model proposal records only the
partial span 217828:422, which ends before line 3461; this contract uses the
complete cited source text through the content of line 3461, span 217828:518.
The already represented grammar shapes are
StandardIR R721 `char-selector`, R722 `length-selector` and R723 `char-length`.

The previous C729 decision correctly rejected selecting C726 as a context
predicate that inferred declaration or allocation context. This slice uses a
different boundary: context is an explicit typed candidate input. No parser,
declaration analysis or context inference is added.

## Decision

Define the eighteenth bounded M3 delivery contract as a C726 star-context
legality oracle. Its candidate carries:

```text
type_param_value:
  star | explicit | unknown

context:
  dummy-argument
  named-constant
  allocate-assumed-length-character
  type-guard
  external-function-character-result
  other
  unknown
```

The first five context states are the exact source-named permitted contexts.
`explicit` means a known value form other than `*`; it is outside C726's
restriction. `other` is a known context not in the source-named set.

The deterministic oracle is:

```text
type_param_value=explicit                         ACCEPTED
type_param_value=star and context in allowed set  ACCEPTED
type_param_value=star and context=other           REJECTED
type_param_value=star and context=unknown         UNRESOLVED
type_param_value=unknown and context in allowed set ACCEPTED
otherwise                                          UNRESOLVED
```

The fixture covers the complete 3-by-7 typed product: 21 cases, including
allowed positive witnesses, a star/other negative neighbour, and unknown
controls. Source, page-boundary, StandardIR-row, semantic-item, source-rule
and contract-identity mutations must fail closed. No model output can promote
a semantic fact.

The exact source binding is J3-24-007 C726, clause 7, canonical byte span
217828:518 through the content of line 3461, canonical lines 3453--3457 and
3460--3461, pages 84--85, with
StandardIR R721/R722/R723. The normative PDF, canonical text, page index and
StandardIR source remain pinned to the existing hashes.

This slice checks only the relation over explicitly typed value-form and
context states. It does not parse Fortran, identify declaration or allocation
contexts, evaluate type parameters, resolve names, inspect procedure results,
or claim full C726 or M3 semantics.

## Rejected

* Inferring the context state from source text. That would require the broader
  declaration, allocation, type-guard and procedure context machinery that
  this bounded slice explicitly excludes.
* Treating every non-`*` value as a parsed or semantically valid Fortran
  expression. `explicit` is only a typed input state for this restriction.
* Splitting C726 into separate declaration, allocation and function analyses.
  The source-named contexts remain one finite candidate state set.
* Resuming E0172, running another model experiment or promoting the retained
  model-origin proposal.

## Reversal condition

Write a successor if canonical lines 3453--3457 and 3460--3461, the page
boundary, or StandardIR R721/R722/R723 do not bind to C726, or if an
independent replay cannot distinguish the 21 typed states without parsing,
context inference or processor facts.

## Evidence

* `research/runs/2026-08.jsonl#R000497` and
  `artifacts/reports/M3/m3-core0-next-property-selection-v5.md`.
* `.cache/runs/E0001/R000003/j3-24-007.canonical.txt`, lines 3453--3457 and
  3460--3461; `.cache/runs/E0001/R000003/j3-24-007.pages.index`, pages 84--85.
* `.cache/runs/E0171/R000433-provenance-replay/standardir.sx`, rows R721,
  R722 and R723.
* `artifacts/standards/j3-24-007.toml` and its pinned PDF hash.
