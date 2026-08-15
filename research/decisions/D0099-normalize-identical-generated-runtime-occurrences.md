# D0099. Normalize identical generated runtime occurrences without losing provenance

Date: 2026-08-15
Status: accepted

## Context

The first E0164 full-contract runtime load exposed two independent generic
problems. Loading one source occurrence at a time caused quadratic storage
growth and reached approximately 46 GiB resident memory before interruption.
The two-pass loader fixed that defect. The selected closure contract then
exposed a second one: helper names derived from long, source-backed
classification names exceeded the existing fixed grammar identity fields.

The source contract intentionally retains duplicate rule occurrences because
their PDF spans and provenance are evidence. The runtime table does not need
to retain two generated productions when their generated identity, left-hand
side and complete right-hand side are identical.

## Decision

Keep every source occurrence in the contract and audit artifacts. During the
generic runtime lowering, coalesce only an exact duplicate generated
production when its identity, left-hand side and complete RHS are identical.
If the same generated identity has a different body, fail with a conflict
rather than silently choosing one. Generated helper names and identities must
be deterministically bounded by the runtime field capacities for arbitrary
valid source names; they may not depend on Fortran rule numbers or a list of
special cases.

The loader must count and allocate its source records before lowering them,
so input size does not cause repeated whole-table copies. These runtime
normalizations are implementation projections only; they never rewrite the
authoritative StandardIR or its source lineage.

## Rejected

* Removing duplicate source records from StandardIR or the contract. That
  destroys occurrence-level PDF evidence.
* Truncating long names and accepting possible collisions.
* Assigning special short names to particular Fortran rules or closure names.
* Treating a memory failure as a grammar or source-extraction failure.

## Evidence

E0164 R000361/R000362 retain the initial loader failure and the bounded
post-loader unresolved result. The selected closure contract and its exact
reference audit are recorded in E0164 R000363. The production implementation
is fortfront-new commit `6ed7a53`; the identity-capacity regression remains
open until its successor commit and focused test are verified.

## Reversal condition

Write a successor if an independent provenance or behavior gate shows that
exact generated deduplication changes accepted language, diagnostics or source
attribution, or if bounded deterministic naming cannot preserve uniqueness
for a valid contract without changing the public contract schema.
