# D0111. Include adjacent sequence boundaries in the witness

Date: 2026-08-16
Status: accepted
Supersedes: D0110

## Context

The first D0110 witness covered repeated items, first-item-plus-repeat
contexts, and compound repeated items. Luna's independent review found a
generic omission: source constructs also contain adjacent statement-bearing
sequence elements without a repeat at that position, for example
`if-then-stmt` followed by `block` and `else-stmt` followed by `block`.
Those are source boundaries and cannot be recovered by inspecting repeats only.

The same review found four related correctness gaps in the first production
projection: derivation ordering was not canonical, malformed RHS wrappers were
indexed before validation, rejected shapes lost their path/provenance, and a
source-form-scoped suffix fact was applied globally. These defects make a
structural replay look more complete than it is.

## Decision

Extend the source-derived witness with `sequence-internal` boundaries. In a
sequence, emit a boundary after a direct source statement class when the
remaining suffix is nullable or statement-bearing. This relation is computed
by the same nullable and statement-reachability fixed points as the repeat
analysis. It must not add a boundary after a nested statement that is already
the final element of its enclosing statement, such as the `action-stmt` in a
single-line `if-stmt`.

The production projection must:

* validate the complete syntax record and RHS shape before indexing it;
* apply a suffix selector only when its source-form scope is `all` (until an
  explicit source-form parameter exists);
* emit deterministic derivation order;
* retain rejected unsupported rows with their source identity, path and
  status, while returning failure; and
* preserve document, clause, page, byte offset and source hash on every row.

The lab and production witnesses are compared on the full source corpus before
any target grammar consumes them. The witness remains a target-lowering input,
not normative StandardIR syntax and not a conflict policy.

## Rejected

* Treating adjacent sequence boundaries as a list of rule-name exceptions.
* Accepting a malformed RHS because the shared header found a plausible child.
* Dropping unsupported rows merely because the overall analysis failed.
* Applying a form-specific source fact to all source forms implicitly.

## Reversal condition

Write a successor if the source standard supplies a more precise application
relation, or if a full source replay plus independent behavior witness shows
that the nullable/statement-bearing suffix relation emits a boundary inside a
nested statement or misses a valid adjacent statement boundary.

## Evidence

* Luna review of `standard-new` `18e404c`, recorded before this decision.
* E0171/R000416: 58-row repeat/compound structural witness with complete
  source lineage; its next replay must include adjacent sequence rows.
* E0171/R000404: the source grammar contains `if-then-stmt block` and related
  construct sequences.
* D0110: source-derived sequence topology and no blind `-stmt` EOS rewrite.
