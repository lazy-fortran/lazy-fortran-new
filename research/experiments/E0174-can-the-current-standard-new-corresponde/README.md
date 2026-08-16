# E0174 — Current correspondence replay

This experiment replays the source-boundary mapper and correspondence witness
at the pinned current `standard-new` commit after the E0173 candidate-evidence
coalescing subgate. It is a deterministic source/target relation check. It does
not enable target separator insertion or semantic/model work.

Run the cell once:

```text
research/experiments/E0174-can-the-current-standard-new-corresponde/run.sh \
  .cache/runs/E0174/R000001
```

Validate it with:

```text
research/experiments/E0174-can-the-current-standard-new-corresponde/analyse.sh \
  .cache/runs/E0174/R000001
```

For an iteration that keeps the same pinned `standard-new` revision and trace
inputs, pass a verified prior run as the second argument. The wrapper checks
the exact input manifest and reuses a machine-readable PASS record for the
exact-commit component gate, `fortran2023.y`, and `correspondence.jsonl`; the
source-boundary mapper and evidence coalescer still run:

```text
research/experiments/E0174-can-the-current-standard-new-corresponde/run.sh \
  .cache/runs/E0174/R000011 .cache/runs/E0174/R000010
```

Each run also records `run-environment.json`, including the exact `fo`
executable hash, toolchain versions, oracle hashes and clean checkout states.
The cold run remains the reproducibility authority; reuse runs are only
iteration controls.
