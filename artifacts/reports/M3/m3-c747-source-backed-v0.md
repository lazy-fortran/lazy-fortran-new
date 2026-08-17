# M3 C747 bounded type-parameter-name exact-once oracle

Bounded-slice status: `PASS`; C747 is promoted only as this bounded oracle
leaf. Full M3 remains `OPEN`. This artifact does not claim a Fortran parser,
name resolver or complete semantic analyzer.

## Source contract

The contract is D0153. It binds J3-24-007 clause 7, C747, canonical lines
3766--3767, printed page 77, UTF-8 byte span `237572:183`, to StandardIR
R727 (`derived-type-stmt`), R732 (`type-param-def-stmt`) and R733
(`type-param-decl`). The normative source text says that each type-param-name
in the derived-type-stmt of a derived-type-def shall appear exactly once in a
type-param-def-stmt in that derived-type-def.

The typed candidate fields are:

```text
derived-name-presence: absent | present | unknown
definition-occurrence-cardinality: zero | one | many | unknown
context: derived-type-def | other | unknown
```

The deterministic oracle accepts every absent derived-name state in
derived-type-definition context, accepts present/one, rejects present/zero and
present/many, and returns `UNRESOLVED` for all other states. This is a bounded
typed relation. It does not inspect actual identifier spellings or parse a
derived-type definition.

## Replay

The clean central verifier is:

```text
tests/e2e/run-m3-c747.sh --fresh
```

It passed in E0212/R000002 with central worktree revision
`cb2e8f1d240a69938d0d7e90b814ccef5d5d6a2f`, functional tree pinned at
`749f438fe5e11c83ffab21f4b0d2a2486ed284f6`, and `standard-new` at
`f94c4c51b51fce22b533b7eeda08741970320913`. The recorded result and committed
trace both have SHA-256
`acd7bafed6987a65655c3af32a2836619164e754b029e0f8dc53c5a7922c5e30`.
The run environment has SHA-256
`c9d76f3ca9842075416e5713c81814af349b47cefb1a02f93d30948d8cd25a80`.

The independent validator has SHA-256
`432c9b64618e5c899d1df09b7fc7a606abc88c83517ddbe681d7a02123297acc`. The
36-state typed product has 5 `ACCEPTED`, 2 `REJECTED` and 29 `UNRESOLVED`
outcomes. Twelve source, StandardIR, contract and semantic-identity mutation
controls are rejected. Model calls and semantic promotions are both zero.

## Evidence

The independent expected-outcome table is
`tests/fixtures/m3-c747-expected-outcomes-v0.json` with SHA-256
`fc2d31361b99e523dd4e2ec32de91e528ec40f41aac5244e3611f9571c5a34ce`. The
source-backed fixture is
`tests/fixtures/m3-c747-source-backed-v0.json` with SHA-256
`5f8102f757d4e1ec7f0a53579c7cfd7053b43bebe1bc7cd64d2ec04e605f5dc1`.
The committed trace is `artifacts/traces/m3-c747-source-backed-v0.json`.

## Non-claims

This leaf does not check extra definition names, which remains outside this
leaf's scope, does not perform case folding or name resolution, does not
diagnose arbitrary Fortran, does not restart E0172 and does not close full M3.
