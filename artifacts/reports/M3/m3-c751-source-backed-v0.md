# M3 C751 bounded replay

Status: `PENDING` until `tests/e2e/run-m3-c751.sh --fresh` passes from a clean
checkout.

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

Regenerate the complete replay with:

```text
tests/e2e/run-m3-c751.sh --fresh
```
