# Focused review: typed AST v1 exact `alpha` witness

The corrected E0239 replay is promotable only under D0179's bounded
multi-character name/span boundary. The evidence packet is central revision
`f5111ec5f594fc53746b2d2a8a16fa742172ee84`; its frozen executable revision is
`7e9e8a4a41d7956ad4c367b42c46121ae9e7a8e1`, and the producer is fortfront
`101965227a3583872eb7db22c04cd6ff40738c82`.

R000686 is the corrected no-bootstrap replay. It executes the exact
`program p / integer :: alpha / end program p` source, emits the typed name
`alpha` with integer declaration span 10 through 28 and the pinned source-hash
label, executes the promoted `z` control through the same producer and compares
it with the established z golden, rejects `integer ::`, repeats alpha output
identically, passes the schema-linked independent oracle and records zero model
calls and semantic promotions.

The exact executable command is:

```text
AST_EXPECTED_CENTRAL_COMMIT=7e9e8a4a41d7956ad4c367b42c46121ae9e7a8e1 \
tests/e2e/run-frontend-ast-v1-name-multichar.sh --fresh
```

The final independent focused reviews R000687 and R000688 both pass scope,
lineage, pins, alpha fields and span, behavioral z control, malformed
rejection, repeat and trace reproducibility, oracle independence and
promotion safety. R000685 is retained: it records the independent oracle
catching the initial handwritten root-span error (`43` instead of `42`)
before promotion.

This promotes only the exact alpha witness. It does not establish arbitrary
identifier parsing, declaration parsing, semantic analysis, MIR or full M3.
The contract witness remains labelled `origin llm`; deterministic replay and
independent review, not model output, authorize the bounded promotion.
