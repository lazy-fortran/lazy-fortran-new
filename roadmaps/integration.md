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

Wave X has integrated the indexed frontend program-declaration query and the
source-backed RV64 SRLI codec. Both passed coordinator-side full `fo` gates;
their task branches were deleted and their production mains are clean and
pushed. The MIR instruction result-type query also passed its coordinator-side
full `fo` gate and was merged and pushed. These additive boundaries do not
redefine a contract, promote semantic facts, or close M3.

Wave Y has integrated the indexed frontend program-declaration-count query.
It passed the coordinator-side full `fo` gate and its task branch was deleted
after push. The source-backed RV64 SRAI slice also passed the full `fo` gate,
was merged and pushed, and its task branch was deleted. The M4 generation
experiment E0119 is reported separately as `R000192` for its first AST/wiring
slice. These boundaries do not redefine a contract, promote semantic facts,
or close M3/M4.

Wave Z has integrated the source-preserving `frontend-ast-v0` SX handoff into
`ffc-new`. It passed coordinator-side full `fo`, retained source spans and
hashes, and its task branch was deleted after push. Wave AA subsequently
integrated the deterministic generator consuming that handoff; neither wave
redefines `mir-v0`, promotes semantic facts, or closes M3/M4.

Wave AA has integrated the deterministic `frontend-ast-v0` generator and its
checked-in generated Fortran records in `fortfront-new`. The generator,
canonical SX witness, malformed/unsupported schema controls, negative
provenance/span/count cases and full `fo` gate passed; the task branch was
deleted after push. E0119 is reported accepted as `R000192` for this first
AST/wiring slice; complete M4 still requires the lexer, parser, semantic and
lowering gates.

The next production backend slice is integrated at `fortback-new`
`dcbae9882850efbe246b8faf22394306589ce530`: a source-backed RV64I `SLTIU`
codec with canonical encoding, malformed/unsupported/wrong-target controls,
and preserved source provenance. Coordinator-side full `fo` passed, the task
branch was removed, and no MIR or AArch64 files changed.

The following backend slice is integrated at `fortback-new`
`205fe1c2cf994274b87f676f07c57fddb911da23`: a source-backed RV64I `XORI`
codec with canonical encoding/decoding, malformed/unsupported/invalid-operand/
wrong-target controls, and preserved source provenance. Coordinator-side full
`fo` passed; the task branch was removed and no MIR or AArch64 files changed.

The first post-D0072 backend slice is integrated at `fortback-new`
`c48922d5dd9ebc9b0524a1f6eb14c3697c5e7327`: a generic source-record-driven
RV64I I-format encoder/decoder. It adds no mnemonic dispatch branch and checks
XORI, shift-shaped and JALR-shaped records through independent metadata,
operand, target and provenance controls. Coordinator-side full `fo` passed,
the task branch was removed, and no MIR or AArch64 files changed.

The second post-D0072 backend slice is integrated at `fortback-new`
`600457fb60eb74ee99cd2d647c6382bcf21f1afe`: a generic AArch64 fixed-record
validator/matcher over imported ADD, SUB and NOP records. It checks mask/match
selection, name independence, malformed metadata, unsupported words, target
identity and source provenance. Coordinator-side full `fo` passed, the task
branch was removed, and no mnemonic dispatch, ABI or MIR behavior changed.

The parallel middle-end slice is integrated at `ffc-new`
`1d356b42dd7821cfebea9fec78291a2c37e456e8`: a generic instruction result-ID
query reusing the validated MIR accessor, with independent valid, malformed,
index-boundary, output-clearing and diagnostic controls. Coordinator-side full
`fo` passed, the task branch was removed, and `mir-v0`, frontend lowering and
backend-specific details were unchanged.

The parallel frontend slice is integrated at `fortfront-new`
`7bb9eae735c21f94bb123c3c6c4048f29b6bcb7e`: a bounded
program/module/subroutine/function
source-witness parser with exact terminator/name matching, span checks and
rejection controls. Coordinator-side full `fo` passed, the task branch was
removed, and no frontend-ast-v0 or mir-v0 contract changed.

The current bounded production pins are `standard-new`
`5c1d258e61c38336cfbb316b76ba8b33e4717b94`, `fortfront-new`
`7bb9eae735c21f94bb123c3c6c4048f29b6bcb7e`, `ffc-new`
`1d356b42dd7821cfebea9fec78291a2c37e456e8`, and `fortback-new`
`600457fb60eb74ee99cd2d647c6382bcf21f1afe`, all on clean `main` branches
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
