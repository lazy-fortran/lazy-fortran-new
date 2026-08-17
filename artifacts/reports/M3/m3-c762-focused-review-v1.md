# M3 C762 focused review

Status: PASS
Origin: MECHANICAL

This report closes the reusable-artifact review for
`T-M3-c762-conditional-nopass-oracle`. It does not close M3 or promote a
semantic fact.

## Claim boundary

```text
leaf_id: T-M3-c762-conditional-nopass-oracle
claim_id: M3-C762-bounded-oracle
parent_id: M3
leaf_status: PASS
claim_status: CLOSED
parent_status: OPEN
evidence_gate_verdict: PASS
review_verdict: PASS
```

The bounded property is C762/R741: when a procedure pointer component has an
implicit interface or no arguments, NOPASS shall be specified. The typed input
is deliberately supplied state, not parsed source: trigger state
`not-triggered`, `triggered` or `unknown`, crossed with NOPASS state `present`,
`absent` or `unknown`. The deterministic oracle returns `ACCEPTED` when the
trigger is absent or NOPASS is present, `REJECTED` for triggered plus absent,
and `UNRESOLVED` otherwise. It does not parse Fortran, infer interfaces or
arguments, or promote a semantic fact.

## Evidence

The implementation and registry are consumed from
`4e10695c5d190b05f0a4f8f34afba05261def80d`; the pushed control-plane revision
used for the final clean replay is
`ee7dd044a909a035a843d8df5b98d88fe9c4719c`. `standard-new` is pinned to
`f94c4c51b51fce22b533b7eeda08741970320913`. E0229 records the implementation
dependency pin and its exact manifest hash.

The clean detached replay command was:

```text
M3_C762_EXPECTED_CENTRAL_COMMIT=ee7dd044a909a035a843d8df5b98d88fe9c4719c C762_EVIDENCE_ROOT=/home/ert/code/lazy-fortran-new STANDARD_NEW_ROOT=/home/ert/code/standard-new /home/ert/code/lazy-fortran-new-c762-final-gate/tests/e2e/run-m3-c762.sh --fresh
```

It passed as `E0229/R000001`. The result and committed trace both hash to
`0bc9ef95f662579eb600a153ea28fbe628dac882adea495040987e6b547b8ca4`; the
run-environment hash is
`3316c8dcb2dc2ee0e6ecb23bbd5414995cef9cb99e54d4442d9fd01439a81c1e`; and the
validator hash is
`ca8b8dddeeeb5c407f76b9fd8e691d179e0392d4dcae7018037fa1586a9bca47`.

The source binding is J3-24-007 C762/R741, canonical lines 3872--3873, byte
span `243055:127`, printed page 79, PDF page 94, ledger page 93, page-index
record `93:239957:2451`, StandardIR R741 occurrence 91 and R742 occurrence
92. The canonical text, page index, PDF and StandardIR hashes are checked by
the validator.

The nine states produce 4 `ACCEPTED`, 1 `REJECTED` and 4 `UNRESOLVED`.
Twelve source, page, identity, contract, fixture and semantic-item mutation
controls are rejected. The replay records zero model calls and zero semantic
promotions. The runner requires a committed trace and compares it byte-for-
byte with the fresh result.

The expected table is independently controller-derived and labelled
`MECHANICAL`. The candidate source/semantic packet is labelled `LLM` and
disputed. Two independent medium-depth focused reviewers returned `PASS` on
the final frozen revision. The worker's warning about normalizing the supplied
source-hash spelling and its unrelated historical-reference pre-commit hook is
retained; the pinned artifact, controller validator and repository gates all
use the verified 64-character canonical hash.

## Non-claims

This closes only the bounded C762 oracle. It does not promote the C762
semantic fact, close full M3, validate arbitrary Fortran parsing, establish
procedure-pointer semantics, or infer interface/argument state from source.
