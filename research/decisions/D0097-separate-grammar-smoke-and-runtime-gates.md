# D0097. Separate grammar smoke checks from executable runtime gates

Date: 2026-08-15
Status: accepted

## Context

E0164/R000348 showed that ANTLR4, Bison and tree-sitter can accept generated
source files while the production frontend still has no executable parser that
consumes the generated StandardIR grammar. The same run also showed that a
five-row source-backed lexical contract and the generic UTF-8 lexer tests are
useful evidence, but do not establish complete Fortran lexical coverage or
language equivalence. The first adjudicator only checked nonempty provenance
fields; the corrected adjudicator now compares each row with the lexical facts
and the pinned standard artifact hash.

## Decision

Keep these gates distinct and report each one by name:

1. source-contract lineage and artifact-hash verification;
2. target-generator smoke checks and negative controls;
3. source projection coverage, including omitted bodies and declared roots;
4. lexical spelling witnesses and their mutation;
5. production lexer/runtime behavior;
6. bounded and external differential behavior; and
7. executable generated-parser runtime behavior.

The first six may be accepted as narrow evidence when their denominators and
limitations are explicit. They never imply the seventh. E0164 remains open
until a generic generated parser runtime consumes the selected grammar and is
tested on positive and negative behavior, including the retained modern-feature
witnesses. No model or semantic run may use the smoke results as a trusted
complete grammar.

Production parser integration must use the versioned grammar contract and
generic dispatch. Rule-number-specific repairs, copied reference productions,
and hidden source-specific exceptions are not allowed.

## Rejected

* Calling parser-generator acceptance a parser-runtime or language-equivalence
  result.
* Calling a five-row lexical contract the complete Fortran lexer inventory.
* Calling a bounded recognizer or ten-fixture differential matrix a normative
  Fortran oracle.
* Treating a lower Bison conflict count as closure of the runtime gate.

## Evidence

E0164/R000348 and the independent Luna review
`research/experiments/E0164-can-source-backed-lexer-contracts-and-ge/reviews/R000348-luna.md`.

## Reversal condition

Write a successor if an executable generated-parser and independent behavior
gate shows that this separation loses a necessary correctness dependency, or if
the current contract cannot express the source/runtime boundary without
language-specific wiring.
