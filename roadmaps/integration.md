# Integration lane

Owner: the central laboratory coordinator. This lane does not own compiler
code. It owns contract revisions, dependency-ready waves, production commit
pins, experiment/run records and cleanup.

## Wave protocol

1. inspect the target checkout and worktree. Require a clean exact base.
2. assign one vertical slice with explicit paths, contract revisions and gates.
3. run independent slices concurrently only when repositories and file scopes
   do not overlap.
4. verify each report, diff, oracle and production gate.
5. merge verified slices promptly into the target main integration line.
6. append the run record, update the lane and central roadmap, then remove the
   local worktree/branch and any published remote task branch.

The coordinator never calls an unverified commit integrated. A failed or
abandoned slice remains in the run ledger with its last commit and failure
state before cleanup. A later slice starts from the newly integrated commit,
not from a stale long-lived task branch.

Wave H is complete for three bounded slices: frontend typed-program-unit SX,
program-declaration-SX-to-MIR lowering, and the RISC-V instruction-to-ELF
witness. E0102 is recorded separately as the first strict Luna semantic
escalation. Wave I is complete for warning cleanup in StandardIR, the
frontend, and the backend, plus the E0103 deterministic relation audit. The
Wave J is complete for the frontend semantic-table consumer, the program-unit
structural bridge, and E0104's bounded multi-line search. E0104 produced no
unique resolutions, so the coordinator pauses at the documented semantic
escalation gate. D0046 now authorizes one bounded document-structure
extraction slice; no new wave should add unjustified document-specific
heuristics or promote semantic facts before its measurement.

The cleanup sequence is explicit:

```sh
git worktree remove /path/to/task-worktree
git branch -d task-branch
git ls-remote --exit-code --heads origin task-branch
git push origin --delete task-branch
git fetch origin --prune
```

Run the remote deletion only when the preceding lookup finds the branch. An
absent remote branch is already clean. A dirty worktree, an unmerged branch or
a network/authentication error stops cleanup for review.

## Cross-lane gates

- StandardIR output is source-backed before frontend acceptance claims.
- frontend output satisfies `frontend-v0` before middle-end lowering claims.
- MIR is stable before backend legalization or instruction-selection claims.
- TargetIR source classes and emission records are present before machine-code
  performance claims.
- every cross-repository result names the contract revisions and exact commits
  used to produce it.
