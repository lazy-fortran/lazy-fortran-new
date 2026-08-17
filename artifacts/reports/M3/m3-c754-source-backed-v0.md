# C754 source-backed bounded oracle

Status: `PASS-BOUNDED-ONLY`, pending focused independent review.

The exact replay command was:

```text
M3_C754_EXPECTED_CENTRAL_COMMIT=3fb7c98585859f22a833a78734769ea577061351 tests/e2e/run-m3-c754.sh --fresh
```

It is recorded as `research/runs/2026-08.jsonl#R000618` with run directory
`.cache/runs/E0224/R000001`. The functional tree is pinned by the E0224
manifest to `d59bfad`; the runner separately records the central replay
revision and checks every functional path against that pin.

## Source binding

The oracle binds J3-24-007 C754, canonical lines 3847--3848, printed page 79,
byte span `241715:150`, and page-index record `93:239957:2451`. It checks the
normative PDF SHA-256, canonical text SHA-256, page-index SHA-256 and
StandardIR SHA-256. Existing StandardIR rows are R737, R738, R739 and R740.

## Typed property

The candidate product has 27 states:

```text
POINTER attribute:       absent | present | unknown
ALLOCATABLE attribute:   absent | present | unknown
component-array-spec:    explicit-shape-list | deferred-shape-list | unknown
```

The deterministic oracle accepts whenever POINTER or ALLOCATABLE is present,
and accepts every explicit-shape-list. It rejects only the definite
absent/absent/deferred-shape-list state. It returns `UNRESOLVED` for the other
non-explicit states without a definitely present attribute. Unknown states are
not guessed.

The replay produced 19 `ACCEPTED`, 1 `REJECTED` and 7 `UNRESOLVED` outcomes.
All 13 source/provenance mutation controls were rejected. The result and
committed trace both have SHA-256
`8051938e0c1771034c78e3a3f10844d423badb1da9b0f32f1c4e24ae145d69eb`.
The run recorded zero model calls and zero semantic promotions.

## Scope

This is a bounded oracle over typed candidate facts. It does not parse user
Fortran, infer attributes from source text, promote C754 as a semantic fact,
close M3, or broaden into C753/C755 or general semantic analysis. The
independent review and evidence gate remain open until the focused packet is
accepted.
