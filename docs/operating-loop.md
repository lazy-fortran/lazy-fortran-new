# Persistent Goal Mode operating loop

`lazy-fortran-new` is the control plane. `TASK_POOL.yaml` is the dependency
queue, `STATUS.md` is the factual handoff, `MILESTONES.md` is the delivery
ledger, and `ROADMAP.md` is the strategic archive. Components never acquire a
competing loop.

## Entry point

At fast-cycle entry read `AGENTS.md`, `TASK_POOL.yaml`, `STATUS.md`, the
active task, and its verifier/evidence paths. Load the roadmap, contracts,
component records, and review protocols only when named by that task or when
integration requires them. Reconcile the full control plane at integration.

## Fast cycle

Work on one active task and one verifier:

1. Read its statement, prerequisites, scope, and declared oracle.
2. Make the smallest change in the owning repository or central lab area.
3. Run the verifier and independent oracle; classify `PASS`, `FAIL`,
   `BLOCKED`, `CONDITIONAL`, or `NO_PROGRESS`.
4. Persist only a durable result, blocker, decision, milestone change, or
   reusable artifact. After `PASS`, select the next dependency-ready task;
   after failure, retry only with a materially distinct fix.

Component-local success, generated code, provenance, hashes, traces, and prose
do not advance central status unless the central fixture consumes them.
Historical evidence whose clean-checkout conditions are not verified for this
checkout is `NEEDS REPLAY`.

Use installed review and evidence skills only at their triggers. A cheap
micro-review is optional for meaningful work; focused review and the full
evidence gate are for milestone promotion, cross-component interfaces, major
reusable artifacts, and release claims.

Every durable commit is pushed to its configured upstream and remotely
verified before it is called integrated. Scratch work and ordinary
`NO_PROGRESS` remain ephemeral.

## Integration cycle

Enter integration after four verified deltas, three no-progress cycles, a
milestone pass, a durable closure/refutation, or a contract, schema, pin, or
interface change. Freeze task selection; verify pins and replay the relevant
central fixture from a clean checkout; reconcile state, evidence, and review;
then select the next `OPEN` task.

Every milestone pass requires the declared component pins, positive fixture,
invalid near-neighbor, independent oracle, clean-checkout reproduction,
regression entry, and trace/artifact evidence. Do not start L2 or a second
fixture family while an earlier replay gate is `NEEDS REPLAY`, `OPEN`, or
`BLOCKED`.

## Blocked leaves

A blocked leaf does not end the compiler mission. Preserve the exact blocker
only when restart or task switching needs it, then choose the highest-
information independent `OPEN` leaf. If none exists, activate bounded
exploration and, only after its trigger, expert escalation. A
`NO_USEFUL_CANDIDATE` result ends one exploration episode, not the mission.

Never self-declare a terminal hard stop. A `MISSION_HARD_STOP_PROPOSED` record
requires an exhausted open-leaf inventory, required consultation and review,
and exact missing external inputs; continue maintenance or evidence work
afterward.
