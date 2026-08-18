# L3 typed frontend AST v1 exact y witness replay

The bounded successor reuses the generated `frontend-ast-v1` record and
checks the exact source witness with variable name `y`:
`program p / integer :: y / end program p`. The malformed neighbour remains
`integer ::`. The expected variable declaration is integer `y`, with span bytes
10 through 24 and source-hash label
`l3-raw-program-variable-name-v1`.

The independent validator reuses the schema parser and structural record-field
check from the promoted AST oracle, then checks the exact y source bytes,
contract and artifact hashes, expected values, repeat equality and absence of
negative output. It does not import fortfront implementation code.

The first central replay bootstrapped the trace; the frozen no-bootstrap
technical replay is:

```text
AST_EXPECTED_CENTRAL_COMMIT=eaca690504abc1a2c218d86e38fdc188b199540d \
tests/e2e/run-frontend-ast-v1-name.sh --fresh
```

The positive was accepted, y was preserved, the malformed neighbour was
rejected, repeated output was identical, trace comparison passed, and model
calls and semantic promotions were zero. Full review and promotion remain
pending.

This is an exact y-witness claim only. Because the bridge recognizes a bounded
set of exact witnesses, it does not establish general source-derived name
handling, identifier or declaration parsing, symbol resolution, semantic
analysis, MIR lowering or full M3.
