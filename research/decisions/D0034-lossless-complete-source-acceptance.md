# D0034. Retain unsupported complete-source constructs as diagnostics

Date: 2026-08-13
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

E0061 classifies every meaningful line in the pinned complete-source corpus,
but its local operation reports failure as soon as a line falls outside the
bounded constructive recognizer. The next parser boundary needs to accept a
whole source file while making that residue visible. E0067 confirms that
selected expression holes can remain local and deterministic without changing
structural wiring.

## Decision

Expose complete-source parsing as a lossless acceptance result. Recognized
records retain their generated kind, StandardIR rule, physical line and
source reference. When the local recognizer reaches an unsupported construct,
retain the preceding records and append one `unsupported` record with its
physical source line, a bounded diagnostic message and a StandardIR context
reference. Return the result to the caller instead of silently skipping the
construct or inventing a new structural branch. A later operation may resume
after the recorded residue once an independent constructive rule exists.

Use the generic `program-unit` context record for an unsupported top-level
construct until a more specific StandardIR rule is available. The context
reference is provenance, not a claim that the unsupported text has been
recognized as that production.

This is autonomous under D0028. The simplest representation that preserves
the complete-file boundary, source location, provenance and direct generated
traversal is preferred.

## Rejected

Aborting with only an integer status is rejected because it loses the useful
prefix and the source location of the residue. Silently skipping the line is
rejected because it creates false acceptance. A model-generated recovery
dispatcher is rejected because the local structural wiring remains generated
and deterministic.

## Reversal condition

Write a successor if the result loses recognized records, cannot locate the
first unsupported physical line, conflates a context reference with a parsed
production, or requires source-specific exception branches to retain the
residue.

<!--
This body is immutable once the status is `accepted`. To change a decision,
write a new record that names this one in Supersedes, Amends or Retracts.
Only the Status line may then point at the successor.
-->
