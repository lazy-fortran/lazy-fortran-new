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
