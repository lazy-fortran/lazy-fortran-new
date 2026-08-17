# Frozen C752 focused-review packet

Claim under review: `M3-C752-bounded-oracle`.

Review this packet independently. Do not read `STATUS.md`, `TASK_POOL.yaml`,
the C752 selection report, prior review reports, or the controller's current
working-tree state. Do not edit the controller checkout, create a model run,
or promote a semantic fact.

## Frozen revision

The implementation and committed trace are frozen at central commit
`28b8b062e0bec958a51974ecadebd082c7bd3c7e`. Inspect exactly these paths at
that revision:

- `contracts/registry.sx`
- `contracts/m3-c752-forbidden-coarray-type-v0.sxs`
- `contracts/fixtures/m3-c752-forbidden-coarray-type-v0.sx`
- `tests/e2e/validate_m3_c752.py`
- `tests/e2e/run-m3-c752.sh`
- `tests/fixtures/m3-c752-source-backed-v0.json`
- `tests/fixtures/m3-c752-expected-outcomes-v0.json`
- `tests/fixtures/m3-c752-semantic-items.sx`
- `tests/golden/m3-c752-semantic-items.sx`
- `artifacts/traces/m3-c752-source-backed-v0.json`
- `research/experiments/E0222-c752-forbidden-coarray-type-oracle/manifest.yaml`

The fresh integrated replay was:

```text
M3_C752_EXPECTED_CENTRAL_COMMIT=28b8b062e0bec958a51974ecadebd082c7bd3c7e tests/e2e/run-m3-c752.sh --fresh
```

Its result is `.cache/runs/E0222/R000004/result.json`, SHA-256
`9a00a854ef4dfefa7d841c45ec65ff9b520d7a72723cbbfb8b5afe229af42156`.
The committed trace has the same SHA-256. Its environment record is
`.cache/runs/E0222/R000004/run-environment.json`, SHA-256
`065f16bc83c689ed0f296d09581a9b7465c4e3de9c92ff9ef6ce9fd6b98b2b9b`.

## Claim and evidence

The bounded property is J3-24-007 C752: if a coarray-spec appears, the
component may not be of type C_PTR or C_FUNPTR from ISO_C_BINDING, or TEAM_TYPE
from ISO_FORTRAN_ENV. The source binding is canonical lines 3842--3844,
printed page 79, byte span `241335:223`, page-index record
`93:239957:2451`, and StandardIR rows R702/R703/R704/R737/R739.

The typed candidate is the product of coarray-spec
`absent|present|unknown` and component type
`C_PTR|C_FUNPTR|TEAM_TYPE|other|unknown`. The expected decision procedure is:

- absent coarray-spec: `ACCEPTED` for every component type;
- present coarray-spec with C_PTR, C_FUNPTR or TEAM_TYPE: `REJECTED`;
- present coarray-spec with other type: `ACCEPTED`;
- all remaining unknown states: `UNRESOLVED`.

The replay must independently establish 15 states, outcome counts 6
`ACCEPTED`, 3 `REJECTED`, 6 `UNRESOLVED`, twelve rejected provenance/source
mutation controls, zero model calls and zero semantic promotions. The
validator's decision procedure must not be copied from the expected JSON.

## Required review scopes

Check source and StandardIR provenance, exact byte/page binding, schema and
fixture closure, the independent expected-outcome table and oracle, all
mutation controls, the fresh-run cleanliness and trace comparison, and the
explicit unresolved boundary for named module-defined types. A reviewer may
run `python3 tests/e2e/validate_m3_c752.py --self-test` and reproduce the
fresh command in an isolated checkout at the frozen revision.

This review covers only the bounded C752 oracle. It does not assess general
Fortran parsing, name resolution, C753/C754, full M3, or semantic promotion.

Return exactly:

```text
Verdict: PASS | NEEDS FIX | INVALID
Evidence: <specific files, commands, and observations>
Required correction: <one correction, or NONE>
```
