# D0119. Preserve boundary-candidate identity before target insertion

Date: 2026-08-16
Status: accepted

## Context

R000435 replayed the selected source-boundary witness against the generic
target correspondence trace. The trace contract is valid, but the 95 input
rows contain 24 duplicate structural groups: different derivations such as
`first-plus-repeat` and `repeat-item` can name the same source occurrence,
raw path and source node. The previous audit called the result 95 one-to-one
joins because its key omitted `source_node_kind` and because it did not report
duplicate candidate identities.

D0117 already defines target correspondence as a relation rather than a
function. That permits multiple target rows for one source occurrence, but it
does not permit a consumer to silently conflate distinct candidate evidence or
to count the same structural boundary as several insertion sites.

## Decision

The source-boundary pipeline has two explicit identities:

1. A **candidate-evidence identity** retains the complete source occurrence,
   raw expression path, source node kind, candidate kind, item and derivation.
2. A **structural boundary identity** is the source occurrence, raw expression
   path, source node kind and boundary role. It is the unit that may eventually
   receive one separator insertion plan.

The deterministic bridge between them must do one of two things, explicitly:

- carry candidate-evidence identity through the generic correspondence trace;
  or
- coalesce equal structural boundary identities before target insertion while
  retaining every contributing candidate kind/item/derivation as evidence.

The audit must report both counts, reject silent duplicate structural keys, and
scope selected-candidate results separately from whole-trace disposition
counts. A selected replay is not green merely because every input row finds a
trace row. Target separator insertion remains disabled until the bridge has
been validated and independently reviewed.

No rule number, left-hand-side spelling, suffix, target spelling or candidate-
kind exception may decide identity. The implementation must use the generic
source lineage and expression structure already present in the contracts.

## Rejected

- Calling duplicate structural rows “one-to-one” because they share one trace
  row.
- Dropping one candidate kind without retaining its derivation evidence.
- Treating the nine selected rule-deduplication relations as evidence that all
  717 full-trace suppressions have retained targets.
- Repairing the duplicate groups by naming individual Fortran rules.

## Reversal condition

Write a successor if an independent source behavior and target parse witness
shows that candidate kinds are semantically distinct insertion sites despite
identical structural identities, or if a stronger generic boundary-forest
contract makes the two-level identity unnecessary.

## Evidence

- E0171/R000435: corrected replay; 95 mapping rows, 71 distinct structural
  keys, 24 duplicate groups, 4,871 trace rows and audit status `FAIL` after the
  duplicate-key check.
- E0171/R000436: independent GPT-5.6 Luna review of the replay.
- D0112: typed source-backed boundary plan before target insertion.
- D0115: raw StandardIR paths before alternative flattening.
- D0116/D0117: typed, relation-valued source/target correspondence.
