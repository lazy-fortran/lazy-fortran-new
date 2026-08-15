# D0096. Capture raw source witnesses before target normalization

Date: 2026-08-15
Status: accepted

## Context

E0154/R000311 reran the four generated grammar formats after D0095's typed
source/target identity repair. The standalone UTF-8 regression passed, but the
real closure pipeline still computed several `source-expression-sha256`
values after lexical canonicalization. The independent witness therefore
rejected the en dash and right-quote alternatives. Six source alternatives
also disappeared into generated helpers, even though the generated targets
were accepted by ANTLR4, Bison and tree-sitter.

The defect is at the ownership boundary: the raw RHS from StandardIR is a
normative fact, while lexical spelling, nullable reduction, role factoring and
other target transformations are target construction. A hash taken after such
a transformation cannot witness the raw source expression.

## Decision

1. At the first typed adapter boundary, before lexicalization or target
   normalization, record the exact source RHS expression and its canonical
   source-expression identity.
2. Carry that source witness and its complete source location/lineage through
   every transformation. A target rule may have a different target-expression
   identity, but it may not replace or recompute the source identity from the
   transformed target tree.
3. Every source-backed alternative remains covered in the selected profile,
   even when its target body is merged, factored or replaced by a generated
   helper. If it has no one-to-one target body, emit a separate typed
   source-preservation witness; do not label a generated helper's hash as a
   source hash and do not remove the source alternative from the denominator.
4. Generated helpers carry `source-expression-sha256 none` when they have no
   normative RHS and carry a complete, aligned dependency lineage plus their
   own target-expression identity.
5. The independent checker treats parser-generator acceptance as subordinate:
   it must verify source-witness coverage, source/target field typing,
   cardinality, mutation rejection and target-tool validity separately.

This is generic pipeline behavior. No rule number, Unicode glyph, lexical
fact, or target format receives a special case.

## Rejected

* Hashing the lexicalized or normalized tree and calling that the source
  identity.
* Keeping only a target hash when a source alternative has been merged or
  factored away.
* Treating ANTLR4, Bison or tree-sitter acceptance as evidence that a source
  alternative was preserved.
* Copying a reference grammar production to repair the missing witness.

## Evidence

The decision is based on E0154/R000311 and D0095.

## Reversal condition

Write a successor if a
source-backed target transformation requires a different typed provenance
contract, or if an independent source-preservation and language witness shows
that the separate witness cannot distinguish source coverage from target-body
equivalence.
