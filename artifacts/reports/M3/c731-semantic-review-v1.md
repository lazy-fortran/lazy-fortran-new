# C731 semantic review v1

Result: `PASS`

Reviewed control-plane revision: `f25c2513b8a849221480ec5d93a206830a8e9e65`.
Replay worktree revision: `94c71ec785ece8927a98a34a17e02aa452df1528`.
Reviewed functional pin: `5ff9c47c121cea7819bbb46f466fe3242e58d036`.
Reviewed replay: `research/runs/2026-08.jsonl#R000509`.

The bounded candidate relation is explicit and complete: the
`length_form × context` product has 12 states, with 2 `ACCEPTED`, 2
`REJECTED` and 8 `UNRESOLVED` outcomes. The negative neighbours are the two
non-constant forms in the two source-named contexts. The validator's
self-test, source/page/rule mutation controls and committed trace comparison
pass.

The C731 source binding is canonical lines 3469--3470, page 85, byte span
`219036:167`, with existing StandardIR R721. The oracle does not parse
Fortran, evaluate expressions, infer contexts or resolve names. The fixture
records zero model calls and zero semantic promotions. No issue was found in
the bounded correctness claim.

Reproduce the primary result with:

```text
M3_C731_EXPECTED_CENTRAL_COMMIT=94c71ec785ece8927a98a34a17e02aa452df1528 tests/e2e/run-m3-c731.sh --fresh
```
