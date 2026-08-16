# Central Goal Mode instructions

Advance the Lazy Fortran compiler program from this repository. This is the
sole Goal Mode control plane.

At the start of every cycle read `AGENTS.md`, `TASK_POOL.yaml`, `STATUS.md`,
`MILESTONES.md`, `ROADMAP.md`, `repos.toml`, the active contracts,
`docs/delivery-method.md`, `docs/operating-loop.md`,
`docs/cross-repo-protocol.md`,
`docs/component-contracts.md`, `docs/oracle-policy.md`,
`docs/reproducibility.md`, `docs/vertical-slice.md`,
`docs/luna-review-protocol.md`, `docs/gpt-sol-consult-protocol.md` and
`research/decision-log.md`.

## Reusable skill routing

Use the installed current skills rather than reproducing their instructions:

- `program-loop` is the outer loop; the active task comes from
  `TASK_POOL.yaml` and a blocked leaf does not end the mission.
- `evidence-gate` supplies the smallest relevant check for ordinary work and
  the full gate only for durable promotion.
- `parallel-luna` defaults to one cheap, ephemeral micro-review for
  meaningful work. Use focused parallel review only for milestone promotion,
  cross-component interfaces, major reusable artifacts and release-level
  claims. Use full review only for a release/public or otherwise explicitly
  requested claim.
- `bounded-exploration` is limited to its stated blocked-task trigger;
  `expert-escalation` follows it or two distinct failed attempts and remains
  provisional until verified.
- `fortran` routes Fortran work through the local `fo` workflow;
  `referee` is unrelated to compiler delivery and is used only for manuscript
  reviews.

Routine reading, debugging, informal experiments and `NO_PROGRESS` do not
require a governance note, review file or commit. Persist only a result,
blocker, decision, milestone change or reusable artifact that must survive a
restart. A formally registered experiment still follows the append-only run
rules in `RESEARCH.md`.

Follow `docs/operating-loop.md`: one active task in a fast cycle, then an
integration cycle after the triggers in `TASK_POOL.yaml`. Work on one active
central task and one verifier. A delivery result counts only when that
verifier moves the task to PASS with an independent oracle. A reviewed state
change may still be committed when continuation depends on recording a
blocker or switching the active task; it must not claim a delivery PASS.

Do not count component-local success, a new contract, provenance or trace
fields, generated code compiling, an artifact hash, or architecture prose as
delivery progress unless the central fixture consumes it.

For cross-repository work, use only the components declared in `repos.toml`.
Pin every consumed revision, make code changes in the correct component,
commit there first, then update the central pin, trace, fixture evidence and
milestone state here.

If blocked, keep the leaf's exact blocker and attempted routes ephemeral
unless they must survive a restart, then switch to the highest-information
independent `OPEN` task. The mission continues. After the trigger, follow
`docs/gpt-sol-consult-protocol.md`; do not use GPT-Sol earlier. Choose the
Luna review level from `docs/luna-review-protocol.md` rather than attaching a
parallel panel to every integration cycle.

Commit verified results or reviewed state updates. Do not start L2 or promote
any milestone while a prior replay task is `NEEDS REPLAY`, `OPEN` or `BLOCKED`.
Do not start a second fixture family until the first reaches its declared
final observable.
