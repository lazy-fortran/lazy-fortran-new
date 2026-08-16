# L0 boundary v2 — Luna reproducibility review

- Snapshot: `ac5a946` plus candidate diff `45fe91104117a04dce8dafa388d318c39f6778947ab94466e42ef900db4eebf5`
- Lane: reproducibility and determinism
- Verdict: `PASS`
- Command inspected: `scripts/run_e2e.sh`

The runner verifies clean pinned component state, clears the ignored component
build tree, checks the exact `fo` version and executable hash, repeats the
generators byte-for-byte, and compares the generated trace with the committed
trace. The narrow L0 reproducibility gate passes.
