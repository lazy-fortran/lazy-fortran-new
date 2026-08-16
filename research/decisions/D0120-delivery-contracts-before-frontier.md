# D0120. Use delivery contracts before frontier work

Date: 2026-08-16
Status: accepted

## Context

The laboratory and `standard-new` have accumulated useful source-boundary,
provenance and correspondence machinery, but recent work has repeatedly
ended in another audit rather than an observable compiler behavior. This is a
delivery problem, not evidence that the underlying research questions are
settled. The two repositories have different responsibilities and must not be
driven by one undifferentiated Goal Mode loop.

`standard-new` owns the normative-source-to-StandardIR boundary. The
laboratory owns cross-repository contracts, fixtures, runs and integration.
Both already have enough contract material to choose a narrow vertical slice;
they do not need another general provenance layer before that slice is tested.

## Decision

The active method is **delivery-contract first**:

* `standard-new` works toward S0, a small normative lexical subset that
  regenerates deterministic StandardIR facts, emits source-to-target
  manifests, and passes positive, negative and mutation-controlled fixtures;
* `lazy-fortran-new` works toward L0, one minimal source fixture crossing its
  declared contract chain to a deterministic observable with an independent
  oracle; and
* every new provenance, correspondence, schema or generated-artifact change
  must be consumed by an executable acceptance test for the active milestone.

The central `ROADMAP.md` and lane views remain the planning authority. The
production repository receives a short Goal Mode addendum and delivery
control files, not a second research ledger or competing roadmap. The active
status is mutable; milestone definitions are stable; runs and decisions remain
append-only and immutable under the existing laboratory rules.

An oracle is defined before implementation. Accepted oracle classes are a
normative source witness, reviewed golden artifact, differential comparison,
metamorphic invariant, or explicit negative behavior. Compilation success,
trace existence and tests generated solely from the implementation are not
oracles.

Until S0 and L0 are green, broad model campaigns, semantic promotion, backend
expansion and additional correspondence machinery are paused unless a named
acceptance test for S0 or L0 requires them. Existing audit-loop work remains
historical evidence and may be resumed only when it is the next executable
blocker for a delivery milestone.

## Rejected

* Using one research-frontier Goal Mode loop for both repositories; their
  ownership and acceptance observables differ.
* Treating another provenance field, trace, or generated artifact as progress
  without a consumer test.
* Adding local roadmaps and research ledgers to production repositories; the
  laboratory already owns those responsibilities.
* Starting with a broad compiler or full-standard claim when a smaller
  independently checked slice can establish the delivery path.

## Reversal condition

Write a successor if S0 or L0 demonstrates that the chosen delivery contract
cannot express the required observable without a broader contract revision, or
if an independent oracle shows that the narrow slice gives a misleading
correctness signal. A failed slice narrows or changes the next milestone; it
does not justify returning to unbounded audit work.

## Evidence

* `standard-new` already contains normative specs, generated artifacts and
  behavioral tests.
* `lazy-fortran-new/contracts/` already contains lexical-layout, frontend,
  StandardIR, MIR, TargetIR and emission contract families.
* D0116--D0119 and E0171 preserve the source-target audit work and its current
  open status; this decision changes what work is allowed next, not the
  historical result.
