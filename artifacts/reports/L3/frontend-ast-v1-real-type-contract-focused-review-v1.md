# Focused review: bounded REAL type-spec contract

Task: `T-L3-frontend-real-type-contract`

Frozen central revision: `24674d497f95c29caba5a358ee5704d5f03a38c8`

The contract is a pre-implementation handoff, not a semantic promotion. It
contains one source-derived `real :: x` case, an integer changed-type control,
and a malformed `real ::` negative. The independent validator pins the source
bytes, the SX witness path and hash, the StandardIR/source document evidence,
the canonical source lines, and the expected outcomes. It does not invoke the
producer.

The first review packet found two oracle-binding defects. The corrected
revisions hard-code the two positive `ACCEPTED` outcomes and bind the negative
witness to its manifest path and SHA-256. Those failed review results remain
retained in the run ledger; they are not erased by the correction.

Final focused review:

- Scope C, adversarial correctness and oracle independence: `PASS`.
- Scope D, reproducibility and evidence integrity: `PASS`.

Both final reviewers used `gpt-5.6-luna` with medium reasoning on the same
immutable revision and observed the exact verifier and central gates passing.
The contract is verified as `PASS-BOUNDED-ONLY`; it makes no claim about
general type parsing, arbitrary Fortran, semantic analysis, or M3 completion.
