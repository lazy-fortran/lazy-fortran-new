# D0166. Select C757 as the next bounded property

Date: 2026-08-17
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Acceptance

The deterministic residual partition and source inspection pass. This accepts
only the selection of C757 as the next bounded property; it does not accept a
C757 semantic fact or close M3.

## Context

After the bounded C754 leaf passed, the pinned witness ledger leaves 138
residual rows (81 `disputed` and 57 `unwitnessed`), with C757@1 first. C757 is
J3-24-007 clause 7, canonical lines 3851--3852, printed page 79 and byte span
`242052:120`. Existing StandardIR supplies R737, R738 and R739 for the
component definition, attribute choices and optional array shape.

## Decision

Select C757's restriction on CONTIGUOUS components as the next bounded
source-backed slice. A later delivery contract must type CONTIGUOUS presence,
POINTER presence and component array presence, preserve unknown states as
`UNRESOLVED`, and avoid inferring any state from model output.

## Rejected

* Treating the witness ledger's model-self-consistency cases as semantic
  evidence.
* Starting general parsing, name resolution, C755/C756/C758 closure or full
  M3 semantic work.
* Treating the C757 source occurrence as proof of a semantic fact before a
  bounded oracle and independent review pass.

## Reversal condition

Write a successor if source inspection, the StandardIR binding or the selected
typed relation is incorrect, or if the bounded oracle needs a different
source-backed representation.

## Evidence

* `research/runs/2026-08.jsonl#R000620` records the preceding C754 promotion.
* `artifacts/reports/M3/m3-core0-next-property-selection-v23.md` records the
  deterministic partition and source binding.
* `.cache/runs/E0181/R000002/analysis/witness/witnesses.jsonl` is the pinned
  residual ledger.
