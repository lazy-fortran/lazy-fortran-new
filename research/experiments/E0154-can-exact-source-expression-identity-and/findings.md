# E0154 current state

The baseline remains intentionally failing. The current exports carry source
rule, location and lineage comments, but not an independently recomputable
identity for the exact RHS alternative. Run the checker with:

```text
research/experiments/E0154-can-exact-source-expression-identity-and/analyse.sh \
  .cache/runs/E0154/R000001 \
  .cache/runs/E0147/R000022/input/standardir.sx
```

The checker recomputes SHA-256 over the canonical SX serialization of each
source RHS alternative, distinguishes repeated rule occurrences by byte span,
checks all four generated formats, and requires a mutation to fail. It is an
independent identity witness, not yet a language-equivalence or parser-runtime
witness. The baseline is expected to report missing expression fields until
the corresponding generic production slice is merged.
