# D0031. Source-linked AST node array with deterministic links

Date: 2026-08-12
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

E0062 produces source-linked logical statements with construct closure. The
next local boundary needs to compose those records into an AST-shaped value
without introducing a runtime object graph, a second semantic representation,
or model-owned composition. The representation must retain source
provenance and leave a direct path to generated, specialized traversal.

## Decision

Represent the generated AST initially as a typed flat node array. Each node
stores its kind, StandardIR rule, parent index, first-child index,
next-sibling index, depth, physical source span and source reference. The
generator creates parent and child links deterministically from the logical
statement stream. The array and link schema are authoritative for this local
operation; grouping, fusion and direct traversal remain generator decisions.

Use this representation for the next AST experiments, including expression
children and source-linked query and diagnostic lookups. Preserve the source
reference on every node. Keep generic allocation or runtime dispatch out of
the generated path unless a measured requirement forces it.

## Rejected

A pointer-linked heap tree is rejected because it adds allocation and pointer
chasing to the initial representation without improving the declared
operation. Separate node objects per construct are rejected because they make
schema-wide traversal and later specialization less direct. Asking a model to
choose or wire the tree is rejected because parent and child composition is a
deterministic consequence of the generated records.

## Reversal condition

Write a successor if independent measurements on representative compiler
workloads show that the flat array materially harms required mutation,
incremental analysis or cache behavior, or if a more general representation
preserves the same provenance and generated direct traversal with lower total
cost.

<!--
This body is immutable once the status is `accepted`. To change a decision,
write a new record that names this one in its Supersedes, Amends or Retracts
header and says what the old reasoning got wrong. Only the Status line of
this file may then be edited, to point at the successor.

Rewriting the reasoning destroys the thing that makes its reversal condition
checkable later: what was actually believed at the time.
-->
