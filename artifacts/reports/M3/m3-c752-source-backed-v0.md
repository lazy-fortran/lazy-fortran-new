# C752 source-backed bounded oracle

Status: `PASS-BOUNDED-ONLY`.

The exact replay command was:

```text
M3_C752_EXPECTED_CENTRAL_COMMIT=745190be4183cde6fb04e9468e14622847218a4b tests/e2e/run-m3-c752.sh --fresh
```

It is recorded as `research/runs/2026-08.jsonl#R000615` with run directory
`.cache/runs/E0222/R000006`. The functional tree is pinned by the E0222
manifest to `7ba4fdce356cff48bc4763df567774f2d9160c7c`; the runner separately
records the central metadata revision and checks every functional path against
that pin.

## Source binding

The oracle binds J3-24-007 C752, canonical lines 3842--3844, printed page 79,
byte span `241335:223`, and page-index record `93:239957:2451`. It checks the
normative PDF SHA-256, canonical text SHA-256, page-index SHA-256 and
StandardIR SHA-256. Existing StandardIR rows are R702, R703, R704, R737 and
R739.

## Typed property

The candidate product has 15 states:

```text
coarray-spec:    absent | present | unknown
component type:  C_PTR | C_FUNPTR | TEAM_TYPE | other | named-module-type-unknown
```

The deterministic oracle accepts absent coarray-spec for every type and
present/other; it rejects present C_PTR, C_FUNPTR and TEAM_TYPE; it returns
`UNRESOLVED` for present named-module-type-unknown and every unknown
coarray-spec state. The explicit unresolved state records that the three named
module-defined types are not direct StandardIR rows.

The replay produced 6 `ACCEPTED`, 3 `REJECTED` and 6 `UNRESOLVED` outcomes.
All 13 source/provenance mutation controls, including `pdf-hash`, were
rejected. The result and committed trace both have SHA-256
`787398d8049d8a04e33c7095aca36bbb241df8ab3583b5e314512a3f46a7459f`.
The run recorded zero model calls and zero semantic promotions.

## Review and scope

The focused review and evidence gate pass is `R000616`, with two independent
reviewers; see `artifacts/reports/M3/m3-c752-focused-review-v3.md`.

The lifecycle is:

```text
leaf_id: T-M3-c752-forbidden-coarray-type-oracle
claim_id: M3-C752-bounded-oracle
parent_id: M3
leaf_status: PASS
claim_status: CLOSED
parent_status: OPEN
evidence_gate_verdict: PASS
review_verdict: PASS
```

This promotes only the bounded C752 oracle. It does not promote a semantic
fact, parse arbitrary Fortran, perform name resolution, inspect C753/C754 or
close full M3.
