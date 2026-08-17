# L3 raw-source-to-executable replay

Status: technical replay `PASS`; promotion: pending focused review.

The exact replay command is:

```text
tests/e2e/run-l3.sh --fresh
```

It consumes the pinned positive source
`tests/fixtures/l3-raw-program-v0.f90` and the mismatched-end neighbour
`tests/negative/l3-raw-program-v0-mismatched-end.f90`, then runs:

```text
raw source → fortfront-source-v0 → frontend-v0 SX
→ ffc-lower-frontend-v0 → MIR-v0 SX
→ fortback-mir-v0 → RV64 Linux ELF → qemu-riscv64
```

The independent oracle is `tests/e2e/validate_l3.py`. It checks the exact
source bytes, the accepted frontend-v0 and MIR-v0 golden observables, the
rejected diagnostic and source span, absence of negative MIR, ELF64/RISC-V
identity, and a second runtime execution. It does not import any production
implementation.

The replay recorded one accepted source case, one rejected neighbour, runtime
exit status zero, zero model calls and zero semantic promotions. Regenerate
those observations with the command above; the committed trace is
`artifacts/traces/l3-raw-program-v0.json` with SHA-256
`aacc3581d9b35667af56318bb9d9fc96d587803551d7965ede9d4877d80ac3a2`.

The replay used central revision `7a3dbb3e0a7ad88d67303ab8b7a1c29727583a94`,
`fortfront-new` revision `89b470760745cc4fd02c142bcb3e44f90a688a93`,
`ffc-new` revision `bcaadcb58c24af613204aa398541c0d2e35abf91`, and
`fortback-new` revision `c578904a8d18e9d5410934f5489a21d5dadfad05`.
The validator SHA-256 is
`d633a441641b5c3cbad09ce8533fb61e304eb2f51df674695b8b7aabfccdea3f`.

This is only the bounded L3 slice. It does not claim declarations,
expressions, I/O, modules, procedures, fixed-form source, or general Fortran
parsing.
