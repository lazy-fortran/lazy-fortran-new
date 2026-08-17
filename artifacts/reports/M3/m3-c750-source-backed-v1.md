# M3 C750 bounded component-array deferred-shape oracle v1

Replay status: `PASS`; the focused independent review and evidence gate pass.
C750 is promoted only as a bounded M3 leaf. Full M3/Core 0 remains `OPEN`.

## Source contract

D0159 selects the C750 relation over pinned J3-24-007 clause 7. The normative
occurrence is canonical lines 3838--3839, printed page 79, byte span
`241058:135`, contained by page-index record 93 (`start 239957`, `length
2451`). The reusable StandardIR witnesses are R737
(`data-component-def-stmt`) and R740 (`component-array-spec`).

The typed candidate fields are:

```text
pointer-or-allocatable-attribute: absent | present | unknown
component-array-spec: deferred-shape-list | explicit-shape-list | unknown
context: component-def-stmt | other | unknown
```

The deterministic oracle accepts present + deferred-shape-list in a
component-def-stmt, rejects present + explicit-shape-list there, and returns
`UNRESOLVED` for every remaining state. No model output can promote a semantic
fact.

## Replay and review

The clean replay was executed at central revision
`7c0bf9740450f26d6bcf879c4a980c7e0d58ce6c` with:

```text
M3_C750_EXPECTED_CENTRAL_COMMIT=7c0bf9740450f26d6bcf879c4a980c7e0d58ce6c tests/e2e/run-m3-c750.sh --fresh
```

It passed as E0218/R000004 and is recorded in R000596. The result and
committed trace are byte-identical with SHA-256
`026f59e792809db1aa5e466e0ed8086e1c1922f8ee4a3cbe302db8d82c85d2c0`. The
run-environment SHA-256 is
`59bf6fc7e6e54121a40c1eb45db864345bddc681608f91addd41095e4f26a12e`.

The complete 27-state product has 1 `ACCEPTED`, 1 `REJECTED` and 25
`UNRESOLVED` outcomes. Twelve source, page-index, StandardIR, contract and
semantic-identity mutations are rejected. Model calls and semantic promotions
are zero. The focused review and evidence gate are recorded in R000597 and
`artifacts/reports/M3/m3-c750-focused-review-v1.md`; both independent review
lanes pass the frozen packet.

## Evidence and non-claims

The expected-outcome table is
`tests/fixtures/m3-c750-expected-outcomes-v0.json`; the source-backed fixture
is `tests/fixtures/m3-c750-source-backed-v0.json`; the independent validator
is `tests/e2e/validate_m3_c750.py`; and the committed trace is
`artifacts/traces/m3-c750-source-backed-v0.json`.

This bounded leaf does not accept arbitrary Fortran source, perform lexical or
grammar parsing, resolve names, validate real POINTER or ALLOCATABLE
declarations, infer array shape from source, check C751 or C754, restart E0172,
or close full M3.
