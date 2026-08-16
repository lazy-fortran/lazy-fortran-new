# D0117. Treat target correspondence as a relation and keep parser evidence layered

Date: 2026-08-16
Status: accepted
Amends: D0116

## Context

D0116 requires a typed trace through target normalization, but a single
source-to-target mapping would still suggest a one-to-one correspondence that
grammar transformations do not generally provide. Flattening can expose
several target boundary slots, deduplication can suppress an occurrence, and a
target parser format can require a structural adaptation that has no unique
source slot. The trace must therefore describe a witnessed relation, not select
one apparently best destination.

The parser-generator literature also separates concerns that were previously
too easy to collapse in reports. Bison treats counterexamples and automaton
reports as the way to understand a conflict; an equal `%expect` count is not
evidence that the same conflicts remain. Tree-sitter distinguishes lexical
precedence, parse precedence and intentional runtime conflicts. Grammar
convergence compares grammars through explicit transformations and states what
kind of equivalence each transformation establishes.

## Decision

The D0116 correspondence trace is a typed relation with zero or more rows per
source occurrence. Every row identifies one witnessed source-to-target relation
or one explicit non-mapping disposition. The producer must preserve occurrence
identity and transformation event identity, so a consumer can distinguish:

* one source boundary mapped to one target slot;
* one source boundary mapped to several target slots after a generic split or
  flattening operation;
* a source occurrence suppressed by a witnessed deduplication or wrapper
  removal; and
* a source occurrence that is ambiguous or unsupported and therefore blocks any
  target insertion that would require guessing.

The trace is emitted while the existing transformation runs. A final-tree
search, name match, hash match or rule-number heuristic is not a trace. Each
transformation event records its input and output expression identities and
the path relation it establishes. Source-expression identity and target-
expression identity remain distinct.

Each target export additionally has a small, explicit target-policy witness.
It records target-only lexical tokenization, parse precedence, intentional
ambiguity, start-symbol wrapping and required helper lowering separately from
the normative source grammar. A target policy may adapt representation; it may
not invent normative productions or silently discard an unresolved source
relation.

Parser evidence is reported in layers: source fidelity, target well-formedness,
transformation witness, bounded language behavior, parse-structure comparison
when defined, and reference comparison. Conflict reports retain the generator,
profile, state/lookahead, counterexample or non-counterexample diagnostic and
classification. Totals and expected-conflict declarations remain descriptive
only.

## Rejected

* Forcing every source occurrence into exactly one target location.
* Treating a suppressed source occurrence as mapped because its spelling still
  appears in provenance comments.
* Applying target precedence or lexical priority to StandardIR itself.
* Comparing conflict totals without state-level witnesses.
* Treating ANTLR, Bison, tree-sitter, Flang or LFortran output as normative
  input rather than comparison evidence.

## Reversal condition

Write a successor if a validated target formalism proves that a functional
correspondence is sufficient for all supported transformations, or if a
stronger independently checkable relation/forest representation is required to
retain source occurrence identity.

## Evidence

* D0116 and R000429/R000430: raw source boundary mapping and the missing
  source-to-target path contract.
* D0102: layered grammar evidence and transformation witnesses.
* L. Lämmel and V. Zaytsev, “An Introduction to Grammar Convergence,” IFM
  2009, <https://doi.org/10.1007/978-3-642-00255-7_17>.
* GNU Bison Manual, “Generation of Counterexamples,”
  <https://www.gnu.org/software/bison/manual/html_node/Counterexamples.html>.
* GNU Bison Manual, “Language and Grammar,”
  <https://www.gnu.org/software/bison/manual/html_node/Language-and-Grammar.html>.
* Tree-sitter documentation, “The Grammar DSL” and “Writing the Grammar,”
  <https://tree-sitter.github.io/tree-sitter/creating-parsers/2-the-grammar-dsl.html>
  and
  <https://tree-sitter.github.io/tree-sitter/creating-parsers/3-writing-the-grammar.html>.
