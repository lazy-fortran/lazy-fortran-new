# L0 boundary v2 — Luna contract review

- Snapshot: `ac5a946` plus candidate diff `45fe91104117a04dce8dafa388d318c39f6778947ab94466e42ef900db4eebf5`
- Lane: contract and interface
- Verdict: `PASS`
- Command inspected: `scripts/run_e2e.sh`

`central_contract = none` is explicit in the manifest and committed trace.
D0022 identifies the component schema as a generator fixture rather than
complete StandardIR, and D0027 identifies lexical facts as a separate
projection. The later central StandardIR boundary is not falsely claimed.
