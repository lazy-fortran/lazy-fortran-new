# E0101 report

## Result

The harness/package gate passed. It packages E0100's 46 ambiguous-candidate
and 81 no-candidate rows with retained normative spans and provenance, and its
strict validator rejects unsupported citations and uncited alias relations.

`model_calls=0`. Execution was blocked because the E0100 cache inputs and an
explicit `MODEL_RUNNER` are absent. No model result is claimed: the evidence
here is limited to harness behavior, package structure, and negative tests.

No adjudication was performed or claimed, and no alias was promoted into
StandardIR.

## Regeneration and checks

From the repository root, the exact local gate command is:

```sh
bash -n research/experiments/E0101-can-a-strictly-cited-model-resolve-e0100/analyse.sh research/experiments/E0101-can-a-strictly-cited-model-resolve-e0100/test.sh && research/experiments/E0101-can-a-strictly-cited-model-resolve-e0100/test.sh
```

With the pinned E0100 cache inputs available, package regeneration is:

```sh
research/experiments/E0101-can-a-strictly-cited-model-resolve-e0100/analyse.sh "$OUTDIR"
```

where `OUTDIR` is the desired run directory. A model validation run additionally
requires `MODEL_RUNNER`; absent that variable, the harness makes no call and
writes an execution-blocker record.
