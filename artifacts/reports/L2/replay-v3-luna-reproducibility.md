# L2 replay v3 — reproducibility and determinism

Reviewer: GPT-5.6 Luna, isolated reproducibility lane
Candidate: `22023d3`

Verdict: NEEDS FIX

First fatal issue: The generated and committed L2 trace is incomplete under
`docs/reproducibility.md`: it records neither clean/dirty state, host system,
locale/environment, nor exact command lines. The runner normalizes locale but
does not record or compare that state.

Evidence: The trace contains component pins, selected tool versions, stage
hashes, negative cases, and runtime status, but not the required
reproducibility environment or command record. Its `cmp` therefore proves only
equality with an incomplete trace.

Required correction: Record and validate clean/dirty state, OS/architecture,
normalized locale and relevant environment, and the executed command record in
the L2 manifest/trace before claiming reproducibility.
