# C729 semantic/source review v1

Status: `PASS`
Origin: `LLM`
Functional snapshot: `7dea0540962b02460c1e89eef9f80f1615524b47`
Control-plane head: `e733e9aff152c861bd151a3570178001b3d876bc`
Replay: `tests/e2e/run-m3-c729.sh --fresh` (authoritative result `R000003` / `R000042`)

The typed candidate is bounded to comma and context states. The oracle
computes C729 before comparing expected labels: absent comma and present comma
in the allowed declaration-type-spec/type-declaration-stmt context are
`ACCEPTED`, a present comma in another known context is `REJECTED`, and
unknown state is `UNRESOLVED`. The source binding is exact for canonical-text
line 3466, page 84, and StandardIR R722/R703/R801. The four cases produce two
accepted, one rejected and one unresolved outcome; all five mutation controls
fail closed. No parser, declaration/name/type analysis, model input or
semantic promotion path is present.

This semantic/source scope passes. It authorizes only bounded C729 promotion;
full M3/Core 0 remains open.
