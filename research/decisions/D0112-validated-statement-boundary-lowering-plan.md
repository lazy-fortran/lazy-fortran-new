# D0112. Validate statement-boundary lowering before target insertion

Date: 2026-08-16
Status: accepted

## Context

R000423 proves that the source-derived statement-sequence witness is reproduced
by `standard-new`, and R000426 independently establishes the expected source
behavior. The next production boundary is where a parser target consumes those
sites. Inserting a separator while walking a target grammar would hide source
applicability, expression paths and rejected cases in target-specific code.

The parser-generator guidance points to the same separation. Bison treats
conflict counts as a regression guard only after each conflict and its
counterexample has been inspected. Tree-sitter separates lexical precedence,
parse precedence and intentional GLR conflicts. Grammar-convergence work treats
transformations as named steps whose evidence is retained rather than as
unrecorded edits.

## Decision

Introduce a typed, source-backed statement-boundary lowering plan between the
StandardIR sequence witness and target grammar insertion. The plan is not a
new normative StandardIR production. It records, for each accepted site:

* source rule and left-hand side;
* canonical expression path and item derivation;
* candidate kind and separator contract;
* complete source lineage and source hash; and
* the target insertion disposition.

The plan validator must reject malformed paths, duplicate sites, missing or
conflicting lineage, unsupported candidate shapes and mismatched source
contracts. It must preserve rejected dispositions with their reason and
provenance. Target lowering consumes only an accepted plan and derives the
target separator representation from the plan; it may not test `-stmt`, name a
Fortran rule, use a rule-number exception, or append EOS to every nested
statement reference.

The plan is applied before target-specific factoring or precedence decisions.
Each target export carries the plan disposition in its transformation witness.
If a target cannot represent an accepted site without an unproven rewrite, the
export fails the deterministic gate rather than silently dropping or guessing.

## Rejected

* Mutating target output from a raw candidate TSV without typed validation.
* Repeating the source suffix test in each target exporter.
* Appending a separator to every nonterminal whose name ends in `-stmt`.
* Treating a Bison or Tree-sitter conflict count as proof that insertion is
  correct.
* Adding precedence, `%expect` or GLR declarations before the boundary plan
  and a bounded behavior witness agree.

## Reversal condition

Write a successor if a source-backed parse-forest or target behavior witness
shows that the plan loses a necessary insertion context, or if all selected
targets can consume a stronger shared contract without retaining the plan's
per-site provenance and rejected dispositions.

## Evidence

* E0171/R000423: exact production parity for 95 source-derived sites.
* E0171/R000426: all nine source behavior cases agree across GNU Fortran,
  Flang and LFortran.
* GNU Bison Manual, “Expect Decl”, “Generation of Counterexamples” and
  “Output Files”,
  <https://www.gnu.org/software/bison/manual/html_node/Expect-Decl.html>,
  <https://www.gnu.org/software/bison/manual/html_node/Counterexamples.html>
  and <https://www.gnu.org/software/bison/manual/html_node/Output-Files.html>.
* Tree-sitter, “The Grammar DSL” and “Writing the Grammar”,
  <https://tree-sitter.github.io/tree-sitter/creating-parsers/2-the-grammar-dsl.html>
  and <https://tree-sitter.github.io/tree-sitter/creating-parsers/3-writing-the-grammar.html>.
* Lämmel and Zaytsev, “An Introduction to Grammar Convergence”,
  <https://doi.org/10.1007/978-3-642-00255-7_17>.
