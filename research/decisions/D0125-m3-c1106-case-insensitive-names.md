# D0125. C1106 names compare case-insensitively

Date: 2026-08-16
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

Amends: D0124

<!-- Optional headers, one per line, when they apply:
Supersedes: D####
Amends: D####
Retracts: D####
-->

## Context

The focused review of E0175/R000469 found that D0124's raw string equality
would reject `FOO` paired with `foo`. J3/24-007 states in the pinned canonical
source that a lower-case letter is equivalent to its upper-case letter in
program units (canonical-text lines 2759--2760, clause 6.1.2). C1106's
"same associate-construct-name" therefore means the same case-insensitive
Fortran name identity, not byte-for-byte spelling.

## Decision

Retain the source spelling in each typed `value` field, but compare present
names by deterministic ASCII/Fortran case-insensitive identity before applying
C1106. The oracle maps only `A`--`Z` to `a`--`z` on the already represented name
values; the current fixture's names are ASCII. Add a positive case-variant
witness and bind the case-equivalence source lines to the same pinned
canonical-text hash.

The outcome rules from D0124 are unchanged otherwise: both known and both
absent, or both present with equal normalized identity, is `ACCEPTED`; a known
one-sided name or unequal normalized identity is `REJECTED`; an unknown side is
`UNRESOLVED`.

## Rejected

Raw string equality is rejected because it contradicts the normative
case-equivalence rule. A second parser or a model-selected normalization is
also rejected: the candidate is already a represented name, and normalization
is a fixed oracle operation.

## Reversal condition

Reverse this amendment if the pinned standard source limits associate construct
name identity differently, if the independent witness shows that
case-equivalent names are not accepted by the normative constraint, or if
normalization must depend on candidate-specific or model-selected behavior.

<!--
This body is immutable once the status is `accepted`. To change a decision,
write a new record that names this one in its Supersedes, Amends or Retracts
header and says what the old reasoning got wrong. Only the Status line of this
file may then be edited, to point at the successor.

Rewriting the reasoning destroys the thing that makes a reversal condition
checkable later: what was actually believed at the time.
-->
