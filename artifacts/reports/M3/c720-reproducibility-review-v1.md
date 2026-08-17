# C720 reproducibility review v1

Packet: control-plane `1f8fa2e5aaf50cbdcd2138e765e1b7265dd06346`, functional
runner `1dd52df79344214edcaa584be93805cbab63720e`, replay worktree
`abecd36ed9a1f560dc675bb8ea0b6679e2f042c3`, and
`research/runs/2026-08.jsonl#R000486`.

Verdict: `PASS`.

The final review checked the functional, replay and standard-new revision
separation, the manifest and run-environment hashes, the clean-checkout
result, the C720 line 3298/page 80/R708 binding, and the retained R000485
failure. `TASK_POOL.yaml` now makes `T-M3-c720-focused-review` active and
declares its verifier, evidence paths and final observable. The prior stale
wiring failure remains recorded in
`artifacts/reports/M3/c720-reproducibility-review-v0.md`.

The corrected replay command is:

```text
M3_C720_EXPECTED_CENTRAL_COMMIT=abecd36ed9a1f560dc675bb8ea0b6679e2f042c3 tests/e2e/run-m3-c720.sh --fresh
```

No reproducibility or integration defect was found.
