# D0140. Complete the C717 oracle truth table with known-violation precedence

Date: 2026-08-17
Status: accepted
Amends: D0139

## Context

The first focused review of the C717 packet found that D0139's prose had an
overlap: it said both that a known negative value or absent representation
method is `REJECTED` and that either unknown state is `UNRESOLVED`. The
implementation checked unknown first, so `(negative, unknown)` and
`(unknown, absent)` were unresolved even though a known violation was present.
The same review found that the six-case fixture did not cover all nine
combinations of the two ternary candidate states. A separate reproducibility
review found that the chosen run identifier `R000077` already belonged to
E0068, so the E0189 replay reference was ambiguous.

## Decision

Amend the bounded C717 contract with the explicit precedence
`known-violation-before-unknown` and the complete truth table:

| `kind_value` | `representation_method` | outcome |
|---|---|---|
| nonnegative | present | ACCEPTED |
| nonnegative | absent | REJECTED |
| nonnegative | unknown | UNRESOLVED |
| negative | present | REJECTED |
| negative | absent | REJECTED |
| negative | unknown | REJECTED |
| unknown | present | UNRESOLVED |
| unknown | absent | REJECTED |
| unknown | unknown | UNRESOLVED |

The independent validator must enumerate all nine rows and apply the same
precedence. The corrected clean replay receives a unique run ID and all
E0189/task/status references use that ID. Prior run lines remain immutable.

This amendment still does not evaluate expressions, inspect processor
capabilities, parse Fortran, infer semantic facts from model output or promote
the retained Core 0 ledger.

## Rejected

* Keeping the six-case partial table; the review showed that it cannot expose
  the overlapping known/unknown-state defect.
* Returning `UNRESOLVED` whenever any state is unknown; that loses a known
  violation and is not the selected fail-closed policy.
* Reusing `R000077`; it is already assigned to E0068.

## Reversal condition

Write a successor if the pinned C717 source requires a different relation, if
the complete table cannot be independently replayed, or if a later source
interpretation demonstrates that known violations must not take precedence.

## Evidence

* `artifacts/reports/M3/c717-semantic-review-v0.md`
* `artifacts/reports/M3/c717-reproducibility-review-v0.md`
* `research/runs/2026-08.jsonl` (the unique corrected E0189 replay ID is
  recorded after the repair)
* `research/decisions/D0139-fourteenth-m3-c717-kind-selector-oracle.md`
