# L3 typed frontend AST v1 replay

The bounded `frontend-ast-v1` slice reaches a typed producer from one exact
raw-source witness. The pinned positive source is
`program p / integer :: x / end program p`; the negative neighbour omits the
declaration entity name. The producer emits one `program-unit` record with one
integer variable declaration named `x`, with variable span bytes 10 through
24. The root span ends at byte 38 under the producer's exclusive boundary
convention.

The independent validator checks the source bytes, negative bytes, contract
and artifact hashes, expected typed fields, repeat equality and absence of
negative output. It does not import fortfront implementation code. The first
replay exposed a missing closing node in the manually reviewed golden; later
focused review exposed an absolute-path-dependent trace hash. The corrected
golden and path-independent trace were then pinned.

Technical replay:

```text
AST_EXPECTED_CENTRAL_COMMIT=a3aa8e052bbd325167c55616d9dc244fc9e83544 \
tests/e2e/run-frontend-ast-v1.sh --fresh
```

Result R000660: positive accepted, negative rejected, repeated output
identical, independent oracle PASS, trace comparison PASS, zero model calls and
zero semantic promotions. The trace hash canonicalizes the source path while
the output oracle still checks the actual checkout path. The committed trace
is `artifacts/traces/frontend-ast-v1.json`.

This is a bounded typed-AST producer claim only. It does not establish general
declaration parsing, semantic analysis, MIR lowering, or arbitrary Fortran
acceptance; full M3 remains open.
