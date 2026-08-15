# D0095. Keep normative source-expression and generated-target identity distinct

Date: 2026-08-15
Status: accepted
Amends: D0088

## Context

E0154/R000308 found that the grammar target could compute a reproducible hash
of a generated assumed-expansion rule and serialize it as
`source-expression-sha256`, even though R401/R402/R403 have no normative syntax
RHS in the StandardIR input. The same replay found that Unicode canonical
bytes and long merged provenance lists need independent witnesses. A hash that
is internally stable is not thereby a hash of the source expression.

## Decision

1. `source-expression-sha256` means the SHA-256 of the exact normative SX RHS
   expression, serialized by the canonical SX writer including its terminating
   newline. The bytes are preserved exactly, including UTF-8 source glyphs.
2. A normalized, synthesized or helper target expression has a distinct
   `target-expression-sha256` when its identity is exported. It must not be
   substituted for a source-expression hash.
3. A generated record with source/fact provenance but no normative RHS carries
   an explicit absent source-expression value (`none`) in the aligned lineage
   witness. It may carry a target-expression hash. Mixed lineages retain one
   aligned value per provenance entry; they are never shortened to fit a
   fixed annotation buffer.
4. The identity checker verifies source-expression hashes only against
   source-backed syntax alternatives. It verifies generated target hashes
   against the target expression representation in a separate subgate.
   Parser-generator acceptance remains subordinate to both.

This is a generic provenance sum type. It applies equally to any future
source-backed language or target format; it does not name a Fortran rule in
production code. The E0154 experiment and all four exporters carry the same
typed witness semantics.

## Rejected

* Calling every reproducible expression hash a source hash because the
  expression was derived from a source-defined fact.
* Dropping source-less entries from a merged lineage list.
* Treating parser-generator acceptance as evidence that a provenance hash is
  correct.
* Solving Unicode or long-line failures with rule-specific exceptions.

## Reversal condition

Write a successor if an independent source/projection witness demonstrates
that the two identity classes cannot be serialized without losing aligned
lineage, or if a target format requires a more expressive generic provenance
sum type. The successor must retain explicit source absence and must not
collapse the two hash meanings.
