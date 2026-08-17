# M3 C757 focused review

Status: PASS

This report closes the reusable-artifact review for
`T-M3-c757-contiguous-pointer-oracle`. It does not close M3 or promote a
semantic fact.

## Claim boundary

```text
leaf_id: T-M3-c757-contiguous-pointer-oracle
claim_id: M3-C757-bounded-oracle
parent_id: M3
leaf_status: PASS
claim_status: CLOSED
parent_status: OPEN
evidence_gate_verdict: PASS
review_verdict: PASS
```

The bounded property is C757/R737: when `CONTIGUOUS` is specified, the
component is an array with the `POINTER` attribute. The typed candidate space
crosses the presence of those three attributes, each `absent`, `present` or
`unknown`. The deterministic oracle returns `ACCEPTED`, `REJECTED` or
`UNRESOLVED`; it does not parse Fortran, infer facts from model output, or
promote a semantic fact.

## Evidence

The clean replay passed at central revision
`6be913c3e6c7702a6dc64d186427f6d09e2fa247`, with `standard-new` pinned to
`f94c4c51b51fce22b533b7eeda08741970320913`. The exact command was:

```text
M3_C757_EXPECTED_CENTRAL_COMMIT=6be913c3e6c7702a6dc64d186427f6d09e2fa247 C757_EVIDENCE_ROOT=/home/ert/code/lazy-fortran-new STANDARD_NEW_ROOT=/home/ert/code/standard-new tests/e2e/run-m3-c757.sh --fresh
```

The replay result and committed trace have SHA-256
`6c84586c6e142bc31b3e6e7c78ccc0c892793b1acff3c9c1971432a9bb709843`.
The run-environment SHA-256 is
`36221baa84872ed52c00822eb823cb2cd609597b29eb0fc29bb569029b46d15a`.
It records the repository revisions, `fo 0.3.2`, its executable hash,
compiler, Python, Git and Poppler versions, and the validator hash.

The exact source binding is J3-24-007 C757, canonical lines 3851--3852,
byte span `242052:120`, printed page 79, page-index record 93, and
StandardIR R737/R738/R739. The canonical text, page index, PDF, StandardIR,
constraint-span and fixture hashes are pinned in the fixture and replay.

The 27 states produce 11 `ACCEPTED`, 5 `REJECTED` and 11 `UNRESOLVED`
outcomes. Fifteen source, page, PDF, identity, contract and semantic-item
mutation controls are rejected. The replay records zero model calls and zero
semantic promotions. The independent validators pass:

- `scripts/check-contracts.sh`
- `python3 tests/e2e/validate_m3_c757.py --self-test`
- the clean `tests/e2e/run-m3-c757.sh --fresh` replay

The expected outcome table is controller-derived and labelled `MECHANICAL`;
the candidate semantic packet remains labelled `LLM` and disputed. Two
independent medium-depth Luna reviewers inspected the corrected frozen packet,
returned `PASS`, and found no issue. The evidence gate therefore passes for
this bounded leaf only.

## Non-claims

This closes only the bounded C757 oracle. It does not promote the C757
semantic fact, close full M3, validate arbitrary Fortran parsing, or inspect
adjacent C755/C756/C758 rules.
