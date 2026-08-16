# D0124. First M3 slice uses associate construct-name consistency

Date: 2026-08-16
Status: amended by D0125
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

<!-- Optional headers, one per line, when they apply:
Supersedes: D####
Amends: D####
Retracts: D####
-->

## Context

M1-M2 and E0174 are closed, while E0172 is abandoned before model output
because its declared service identity did not match the live endpoint. The
missing M3 artifact is therefore a deterministic semantic verifier, not more
grammar correspondence or another model campaign.

The pinned E0171 StandardIR source already represents the ASSOCIATE construct
with R1102, R1103 and R1106. The pinned J3/24-007 source contains the short
C1106 constraint that relates the optional construct name on the opening and
closing statements. It is the smallest available relation that is semantic,
source-backed and testable without general parsing, name resolution or type
analysis.

## Decision

Define the first M3 delivery slice as the C1106 associate-construct-name
oracle. Its typed candidate is one associate-construct-name-pair fact with two
typed sides, start and end. Each side has known: boolean, present: boolean and
value: string|null; value is non-null exactly when present is true.

The deterministic oracle returns exactly one of:

- ACCEPTED when both sides are known and both names are absent, or both are
  present with equal values;
- REJECTED when both sides are known but exactly one is present or the present
  values differ;
- UNRESOLVED when either side is not known.

The contract pins the J3/24-007 PDF hash, its canonical-text hash and the
source-backed StandardIR syntax rows for R1102, R1103 and R1106. It requires
positive witnesses for equal and both-absent names, negative neighbours for
unequal and one-sided names, and mutation controls for the normative source
hash, syntax source hash and rule identity. The central replay computes the
outcome from the typed facts; expected labels in the fixtures are an
independent test oracle, not an input to the implementation.

The slice is laboratory code and evidence only. It does not parse arbitrary
Fortran, lower to compiler IR, claim semantic promotion for model output, or
modify a production repository. Any future model may propose a candidate, but
no model output can promote a semantic fact; only this deterministic oracle and
its source/provenance gate can produce ACCEPTED.

This is an autonomous decision under D0028 and the source-backed,
deterministic-first boundary in D0060.

## Rejected

The C706 abstract-type relation is deferred because its oracle requires a
typed declaration/type environment rather than two already represented
construct-name fields. C1106 is smaller and has an independently represented
source grammar shape.

Resuming E0172 or starting a broad semantic residual campaign is rejected
because neither supplies the missing decision procedure. General parsing,
parser-conflict work, compiler semantic analysis and production changes are
outside this first M3 contract.

## Reversal condition

Reverse this decision if the C1106 gate cannot independently bind the
normative constraint to the pinned StandardIR syntax occurrences, cannot
distinguish UNRESOLVED from a rejected known fact, or requires
candidate-specific production logic. A successful gate does not by itself
authorize broad semantic work; that requires a later contract.

<!--
This body is immutable once the status is `accepted`. To change a decision,
write a new record that names this one in its Supersedes, Amends or Retracts
header and says what the old reasoning got wrong. Only the Status line of this
file may then be edited, to point at the successor.

Rewriting the reasoning destroys the thing that makes a reversal condition
checkable later: what was actually believed at the time.
-->
