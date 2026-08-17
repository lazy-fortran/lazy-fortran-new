# M3 C759 focused review

Status: PASS

This report closes the reusable-artifact review for
`T-M3-c759-type-param-value-oracle`. It does not close M3 or promote a
semantic fact.

## Claim boundary

```text
leaf_id: T-M3-c759-type-param-value-oracle
claim_id: M3-C759-bounded-oracle
parent_id: M3
leaf_status: PASS
claim_status: CLOSED
parent_status: OPEN
evidence_gate_verdict: PASS
review_verdict: PASS
```

The bounded property is C759/R736: a `type-param-value` in a
`component-def-stmt` is a colon or a component specification expression. The
typed input is deliberately opaque: `colon`, `component-specification`,
`other` or `unknown`. The deterministic oracle returns `ACCEPTED` for the
first two, `REJECTED` for `other`, and `UNRESOLVED` for `unknown`. It does not
parse Fortran, resolve expressions, or promote a semantic fact.

## Evidence

The corrected replay passed at central revision
`fb3a36b7ceb804cd81f09b60ee285d40040feb72`, with `standard-new` pinned to
`f94c4c51b51fce22b533b7eeda08741970320913`. The exact command was:

```text
M3_C759_EXPECTED_CENTRAL_COMMIT=fb3a36b7ceb804cd81f09b60ee285d40040feb72 C759_EVIDENCE_ROOT=/home/ert/code/lazy-fortran-new STANDARD_NEW_ROOT=/home/ert/code/standard-new tests/e2e/run-m3-c759.sh --fresh
```

Replay `E0226/R000006` and the committed trace have SHA-256
`8c2540368c3ff5c75d3a493c6cc2b3cc6caae111518c18426815f2bb9e67515c`.
The run-environment SHA-256 is
`e2ccc65163266bd9ea6dbf146c7156b38be0711f8a3bd704a2a4b8f1c300c0f7`.
The validator SHA-256 is
`27be8e57a965ec534eacabe72af4dd55a6d395d92aacc7d54c54ceddeec62050`.

The source binding is J3-24-007 C759/R736, canonical lines 3854--3855, byte
span `242269:126`, printed page 79, ledger page 92, page-index/PDF page 93,
and StandardIR R736 occurrence 86. The canonical text, page index, PDF and
StandardIR hashes are checked by the validator.

The four states produce 2 `ACCEPTED`, 1 `REJECTED` and 1 `UNRESOLVED`.
Fifteen source, page, PDF, identity, contract and semantic-item mutation
controls are rejected. The replay records zero model calls and zero semantic
promotions. The validator self-test and contract checker pass, and semantic
SX canonicalization matches its golden output.

The expected table is independently controller-derived and labelled
`MECHANICAL`. The candidate source/semantic packet remains labelled `LLM` and
disputed. The schema now explicitly defines `c759-value-kind`, embeds it in
`semantic-candidate` as `fact`, and the validator checks that correspondence
against JSON `fact.value_kind`. Two independent medium-depth focused reviewers
returned `PASS` with no first issue. The evidence gate therefore passes for
this bounded leaf only.

The implementation was produced on the isolated Luna worker branch
`bd39732dab82b59850f70b8417590b5a181bd144` from base
`73076b346b8bb275a2cac33d3bfbd7ba7e402548`; the controller integrated it and
performed the provenance correction and schema repair. The worker's historical
reference pre-commit hook could not resolve unrelated old objects in its
isolated checkout; that failure is retained as a warning, not as semantic
evidence.

## Non-claims

This closes only the bounded C759 oracle. It does not promote the C759
semantic fact, close full M3, validate arbitrary Fortran parsing, or establish
expression semantics.
