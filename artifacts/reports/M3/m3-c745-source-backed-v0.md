# M3 C745 bounded SEQUENCE component-presence oracle

Replay status: `PASS`; focused review is pending. Full M3 remains `OPEN`.
This artifact does not claim a Fortran parser, a semantic analyzer, or a
promotion of the retained C745 row.

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

The human-authored expected-outcome table
`tests/fixtures/m3-c745-expected-outcomes-v0.json` is the independent
behavioral oracle. In `derived-type-def`, absent SEQUENCE is `ACCEPTED`,
present SEQUENCE with one or more components is `ACCEPTED`, and present
SEQUENCE with zero components is `REJECTED`. Every other typed state is
`UNRESOLVED`. The validator computes the relation independently and compares
it with that table. It covers all 27 states, four accepted witnesses, one
negative neighbour, 22 unresolved controls and twelve source, page, StandardIR
and contract-identity mutations. Every mutation is rejected.

## Replay

The exact clean-checkout command is:

```text
M3_C745_EXPECTED_CENTRAL_COMMIT=ed172bad35dc758cd5490c7440a9039a93f115d5 tests/e2e/run-m3-c745.sh --fresh
```

The final replay is `E0208/R000005`, recorded as `R000547`. Its result matches
the committed trace byte-for-byte. Both have SHA-256
`06f2c26c5c051d24229e09215b8a31dffe481a06c41bd57c542a282de3e0247f`; the run
environment has SHA-256
`b6c52f18a80da351c1927a1668f4d0cacf9fbec1d5ce30e30a5db31e6ac831a4`.
The replay records 4 `ACCEPTED`, 1 `REJECTED`, 22 `UNRESOLVED`, twelve
rejected mutation controls, zero model calls and zero semantic promotions.

The central replay revision is
`ed172bad35dc758cd5490c7440a9039a93f115d5`; the functional revision pinned by
E0208 is `06b4382072f8af49f16368c7cb57631accec8f1e`; and the pinned
`standard-new` revision is `f94c4c51b51fce22b533b7eeda08741970320913`. The
validator SHA-256 is
`60a9b53f8d953d13f6a0db114be964e50050e49eac9fcd6b1c4478a42de5c68a`; the
source fixture SHA-256 is
`c673bfabad68bde8544f1fead5845b21326d76cf0bad44a226b598be1f61e71f`; and the
independent expected-outcome table SHA-256 is
`466689895dbd4d6b12df43498a69bd85c81382903ecbc2871df161b2c4b533dd`.

The pinned canonical text, page index, StandardIR and normative PDF hashes
are respectively
`1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e`,
`49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929`,
`106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2` and
`7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2`.

R000543--R000546 and focused-review R000548--R000550 retain the missing-trace,
pin, self-consistency, trace-refresh and evidence-handoff failures. They are
not deleted or superseded; the corrected packet is the one in R000547.

## Scope and non-claims

The oracle checks only this typed projection of C745. It does not parse a
derived-type definition, count real components, classify component types,
inspect type parameters or type-bound procedures, diagnose invalid Fortran,
promote a semantic fact, restart E0172, or close full M3. It is a bounded
source-backed oracle delivery, not arbitrary user-Fortran compilation.
