# Frozen C751 focused-review packet

Claim under review: `M3-C751-bounded-oracle`.

Task identity:

```text
leaf_id: T-M3-c751-coarray-allocatable-oracle
claim_id: M3-C751-bounded-oracle
parent_id: M3
revision: bf17ff2193322677dcd631459380f7c3a7f446fb
```

The exact verifier is:

```text
M3_C751_EXPECTED_CENTRAL_COMMIT=bf17ff2193322677dcd631459380f7c3a7f446fb tests/e2e/run-m3-c751.sh --fresh
```

The replay result is `.cache/runs/E0220/R000002/result.json`; its committed
trace is `artifacts/traces/m3-c751-source-backed-v0.json`. The source-backed
fixture is `tests/fixtures/m3-c751-source-backed-v0.json`, with expected table
`tests/fixtures/m3-c751-expected-outcomes-v0.json`. The normative source,
page index and StandardIR hashes are recorded in the fixture and run
environment.

The bounded claim is only this typed relation over an already represented data
component context: absent `coarray-spec` is `ACCEPTED`; a deferred coshape
with ALLOCATABLE present is `ACCEPTED`; a deferred coshape without ALLOCATABLE
is `REJECTED`; every explicit coshape is `REJECTED`; unknown states are
`UNRESOLVED`. The replay has 12 states, 12 rejected mutations, zero model
calls and zero semantic promotions.

Explicit exclusions: no arbitrary Fortran parsing, no declaration semantics,
name resolution, C752/C754 inspection, compiler implementation, broad M3
promotion or model-based semantic promotion.

Review scopes: source/contract binding, oracle correctness and counterexamples,
reproducibility, clean-state behavior, and scope discipline. Return `PASS`,
`NEEDS FIX`, or `INVALID`, identify the first fatal issue if any, and return
the lifecycle fields separately. Do not edit files, run model experiments, or
promote the claim.
