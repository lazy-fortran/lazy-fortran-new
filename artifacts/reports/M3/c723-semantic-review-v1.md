# C723 semantic/source review v1

Status: `PASS`
Origin: `LLM`
Functional snapshot: `dc39e23d383b5eec182596a5dda08de20bcae624`
Control-plane head: `51a64d03a8d11ac0bff659c60e2e6a28dc876e67`
Replay: `tests/e2e/run-m3-c723.sh .cache/runs/E0183/R000001`

The typed candidate is bounded to shape and value-type states. The oracle
computes only scalar plus integer/real legality from those fields. It does not
resolve names, parse expressions, evaluate literals, select kinds, inspect
processor facts, perform compiler work or consume model output. The C723 source
binding is exact: canonical-text line 3396 and StandardIR R718/R719/R720 match
the pinned pages, byte spans, source hash and occurrence identities.

Outcomes are computed before expected labels are checked. The fixture contains
two accepted scalar integer/real witnesses, one rejected non-scalar neighbour
and one unknown-type unresolved control. All five source/rule identity
mutations fail closed. The committed result records two `ACCEPTED`, one
`REJECTED`, one `UNRESOLVED`, zero model calls and zero semantic promotions.

Checks: independent inspection of the pinned source and StandardIR rows,
`python3 tests/e2e/validate_m3_c723.py --self-test`, committed result and trace
hash comparison. This review passes the semantic/source scope only; paired
focused review is required for bounded-slice promotion, and full M3 remains
open.
