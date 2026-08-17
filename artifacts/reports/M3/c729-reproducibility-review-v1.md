# C729 reproducibility/control-plane review v1

Status: `PASS`
Origin: `LLM`
Functional snapshot: `7dea0540962b02460c1e89eef9f80f1615524b47`
Control-plane head: `e733e9aff152c861bd151a3570178001b3d876bc`
Standard-new: `f94c4c51b51fce22b533b7eeda08741970320913`
Replay: `tests/e2e/run-m3-c729.sh --fresh` (authoritative result `R000003` / `R000042`)

E0184 pins the exact functional snapshot and clean standard-new revision.
The append-only R000039→R000040→R000041→R000042 chain retains the initial
metadata defect and its correction; R000042 is the authoritative fresh
replay. R000002 and R000003 demonstrate repeatable `--fresh` allocation. The
result and committed trace hashes match, the schema hash is exactly 64
characters, source and contract gates pass, and the runner ends with clean
checkouts. Model calls and semantic promotions are zero.

This reproducibility/control-plane scope passes. Together with the semantic
review, it authorizes only bounded C729 promotion; full M3/Core 0 remains
open.
