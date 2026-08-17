# M3 C748 bounded component-attribute exact-once oracle

Bounded-slice status: `PASS`; C748 is eligible for promotion only as this
bounded oracle leaf. Full M3 remains `OPEN`. This artifact does not claim a
Fortran parser, name resolver or complete semantic analyzer.

## Source contract

The contract is D0155. It binds J3-24-007 clause 7, canonical line 3834,
printed page 79, UTF-8 byte span `240727:97`, and canonical page-index record
93 (`start 239957`, `length 2451`) to StandardIR R737
(`data-component-def-stmt`). The normative source text says that no
component-attr-spec shall appear more than once in a component-def-stmt. The
validator independently requires unique byte-span containment by page-index
record 93; the printed page and canonical page-index coordinates are recorded
separately.

The typed candidate fields are:

```text
attribute-name-presence: absent | present | unknown
definition-occurrence-cardinality: zero | one | many | unknown
context: component-def-stmt | other | unknown
```

The deterministic oracle accepts every absent attribute-name state in
component-definition context, accepts present/one, rejects present/zero and
present/many, and returns `UNRESOLVED` for all other states. It does not inspect
actual attribute spellings, parse a component definition, or check C749--C751.

## Replay

The clean central verifier is:

```text
M3_C748_EXPECTED_CENTRAL_COMMIT=<current-commit> tests/e2e/run-m3-c748.sh --fresh
```

It passed in E0214/R000001 with central worktree revision
`c4b4e29fd275534ed5df57b8a5678592c9324b60`, functional tree pinned at
`8a124949318a6dda5abb3d33d85cb3c93c8ca946`, and `standard-new` at
`f94c4c51b51fce22b533b7eeda08741970320913`. The recorded result and committed
trace both have SHA-256
`e39ab5b86c284dda776c716dbe2a30699e23b061de1caee1788df518ad7386d2`.
The run environment has SHA-256
`fe176ec3ec61b3dc9863943178064360dc958896953015b995387d2aab755502`.

The independent validator has SHA-256
`c1bcb0d5f5d8a52d1f67caaa1fce41a51a37a1b96686077b6858d3823cba29f1`. The
36-state typed product has 5 `ACCEPTED`, 2 `REJECTED` and 29 `UNRESOLVED`
outcomes. Twelve source, page-index, StandardIR, contract and semantic
identity mutation controls are rejected. Model calls and semantic promotions
are both zero.

## Evidence

The independent expected-outcome table is
`tests/fixtures/m3-c748-expected-outcomes-v0.json` with SHA-256
`f8505cbe46fa7e0fc937a170d99a6db4e1c39fc36210f686041188990cbf90d3`. The
source-backed fixture is
`tests/fixtures/m3-c748-source-backed-v0.json` with SHA-256
`26290cd4d4bf664d9127a0b257b0a0937dda3cc894bf50385450e2ca1d5cb1d5`.
The committed trace is `artifacts/traces/m3-c748-source-backed-v0.json`.

## Non-claims

This leaf does not check C749 through C751, perform case folding or name
resolution, diagnose arbitrary Fortran, restart E0172 or close full M3.
