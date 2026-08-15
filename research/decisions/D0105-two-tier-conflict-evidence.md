# D0105. Separate parser smoke gates from forensic conflict evidence

Date: 2026-08-15
Status: accepted

## Context

The selected `program` replay reached the parser generators only after source
identity, lexical and profile checks, but the replay harness did not request
the producer's transformation witness for each generated format. A separate
transformation replay therefore proved less than the exact four artifacts
being tested. The next tree-sitter failure is a real target diagnostic:
`SAVE` followed by `LETTER` has two possible parser interpretations. A raw
conflict count or one generator's suggested declaration does not say whether
the source grammar is ambiguous, whether the target needs more lookahead, or
whether the lexer/profile contract is wrong.

The parser literature makes these distinctions explicit. Bison's counterexample
facility is a forensic aid and its manual warns that equal `%expect` counts do
not imply equal conflicts. Tree-sitter distinguishes parse precedence from
lexical precedence and permits declared GLR conflicts only for intentional
ambiguity. Grammar convergence likewise requires named transformations and an
explicit statement of what equivalence they establish.

## Decision

The grammar replay has two tiers.

1. The fast artifact gate runs source preflight, generation, exact source
   identity, lexical witnesses, transformation-witness validation and the
   explicit profile contract. The producer must emit one transformation
   witness for every target format. A failure stops before any parser
   generator or behavior oracle.
2. The forensic conflict replay runs only on a green artifact. It retains
   pinned tool versions, Bison state/lookahead/solved reports and counterexample
   groups, plus the complete tree-sitter diagnostic. It normalizes each
   conflict into a machine-readable record containing the target/profile,
   lookahead or token prefix, competing target symbols, source lineages and
   transformation dispositions. Conflict totals are summaries, not the
   denominator of a correctness claim.

Every conflict must be classified before a target rewrite is considered:

* source-preserving ambiguity;
* target parser limitation or insufficient lookahead;
* lexer or profile-contract interaction;
* target lowering artifact; or
* unresolved.

An associativity, precedence, Bison `%expect`, or tree-sitter `conflicts`
declaration is allowed only when a generic source-derived transformation and
an independent bounded behavior/forest witness justify the classification. The
declaration must be generated from that policy; it may not be added because a
particular rule number or one diagnostic happened to fail. The GLR-capable
source export remains the default while classification is open.

## Rejected

* Treating parser-generator acceptance as proof of source fidelity or language
  equivalence.
* Treating a lower conflict count, a matching `%expect` count, or a single
  Tree-sitter suggestion as a resolution.
* Running expensive counterexample generation as an unconditional fast CI
  step.
* Letting a separate witness replay stand in for the witness emitted with the
  exact target artifact.
* Adding a rule-number-specific precedence or conflict exception.

## Reversal condition

Write a successor if an independent target specification or bounded
parse-forest comparison shows that the two-tier protocol loses a necessary
correctness dependency, or if a target offers a stronger machine-checkable
conflict contract that makes the normalized witness record redundant.

## Evidence

* E0171/R000402: source, identity, lexical, profile and nullable lowering gates
  pass, but Tree-sitter reports an unresolved `SAVE`/`LETTER` conflict.
* E0171/R000399: the producer-emitted Bison transformation witness closes the
  source-lineage subgate, but the prior replay did not require witnesses for
  all four formats.
* GNU Bison Manual, “Generation of Counterexamples” and “Output Files”,
  <https://www.gnu.org/software/bison/manual/html_node/Counterexamples.html>
  and
  <https://www.gnu.org/software/bison/manual/html_node/Output-Files.html>.
* Tree-sitter, “The Grammar DSL” and “Writing the Grammar”,
  <https://tree-sitter.github.io/tree-sitter/creating-parsers/2-the-grammar-dsl.html>
  and
  <https://tree-sitter.github.io/tree-sitter/creating-parsers/3-writing-the-grammar.html>.
* R. Lämmel and V. Zaytsev, “An Introduction to Grammar Convergence”,
  <https://doi.org/10.1007/978-3-642-00255-7_17>.
