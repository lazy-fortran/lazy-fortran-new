# Frozen C751 focused-review packet v2

This packet is an independent review of the bounded claim below. Do not read
or use any prior review report, review run, current STATUS/TASK_POOL wording,
or any later conclusion. In particular, do not inspect `R000600` or
`m3-c751-focused-review-v1.md`; those are outside this packet.

Claim under review: `M3-C751-bounded-oracle`.

```text
leaf_id: T-M3-c751-coarray-allocatable-oracle
claim_id: M3-C751-bounded-oracle
parent_id: M3
revision: bf17ff2193322677dcd631459380f7c3a7f446fb
```

Review only these frozen-revision paths and pinned inputs:

```text
contracts/m3-c751-coarray-allocatable-v0.sxs
contracts/fixtures/m3-c751-coarray-allocatable-v0.sx
tests/e2e/run-m3-c751.sh
tests/e2e/validate_m3_c751.py
tests/fixtures/m3-c751-source-backed-v0.json
tests/fixtures/m3-c751-expected-outcomes-v0.json
tests/fixtures/m3-c751-semantic-items.sx
tests/golden/m3-c751-semantic-items.sx
artifacts/traces/m3-c751-source-backed-v0.json
.cache/runs/E0220/R000002/result.json
.cache/runs/E0220/R000002/run-environment.json
.cache/runs/E0001/R000003/j3-24-007.canonical.txt
.cache/runs/E0001/R000003/j3-24-007.pages.index
.cache/runs/E0171/R000433-provenance-replay/standardir.sx
.cache/j3-24-007.pdf
```

The exact verifier command recorded by the frozen run is:

```text
M3_C751_EXPECTED_CENTRAL_COMMIT=bf17ff2193322677dcd631459380f7c3a7f446fb tests/e2e/run-m3-c751.sh --fresh
```

The bounded claim is this typed relation over an already represented data
component context: absent `coarray-spec` is `ACCEPTED`; deferred-coshape with
ALLOCATABLE present is `ACCEPTED`; deferred-coshape without ALLOCATABLE is
`REJECTED`; every explicit-coshape is `REJECTED`; unknown states are
`UNRESOLVED`. The frozen replay has 12 states, 12 rejected mutations, zero
model calls and zero semantic promotions.

Check source binding, oracle independence and counterexamples,
reproducibility, clean-state behavior, and scope discipline. Explicit
exclusions are arbitrary Fortran parsing, declaration semantics, name
resolution, C752/C754 inspection, compiler implementation, broad M3
promotion and model-based semantic promotion.

Do not edit files, create or delete temporary clones, run model experiments,
or promote the claim. Return exactly:

```text
Verdict: PASS | NEEDS FIX | INVALID
First fatal issue: [none if PASS; otherwise one exact issue]
Evidence: [path, command output, counterexample or dependency]
Required correction: [one minimal corrective action]
```
