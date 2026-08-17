# C1579 semantic/source review v0

Status: `NEEDS_FIX`

Snapshot: central commit `8ec74c4d6f479e5d334b3477e33b187e1eb77180`.

The review inspected D0136, the E0187 manifest, the C1579 contract and
fixtures, `tests/e2e/validate_m3_c1579.py`, the canonical source, StandardIR
R1532/R1544, the committed trace and run R000057. The exact source lines,
printed page, PDF hash, canonical hash and StandardIR metadata matched. The
validator self-test, contract negative control, byte-identical trace check and
six mutation controls passed. No parsing, inference, scope resolution, model
call or semantic promotion was found.

The oracle logic is fail-closed, but the fixture does not witness the complete
typed 3x3 state table. It omits `(absent, unknown)`, `(unknown, present)` and
`(unknown, unknown)`, all of which must be `UNRESOLVED`. The code classifies
these combinations correctly, but the missing witnesses prevent bounded
semantic promotion. The correction must add the three cases, require table
coverage in the independent validator, regenerate the trace, and replay the
exact gate:

```text
tests/e2e/run-m3-c1579.sh --fresh
```
