# L0 current replay — Luna reproducibility review

- Snapshot: `d268f7f`
- Lane: reproducibility and determinism
- Verdict: `PASS`
- Command inspected: `scripts/run_e2e.sh`
- Evidence inspected: `repos.toml`, `scripts/check_pins.sh`, the L0
  manifest, the committed L0 trace, and the replay output.

The central checkout and pinned component checkouts were clean before the
replay. The pinned source/schema/component hashes matched, repeated
roundtrip and schema generation matched byte-for-byte, and the negative and
mutation controls failed as expected. This lane is sufficient for the narrow
replay, subject to the contract/interface failure.
