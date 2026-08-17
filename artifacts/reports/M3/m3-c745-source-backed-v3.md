# M3 C745 bounded SEQUENCE component-presence oracle

Bounded-slice status: `PASS`; C745 is promoted only as this bounded oracle
leaf. Full M3 remains `OPEN`. This artifact does not claim a Fortran parser or
general semantic analysis.

## Contract and result

The contract binds J3-24-007 C745 to canonical lines 3665--3667, printed page
89 and UTF-8 byte span `232141:276`, over existing StandardIR witnesses R726
(`derived-type-def`), R731 (`sequence-stmt`) and R735 (`component-part`). Its
typed candidate product is:

```text
SEQUENCE presence: absent | present | unknown
component presence: zero | one-or-more | unknown
context: derived-type-def | other | unknown
```

The human-authored table
`tests/fixtures/m3-c745-expected-outcomes-v0.json`, SHA-256
`466689895dbd4d6b12df43498a69bd85c81382903ecbc2871df161b2c4b533dd`, is the
independent behavioral oracle. The validator computes the relation and
compares it with that table. The complete product has 27 states: 4
`ACCEPTED`, 1 `REJECTED`, 22 `UNRESOLVED`; twelve source, page, StandardIR
and contract-identity mutations are rejected. The replay performs zero model
calls and zero semantic promotions.

## Authoritative evidence

The active milestone command is:

```text
scripts/verify_active_milestone.sh
```

The authoritative replay is `E0208/R000010`, recorded as `R000556`, from
control-plane revision `2b9317c9afd8cea1ce6cb14c8c945f2b3742041c`. Its result
and committed trace both have SHA-256
`06f2c26c5c051d24229e09215b8a31dffe481a06c41bd57c542a282de3e0247f`; its
run environment has SHA-256
`2f39fcb13d5094295c858c30ac5460a3225193ce39022d08effe2dead0a61ef7`.
The focused review is `R000560`, and both independent review lanes pass.

The functional revision is
`06b4382072f8af49f16368c7cb57631accec8f1e`; `standard-new` is pinned at
`f94c4c51b51fce22b533b7eeda08741970320913`. The validator SHA-256 is
`60a9b53f8d953d13f6a0db114be964e50050e49eac9fcd6b1c4478a42de5c68a`; the
source fixture SHA-256 is
`c673bfabad68bde8544f1fead5845b21326d76cf0bad44a226b598be1f61e71f`.

The broader M3 residual remains 147 rows, 84 disputed and 63 unwitnessed,
until a post-C745 reconciliation is run. R000543--R000559 remain retained,
including the failed replay/review history and the parseable-ledger
correction. The raw malformed predecessor is retained at
`research/runs/archive/2026-08.jsonl.raw`.

## Non-claims

This leaf does not parse a derived-type definition, count real components,
classify component types, inspect type parameters or type-bound procedures,
diagnose invalid Fortran, restart E0172, or close full M3. It is a bounded
source-backed oracle delivery, not arbitrary user-Fortran compilation.
