# D0114. Map boundary paths before target normalization

Date: 2026-08-16
Status: accepted

## Context

R000428 closes validation of the source-derived boundary plan, but its
canonical paths still refer to the source expression tree. Target
normalization can remove wrappers, deduplicate alternatives or change
recursion, so inserting a separator by searching the normalized tree would
silently conflate source and target structure.

## Decision

The next mapping slice resolves each accepted boundary candidate against the
source grammar rule and its source occurrence before target normalization. The
mapping key includes source document/hash, clause, rule, left-hand side, page,
byte start and canonical expression path. It resolves the path structurally
from the source rule root and records the source node kind/name and alternative
set.

Each candidate receives exactly one explicit disposition: `mapped`,
`ambiguous`, `unsupported` or `suppressed`. A candidate with multiple source
alternatives is ambiguous unless the source occurrence and expression path
select one unambiguously. No target token is inserted in this slice. Mapping
failures remain evidence and block later target insertion; no rule-number,
LHS-suffix or target-spelling exception is permitted.

This keeps the source witness and target normalization as separate typed
boundaries and avoids adding source paths to the target IR until a real need is
demonstrated.

## Rejected

* Searching normalized target text for a source rule or item name.
* Treating a successful `(rule, path)` string lookup as sufficient without
  source occurrence lineage.
* Choosing the first matching alternative.
* Inserting separators while mapping.
* Extending target normalization with Fortran-specific path exceptions.

## Reversal condition

Write a successor if a complete source mapping shows that target normalization
must preserve additional source identity to represent all accepted sites, or
if a bounded target witness proves that a stronger shared source/target map is
required before insertion.

## Evidence

* R000420/R000423: 95 source-derived sites with canonical paths and complete
  source occurrence lineage.
* R000428: strict plan validation and truthful exporter identity pass; target
  insertion remains open.
* D0112: validated statement-boundary lowering plan.
* D0113: truthful generated identity and numeric source ordering.
