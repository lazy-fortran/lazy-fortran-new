# Central Goal Mode instructions

Advance the Lazy Fortran compiler program from this repository. It is the
sole Goal Mode control plane.

## Cycle entry

Read `AGENTS.md`, `STATUS.md`, `TASK_POOL.yaml`, the active task, and its
named verifier/evidence. Load `MILESTONES.md`, `ROADMAP.md`, `repos.toml`,
contracts, review protocols, and `research/decision-log.md` only when the
active task names them or integration requires them. Reconcile the full
control plane at integration.

Use one active central task and one verifier. The verifier plus an independent
oracle determine status; local green tests, contracts, provenance, generated
code, hashes, traces and prose do not. Persist only durable results, blockers,
decisions, milestone changes, or reusable artifacts. Registered experiments
still obey the append-only rules in `RESEARCH.md`.

The installed skills provide the generic loop. Use `program-loop` with the
relevant domain skill as the baseline; invoke `evidence-gate`,
`parallel-luna`, `bounded-exploration`, and `expert-escalation` only at their
triggers. Use `fortran` for `fo`; use `referee` only for manuscripts.

For cross-repository work, use only `repos.toml`, pin every consumed revision,
commit component changes first, then update the central pin and run the
central verifier. A durable state change is pushed and remotely verified.
Do not start L2 or a second fixture family while the preceding replay gate is
open. A blocked leaf changes the active task; it does not end the mission.
