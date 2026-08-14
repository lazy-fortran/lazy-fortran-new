# D0062 — Make typed semantic proposals value-directed and witness-gated

Status: amended by D0063
Date: 2026-08-14
Amends: D0061

## Context

The first E0116 C702 smoke accepted a JSON-shaped predicate that compared two
fact-like names. It was syntactically valid but vacuous as a value relation.
The same review found that the broad constructor list did not validate the 21
existing accepted controls, and a cross-page rule lookup could escape the tool
boundary and abort a run. Schema acceptance alone therefore did not provide a
credible semantic result.

## Decision

Keep the Qwen proposal protocol, but make its typed boundary explicit:

- binary value relations put a value field first and a literal second;
  field-to-field identity uses `same-as`;
- the schema includes the existing source-backed domain constructors and parses
  numeric/list S-expressions canonically for exact controls;
- source-span/page errors are typed tool rejections, never runner crashes;
- the generic source form `shall not ... except ...` is normalized through an
  implication shape, and a separate deterministic witness stage derives the
  corresponding predicate for that repeated form and runs positive, negative
  and neutral cases;
- only predicates that pass that independent witness are promoted. Other
  schema-accepted rows remain explicitly unwitnessed or disputed.

The implementation contains no constraint-specific branch. The source form,
predicate shape and witness cases are generic. E0116 remains a complete ledger
experiment: every occurrence receives a terminal result and every unproven
proposal remains in the denominator.

## Rejected

- Treat schema validity as semantic validation.
- Let the model compare arbitrary fact-like names and infer their value types.
- Add a hand-written C702 checker or a separate branch for each failed rule.
- Promote every accepted proposal before an independent witness exists.
- Abort the campaign when a bounded source span crosses a page boundary.

## Reversal condition

Amend this decision if the value/literal rule rejects valid recurring standard
forms, if the generic exception normalizer requires more implementation than
the repeated source form it covers, or if an independent witness accepts a
mutated predicate or disagrees with the pinned source-derived predicate.
