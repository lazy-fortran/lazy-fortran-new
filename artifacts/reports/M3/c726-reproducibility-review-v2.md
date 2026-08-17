# C726 focused reproducibility review v2

Verdict: `NEEDS FIX`

R000502 is a clean, trace-matching replay with zero model calls and zero
semantic promotions, but the active task handoff still reports the task as
`NOT_STARTED` and omits the replay result, environment, trace and review
evidence. The handoff must enumerate those artifacts and the next replay must
be recorded against the current pushed revision.

Evidence inspected:

- `TASK_POOL.yaml`
- `STATUS.md`
- `MILESTONES.md`
- `research/experiments/E0194-can-a-deterministic-source-backed-oracle/manifest.yaml`
- `research/runs/2026-08.jsonl#R000502`
- `.cache/runs/E0194/R000004/result.json`
- `.cache/runs/E0194/R000004/run-environment.json`
- `artifacts/traces/m3-c726-source-backed-v0.json`

This review covers task wiring, revision separation, clean-checkout behavior,
hashes, trace wiring, mutation controls and control-plane integration. It does
not adjudicate full C726 or M3 semantics.
