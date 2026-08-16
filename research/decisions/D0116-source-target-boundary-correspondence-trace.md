# D0116. Carry boundary correspondence through target transformations

Date: 2026-08-16
Status: accepted

## Context

R000429/R000430 map all 95 selected statement-boundary sites to the raw
StandardIR SX tree, but the target normalizer currently exposes only target
expressions, source provenance and expression hashes. It does not expose how a
source node or sequence boundary moved when a target transformation flattens
sequences, removes nullable wrappers, deduplicates alternatives or eliminates
left recursion.

Inferring a target location afterwards from rule names, token spellings,
expression hashes or a best structural similarity would lose occurrence
identity and could silently attach a boundary to the wrong generated rule.
The grammar-convergence and parser-generator evidence rules require the
transformation itself to state what it preserved or removed.

## Decision

Target normalization must expose a typed correspondence trace for the selected
source boundary plan. A trace row retains:

* the complete source occurrence and raw expression path;
* the source alternative identity and source node/boundary role;
* target rule/LHS/alternative identity;
* the target expression path and sequence boundary slot when one exists;
* the generic transformation operation and input/output expression hashes; and
* one disposition: `mapped`, `ambiguous`, `suppressed` or `unsupported`.

The trace is produced during the existing generic transformation operations,
not reconstructed from the final target text. Identity and child-wise sequence
operations compose paths; flattening and wrapper removal record the relation;
deduplication and recursion elimination retain all source witnesses and emit a
non-guessing disposition when no unique target slot remains. Target separator
insertion consumes only a validated trace and remains disabled in this slice.

The trace is a generic interface. It may not test a Fortran rule number, an
`-stmt` suffix, a token spelling, a selected alternative number, or a target
format name to repair a missing relation.

## Rejected

* Searching normalized target trees for a source node by name or hash.
* Re-running a second, slightly different normalizer solely to recover paths.
* Choosing the first duplicate target location.
* Treating source provenance lists as a path correspondence.
* Inserting separators before the trace has a validated disposition for every
  selected site.

## Reversal condition

Write a successor if a bounded generic trace cannot represent a valid target
transformation without retaining a richer source forest, or if an independent
target witness shows that explicit trace rows lose a required correspondence.

## Evidence

* R000429/R000430: raw-source mapping of the selected boundary witness and its
  independent bounded review.
* D0095/D0096: distinct source/target identity and raw witness propagation.
* D0102: transformation witnesses are separate from target-generator and
  language evidence.
* D0114/D0115: source paths are resolved before target normalization.
