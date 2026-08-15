# D0107. Use a companion source-backed lexer-layout contract

Date: 2026-08-15
Status: accepted

## Context

E0171/R000404 and the normalized conflict inventory expose a missing input,
not a justified Tree-sitter exception. The current lexer contract describes
token spellings and Unicode classes, but not statement termination,
continuation, or the fact that statement keywords are not reserved names.
The J3/24-007 anchors in E0171/R000407 provide those facts from the normative
source. A production consumer needs a pinned interface for them before the
`SAVE` / `LETTER` conflict can be classified.

## Decision

Add `contracts/lexical-layout-v0.sxs` as a companion, target-neutral contract
to the existing lexical-token contract. Its records represent source-backed
statement-boundary, continuation-signal and keyword-name-policy facts, each
with source provenance and an origin label. The contract is an input to the
target lexer projection; it is not a new StandardIR grammar production and it
does not encode parser-generator conflict policy.

The initial production slice must consume the exact `lexical-layout-v0`
revision without inventing facts not present in the pinned source anchors.
Positive and negative behavior witnesses must cover the contract before any
Tree-sitter conflict declaration, precedence, associativity or Bison `%expect`
is considered.

## Rejected

* Adding an `EOS` production to StandardIR for the convenience of one parser
  target.
* Encoding layout facts as free-form prose or parser-generator actions.
* Copying lexer behavior from LFortran, Flang or a reference grammar into the
  contract.
* Treating the existing lexical-token contract as implicitly complete.

## Reversal condition

Write a successor if a source-backed, target-independent lexer contract already
represents these facts without a revision, or if independent behavior
witnesses show that no parser-visible layout fact is needed to distinguish the
conflicting cases.

## Evidence

* E0171/R000407: J3/24-007 clauses 4.1.4, 5.5.2 and 6.3.2.5 establish
  statement termination and non-reserved statement-keyword behavior.
* D0106: statement boundaries belong in the target lexer contract, not in
  normative StandardIR syntax.
* GNU Bison, “Generation of Counterexamples,”
  <https://www.gnu.org/software/bison/manual/html_node/Counterexamples.html>.
* Tree-sitter, “Writing the Grammar,”
  <https://tree-sitter.github.io/tree-sitter/creating-parsers/3-writing-the-grammar.html>.
