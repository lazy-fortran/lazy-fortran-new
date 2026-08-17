# M3 C745 bounded SEQUENCE component-presence oracle

Replay status: `PASS`; focused review is pending. Full M3 remains `OPEN`.
This artifact promotes no semantic fact and does not claim a Fortran parser.

## Contract

The contract binds J3-24-007 C745 to canonical lines 3665--3667, printed page
89 and UTF-8 byte span `232141:276`. Its existing StandardIR witnesses are
R726 (`derived-type-def`), R731 (`sequence-stmt`) and R735
(`component-part`). The typed candidate product is:

```text
SEQUENCE presence: absent | present | unknown
component presence: zero | one-or-more | unknown
context: derived-type-def | other | unknown
```

The human-authored table
`tests/fixtures/m3-c745-expected-outcomes-v0.json`, SHA-256
`466689895dbd4d6b12df43498a69bd85c81382903ecbc2871df161b2c4b533dd`, is the
independent behavioral oracle. The validator computes the relation and
compares it with that table. It covers all 27 states, four accepted
witnesses, one negative neighbour, 22 unresolved controls and twelve source,
page, StandardIR and contract-identity mutations. Every mutation is
rejected.

## Authoritative replay

Regenerate the active milestone and its C745 dispatch with:

```text
scripts/verify_active_milestone.sh
```

The authoritative replay is `E0208/R000010`, recorded as `R000556`, from
control-plane revision `2b9317c9afd8cea1ce6cb14c8c945f2b3742041c`. Its result
and committed trace both have SHA-256
`06f2c26c5c051d24229e09215b8a31dffe481a06c41bd57c542a282de3e0247f`; its
run environment has SHA-256
`2f39fcb13d5094295c858c30ac5460a3225193ce39022d08effe2dead0a61ef7`.
The replay records 4 `ACCEPTED`, 1 `REJECTED`, 22 `UNRESOLVED`, twelve
rejected mutation controls, zero model calls and zero semantic promotions.

The functional revision is
`06b4382072f8af49f16368c7cb57631accec8f1e`; `standard-new` is pinned at
`f94c4c51b51fce22b533b7eeda08741970320913`. The validator SHA-256 is
`60a9b53f8d953d13f6a0db114be964e50050e49eac9fcd6b1c4478a42de5c68a`; the
source fixture SHA-256 is
`c673bfabad68bde8544f1fead5845b21326d76cf0bad44a226b598be1f61e71f`.

The pinned canonical text, page index, StandardIR and normative PDF hashes
are respectively
`1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e`,
`49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929`,
`106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2` and
`7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2`.

R000543--R000555 and focused-review R000548--R000550 retain the missing-trace,
pin, self-consistency, trace-refresh, evidence-handoff and stale-linkage
failures. None is deleted or rewritten.

## Scope and non-claims

The oracle checks only this typed projection of C745. It does not parse a
derived-type definition, count real components, classify component types,
inspect type parameters or type-bound procedures, diagnose invalid Fortran,
promote a semantic fact, restart E0172, or close full M3. It is a bounded
source-backed oracle delivery, not arbitrary user-Fortran compilation.
