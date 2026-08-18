# Focused review: bounded REAL type-spec implementation

Task: `T-L3-frontend-real-type-implementation`

Frozen executable revision: `f47b064206af6a45d5101764e03bf38a9de8698e`

Pushed component revision: `c91595db71aa353564ec5a7f8c2a61b80e82b389`

The central no-bootstrap replay `R000709` accepts the exact `real :: x`
source and the changed-type `integer :: x` control, repeats both AST outputs
byte-for-byte, and rejects the malformed `real ::` neighbour. The independent
replay oracle checks the typed AST root, declaration, variable type/name and
source paths. The committed trace hash is
`a97d8469d9ffc92286a8ca76db1f50309cb7bbcde262417ad0225e1619bf7214`.

The initial runner wiring failure is retained as `R000707`; bootstrap replay
`R000708` and clean no-bootstrap replay `R000709` are the successful technical
evidence. The producer component gate passed on the isolated worker and again
on pushed main. No schema, kind-selector, general parser, semantic-analysis,
or backend change is included.

Final focused review:

- Scope C, adversarial correctness and scope: `PASS`.
- Scope D, reproducibility and evidence integrity: `PASS`.

Both reviewers used `gpt-5.6-luna` with medium reasoning on the same frozen
packet. The result is `PASS-BOUNDED-ONLY`; it is not a claim that arbitrary
Fortran or full M3 semantics are implemented.
