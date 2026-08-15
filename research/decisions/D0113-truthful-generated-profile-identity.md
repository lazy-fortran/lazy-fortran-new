# D0113. Keep generated profile identity truthful

Date: 2026-08-16
Status: accepted

## Context

The Luna review of `standard-new` `d2835f4` found that the generic SX exporters
label arbitrary or partial input as `Fortran2023`. The repository deliberately
does not commit the complete normative StandardIR corpus; the current tools
consume caller-supplied records. A generated projection therefore cannot claim
that its input is the complete Fortran 2023 standard merely because one
exporter has a hard-coded grammar name.

The same review found that the new boundary plan orders byte offsets as text.
That is latent corruption: source occurrence `100` must sort after `20`.
Provenance shape and ordering are part of the plan contract even before target
insertion exists.

## Decision

Generic exporters use a truthful neutral identity such as `StandardIR` or
`standardir` by default. They may use a language/profile identity only when a
validated profile input explicitly supplies it. The exporter header and README
must distinguish a projection of supplied records from a complete normative
language representation.

The statement-boundary plan requires a 64-hex source-document hash and
non-negative decimal source byte offsets. Its deterministic ordering parses
validated offsets numerically. Distinct source occurrences with the same rule
and expression path remain distinct when their source occurrence lineage
differs; exact repeated occurrences remain rejected.

## Rejected

* Hard-coding `Fortran2023` or `fortran2023` into a generic exporter.
* Treating a nonempty hash-shaped field as proof that the referenced document
  was verified; document/hash authenticity remains the laboratory provenance
  gate.
* Sorting source locations lexicographically because offsets are serialized as
  text.
* Adding a special case for a particular rule or page.

## Reversal condition

Write a successor if the production input contract gains a validated profile
identity and all exporters can consume it without making incomplete input look
complete, or if a source-location type replaces serialized offsets with a
validated numeric representation everywhere in the plan.

## Evidence

* Luna review of `standard-new` `d2835f4`, recorded with the production slice
  report on 2026-08-16.
* R000427: the boundary plan is green but intentionally does not insert target
  separators.
* D0112: validated statement-boundary lowering plan.
