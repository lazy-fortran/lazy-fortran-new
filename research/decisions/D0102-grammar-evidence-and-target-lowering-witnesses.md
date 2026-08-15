# D0102. Separate grammar evidence levels and witness every target lowering

Date: 2026-08-15
Status: accepted

## Context

The current four-format inventory is useful, but its earlier wording could be
read as a parser-quality or language-equivalence result. Canonical head counts,
source-lineage equality and successful parser-generator invocation do not show
that two grammars accept the same token language, produce equivalent trees, or
handle the same lexer contract. The current Bison conflict inventory also
compares diagnostics, not correctness. A second problem is that target
lowerings introduce helper productions without one uniform transformation
witness, so their structural differences cannot yet be audited mechanically.

This distinction is standard practice in grammar comparison. Grammar
convergence compares independently produced grammars through explicit
transformations and records what equivalence those transformations establish;
it does not infer equivalence from names. Bison's counterexample facility is a
diagnostic for understanding conflicts, while its `%expect` declarations are
not a proof that the expected conflicts are harmless. Tree-sitter separately
distinguishes lexical precedence, parse precedence and intentional GLR
conflicts. Earley and GLL provide independent recognizer models for bounded
language checks, but do not make arbitrary grammar equivalence decidable.

## Decision

Every grammar comparison and target-lowering experiment reports these evidence
levels separately:

1. **source fidelity**: PDF/source spans, raw RHS identity, duplicate
   occurrences, token/ref classification and source hashes;
2. **projection well-formedness**: target syntax, declared roots, references,
   generator acceptance and target-specific token contracts;
3. **transformation witness**: every generated helper records its source
   alternative IDs, transformation kind, input expression hashes, output hash,
   profile and omission disposition;
4. **bounded language behavior**: an independent recognizer and explicit
   positive/negative corpus compare acceptance, EOF consumption and diagnostic
   class for the same declared root and lexer profile;
5. **parse structure**: normalized trees or shared forests are compared only
   when both targets expose a defined comparable structure;
6. **reference comparison**: external grammars and compilers are retained as
   structural, behavioral or implementation-policy evidence, with every
   reference-only item classified. They are never treated as normative input.

Head inventories and conflict totals are therefore descriptive metrics, never
pass criteria for language equivalence. Conflict analysis must retain Bison
state reports and counterexamples (`-Wcounterexamples` during analysis),
classify each conflict as preserved ambiguity, target-resolved ambiguity,
lexer/contract interaction, or unresolved, and keep `%expect` out of generated
exports until an independent behavior gate justifies a policy.

Each export gets an explicit profile manifest naming its root, EOF policy,
lexer/token contract, transformation map and omissions. A reference tokenizer
is compared through a normalized event contract only on the shared profile;
extensions, trivia and implementation tokens are classified rather than
forced into false token equality.

The canonical comparison question is consequently:

> Does this source-backed projection preserve the declared profile's bounded
> language and provenance under a witnessed, generic transformation?

“Matches LFortran” is not an accepted result category. A result may instead
identify a genuine StandardIR advantage, a target-engineering advantage, a
profile difference, a reference extension, or an unresolved discrepancy.

## Rejected

* Treating equal canonical nonterminal-head sets as language equivalence.
* Using a pinned reference grammar's productions, token names, precedence or
  actions as StandardIR input.
* Rewriting a generated grammar's `%start` line in an audit script to create a
  different parser profile. The producer must emit the requested profile.
* Comparing raw token inventories across different lexer ABIs as if they were
  the same contract.
* Promoting a lower conflict count, a Bison `%expect` match, or parser-generator
  acceptance without an independent positive/negative language witness.
* Calling a grammar “perfect” when only structural and bounded behavioral
  evidence has been established.

## Reversal condition

Write a successor if a stronger independently checkable proof or bounded
language/forest comparison shows that one of these evidence levels is
unnecessary for a specific target transformation, or if a source-derived
target formalism makes the current transformation-witness contract
insufficient. A new target profile, lexer ABI or semantic action contract is a
separate decision.

## Evidence

* E0171/R000387: current structural inventory; explicitly not language
  equivalence.
* E0157/R000396: explicit hashed reference-feature-anchor input and
  per-anchor MATCH/NO_ANCHOR_DECLARED report; comparison labels remain
  structural evidence only.
* E0159/R000368: state-header conflict inventory and pinned LFortran policy;
  resolution not attempted.
* E0161/R000340: bounded positive/negative language gate for an opt-in target
  projection.
* L. Lämmel and V. Zaytsev, “An Introduction to Grammar Convergence,” IFM
  2009, <https://doi.org/10.1007/978-3-642-00255-7_17>.
* GNU Bison Manual, “Generation of Counterexamples,”
  <https://www.gnu.org/software/bison/manual/html_node/Counterexamples.html>.
* Tree-sitter documentation, “The Grammar DSL” and “Writing the Grammar,”
  <https://tree-sitter.github.io/tree-sitter/creating-parsers/2-the-grammar-dsl.html>
  and
  <https://tree-sitter.github.io/tree-sitter/creating-parsers/3-writing-the-grammar.html>.
* J. Earley, “An Efficient Context-Free Parsing Algorithm,”
  <https://doi.org/10.1145/362007.362035>.
* E. Scott and A. Johnstone, “GLL parse-tree generation,”
  <https://doi.org/10.1016/j.scico.2012.03.005>.
