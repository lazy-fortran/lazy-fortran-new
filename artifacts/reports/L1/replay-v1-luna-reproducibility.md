# L1 replay — independent reproducibility review

Date: 2026-08-16
Candidate tracked diff SHA-256: `e57861c7cc12f0e815e1fd09ce3f7275a59865adb7f7233c1373f1a1058d35ab`
Reviewer: native GPT-5.6 Luna, reproducibility/determinism lane

## Verdict

FAIL.

`tests/e2e/run-l1.sh` records component revisions from the fixture manifest but
never verifies those values against the actual checkout `HEAD`s. The central
pin check does not close this gap because it validates the central pins, not the
fixture’s attribution fields.

## Required correction

Resolve the actual `HEAD` of `standard-new` and `fortfront-new`, require exact
equality with the manifest commits, and write only those verified revisions to
the trace.
