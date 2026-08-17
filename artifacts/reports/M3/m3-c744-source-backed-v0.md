# M3 C744 bounded END TYPE name relation oracle

Status: `REPLAY PASS`; focused independent review is recorded separately
before bounded promotion. Full M3 remains `OPEN`. This artifact does not claim a
Fortran parser, semantic analyzer, identifier resolver or promotion of the
retained C744 semantic row.

## Contract

The contract binds J3-24-007 C744 to canonical lines 3639--3640, printed page
89 and UTF-8 byte span `230888:137`. Its existing StandardIR witnesses are
R727 (`derived-type-stmt`) and R730 (`end-type-stmt`). The typed candidate
product is:

```text
END TYPE name presence: absent | present | unknown
name relation: same | different | unknown
context: derived-type-def | other | unknown
```

`absent` in `derived-type-def`, and `present` with `same` there, are
`ACCEPTED`; `present` with `different` there is `REJECTED`; every other state
is `UNRESOLVED`. The validator covers all 27 states, four accepted witnesses,
one negative neighbour, 22 unresolved controls and twelve source, page,
StandardIR and contract-identity mutations. Every mutation is rejected. No
model output can promote a semantic fact.

## Replay

The exact clean-checkout command is:

```text
M3_C744_EXPECTED_CENTRAL_COMMIT=bbf32b84a7bcfd38755e1f745ded1944fb966e8b tests/e2e/run-m3-c744.sh --fresh
```

Replay `E0206/R000003` passes and compares its generated result byte-for-byte
with `artifacts/traces/m3-c744-source-backed-v0.json`: 4 `ACCEPTED`, 1
`REJECTED`, 22 `UNRESOLVED`, twelve rejected mutation controls, zero model
calls and zero semantic promotions. The result and committed trace both have
SHA-256
`efbf3eca06176f41dfa8d879b85f859ef4cf21b692d7db0d36079ed490ccc811`. The
run environment has SHA-256
`f85643cf17a5bc7e9ebf37aa54825ece337064d1fc48f1a9c05294fe3a98e7af`.

The central control-plane revision is
`bbf32b84a7bcfd38755e1f745ded1944fb966e8b`; the functional revision pinned by
E0206 is `fd9ce7a6b4f0aa13e257cca2f5c5906b0ac099d1`; and the pinned
`standard-new` revision is `f94c4c51b51fce22b533b7eeda08741970320913`. The
independent validator SHA-256 is
`e42a341a836cbb69f4565f9b794382aee11a36c42d6b2f89f45a8f9ef9e6ef91` and the
source-backed fixture SHA-256 is
`70a8f7e944cbf06a4ecab0e82bd1be380a2e06b11e1e7b3e63e86439a924ca24`.

The pinned canonical text, page index, StandardIR and normative PDF hashes
are respectively
`1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e`,
`49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929`,
`106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2` and
`7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2`.

Focused independent review is recorded in
`artifacts/reports/M3/m3-c744-focused-review-v1.md`. Promotion remains gated
on that review and a clean replay after this report is committed. No C744
semantic fact or full M3 claim is promoted.

## Scope and non-claims

The oracle checks only the typed relation stated by C744. It does not parse a
derived-type definition, compare real identifier spellings, define
case-folding, match construct nesting, perform name resolution, diagnose
invalid Fortran or close the retained E0181 witness ledger. It is a bounded
M3 delivery slice, not arbitrary user-Fortran compilation.
