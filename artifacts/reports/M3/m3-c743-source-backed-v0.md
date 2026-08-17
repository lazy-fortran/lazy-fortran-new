# M3 C743 bounded private-or-sequence uniqueness oracle

Status: `PASS` for the bounded C743 leaf after focused independent review; the
full M3 milestone remains `OPEN`.
This artifact does not claim a Fortran parser, semantic analyzer or promotion
of the retained C743 semantic row.

## Contract

The contract binds J3-24-007 C743 to canonical line 3637, printed page 89 and
UTF-8 byte span `230736:105`. Its existing StandardIR witnesses are R726
(`derived-type-def`) and R729 (`private-or-sequence`). The oracle classifies
the typed product:

```text
private-or-sequence occurrence: none | single | duplicate | unknown
context: derived-type-def | other | unknown
```

`none` and `single` in `derived-type-def` are `ACCEPTED`; `duplicate` there is
`REJECTED`; every other state is `UNRESOLVED`. The validator covers all 12
states, two positive witnesses, one negative neighbour, nine unresolved
controls and twelve source/provenance/identity mutations. Every mutation is
rejected. No model output can promote a semantic fact.

## Replay

The exact clean-checkout command is:

```text
M3_C743_EXPECTED_CENTRAL_COMMIT=e4e7edf8281050f3dc854a5a984baba80d9aab27 tests/e2e/run-m3-c743.sh --fresh
```

Replay `E0204/R000003` passes with 2 `ACCEPTED`, 1 `REJECTED`, 9
`UNRESOLVED`, twelve rejected mutation controls, zero model calls and zero
semantic promotions. The result and committed trace both have SHA-256
`fafdaed904d48f3bfafdbe70f33ef47cac5992e2db89e9755e912ed2f8364188`.
The run environment has SHA-256
`bb0b18e76de32aa79a76b9d5adf26f300eb02f014e03dfc3b75071b3037a2874`.

The final clean control-plane replay is `E0204/R000006` at revision
`56693eba2bad8347387964fbec11bd99171bb126`; it reproduces the same committed
trace and has run-environment SHA-256
`7a49f05b5ad17af37d22f0928a4a56ffcfbcf36479868aaa5725eaf3d73b5cfc`.

The replay uses central revision `e4e7edf8281050f3dc854a5a984baba80d9aab27`,
functional revision `061f6769d042406b608da2a908d665a9856d856d`, and
standard-new revision `f94c4c51b51fce22b533b7eeda08741970320913`. The pinned
canonical text, page index and StandardIR hashes are respectively
`1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e`,
`49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929` and
`106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2`.

Focused independent review `R000532` passes; see
`artifacts/reports/M3/m3-c743-focused-review-v1.md`. The bounded candidate is
promoted only as this typed oracle leaf. No C743 semantic fact or full M3
claim is promoted.

## Scope and non-claims

The oracle checks only a typed uniqueness relation. It does not parse a
derived-type definition, distinguish the meaning of PRIVATE from SEQUENCE,
validate the R729 alternatives, resolve type names, inspect a processor or
close the retained E0181 witness ledger. The implementation is a bounded M3
delivery slice, not arbitrary user-Fortran compilation.
