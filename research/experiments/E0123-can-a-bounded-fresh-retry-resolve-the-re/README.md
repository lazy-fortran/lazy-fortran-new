# E0123: fresh bounded retry of residual semantic rows

E0123 retries only the 53 E0117 rows that ended `unresolved` or
`hard_failure`. It keeps the 234 other rows as immutable predecessor controls,
starts each retry as a fresh episode, requests thinking off first, and permits
one fresh thinking-on episode after failure. Required witness maps, source
evidence, schema validation and row-key merging remain deterministic gates.

The runtime is the verified upstream llama.cpp master build recorded in the
manifest. The service must be healthy before the run is launched; its health
check and exact version output belong in the run record.

Planned run shape:

```sh
research/experiments/E0116-can-bounded-qwen-semantic-proposals-clos/run-semantic.py \
  --outdir .cache/runs/E0123/R000001 \
  --retry-from .cache/runs/E0117/R000003-full/rows.jsonl \
  --api-url http://10.77.0.10:8080/v1/chat/completions \
  --require-witnesses --escalate-thinking \
  --max-turns 32 --max-tokens 4096 --finalization-turns 3
```

Run the one-shot preflight first; it refuses a loading/unavailable endpoint or
an unexpected llama.cpp binary:

```sh
research/experiments/E0123-can-a-bounded-fresh-retry-resolve-the-re/preflight.sh
```

The semantic command is not run until this preflight passes.

After the retry completes, merge only the exact predecessor residual set:

```sh
python3 research/experiments/E0116-can-bounded-qwen-semantic-proposals-clos/merge-retry.py \
  .cache/runs/E0117/R000003-full/rows.jsonl \
  .cache/runs/E0123/R000001/rows.jsonl \
  --replace-status unresolved --replace-status hard_failure \
  --outdir .cache/runs/E0123/R000001/merged
```
