# D0162. C751 bounded coarray-ALLOCATABLE oracle

Date: 2026-08-17
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Acceptance

The clean technical replay and two independent focused reviews pass. This
accepts only the bounded C751 oracle leaf; the parent M3 claim remains open.

## Context

E0219/R000598 selected J3-24-007 C751, canonical lines 3840--3841, printed
page 79 and byte span `241193:142`, over existing StandardIR R737/R739/R809/R810/R811.
The typed candidate crosses coarray-spec absent, deferred-coshape-list,
explicit-coshape-spec or unknown with ALLOCATABLE absent, present or unknown.

The clean technical replays are E0220/R000599 and R000602. They return four
`ACCEPTED`, four `REJECTED` and four `UNRESOLVED`
states, rejects twelve source/provenance/contract mutations, and records zero
model calls and zero semantic promotions. Reproduce it with:

```text
M3_C751_EXPECTED_CENTRAL_COMMIT=89b13c3051ecaf6948c7adc4b40a451d161182a5 tests/e2e/run-m3-c751.sh --fresh
```

## Decision

Promote only the bounded typed relation:

```text
absent coarray-spec                              ACCEPTED
deferred-coshape-list + ALLOCATABLE present     ACCEPTED
deferred-coshape-list + ALLOCATABLE absent      REJECTED
explicit-coshape-spec                            REJECTED
unknown states                                   UNRESOLVED
```

No model output can promote a semantic fact. The oracle does not parse
Fortran, inspect C752/C754, resolve names, infer real declarations or close
full M3.

## Rejected

* Treating the technical replay as sufficient evidence for durable promotion.
* Treating the C751 oracle as a complete semantic implementation or a Fortran
  parser.

## Reversal condition

Write a successor if focused review finds a source, contract, oracle or
reproducibility defect, or if any mutation control is accepted.

## Evidence

* `research/runs/2026-08.jsonl#R000598` records selection.
* `research/runs/2026-08.jsonl#R000599` records the first technical replay.
* `research/runs/2026-08.jsonl#R000600` records the unavailable review attempt.
* `research/runs/2026-08.jsonl#R000601` records two focused review passes.
* `research/runs/2026-08.jsonl#R000602` records the current clean replay.
* `artifacts/reports/M3/m3-c751-source-backed-v0.md` records the replay.
* `artifacts/reports/M3/m3-c751-focused-review-v2.md` records the two review passes.
* `artifacts/traces/m3-c751-source-backed-v0.json` pins the result.
