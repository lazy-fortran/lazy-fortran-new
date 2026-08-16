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

The integration cycle freezes new task selection, verifies all component pins,
replays every relevant central verifier from a clean checkout, runs the four
independent Luna reviews in `docs/luna-review-protocol.md`, and reconciles
`STATUS.md`, `MILESTONES.md`, `TASK_POOL.yaml` and evidence. A milestone is
not promoted until the integration cycle agrees with its independent oracles.

After a successful integration cycle, select the next dependency-ready OPEN
task. A local milestone PASS is a transition point, not a reason to stop the
long-horizon loop.

## Failure and consultation

Increment `retry_count` for each failed verifier attempt and retain every
failure. After two materially distinct technical attempts, or when evidence
cannot determine a design/specification choice, use the bounded GPT-Sol
protocol. Do not ask GPT-Sol for routine implementation, status, or prose.

If no dependency-ready task exists, mark the active task BLOCKED with the
exact missing prerequisite and stop for new authority or evidence. Do not
invent a parallel task or a new framework.

## Delivery prohibition

The following are never central progress by themselves: architecture prose,
provenance fields, correspondence records, generated code compiling,
component-local tests, artifact hashes, or traces that no independent test
consumes. They become relevant only when the active central verifier consumes
them on the declared vertical path.
