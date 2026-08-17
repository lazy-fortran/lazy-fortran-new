# C720 reproducibility review v0

Packet: control-plane `3be59fdc5c28bcaa876c51dd91777841db370a00`, functional
runner `1dd52df79344214edcaa584be93805cbab63720e`, replay worktree
`abecd36ed9a1f560dc675bb8ea0b6679e2f042c3`, and
`research/runs/2026-08.jsonl#R000486`.

Verdict: `NEEDS FIX`.

The source, PDF, page-index, StandardIR, clean-checkout, trace and hash
evidence was consistent. The control-plane active task remained
`T-M3-c717-focused-review` while the C720 review was pending, and no explicit
C720 focused-review task existed in `TASK_POOL.yaml`. This made task ownership
and promotion state inconsistent even though the bounded replay command
passed:

```text
M3_C720_EXPECTED_CENTRAL_COMMIT=abecd36ed9a1f560dc675bb8ea0b6679e2f042c3 tests/e2e/run-m3-c720.sh --fresh
```

Required correction: make the C720 focused review the active task and add its
verifier, evidence paths and final observable.
