# D0103. Make grammar profile entry and EOF policies explicit

Date: 2026-08-15
Status: accepted

## Context

The selected generated profile was labelled `program`, but the generated
targets did not express one common entry contract. Bison had a start wrapper;
ANTLR4 exposed the first ordinary rule as the practical entry point; and
tree-sitter's first rule was a lexical rule. Generator acceptance therefore
did not prove that a target recognized one complete input from the declared
root. This is exactly the kind of target-default dependency that grammar
engineering should make explicit before comparing behavior.

## Decision

Every generated grammar profile has a checked-in profile policy naming its
source root, target root, entry rule, target-specific EOF policy and artifact.
The producer emits a target comment carrying the same fields. The entry rule
is generated from the selected-root option, never from a Fortran rule number.

For the selected `program` profile, the four targets use these policies:

- EBNF: explicit wrapper from the entry rule to `program`;
- ANTLR4: explicit entry rule consuming `EOF`;
- Bison: explicit `%start` wrapper; Bison's parser acceptance after the start
  reduction supplies EOF handling;
- tree-sitter: the explicit entry wrapper is the first rule, with tree-sitter's
  full-input parse behavior recorded rather than pretending it has an ANTLR
  `EOF` token.

An independent validator checks the producer output and the normalized lexer
contract before parser generators or behavioral comparisons run. A target may
use a different spelling or internal lowering, but it must satisfy the policy
and record its semantics. All-root output remains a separate profile and must
not be silently turned into a selected-root parser by an audit script.

## Rejected

- Relying on the first emitted rule as a start symbol. It makes source order an
  accidental API and already selected a lexical rule for tree-sitter.
- Treating parser-generator acceptance as proof of EOF consumption or root
  correctness.
- Adding one Fortran-specific wrapper for `program`. The wrapper is a generic
  projection of any selected root.
- Rewriting a generated artifact in the laboratory to repair its entry point.

## Reversal condition

Supersede this decision if a target's authoritative grammar interface proves a
stronger, independently checkable entry/EOF contract that makes an emitted
wrapper redundant, or if the policy cannot represent a future target without
losing source-root and full-input semantics.

## Evidence

- E0171/R000399: complete producer-emitted transformation witness, but root/EOF
  policy remained open.
- Current generated E0164/R000385: ANTLR4 has no explicit EOF entry wrapper;
  tree-sitter's first rule is `r_letter`; Bison has `standardir_start`.
- GNU Bison Manual, “Output Files” and “Generation of Counterexamples”,
  <https://www.gnu.org/software/bison/manual/html_node/Output-Files.html> and
  <https://www.gnu.org/software/bison/manual/html_node/Counterexamples.html>.
- Tree-sitter documentation, “The Grammar DSL” and “Writing the Grammar”,
  <https://tree-sitter.github.io/tree-sitter/creating-parsers/2-the-grammar-dsl.html>
  and
  <https://tree-sitter.github.io/tree-sitter/creating-parsers/3-writing-the-grammar.html>.
- L. Lämmel and V. Zaytsev, “An Introduction to Grammar Convergence,” IFM
  2009, <https://doi.org/10.1007/978-3-642-00255-7_17>.
