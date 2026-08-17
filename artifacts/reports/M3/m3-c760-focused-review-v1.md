# M3 C760 focused review

Status: PASS

This report closes the reusable-artifact review for
`T-M3-c760-harvested-oracle`. It does not close M3 or promote a semantic
fact.

## Claim boundary

- leaf: `T-M3-c760-harvested-oracle`
- claim: `M3-C760-bounded-oracle`
- parent: `M3`
- leaf status: `PASS`
- claim status: `CLOSED`
- parent status: `OPEN`
- evidence-gate verdict: `PASS`
- review verdict: `PASS`

The bounded property is the at-most-once occurrence of
`proc-component-attr-spec` in C760/R741. The oracle accepts zero or one
occurrence, rejects a duplicate, and returns `UNRESOLVED` for unknown input.
It does not parse Fortran, infer facts from model output, or promote a
semantic fact.

## Evidence

The clean replay passed at central revision
`1a4bf3ad1a1b1aeb2ae85e5fc0b5c084893a68d5`, with `standard-new` pinned to
`f94c4c51b51fce22b533b7eeda08741970320913`. The exact command was:

```text
C760_EXPECTED_CENTRAL_COMMIT=1a4bf3ad1a1b1aeb2ae85e5fc0b5c084893a68d5 C760_EVIDENCE_ROOT=/home/ert/code/lazy-fortran-new STANDARD_NEW_ROOT=/home/ert/code/standard-new tests/e2e/run-m3-c760.sh --fresh
```

The replay result and committed trace have SHA-256
`6eda417921fd87afb61d912332489cc98ef6eece8cee10e80ea835366690886a`.
The run environment records `fo 0.3.2`, its executable hash, compiler,
Python, Git, Poppler, both repository revisions, and the validator hash.

The result has four typed cases: two `ACCEPTED`, one `REJECTED`, and one
`UNRESOLVED`. Ten source, provenance, identity, contract, and semantic-item
mutation controls were rejected. The replay recorded zero model calls and
zero semantic promotions. The independent validators passed:

- `scripts/check-contracts.sh`
- `python3 tests/e2e/validate_m3_c760.py --self-test`
- the clean `tests/e2e/run-m3-c760.sh --fresh` replay

Two independent focused reviewers inspected the corrected packet and found
no issue. Both returned `PASS`; the second independently returned the claim
status `CLOSED`. The evidence gate therefore records `PASS` for this bounded
leaf only.

## Harvest relationship

The semantic packet was selected from the provisional Luna harvest. Its
semantic packet origin remains `LLM`; source envelopes and replay results are
controller-mechanical. The harvest manifest is staging evidence, not a batch
promotion mechanism. It cannot promote any semantic fact or bypass the
per-leaf oracle gate.
