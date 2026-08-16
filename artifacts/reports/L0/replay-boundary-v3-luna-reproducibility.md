# L0 boundary replay — independent reproducibility review

Date: 2026-08-16
Snapshot: corrected L0 candidate before this report set
Candidate diff SHA-256: `5b563f54bdecb3a4105ff06e657ce0780e017460f578ad13ec57887e957ec33e`
Reviewer: native GPT-5.6 Luna, reproducibility/determinism lane

## Verdict

PASS.

The pinned component revisions are clean. The exact `fo 0.3.2` executable and
binary hash match the fixture. The clean component build, repeated generation,
independent oracle, malformed and mutation checks, and committed-trace
comparison all pass.

## Evidence checked

- `scripts/run_e2e.sh` passes.
- All four component pins are clean and resolve.
- Generated outputs are byte-identical across repeated runs.
- The trace produced by the run is equal to the committed trace.
- The toolchain version and executable hash are recorded in the trace.

Smallest remaining blocker at review time: reconcile the four lane reports and
promote L0 in the central ledger.
