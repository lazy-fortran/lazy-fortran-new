# C718 reproducibility/control-plane review v2

Status: `PASS`
Origin: `LLM`
Functional snapshot: `a0a8da40e712068502a0dc5c7487e9b1ecacdbe1`
Control-plane head: `87b52cf0a87236a48804b513cb336014223fba9b`
Replay: `tests/e2e/run-m3-c718.sh .cache/runs/E0182/R000002`

E0182 pins the exact functional snapshot and standard-new
`f94c4c51b51fce22b533b7eeda08741970320913`. The clean replay R000002 confirms
the functional tree matches the pin, sxsemantic canonicalization, all PDF,
canonical-text, StandardIR, fixture and semantic-item hashes, exact committed
trace comparison, five mutation failures, zero model calls and zero semantic
promotions. The central and standard-new worktrees are clean and the remote
contains the control-plane head.

The control plane records the earlier R000033 pin mismatch as retained failed
evidence, the corrected R000034 replay, the exact command and all paths. Full
M3 remains OPEN because E0181 still has 4 hard failures, 2 unresolved rows,
94 disputed rows and 69 unwitnessed rows. This review authorizes promotion of
the bounded C718 slice only.
