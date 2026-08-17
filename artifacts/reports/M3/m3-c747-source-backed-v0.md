# M3 C747 bounded type-parameter-name exact-once oracle

Bounded-slice status: `PASS`; C747 is promoted only as this bounded oracle
leaf. Full M3 remains `OPEN`. This artifact does not claim a Fortran parser,
name resolver or complete semantic analyzer.

## Source contract

The contract is D0153 as amended by D0154. It binds J3-24-007 clause 7, C747, canonical lines
3766--3767, printed page 77, UTF-8 byte span `237572:183`, and canonical
page-index record 91 (`start 235554`, `length 2214`) to StandardIR R727
(`derived-type-stmt`), R732 (`type-param-def-stmt`) and R733
(`type-param-decl`). The normative source text says that each type-param-name
in the derived-type-stmt of a derived-type-def shall appear exactly once in a
type-param-def-stmt in that derived-type-def. The validator independently
requires the byte span to be contained by that page-index record; printed page
77 and canonical page-index page 91 are recorded separately.

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
M3_C747_EXPECTED_CENTRAL_COMMIT=<current-commit> tests/e2e/run-m3-c747.sh --fresh
```

It passed in E0212/R000006 with central worktree revision
`7a762f55b1f435799a21ab80a95f3db4ba4bf860`, functional tree pinned at
`bffd7c208956bb8a231712ead6e1fef243ec3887`, and `standard-new` at
`f94c4c51b51fce22b533b7eeda08741970320913`. The recorded result and committed
trace both have SHA-256
`eb9a72073eb3cf4a5a1b5e81574d6257c683af4d6dce41db245ac4b0fe2283c1`.
The run environment has SHA-256
`fc92a469313fa1bddf7858a0eec028bfc9c8a9617a42f5a38aae68d811efa5e3`.

The independent validator has SHA-256
`78caf3130cd0f12d87b4d7d328bb846ccab1656069863ae875d69676016d446c`. The
36-state typed product has 5 `ACCEPTED`, 2 `REJECTED` and 29 `UNRESOLVED`
outcomes. Twelve source, page-index, StandardIR, contract and semantic-identity
mutation controls are rejected. Model calls and semantic promotions are both
zero.

## Evidence

The independent expected-outcome table is
`tests/fixtures/m3-c747-expected-outcomes-v0.json` with SHA-256
`fc2d31361b99e523dd4e2ec32de91e528ec40f41aac5244e3611f9571c5a34ce`. The
source-backed fixture is
`tests/fixtures/m3-c747-source-backed-v0.json` with SHA-256
`fb29976c5155f23ba0fbab0c516bfaf99b0a2bbe7888070279427ae97b76ef1a`.
The committed trace is `artifacts/traces/m3-c747-source-backed-v0.json`.

## Non-claims

This leaf does not check extra definition names, which remains outside this
leaf's scope, does not perform case folding or name resolution, does not
diagnose arbitrary Fortran, does not restart E0172 and does not close full M3.
