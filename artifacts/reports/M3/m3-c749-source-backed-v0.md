# M3 C749 bounded component-type eligibility oracle

Replay status: `PASS` for the bounded leaf; promotion remains pending the
focused independent review. The complete M3/Core 0 claim remains `OPEN`.
This artifact does not claim a Fortran parser, name resolver, general semantic
analyzer or compiler completeness.

## Source contract

D0157 selects the C749 relation over the pinned J3-24-007 source. The exact
normative occurrence is canonical lines 3835--3837, printed page 79, and byte
span `240824:234`. The span is contained by canonical page-index record 93
(`start 239957`, `length 2451`). The reusable StandardIR witnesses are
R703 (`declaration-type-spec`) and R737
(`data-component-def-stmt`).

The typed candidate fields are:

```text
pointer-or-allocatable-attribute: absent | present | unknown
declaration-type-category: intrinsic | previously-defined-derived | enum |
  enumeration | other | unknown
context: component-def-stmt | other | unknown
```

The deterministic oracle accepts the four allowed type categories when the
attribute is absent in a component-def-stmt, rejects the same context with
the `other` category, and returns `UNRESOLVED` for every remaining state.
It does not inspect actual declarations, resolve named types, parse component
definitions, or check C750/C751.

## Replay

The exact clean command is:

```text
M3_C749_EXPECTED_CENTRAL_COMMIT=20ef900b18e16009f4aa5b3d8fb7dc8ea7f7699c tests/e2e/run-m3-c749.sh --fresh
```

It passed as E0216/R000006. The central worktree was
`20ef900b18e16009f4aa5b3d8fb7dc8ea7f7699c); the functional tree matched
manifest pin `9c26f1ebab90864f08d8fa191601d18d97f6c71e`; and standard-new was
`f94c4c51b51fce22b533b7eeda08741970320913). The result and committed trace
are byte-identical with SHA-256
`4ad1c0d77479c7904cebfb9da2153d118dcd29370394c359c0805618e1890aa3`. The
run-environment record has SHA-256
`777e21e3d74b2d68b13bef65d662ab5ed5232291e900392d34f150ca874df667`.

The 54-state product has 4 `ACCEPTED`, 1 `REJECTED` and 49
`UNRESOLVED` outcomes. Twelve source, page-index, StandardIR, contract and
semantic-identity mutation controls are rejected. Model calls and semantic
promotions are both zero.

## Evidence

The independent expected-outcome table is
`tests/fixtures/m3-c749-expected-outcomes-v0.json` with SHA-256
`d06f0aa7ecfa2097e0daf5d1c03c2ed36160c7aa17d4c83c1d849185b6e855b1`.
The source-backed fixture is
`tests/fixtures/m3-c749-source-backed-v0.json` with SHA-256
`bdf7f6c22850abd4ad442a6ad4c790660e6fedfa47e9feea5431da52f7f08ea2`.
The independent validator is
`tests/e2e/validate_m3_c749.py` with SHA-256
`6aaa30c862948c67cfa65aec2458e0638574c749a80c48fc00200a3093d203d0`.
The committed trace is `artifacts/traces/m3-c749-source-backed-v0.json`.

The retained failed attempts R000583--R000588 record runner permission,
functional-pin, fixture-hash and trace-bootstrap defects. None produced a
semantic promotion; the fresh R000006 replay is the first complete passing
gate.

## Non-claims

This bounded leaf does not accept arbitrary Fortran source, perform lexical or
grammar parsing, resolve names, validate actual POINTER or ALLOCATABLE
declarations, infer whether a derived type was previously defined, check C750
or C751, restart E0172, or close full M3.
