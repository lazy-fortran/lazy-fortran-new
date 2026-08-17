# D0160. C750 bounded component-array deferred-shape oracle

Date: 2026-08-17
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Acceptance

The fresh replay, focused independent review and evidence gate pass at the
frozen control-plane revision. This accepts only the bounded C750 oracle leaf;
the parent M3 claim remains open.

## Context

The selected C750 contract binds J3-24-007 clause 7, canonical lines
3838--3839, printed page 79, byte span `241058:135`, to existing StandardIR
R737/R740. The clean replay passes with a complete 27-state table, one
accepted state, one rejected neighbour, 25 unresolved states, twelve rejected
mutation controls, zero model calls and zero semantic promotions.

## Decision

Promote only the bounded C750 typed relation:

```text
component-def-stmt + present + deferred-shape-list  ACCEPTED
component-def-stmt + present + explicit-shape-list  REJECTED
all other typed states                              UNRESOLVED
```

No model output can promote a semantic fact. The candidate does not parse
Fortran, inspect real component declarations, resolve names, infer array shape
or close full M3.

## Rejected

* Treating the deterministic replay as a complete C750 semantic implementation.
* Combining C750 with C751 or C754.
* Promoting the C750 relation as a complete semantic implementation.

## Reversal condition

Write a successor if focused review finds a source, contract, oracle or
reproducibility defect, or if an independent mutation control is accepted.

## Evidence

* `research/runs/2026-08.jsonl#R000594` records the C750 selection.
* `research/runs/2026-08.jsonl#R000596` records the clean C750 replay.
* `research/runs/2026-08.jsonl#R000597` records the focused review and evidence
  gate.
* `artifacts/reports/M3/m3-c750-source-backed-v1.md` records the bounded
  result and non-claims.
* `artifacts/reports/M3/m3-c750-focused-review-v1.md` records the two passing
  independent review lanes.
* `.cache/runs/E0218/R000004/result.json` and its run-environment record pin
  the replay outputs and toolchain.

<!--
This body is immutable once the status is `accepted`. To change a decision,
write a new record that names this one in its Supersedes, Amends or Retracts
header and says what the old reasoning got wrong. Only the Status line of this
file may then be edited, to point at the successor.
-->
