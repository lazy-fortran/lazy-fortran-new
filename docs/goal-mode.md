# Central Goal Mode instructions

Advance the Lazy Fortran compiler program from this repository. It is the
sole Goal Mode control plane.

Ordinary implementation uses the code-first default in `AGENTS.md`: edit,
check as useful, make a normal commit, and push. The control-plane procedure
below is for explicitly requested experiments, audits, releases, and milestone
promotion.

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

## Fast-wave rule

The governing decision is D0167.
When the active task is a fixture harvest, the controller may dispatch
independent Luna workers from frozen source partitions. Use `gpt-5.6-luna`
with reasoning effort `medium`. Workers return provisional batch artifacts and
never edit central state. The controller performs one intake pass, then
dispatches independent ready implementation candidates while later harvest
continues. The exact candidate verifier and independent oracle remain the
promotion authority.
