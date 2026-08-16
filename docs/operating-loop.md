# Persistent Goal Mode operating loop

`lazy-fortran-new` is the control plane. `TASK_POOL.yaml` is the durable
dependency queue; `STATUS.md` is the current factual handoff; `MILESTONES.md`
is the definition-of-done ledger. The existing `ROADMAP.md` remains the
long-horizon architecture and research plan. Component repositories remain
implementation repositories and never acquire a competing loop.

When `ROADMAP.md` and `STATUS.md` disagree about the current delivery
position, `STATUS.md`, `MILESTONES.md` and `TASK_POOL.yaml` govern the active
loop. Preserve the roadmap wording and record the discrepancy; do not infer a
promotion from prose or commit history.

## Entry point

Every Goal Mode cycle starts by reading, in this order:

1. `AGENTS.md`
2. `TASK_POOL.yaml`
3. `STATUS.md`
4. `MILESTONES.md`
5. `ROADMAP.md`
6. `repos.toml`
7. the active contracts and the documents listed in `docs/goal-mode.md`
8. the active task's fixture, verifier and evidence paths

The active task is the only task that may be implemented in a fast cycle.
Its status is changed only by executing its named verifier. Commit messages,
component-local green tests, and plausible generated output do not change
central status.

## Fast cycle

A fast cycle is one bounded task and one verifier:

1. Check that the assigned component checkouts and central checkout are clean.
2. Read the active task and its prerequisites.
3. Make the smallest change in the owning repository or central lab area.
4. Run the named verifier and its independent oracle.
5. Record hashes, diagnostics, retry count and evidence.
6. If PASS, update the task pool and select the next dependency-ready task.
7. If FAIL, retain the failure and retry only with a materially distinct fix.

For ordinary meaningful work, the installed `parallel-luna` skill may run one
micro-review against the immutable task packet. Its PASS is ephemeral; its
issue form returns to the active task. It does not create a review file,
ledger entry or commit by itself.

No fast cycle may silently promote a milestone, begin L2 while an L0/L1
replay gate is open, or turn an unconsumed trace into delivery progress.

Every milestone PASS requires all of these, even when its local definition
lists fewer details: pinned component revisions; a positive fixture; an
invalid near-neighbor; an independent oracle; clean-checkout reproduction; a
regression-corpus entry; and trace/artifact evidence.

## Integration cycle

Enter an integration cycle after any one of these events:

- four verified deltas;
- three consecutive no-progress cycles;
- a milestone PASS;
- a contract, schema, repository pin or interface change.

The integration cycle freezes new task selection, verifies relevant component
pins, replays the relevant central verifier from a clean checkout, and
reconciles durable state. It selects the review level in
`docs/luna-review-protocol.md`: focused parallel review is reserved for
milestone promotion, cross-component interfaces, major reusable artifacts and
release-level claims; a routine integration check need not start a panel. A
milestone is not promoted until its evidence gate and required independent
review agree with its oracles.

After a successful integration cycle, select the next dependency-ready OPEN
task. A local milestone PASS is a transition point, not a reason to stop the
long-horizon loop.

## Blocked leaves are not terminal

A blocked replay, milestone task, unavailable oracle, missing contract, or
reviewed external dependency is a property of one delivery leaf, not of the
compiler mission.

If the active task is `BLOCKED`, `NO_PROGRESS`, or exploration returns
`NO_USEFUL_CANDIDATE`:

1. keep the exact blocker, failed routes and missing input in working context;
2. persist and commit them only if continuation depends on surviving restart;
3. mark only that task `BLOCKED` when durable task state is being kept;
4. select the highest-information independent dependency-ready `OPEN` task;
5. if none exists, use bounded exploration and expert escalation to create one
   bounded, falsifiable evidence-acquisition task;
6. continue the program loop.

`NO_USEFUL_CANDIDATE` ends one exploration episode. It never ends the
compiler mission. Do not invent an unbounded framework or silently start a
second fixture family.

## Mission hard stop

An agent may not self-declare terminal hard stop. It may create a
`MISSION_HARD_STOP_PROPOSED` record only if every known delivery leaf is
closed, refuted, blocked, or conditional; independent open-leaf searches are
exhausted; the consultation protocol has run; independent reviewers confirm
the inventory; and exact missing external inputs are named.

After creating such a record, continue with reproducibility maintenance,
dependency/literature watch, bounded evidence acquisition, task-pool refresh,
or explicit user direction. Only explicit user instruction, terminal delivery
proof, or terminal refutation ends the compiler mission.

## Delivery prohibition

The following are never central progress by themselves: architecture prose,
provenance fields, correspondence records, generated code compiling,
component-local tests, artifact hashes, or traces that no independent test
consumes. They become relevant only when the active central verifier consumes
them on the declared vertical path.

Routine reading, debugging, informal experiments and `NO_PROGRESS` likewise
do not create governance notes or mandatory commits unless they produce a
durable result, blocker, decision, milestone change or reusable artifact.
