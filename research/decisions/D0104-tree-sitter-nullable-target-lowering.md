# D0104. Eliminate nullable non-start rules in the tree-sitter target

Date: 2026-08-15
Status: accepted

## Context

The source grammar legitimately contains nullable nonterminals. The first
selected-root replay passes the source, identity, lexical and explicit
entry/EOF gates, and ANTLR4 and Bison accept their projections. Tree-sitter
0.26.9 rejects the target because a non-start rule, `r_block`, matches the
empty string. This is a target-language restriction, not evidence that the
source production is wrong.

## Decision

The tree-sitter projection performs a generic nullable analysis over the
normalized grammar and eliminates empty-matching non-start rules by
propagating their nullable alternatives into referring expressions. The
transformation is deterministic, source-independent and bounded. Every
propagated, transformed or omitted source alternative remains in the
transformation witness with input/output hashes and a target disposition.

The selected entry wrapper remains the first tree-sitter rule and may be
nullable only when the selected source root itself is nullable. If a target
case cannot be represented without unbounded expansion or source loss, the
producer fails closed with a machine-readable disposition; it does not add a
rule-number exception, silently delete a production or weaken the oracle.

All-root and selected-root profiles retain separate reachability and target
policies. Tree-sitter-specific nullable lowering is not copied into StandardIR
or the ANTLR4/Bison/EBNF projections.

## Rejected

- Renaming or deleting `r_block` because it is the first observed failure.
- Making every nullable rule the tree-sitter start rule.
- Replacing nullable rules with a synthetic token or an arbitrary sentinel.
- Declaring the tree-sitter generator failure harmless because the other two
  generators accept the output.
- Copying a hand-factored nullable solution from a reference grammar.

## Reversal condition

Supersede this decision if tree-sitter gains a stable target facility that
represents nullable non-start rules with equivalent parse behavior, or if an
independent bounded forest comparison shows that a different generic lowering
preserves the declared profile with less expansion and complete provenance.

## Evidence

- E0171/R000401: source and profile gates pass; tree-sitter 0.26.9 rejects
  nullable non-start `r_block`.
- Tree-sitter, “The Grammar DSL” and “Writing the Grammar,”
  <https://tree-sitter.github.io/tree-sitter/creating-parsers/2-the-grammar-dsl.html>
  and
  <https://tree-sitter.github.io/tree-sitter/creating-parsers/3-writing-the-grammar.html>.
- L. Lämmel and V. Zaytsev, “An Introduction to Grammar Convergence,” IFM
  2009, <https://doi.org/10.1007/978-3-642-00255-7_17>.
- D0102: target lowering must be witnessed and language claims separated from
  generator acceptance.
