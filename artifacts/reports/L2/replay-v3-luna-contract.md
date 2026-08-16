# L2 replay v3 — contract and interface

Reviewer: GPT-5.6 Luna, isolated contract lane
Candidate: `22023d3`

Verdict: PASS

First fatal issue: None.

Evidence: Contracts, fixtures, manifests, trace, hashes, and pinned component
revisions are internally consistent. `ffc-new` validates frontend-v0 input
and emits MIR-v0; `fortback-new` parses the instruction list, enforces the
bounded `main`/`add`/`return`/RV64 profile, and rejects malformed or
out-of-scope MIR without artifacts. No serialized TargetIR boundary is
promoted.

Required correction: None.
