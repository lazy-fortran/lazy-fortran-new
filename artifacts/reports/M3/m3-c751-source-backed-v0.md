# M3 C751 bounded replay

Technical replay status: `PASS` in `.cache/runs/E0220/R000005` from the clean
revision recorded by `tests/e2e/run-m3-c751.sh --fresh`. Promotion status:
`PASS` for the bounded leaf after focused review `R000601`.

The slice checks J3-24-007 C751 against the existing StandardIR component and
coarray shapes. Its typed denominator is twelve states: coarray-spec absent,
deferred-coshape-list, explicit-coshape-spec or unknown crossed with
ALLOCATABLE absent, present or unknown. The deterministic oracle returns four
`ACCEPTED`, four `REJECTED` and four `UNRESOLVED` results. It accepts the
absence of a coarray-spec vacuously, accepts a deferred co-shape with
ALLOCATABLE present, rejects the missing-ALLOCATABLE deferred case and rejects
all explicit co-shapes; unknown states remain unresolved.

The verifier binds canonical source lines 3840--3841, byte span `241193:142`,
printed page 79 and page-index records for pages 93, 121 and 122 to StandardIR
R737, R739, R809, R810 and R811. Twelve source, page, provenance and contract
mutations must be rejected. It does not parse Fortran, inspect C752/C754,
resolve names or promote semantic facts. Model calls and semantic promotions
are zero by contract.

Regenerate the complete technical replay with:

```text
tests/e2e/run-m3-c751.sh --fresh
```

The focused review is recorded in
`artifacts/reports/M3/m3-c751-focused-review-v2.md`. The earlier unavailable
review attempt remains retained as `R000600`; it did not affect the final
promotion decision.
