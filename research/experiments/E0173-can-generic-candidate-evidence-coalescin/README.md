# E0173 — Generic candidate-evidence coalescing

This experiment separates candidate-evidence identity from structural-boundary
identity for the selected E0171 witness. It is the D0119 subgate before target
separator insertion. The coalescer keeps one representative site and writes a
sidecar row for every contributing candidate derivation.

Run the deterministic cell once with:

```text
research/experiments/E0173-can-generic-candidate-evidence-coalescin/run.sh \
  .cache/runs/E0173/R000001
```

Validate it with:

```text
research/experiments/E0173-can-generic-candidate-evidence-coalescin/analyse.sh \
  .cache/runs/E0173/R000001
```

The frozen input is `.cache/runs/E0171/R000435-correspondence-replay/candidates.tsv`.
The result is limited to identity accounting and the existing correspondence
trace. It does not enable target insertion, parser behavior, or semantic work.
