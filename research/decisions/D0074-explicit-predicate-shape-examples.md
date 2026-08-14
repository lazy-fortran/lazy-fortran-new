# D0074 — Show typed predicate shapes explicitly in the model prompt

Date: 2026-08-14
Status: accepted

## Context

The E0123 predecessor diagnosis retained 53 residual rows. Besides transport
errors, the gate saw repeated structural mistakes: binary value operators
applied to two fact names and non-predicate terms supplied to `and`, `not` or
`implies`. E0116 already describes these rules in prose, but the failures show
that a prose-only description is not a reliable interface for a small typed
JSON language.

## Decision

Future semantic proposal prompts shall include a small, generic set of valid
and invalid constructor-shape examples alongside the existing prose. The
examples shall cover nested boolean predicates, value-versus-literal
comparisons, field identity with `same-as`, and source-backed `relation`.
They are explanatory prompt material only: the allowed constructors,
validator, source gate, evidence rules and promotion gate remain unchanged.

The examples must not mention individual constraint IDs, add an operator,
invent a fact, or encode a Fortran-specific semantic alias. E0123 retains its
original prompt and immutable commit pin; this decision applies to a successor
experiment.

## Rejected

- Relaxing the deterministic validator to accept malformed nesting: this would
  lower the evidence quality and conceal model errors.
- Adding one prompt branch per gate message or constraint: this would turn the
  protocol into corpus-specific special casing.
- Giving the model executable expressions or unrestricted schema prose:
  neither provides a bounded typed proposal.

## Reversal condition

Write a successor if a controlled successor using the examples fails to reduce
structural gate errors without reducing source/evidence validity, or if the
examples cause accepted-control regressions. Report the complete denominator
and failure classes before reversing the choice.
