# M3 C761 focused review

Status: PASS
Origin: MECHANICAL

This report closes the reusable-artifact review for
`T-M3-c761-pointer-presence-oracle`. It does not close M3 or promote a
semantic fact.

## Claim boundary

```text
leaf_id: T-M3-c761-pointer-presence-oracle
claim_id: M3-C761-bounded-oracle
parent_id: M3
leaf_status: PASS
claim_status: CLOSED
parent_status: OPEN
evidence_gate_verdict: PASS
review_verdict: PASS
```

The bounded property is C761/R741: `POINTER` shall appear in each
`proc-component-attr-spec-list`. The typed input is deliberately supplied
state, not parsed source: `pointer-present`, `pointer-absent` or `unknown`.
The deterministic oracle returns `ACCEPTED`, `REJECTED` or `UNRESOLVED`
respectively. It does not parse Fortran, construct attribute lists, infer
pointer presence or promote a semantic fact.

## Evidence

The implementation and registry are consumed from
`a4d2bcb2eaba63bb604e95684e3a265ee76fd48c`; the pushed control-plane revision
used for the final clean replay is
`991c811dacd7cd4a61b8ae36e87f489e9d6c4971`. `standard-new` is pinned to
`f94c4c51b51fce22b533b7eeda08741970320913`. E0228 records the implementation
dependency pin and its exact manifest hash.

The clean detached replay command was:

```text
M3_C761_EXPECTED_CENTRAL_COMMIT=991c811dacd7cd4a61b8ae36e87f489e9d6c4971 C761_EVIDENCE_ROOT=/home/ert/code/lazy-fortran-new STANDARD_NEW_ROOT=/home/ert/code/standard-new /home/ert/code/lazy-fortran-new-c761-final-gate/tests/e2e/run-m3-c761.sh --fresh
```

It passed as `E0228/R000001`. The result and committed trace both hash to
`9fb7a9ee4a42fbb3b5518d30b392a7adf2d36edd96f73aaa767335d472f53f65`; the
run-environment hash is
`d9bc82520952f46ce69b7635bc6f14e22429e9abd5d6eddba5de632e62769566`; and the
validator hash is
`50d03f256c4b6f60a0a78adcecceb0ebc434e422e160682fb9e53dd26036e88c`.

The source binding is J3-24-007 C761/R741, canonical line 3871, byte span
`242981:74`, printed page 79, PDF page 94, ledger page 93, page-index record
`93:239957:2451`, StandardIR R741 occurrence 91 and R742 occurrence 92. The
canonical text, page index, PDF and StandardIR hashes are checked by the
validator.

The three states produce 1 `ACCEPTED`, 1 `REJECTED` and 1 `UNRESOLVED`.
Eleven source, page, identity, contract, fixture and semantic-item mutation
controls are rejected. The replay records zero model calls and zero semantic
promotions. The runner now requires a committed trace and compares it
byte-for-byte with the fresh result.

The expected table is independently controller-derived and labelled
`MECHANICAL`. The candidate source/semantic packet is labelled `LLM` and
disputed. Two independent medium-depth focused reviewers returned `PASS` on
the final frozen revision, including the enforced trace comparison. The
worker's unrelated historical-reference pre-commit warning is retained as a
warning; the controller replay and repository gates pass independently.

## Non-claims

This closes only the bounded C761 oracle. It does not promote the C761
semantic fact, close full M3, validate arbitrary Fortran parsing, establish
procedure-pointer semantics, or infer pointer presence from source text.
