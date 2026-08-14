# Integration lane

Owner: the central laboratory coordinator. This lane does not own compiler
code. It owns contract revisions, dependency-ready waves, production commit
pins, experiment/run records and cleanup.

## Wave protocol

1. inspect the target checkout and worktree. Require a clean exact base.
2. assign one vertical slice with explicit paths, contract revisions and gates.
3. run independent slices concurrently only when repositories and file scopes
   do not overlap.
4. while agents work, execute the coordinator's independent laboratory slice
   immediately; do not wait idle for reports or poll detached processes.
5. verify each report, diff, oracle and production gate.
6. merge verified slices promptly into the target main integration line.
7. append the run record, update the lane and central roadmap, then remove the
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

Wave K integrated the frontend diagnostic SX, AArch64 ELF64, and bounded
StandardIR structure-index slices. E0106 measured the latter against the
E0100/E0104 residue and found candidate evidence for 126 of 127 rows without
semantic promotion. The next M3 gate is a stricter laboratory-only definition
measurement. Production work may proceed concurrently only in disjoint
backend codec/decoder and contract-first middle-end scopes.

Wave L integrated the AArch64 ADD/SUB decoder and frontend StandardIR
syntax-item SX slices. The coordinator completed E0106 concurrently. Their
exact commits and gates are recorded in the run ledger; all task worktrees and
branches were removed after merge.

The current bounded production pins are `standard-new`
`27329a701575f32776281f235290e465c5588105`, `fortfront-new`
`0b84cd978af21c2cf5f66841794079172225332f`, `ffc-new`
`d83f5b7132d1e1250afb98583e287ae0b65267f9`, and `fortback-new`
`015393970b654a3f6ad557fc8084456d8a9e38d6`, all on clean `main` branches
tracking `origin/main`. Verify any pin with `git -C ../<repo> cat-file -t`
and the branch state with `git -C ../<repo> status --short --branch`.
Use the full commit argument for an immutable pin when checking a recorded
result.

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
