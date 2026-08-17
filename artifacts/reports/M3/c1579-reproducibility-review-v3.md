# C1579 reproducibility/control-plane review v3

Status: `PASS`

Snapshot: central commit `008d6e30dc0db0010a50a2d10f458b88039ddac4`.

`HEAD` and `origin/main` match and both central and standard-new worktrees are
clean. The exact command `tests/e2e/run-m3-c1579.sh --fresh` produced
E0187/R000004, recorded as R000062; the result equals the committed trace and
all source, page-index, schema, fixture, environment and toolchain hashes
match. The retained failures R000058, R000059, R000061 and R000063 remain
visible. Current control-plane handoff references use E0187/R000004 and
R000062; the bounded promotion leaves full M3/Core 0 open.
