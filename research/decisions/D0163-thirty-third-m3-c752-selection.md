# D0163. Select C752 forbidden coarray types as the next bounded property

Date: 2026-08-17
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Acceptance

The deterministic residual partition and source inspection pass. This accepts
only the selection of C752 as the next bounded property; it does not accept a
C752 semantic fact or close M3.

## Context

After promotion of the bounded C751 oracle, the pinned witness ledger leaves
140 residual rows (81 disputed and 59 unwitnessed), with C752@1 first. C752 is
J3-24-007 clause 7, canonical lines 3842--3844, printed page 79 and byte span
`241335:223`. The existing StandardIR witnesses are R702/R703/R704/R737/R739.

## Decision

Select C752's relation between coarray-spec presence and forbidden component
type identity as the next bounded slice. The candidate must distinguish
`C_PTR`, `C_FUNPTR`, `TEAM_TYPE`, other type and unknown type identity. A
missing type identity remains `UNRESOLVED`; no model output may promote it.
The next implementation must explicitly preserve the fact that the three
named module-defined types are not yet direct StandardIR rows.

## Rejected

* Treating the witness ledger's model-self-consistency row as semantic evidence.
* Inferring module-defined type identity from a keyword, compiler behavior or
  model output.
* Starting general parsing, name resolution, C752/C753/C754 closure or full M3.

## Reversal condition

Write a successor if source inspection, the StandardIR binding or the residual
partition is found to be incorrect, or if the next bounded oracle needs a
different typed representation.

## Evidence

* `research/runs/2026-08.jsonl#R000602` records the preceding C751 promotion.
* `research/runs/2026-08.jsonl#R000603` records the superseded malformed-path attempt.
* `research/runs/2026-08.jsonl#R000604` records the corrected command with pre-correction artifact hashes.
* `research/runs/2026-08.jsonl#R000605` records the authoritative deterministic selection.
* `artifacts/reports/M3/m3-core0-next-property-selection-v21.md` records the
  source and StandardIR binding.
* `.cache/runs/E0181/R000002/analysis/witness/witnesses.jsonl` is the pinned
  residual ledger.
