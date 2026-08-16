# L1 replay — independent oracle review

Date: 2026-08-16
Candidate tracked diff SHA-256: `e57861c7cc12f0e815e1fd09ce3f7275a59865adb7f7233c1373f1a1058d35ab`
Reviewer: native GPT-5.6 Luna, oracle-independence lane

## Verdict

FAIL.

The runner checks that `standard-new` rejects the malformed neighbor and emits
`unclosed SX list`, but `tests/e2e/oracle_l1.py` never reads or validates the
negative fixture. An implementation could therefore reject a well-formed file
and still pass this oracle.

## Required correction

Pass the malformed fixture to the independent oracle and have the oracle
verify its reviewed malformed structure before accepting the runtime rejection
as evidence.
