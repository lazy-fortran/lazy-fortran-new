# M3 C601 semantic review v1

Verdict: NEEDS FIX

Packet: central commit `57c742214192af7f69b7747737018dbba41124e3`, functional
pin `64d1c43`, verifier
`tests/e2e/run-m3-c601.sh .cache/runs/E0177/R000001`.

First fatal issue: the validator accepted fixture-declared canonical line and
StandardIR row identities without independently constraining them. A mutated
line identity or row identity could therefore bind the same oracle to another
source region. The required correction is to assert canonical line 2809 and
the exact R601/R602/R603 row set in the independent validator, and to add both
identity mutations before replay.

Review scope: source binding, adversarial correctness, and bounded semantic
scope. No files were changed by the reviewer.
