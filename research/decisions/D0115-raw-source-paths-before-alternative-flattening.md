# D0115. Resolve source paths against raw StandardIR before flattening

Date: 2026-08-16
Status: accepted
Amends: D0114

## Context

The first source-path mapper walked the typed rules produced by the SX
adapter. That adapter deliberately flattens a raw `(alt ...)` expression into
one typed rule per alternative. The statement-sequence witness, however,
records paths in the raw StandardIR expression tree. R1505 is a concrete
control: its two candidates use `rhs/1/1` and `rhs/2/1`, where the first path
component selects an alternative in the raw tree. A flattened alternative
root cannot distinguish that source path without an unrecorded guess.

This is the same class of error that the grammar-convergence literature warns
against: a projection step must retain an explicit correspondence rather than
silently identifying structures that only look alike after normalization.

## Decision

The authoritative source-path mapping consumes the raw StandardIR SX syntax
expression, before alternative flattening or any target normalization. It
matches the complete source occurrence lineage, navigates the canonical path
over raw child ordinals, and records the raw node kind, name, pre-order index
and selected raw alternative where applicable. The existing typed mapper may
remain as a separate target-tree utility only when its input contract states
that paths are already expressed in that typed tree.

The production CLI and full-corpus gate must use the raw-source entry point.
No rule-number, LHS, alternative-number, token spelling or path-prefix
exception may repair a mismatch. If raw source shape is unavailable or a path
does not resolve uniquely, the result is an explicit unsupported or ambiguous
disposition and later target insertion remains blocked.

## Rejected

* Stripping the first path component whenever a typed rule has an alternative.
* Assuming alternative one is equivalent to a non-alternative expression.
* Matching source paths against generated target text or normalized typed
  trees.
* Copying a reference grammar to recover the missing source correspondence.

## Reversal condition

Write a successor if a complete raw-source replay shows that the raw SX tree
does not retain enough information to identify a witnessed source path, or if
a validated correspondence table can preserve that information without
making the raw-source gate depend on a target projection.

## Evidence

* R000420: canonical paths are derived from the raw StandardIR expression
  tree and retain complete source lineage.
* R000428: typed boundary-plan validation passes but does not establish
  source-path mapping.
* R1505 in the pinned StandardIR source: the raw `(alt ...)` control exposes
  the flattening ambiguity.
* D0114: source mapping remains before target normalization.
* Lämmel and Zaytsev, “An Introduction to Grammar Convergence”,
  <https://doi.org/10.1007/978-3-642-00255-7_17>.
