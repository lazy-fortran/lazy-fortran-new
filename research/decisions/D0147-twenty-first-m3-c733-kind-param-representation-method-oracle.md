# D0147. Twenty-first M3 slice uses C733 logical-literal representation-method states

Date: 2026-08-17
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

Post-C732 reconciliation `R000516` leaves 151 outside-promoted witness rows;
selection replay `R000517` identifies `C733@1` as the first residual row.
The pinned normative occurrence is J3-24-007, clause 7, line 3564, page 87,
byte span `226248:107`. It says that the value of `kind-param` shall specify
a representation method that exists on the processor.

The already represented StandardIR shape is `R725`,
`logical-literal-constant`, on page 87, byte span `226157:90`. It is reusable
grammar evidence; it does not establish processor support. The retained C733
model proposal is not evidence and its page or witness values are not reused.

## Decision

Define the twenty-first bounded M3 delivery contract as a relation over two
explicit typed candidate fields:

```text
kind-param-state:
  processor-supported | processor-unsupported | unknown

context:
  logical-literal-constant | other | unknown
```

The deterministic oracle is:

```text
processor-supported and context=logical-literal-constant  ACCEPTED
processor-unsupported and context=logical-literal-constant REJECTED
otherwise                                                   UNRESOLVED
```

The fixture shall include positive witnesses, an unsupported negative
neighbour, unresolved state/context controls, and source, page, StandardIR,
semantic-item and contract-identity mutations. No model output can promote a
semantic fact. The fixture's resolution remains `disputed`; the bounded result
is an executable oracle, not a promotion of the retained residual row.

This slice checks only the relation over typed states. It does not inspect a
processor, determine whether a kind exists, parse a logical literal, evaluate
a kind expression, resolve names, or claim full C733 or M3 semantics.

## Rejected

* Querying a compiler or processor to establish support. That would make the
  oracle environment-dependent rather than a deterministic relation over the
  typed candidate.
* Inferring `context` or `kind-param-state` from Fortran source. Those facts
  require the broader literal, expression and processor model outside this
  slice.
* Treating the retained model-origin proposal as accepted evidence or running
  another model experiment.
* Binding the contract to page 86 because a model-origin row named page 86.
  C733 is on page 87 in the pinned canonical/page-index evidence.

## Reversal condition

Write a successor if canonical line 3564, page 87, byte span `226248:107`, or
StandardIR R725 does not bind as recorded, or if an independent replay cannot
distinguish the typed states without processor inspection, literal parsing,
context inference or semantic promotion.

## Evidence

* `research/runs/2026-08.jsonl#R000517` and
  `artifacts/reports/M3/m3-core0-next-property-selection-v8.md`.
* `.cache/runs/E0001/R000003/j3-24-007.canonical.txt`, line 3564;
  `.cache/runs/E0001/R000003/j3-24-007.pages.index`, page 87.
* `.cache/runs/E0171/R000433-provenance-replay/standardir.sx`, row R725.
* `artifacts/standards/j3-24-007.toml` and its pinned PDF hash.
