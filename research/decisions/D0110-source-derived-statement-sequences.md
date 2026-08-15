# D0110. Derive statement separators at sequence boundaries

Date: 2026-08-16
Status: superseded by D0111

## Context

The v2 lexical-layout contract records that statement classes ending in
`-stmt` follow the source-form statement rules. That fact is necessary but not
sufficient to lower the grammar. Appending an end-of-statement token to every
`-stmt` nonterminal is wrong: the standard grammar nests `action-stmt` inside
constructs such as `if-stmt`, where the enclosing statement owns the source
boundary. The `SAVE`/`LETTER` conflict exposed this distinction.

The pinned LFortran parser provides a useful independent design comparison. Its
lexer emits newline/comment separator tokens and its generic `statement` rule
consumes a separator around a complete statement. Bison's counterexample
guidance and Tree-sitter's lexical/parse precedence model likewise require the
boundary and token policy to be explicit before a conflict declaration can be
trusted. These references inform the design; no production is copied into
StandardIR.

## Decision

Keep the normative StandardIR syntax unchanged. Derive a separate,
source-backed statement-sequence witness from:

1. the v2 source facts for statement applicability and termination;
2. the StandardIR expression graph; and
3. a fixed-point structural analysis that identifies repeated or
   first-item-plus-repeated contexts whose item can derive a statement class.

The target lowering may introduce separator terminals only at those witnessed
sequence boundaries. A nested statement reference is not a boundary merely
because its name ends in `-stmt`. The witness must retain the containing
nonterminal, expression path, item class, source facts and derivation evidence.

The first implementation is a deterministic candidate inventory, not a
conflict policy. A target may consume it only after an independent positive and
negative source-behavior witness shows that separators reject statement
concatenation while preserving nested and continued statements. EOF handling,
semicolon handling, comments, fixed-form records and free-form continuation
remain explicit lexer/runtime behavior, not hidden in the inventory.

## Rejected

* Appending EOS to every `-stmt` production.
* Copying LFortran's `statement` or separator productions into StandardIR.
* Resolving `SAVE`/`LETTER` with `%expect`, Tree-sitter conflict declarations,
  precedence, or a rule-number exception before boundary behavior is witnessed.
* Inferring statement sequences from a reference grammar's hand-factored names.

## Reversal condition

Write a successor if the source standard supplies an explicit application
relation that is more precise than the structural witness, or if an
independent behavior/forest witness demonstrates that the fixed-point relation
adds or omits a boundary for a valid source-form case.

## Evidence

* E0171/R000407 and R000411: source-backed statement termination and
  applicability facts from J3/24-007 clauses 4.1.4, 5.5.2 and 6.3.2.
* E0171/R000404 and R000406: the unresolved `SAVE`/`LETTER` conflict and its
  normalized evidence.
* The pinned LFortran parser/tokenizer read recorded in
  `docs/provenance.md` on 2026-08-16.
* Bison, “Generation of Counterexamples,”
  <https://www.gnu.org/software/bison/manual/html_node/Counterexamples.html>.
* Tree-sitter grammar DSL and conflict documentation,
  <https://tree-sitter.github.io/tree-sitter/creating-parsers/2-the-grammar-dsl.html>.
* Lämmel and Zaytsev, “An Introduction to Grammar Convergence,”
  <https://doi.org/10.1007/978-3-642-00255-7_17>, for preserving named
  transformations rather than hiding them in target-specific edits.
