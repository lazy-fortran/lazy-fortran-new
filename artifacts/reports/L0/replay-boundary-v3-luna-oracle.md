# L0 boundary replay — independent oracle review

Date: 2026-08-16
Snapshot: corrected L0 candidate before this report set
Candidate diff SHA-256: `5b563f54bdecb3a4105ff06e657ce0780e017460f578ad13ec57887e957ec33e`
Reviewer: native GPT-5.6 Luna, oracle-independence lane

## Verdict

PASS.

The oracle is implementation-independent. It checks the five retained lexical
facts and their provenance, golden and schema hashes, the declared boundary,
malformed-input diagnostics, and mutation rejection. Repeated generation is
byte-identical and the generated trace matches the committed trace.

## Evidence checked

- `scripts/run_e2e.sh` passes.
- `tests/e2e/oracle_l0.py` does not regenerate its expected facts from the
  implementation under test.
- The positive, malformed negative, and source-mutation cases are exercised.

Smallest remaining blocker at review time: reconcile the four lane reports and
promote L0 in the central ledger.
