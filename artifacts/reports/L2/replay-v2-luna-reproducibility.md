# L2 replay v2 — reproducibility and determinism

Reviewer: GPT-5.6 Luna, isolated reproducibility lane
Candidate: `57689ef`

Verdict: PASS

First fatal issue: None.

Evidence: HEAD `57689ef` and the worktree are clean. The central verifier
passes three times, including empty-cache and `de_AT.utf8` runs. Exact
component pins, `fo`, QEMU, readelf, MIR/ELF bytes, oracle witnesses, negative
paths, committed trace, cited files/commits, shell syntax, and the contract
negative control all pass.

Required correction: None.
