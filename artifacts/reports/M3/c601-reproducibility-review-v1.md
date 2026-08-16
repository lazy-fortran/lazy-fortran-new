# M3 C601 reproducibility review v1

Verdict: NEEDS FIX

Packet: central commit `57c742214192af7f69b7747737018dbba41124e3`, functional
pin `64d1c43`, verifier
`tests/e2e/run-m3-c601.sh .cache/runs/E0177/R000001`.

First fatal issue: the frozen packet was reviewed after the append-only
R000016 run record was added to the worktree, so central was dirty and the
exact run directory already existed. The required correction is to commit the
unchanged run record, make the validator correction, and perform a fresh
replay from a clean central checkout.

Review scope: clean-checkout reproducibility, pins, exact artifacts and
control-plane integration. No files were changed by the reviewer.
