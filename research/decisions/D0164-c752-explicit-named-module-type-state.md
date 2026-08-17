# D0164. Make unresolved C752 module-defined type identity explicit

Date: 2026-08-17
Status: accepted
Amends: D0163
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Acceptance

The focused review of the first C752 implementation found that a generic
`unknown` type state did not make the named module-defined-type boundary
auditable. This amendment changes only the typed representation of that state;
the bounded property and source selection remain C752.

## Context

D0163 selected the 15-state product of coarray-spec
`absent|present|unknown` and component type
`C_PTR|C_FUNPTR|TEAM_TYPE|other|unknown`. The C752 source names three
module-defined types, but their identity and module origin are not direct
StandardIR rows. A generic type `unknown` is therefore too ambiguous: it does
not show whether the unresolved fact is specifically the named module-type
identity that C752 needs.

## Decision

Amend the component-type axis to
`C_PTR|C_FUNPTR|TEAM_TYPE|other|named-module-type-unknown`. Keep the product
at 15 states. `named-module-type-unknown` is `UNRESOLVED` whenever a coarray
spec is present; with an absent coarray-spec the restriction is vacuous and
the state is `ACCEPTED`. Only a positively resolved `other` type may be
accepted when a coarray-spec is present.

The validator must also compare the fixture's `source.pdf_sha256` field with
the pinned PDF digest and include that field in the negative mutation
controls.

## Rejected

* Treating a generic unknown type as sufficient evidence for the named module
  boundary.
* Expanding the slice into a general module/type identity analysis.
* Adding a separate state family that would broaden the selected 15-state
  contract without a new source-backed property.

## Reversal condition

Write a successor if direct StandardIR rows for the named module-defined types
become available, if the source-backed candidate needs a different typed
partition, or if the 15-state bounded contract cannot preserve the unresolved
boundary.

## Evidence

* `artifacts/reports/M3/m3-c752-focused-review-v1.md` records the two defects
  found at the frozen first implementation.
* `research/runs/2026-08.jsonl#R000611` records the focused review verdict.
* `research/decisions/D0163-thirty-third-m3-c752-selection.md` records the
  unchanged C752 source selection and is amended by this decision.
