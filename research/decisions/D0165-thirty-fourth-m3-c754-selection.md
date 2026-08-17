# D0165. Select C754 as the next bounded property

Date: 2026-08-17
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Acceptance

The deterministic residual partition and source inspection pass. This accepts
only the selection of C754 as the next bounded property; it does not accept a
C754 semantic fact or close M3.

## Context

After the bounded C752 leaf passed, the pinned witness ledger leaves 139
residual rows (81 disputed and 58 unwitnessed), with C754@1 first. C754 is
J3-24-007 clause 7, canonical lines 3847--3848, printed page 79 and byte span
`241715:150`. Existing StandardIR supplies R737/R738/R739/R740.

## Decision

Select C754's restriction on component-array-spec when neither POINTER nor
ALLOCATABLE is specified as the next bounded slice. The implementation must
separate pointer-attribute presence, allocatable-attribute presence and
component-array-spec shape, preserve unknown states as `UNRESOLVED`, and keep
the property source-backed and deterministic. It must not infer attribute
presence or shape from model output.

## Rejected

* Treating the witness ledger's model-self-consistency row as semantic evidence.
* Starting general parsing, name resolution, C753/C755 closure or full M3.
* Treating the C754 source occurrence as proof of a semantic fact before its
  bounded oracle and independent review pass.

## Reversal condition

Write a successor if source inspection, the StandardIR binding or the selected
typed relation is incorrect, or if the bounded oracle needs a different
source-backed representation.

## Evidence

* `research/runs/2026-08.jsonl#R000616` records the preceding C752 promotion.
* `artifacts/reports/M3/m3-core0-next-property-selection-v22.md` records the
  deterministic partition and source binding.
* `.cache/runs/E0181/R000002/analysis/witness/witnesses.jsonl` is the pinned
  residual ledger.
