# M3 C750 bounded component-array deferred-shape oracle

Replay status: `PASS`; source review passed, and the reproducibility review is
pending after the evidence packet was re-frozen. C750 is not promoted as a
durable M3 leaf until that review passes. The complete M3/Core 0 claim remains
`OPEN`.
This artifact does not claim a Fortran parser, name resolver, general semantic
analyzer or compiler completeness.

## Source contract

D0159 selects the C750 relation over the pinned J3-24-007 source. The exact
normative occurrence is canonical lines 3838--3839, printed page 79, and byte
span `241058:135`. The span is contained by canonical page-index record 93
(`start 239957`, `length 2451`). The reusable StandardIR witnesses are
R737 (`data-component-def-stmt`) and R740 (`component-array-spec`).

The typed candidate fields are:

```text
pointer-or-allocatable-attribute: absent | present | unknown
component-array-spec: deferred-shape-list | explicit-shape-list | unknown
context: component-def-stmt | other | unknown
```

The deterministic oracle accepts present + deferred-shape-list in a
component-def-stmt, rejects present + explicit-shape-list in that context, and
returns `UNRESOLVED` for every remaining state. It does not inspect actual
declarations, decide whether a real component array is deferred, parse
component definitions, or check C751/C754.

## Replay

The exact clean command is:

```text
M3_C750_EXPECTED_CENTRAL_COMMIT=7c0bf9740450f26d6bcf879c4a980c7e0d58ce6c tests/e2e/run-m3-c750.sh --fresh
```

It passed as E0218/R000004. The central worktree was
`7c0bf9740450f26d6bcf879c4a980c7e0d58ce6c`; the functional tree matched
manifest pin `474ad0c`; and standard-new was
`f94c4c51b51fce22b533b7eeda08741970320913`. The result and committed trace
are byte-identical with SHA-256
`026f59e792809db1aa5e466e0ed8086e1c1922f8ee4a3cbe302db8d82c85d2c0`. The
run-environment record has SHA-256
`59bf6fc7e6e54121a40c1eb45db864345bddc681608f91addd41095e4f26a12e`.

The complete 27-state product has 1 `ACCEPTED`, 1 `REJECTED` and 25
`UNRESOLVED` outcomes. Twelve source, page-index, StandardIR, contract and
semantic-identity mutation controls are rejected. Model calls and semantic
promotions are both zero.

## Evidence

The independent expected-outcome table is
`tests/fixtures/m3-c750-expected-outcomes-v0.json` with SHA-256
`694c5b8312853cef1fa232662e53a0a13e4829cfc0c654b5129e62f51a2e8095`.
The source-backed fixture is
`tests/fixtures/m3-c750-source-backed-v0.json` with SHA-256
`0d0ed8864c86df9d8de3dfb3bf7c825a67c9fa8d7d699065c60ccdb53c9f2d45`.
The independent validator is
`tests/e2e/validate_m3_c750.py` with SHA-256
`d5061c8517d7d07153c41cf384077fcbcf464279ed5b2e24584fcd28b26ebad3`.
The committed trace is `artifacts/traces/m3-c750-source-backed-v0.json`.

## Non-claims

This bounded leaf does not accept arbitrary Fortran source, perform lexical or
grammar parsing, resolve names, validate actual POINTER or ALLOCATABLE
declarations, infer array shape from source, check C751 or C754, restart E0172,
or close full M3.
