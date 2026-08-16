# L2 replay v2 — oracle independence

Reviewer: GPT-5.6 Luna, isolated oracle lane
Candidate: `57689ef`

Verdict: NEEDS FIX

First fatal issue: The runner does not consume recorded runtime/tool pins.
It hard-codes `fo`, QEMU, readelf, and exit-status values in
`tests/e2e/run-l2.sh`, while the evidence manifest records them. The runtime
status is not checked against the evidence manifest by either oracle.

Evidence: The verifier passes, including pinned component commits, MIR/code-
word checks, QEMU execution, deterministic replay, and negative artifact
checks. However, mutating the recorded runtime/tool expectations would not
affect acceptance.

Required correction: Make the evidence manifest authoritative: load and
validate its tool/runtime pins and compare QEMU's status against its recorded
`runtime_exit_status` instead of literals.
