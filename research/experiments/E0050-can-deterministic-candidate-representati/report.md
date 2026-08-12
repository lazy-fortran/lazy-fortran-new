# E0050. Pending representation candidate comparison

## Question

Can deterministic candidate representations expose the D0024 and D0026
tradeoff without accepting one?

## Method

The analysis command reruns E0049, verifies the normalized-resolution,
overlap, and expansion-inventory hashes, and reconstructs the 80/20 family
denominator. It emits a nine-row comparison matrix for the three overlap terms
under three explicitly named strategies:

1. R402 alias precedence;
2. R403 expansion precedence; and
3. unresolved compositional facts.

The matrix is evidence for the pending decision only. It is not a parser
projection and does not modify StandardIR.

## Result

The command passed without selecting a strategy. All three candidates cover
the three overlap terms. Alias precedence is the only parser-ready candidate,
but it loses all three R403 scalar facts. Expansion precedence and unresolved
composite facts retain both relationships for all three terms, but neither is
accepted as the project representation. The complete family denominator is 80
R401 and 20 R403 terms. The independent difference is zero and the mutation
negative control fails as expected.

## Boundary

E0050 supplies a compact tradeoff table for the planning model. It does not
accept D0024 or D0026, generate a complete parser input, or claim that an
unresolved composite is a runtime representation. The next decision must state
how both source facts and their provenance are carried into parser and semantic
schemas.
