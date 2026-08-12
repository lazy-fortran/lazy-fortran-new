# E0054. D0027 lexical projection candidates

## Question

Can deterministic lexical projection candidates expose the D0027 tradeoff
without selecting one?

## Method

The analysis command reruns E0053 and reconstructs its five-term lexical and
ambiguous-Unicode residue. It generates a 15-row comparison matrix for three
strategies: generated lexer classes for the accepted lexical facts, a
target-independent lexical-fact schema, and retaining all five terms
unresolved. Each row retains the source fact and provenance state.

## Result

All three candidates preserve the five source facts. The primitive-lexer and
schema-lexical candidates project the three lexical classes and retain the two
ambiguous Unicode or quotation forms under D0020. The unresolved candidate
projects none of the five terms. No candidate produces a complete parser
input, and selection remains deferred to D0027. The controlled candidate-label
mutation fails as expected. No model calls were made.

## Boundary

E0054 supplies the missing D0027 tradeoff table. It does not choose a lexer
representation or modify StandardIR. The planning model can now compare
D0027 alongside the D0024/D0026 expansion matrix before the wiring generator
is applied.
