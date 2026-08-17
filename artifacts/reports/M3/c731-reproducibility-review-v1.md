# C731 reproducibility review v1

Result: `PASS`

Reviewed control-plane revision: `f25c2513b8a849221480ec5d93a206830a8e9e65`.
Replay worktree revision: `94c71ec785ece8927a98a34a17e02aa452df1528`.
Reviewed replay: `research/runs/2026-08.jsonl#R000509`.

The current replay is durably recorded and wired to the E0196 manifest,
`TASK_POOL.yaml`, `STATUS.md`, `ROADMAP.md`, `MILESTONES.md` and
`research/index.md`. `HEAD` equals `origin/main`; the functional tree matches
the manifest pin; the pinned `standard-new` checkout is clean; and the result,
trace and recorded input hashes agree. The runner checks the committed
negative-control gate, canonicalizes the semantic-items fixture, rejects all
12 mutations and records the toolchain and environment.

The focused review remains bounded to the C731 delivery contract. It does not
promote a general semantic fact or close full M3. No reproducibility or
integration issue remains.

Reproduce the primary result with:

```text
M3_C731_EXPECTED_CENTRAL_COMMIT=94c71ec785ece8927a98a34a17e02aa452df1528 tests/e2e/run-m3-c731.sh --fresh
```
