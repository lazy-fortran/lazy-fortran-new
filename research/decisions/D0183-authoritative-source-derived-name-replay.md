# D0183. Identify the authoritative source-derived-name replay

Date: 2026-08-18
Status: accepted
Amends: D0182

## Context

D0182 correctly fixed the J3-24-007 source hash, but it named R000692 as the
authoritative replay. R000693 is the later no-bootstrap replay at central
`0ac0e88e2add068b7ac434c46473657a66438f6e`; it consumes the same committed
producer, replay harness and trace after the D0182 amendment. Central
`6b7ab6a5a9972f1ab1675f09a3163dfd9c6efa07` records R000693 and changes only
control-plane run/task/index metadata after that executable replay.

## Decision

Treat R000693 as the authoritative technical replay for promotion. Its exact
command is:

```text
AST_EXPECTED_CENTRAL_COMMIT=0ac0e88e2add068b7ac434c46473657a66438f6e tests/e2e/run-frontend-ast-v1-name-derived.sh --fresh
```

The executable lineage is explicit: R000693 ran at `0ac0e88`; the evidence
packet at `6b7ab6a` is its metadata-only descendant. R000692 remains retained
as an earlier no-bootstrap replay. The source-document SHA remains the full
value `1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e`.

## Rejected

Rerunning solely to manufacture a later hash, editing an earlier run, or
calling the metadata descendant a fresh executable replay is rejected. The
recorded base-plus-descendant lineage is the evidence.

## Reversal condition

Write a successor if a clean replay at `0ac0e88` no longer reproduces the
committed trace, if the metadata descendant changes an executable input, or if
the source hash disagrees with the pinned manifest or StandardIR.
