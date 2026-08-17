# M3 C748 bounded component-attribute at-most-once oracle

Bounded-slice status: `PASS`; C748 is promoted only as this bounded oracle leaf
after focused independent review R000580. Full M3 remains `OPEN`. This artifact
does not claim a Fortran parser, name resolver or complete semantic analyzer.

## Source contract

The corrected contract is D0156, amending D0155. It binds J3-24-007 clause 7,
canonical line 3834, printed page 79, UTF-8 byte span `240727:97`, and
canonical page-index record 93 (`start 239957`, `length 2451`) to StandardIR
R737 (`data-component-def-stmt`). The normative text says that no
component-attr-spec shall appear more than once in a component-def-stmt; this
is an at-most-once constraint, so zero occurrences are valid. The validator
independently requires unique byte-span containment by page-index record 93.

The typed candidate fields are:

```text
attribute-name-presence: absent | present | unknown
definition-occurrence-cardinality: zero | one | many | unknown
context: component-def-stmt | other | unknown
```

The deterministic oracle accepts absent attributes and present/zero or
present/one in component-definition context, rejects present/many there, and
returns `UNRESOLVED` for all other states. It does not inspect actual
attribute spellings, parse a component definition, or check C749--C751.

## Replay

The clean central verifier is:

```text
M3_C748_EXPECTED_CENTRAL_COMMIT=<current-commit> tests/e2e/run-m3-c748.sh --fresh
```

It passed in E0214/R000004 with central worktree revision
`b3abc202c9e0b82058feccfc1c06099715b589c9`, the corrected functional revision
`d60211a`, and `standard-new` at
`f94c4c51b51fce22b533b7eeda08741970320913`. The recorded result and committed
trace both have SHA-256
`c7eff81858ef61a7194faf97555de9a671a03c7170ee11e6b8dc69c87af72c2e`. The
run environment has SHA-256
`63602187297326ba8cd47f403eba1eadfffb2442cab00affb4ef40432b9334eb`.

The independent validator has SHA-256
`fa40c2d7e260fba655b91bbf88c22aa1604b91c168f5cad2adbc817df1e21be3`. The
36-state typed product has 6 `ACCEPTED`, 1 `REJECTED` and 29 `UNRESOLVED`
outcomes. Twelve source, page-index, StandardIR, contract and semantic
identity mutation controls are rejected. Model calls and semantic promotions
are both zero.

## Evidence

The independent expected-outcome table is
`tests/fixtures/m3-c748-expected-outcomes-v1.json` with SHA-256
`8d1122edfad7bcf600f9729c4d2625ed3fb319b1cf2868036aa033bac171997f`.
The source-backed fixture is
`tests/fixtures/m3-c748-source-backed-v1.json` with SHA-256
`a5d8b70724dd36e9d16addd3e5f0ea34c57505a7d51180f38df35dc95febf336`.
The semantic fixture and golden output have SHA-256
`00835d33b235953735bad59d4762c7aac146d88fd978c10da6f7ecb364f0008f`.
The committed trace is `artifacts/traces/m3-c748-source-backed-v1.json`.

## Review outcome

The semantic and reproducibility focused reviewers both returned `PASS` with
no findings. Their lifecycle records remain open for the parent M3 claim;
this promotion is limited to the bounded C748 oracle leaf. The v0
exact-once review failure is retained in R000578 and is not promoted.

## Non-claims

This leaf does not check C749 through C751, perform case folding or name
resolution, diagnose arbitrary Fortran, restart E0172 or close full M3.
