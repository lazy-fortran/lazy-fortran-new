# C732 reproducibility review

Status: `PASS` for the bounded slice only.

The independent reproducibility review inspected the frozen packet at
controller revision `8e4fbe47a1a799c32bc5f7dd758f4b8295c06b41`. `HEAD` equals
`origin/main`; the replay is recorded as `R000514` with result SHA-256
`693c3690cd2a9ef61cc6cac2bea7a67b68daaac2d4dd40a39021e555ec4af1f9` and
environment SHA-256
`1f5312f662f8c2f5778660ed30abbd33fd3bef569edaab4932d6e809d8c8c1cf`.

The result and committed trace match. The validator self-test passes, the
clean central replay passes, and the experiment manifest and TASK_POOL wire
the replay and hashes. The replay command is:

```text
M3_C732_EXPECTED_CENTRAL_COMMIT=40bad4f842a87000ceddb68449a801c2282e2b60 tests/e2e/run-m3-c732.sh --fresh
```

No integration or reproducibility defect remains. This review supports only
the bounded C732 artifact and does not close full M3.
