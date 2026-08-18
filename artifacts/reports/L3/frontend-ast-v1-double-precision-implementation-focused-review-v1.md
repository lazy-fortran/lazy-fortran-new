# DOUBLE PRECISION AST-v1 implementation and replay focused review

Central revision: `82bed395cc743e5f3f2a0a8139aa46b05b8d4308`
Component revision: `c3647c4ba3d8740afcf2b96af0ea0cdf39dfad19`
Review model: `gpt-5.6-luna`, medium, two independent reviewers
Scope: exact DOUBLE PRECISION implementation/replay leaf only

## Verdict

PASS for the bounded implementation and replay.

Both reviewers reproduced the no-bootstrap replay and confirmed exact source
spelling `double precision` maps to AST-v1 atom `double-precision`; the REAL
control remains `real`; identities are `main`/`main`/`x`; positive outputs are
byte-identical on repetition; and the malformed declaration produces no AST
and the frozen rejection marker. The committed trace and replay outputs match.

Central and component branches are clean and pushed. The replay manifest hash
is `2aae73ad974beac9e71d68e079213ec0fc6d60f9dcf615ddb18042046aa0be3d`; the
trace hash is
`558d0f5ba1bc29f642bd7c439847216831c0454d250c08013cd783447a7f1702`.
R000720 remains the original caught serializer-boundary failure. R000724 is
retained stale metadata and is excluded from promotion; R000725 and R000726
are the corrected replay lineage, with R000726 superseding R000725.

This promotes only the exact bounded producer/replay leaf. It does not promote
general parsing, semantic analysis, schema expansion or M3 semantics.

Runs: R000727, R000728.
