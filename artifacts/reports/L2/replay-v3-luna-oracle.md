# L2 replay v3 — oracle independence

Reviewer: GPT-5.6 Luna, isolated oracle lane
Candidate: `22023d3`

Verdict: NEEDS FIX

First fatal issue: The recorded `runtime_oracle` identity in the evidence
manifest is never validated. The runner invokes hard-coded `qemu-riscv64`, and
the oracle checks only its version string and exit status. Mutating
`runtime_oracle` would silently pass.

Evidence: `artifacts/manifests/l2-first-executable-v0.toml` records
`runtime_oracle = "qemu-riscv64"`, but neither `tests/e2e/run-l2.sh` nor
`tests/e2e/oracle_l2.py` reads or compares that field.

Required correction: Load and validate `runtime_oracle` from the evidence
manifest, and invoke/check exactly that declared runtime identity before
accepting the observed status.
