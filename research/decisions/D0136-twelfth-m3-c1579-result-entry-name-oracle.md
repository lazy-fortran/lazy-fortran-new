# D0136. Twelfth M3 slice uses C1579 RESULT entry-name exclusion

Date: 2026-08-17
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

The eleventh bounded M3 slice, C738, is promoted, but full M3/Core 0 remains
open under the retained E0181 ledger gate. The exact E0181 replay still has
two unresolved rows, C1579 and C1586. C1579 is the smaller source-backed
property: its R1544 `entry-stmt` shape is already represented in StandardIR,
and the rule is one implication over RESULT presence and entry-name
declaration state.

## Decision

Define the twelfth bounded M3 delivery slice as the C1579 RESULT entry-name
exclusion oracle. The typed candidate carries only these states:

```text
RESULT absent → ACCEPTED
RESULT present + entry-name absent from specification/type declarations → ACCEPTED
RESULT present + entry-name present in specification/type declarations → REJECTED
unknown RESULT or declaration state → UNRESOLVED
```

The source binding is J3-24-007 C1579 at canonical-text lines 15386--15387,
printed page 356, with the existing StandardIR R1544 `entry-stmt` shape and
R1532 `function-subprogram` context pinned by exact metadata and source hash.
Candidate facts are human-authored; no model output can promote a semantic
fact.

Only this implication is evaluated. The oracle does not parse ENTRY or
FUNCTION statements, resolve scopes, infer declaration state, perform name
resolution, or wire compiler semantics.

## Rejected

* Selecting C1586 as the next slice: its scalar-expression rule combines
  constants, variables, function references, intrinsic operations, arrays and
  statement functions, so it is not the smallest executable contract.
* Restarting E0172 or another broad model experiment.
* Treating the unresolved E0123 model rows as accepted semantic evidence.

## Reversal condition

Write a successor if C1579 cannot bind to the two canonical source lines and
the pinned R1544/R1532 StandardIR shapes, or if a clean replay contradicts the
source identity or independent oracle outcomes.

## Evidence

* `.cache/runs/E0001/R000003/j3-24-007.canonical.txt` lines 15386--15387.
* `.cache/runs/E0171/R000433-provenance-replay/standardir.sx` rows R1532 and
  R1544.
* `.cache/runs/E0181/R000001/analysis/merged/selected-rows.jsonl` C1579@1,
  retained as unresolved residual evidence.
* `research/experiments/E0186-can-a-deterministic-oracle-enforce-c738-/manifest.yaml`
  and focused review `research/runs/2026-08.jsonl#R000055`.
