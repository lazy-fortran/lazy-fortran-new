# L2 focused Luna review — reproducibility and determinism

Snapshot: `19b0972d57e568de9fc9a494335bdcb76cf565de`

Claim: the bounded L2 result is reproducible from the recorded command,
component pins, tool identities, hashes and trace.

Verdict: `PASS`

First fatal issue: none.

Evidence: `git rev-parse HEAD` matched the snapshot;
`bash -n tests/e2e/run-l2.sh`, `python3 -m py_compile tests/e2e/oracle_l2.py`
and `scripts/verify_active_milestone.sh` passed; the manifest and trace record
the pinned `fo`, Python, QEMU and `readelf` identities, exact oracle command,
path aliases, hashes and deterministic MIR/ELF comparisons.

Required correction: none.
