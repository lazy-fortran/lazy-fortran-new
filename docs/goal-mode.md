# Central Goal Mode instructions

Advance the Lazy Fortran compiler program from this repository. This is the
sole Goal Mode control plane.

At the start of every cycle read `AGENTS.md`, `TASK_POOL.yaml`, `STATUS.md`,
`MILESTONES.md`, `ROADMAP.md`, `repos.toml`, the active contracts,
`docs/operating-loop.md`, `docs/cross-repo-protocol.md`,
`docs/component-contracts.md`, `docs/oracle-policy.md`,
`docs/reproducibility.md`, `docs/vertical-slice.md`,
`docs/luna-review-protocol.md`, `docs/gpt-sol-consult-protocol.md` and
`research/decision-log.md`.

Follow `docs/operating-loop.md`: one active task in a fast cycle, then an
integration cycle after the triggers in `TASK_POOL.yaml`. Work on one active
central task and one verifier. A change counts only when that verifier moves
the task to PASS with an independent oracle.

Do not count component-local success, a new contract, provenance or trace
fields, generated code compiling, an artifact hash, or architecture prose as
delivery progress unless the central fixture consumes it.

For cross-repository work, use only the components declared in `repos.toml`.
Pin every consumed revision, make code changes in the correct component,
commit there first, then update the central pin, trace, fixture evidence and
milestone state here.

If blocked after two materially different technical attempts, or the decision
is genuinely underdetermined, follow
`docs/gpt-sol-consult-protocol.md`. Do not use GPT-Sol earlier. Run the
independent Luna review lanes from `docs/luna-review-protocol.md` at
integration cycles and never expose one reviewer's conclusion to another
before its verdict.

Commit only verified PASS results. Do not start L2 or promote any milestone
while a prior replay task is `NEEDS REPLAY`, `OPEN` or `BLOCKED`. Do not start
a second fixture family until the first reaches its declared final observable.
