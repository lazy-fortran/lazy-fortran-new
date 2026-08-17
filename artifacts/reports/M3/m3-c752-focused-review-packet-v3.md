# Frozen C752 focused-review packet v3

Claim under review: `M3-C752-bounded-oracle`.

Review this packet independently. Do not read `STATUS.md`, `TASK_POOL.yaml`,
the C752 selection report, v1/v2 review reports, or the controller's current
working-tree state. Do not edit the controller checkout, create a model run,
or promote a semantic fact.

## Frozen revision

The corrected implementation is frozen at central commit
`745190be4183cde6fb04e9468e14622847218a4b`. Inspect exactly these paths at
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
- `research/decisions/D0164-c752-explicit-named-module-type-state.md`

The manifest's central pin `7ba4fdce356cff48bc4763df567774f2d9160c7c` is the
functional-tree pin. This is intentional: the runner records the later
central metadata replay revision separately and checks
`functional_tree_matches_pin`. Do not treat that expected two-revision
relationship as drift; verify the runner's explicit functional-path check.

The fresh integrated replay was:

```text
M3_C752_EXPECTED_CENTRAL_COMMIT=745190be4183cde6fb04e9468e14622847218a4b tests/e2e/run-m3-c752.sh --fresh
```

Its result is `.cache/runs/E0222/R000006/result.json`, SHA-256
`787398d8049d8a04e33c7095aca36bbb241df8ab3583b5e314512a3f46a7459f`.
The committed trace has the same SHA-256. Its environment record is
`.cache/runs/E0222/R000006/run-environment.json`, SHA-256
`9230631c06ead0ffca5db4180facd6a1190bc315e7bb31b1a4f7511625e7066d`.

## Claim and evidence

The bounded property is J3-24-007 C752: if a coarray-spec appears, the
component may not be of type C_PTR or C_FUNPTR from ISO_C_BINDING, or TEAM_TYPE
from ISO_FORTRAN_ENV. The source binding is canonical lines 3842--3844,
printed page 79, byte span `241335:223`, page-index record
`93:239957:2451`, and StandardIR rows R702/R703/R704/R737/R739.

The typed candidate is the product of coarray-spec
`absent|present|unknown` and component type
`C_PTR|C_FUNPTR|TEAM_TYPE|other|named-module-type-unknown`. The explicit
named-module-type-unknown state records that the named module-defined type
identity is not represented directly in the pinned StandardIR. The expected
decision procedure is:

- absent coarray-spec: `ACCEPTED` for every component type;
- present coarray-spec with C_PTR, C_FUNPTR or TEAM_TYPE: `REJECTED`;
- present coarray-spec with other type: `ACCEPTED`;
- present named-module-type-unknown and all unknown coarray-spec states:
  `UNRESOLVED`.

The replay must independently establish 15 states, outcome counts 6
`ACCEPTED`, 3 `REJECTED`, 6 `UNRESOLVED`, thirteen rejected provenance/source
mutation controls including `pdf-hash`, zero model calls and zero semantic
promotions. The validator's decision procedure must not be copied from the
expected JSON and must compare the fixture PDF hash to the fetched PDF digest.

## Required review scopes

Check source and StandardIR provenance, exact byte/page/PDF binding, schema and
fixture closure, the explicit unresolved named-module-type state, the
independent expected-outcome table and oracle, all mutation controls, the fresh
run cleanliness and trace comparison, the functional-tree pin relationship,
and the scope exclusions. A reviewer may run
`python3 tests/e2e/validate_m3_c752.py --self-test` and reproduce the fresh
command in an isolated checkout at the frozen revision.

This review covers only the bounded C752 oracle. It does not assess general
Fortran parsing, name resolution, C753/C754, full M3, or semantic promotion.

Return exactly:

```text
Verdict: PASS | NEEDS FIX | INVALID
Evidence: <specific files, commands, and observations>
Required correction: <one correction, or NONE>
```
