# D0044. Parallel lanes, versioned contracts and branch lifecycle

Date: 2026-08-13
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

The program now has several production repositories and needs to consume the
roadmap from the front, middle and back without turning production repositories
into planning repositories. Exact pins and non-overlapping slices are useful,
but they do not by themselves expose the interfaces that let independent work
converge. Long-lived task branches and worktrees would also turn small slices
into an accumulating merge queue.

## Decision

Keep `ROADMAP.md` as the sole program roadmap and add concise central lane
roadmaps under `roadmaps/`. Keep cross-repository interfaces as versioned SX
schemas under `contracts/`, with canonical witnesses under
`contracts/fixtures/`. The laboratory owns contract revisions, compatibility
decisions, source pins, run records and integration status. Production
repositories own implementations, generated source and behavioral tests.

Use one vertical slice per delegated agent. A slice has one exclusive checkout
or worktree, one exact base commit, one short-lived task branch, explicit file
scope, pinned contract revisions, and an independent behavioral or structural
oracle. Launch slices in dependency-ready waves. Do not speculate past an
unavailable contract merely to increase concurrency.

Contract revisions are additive by default. A breaking change requires a new
revision, a decision record and a migration slice. Agents may self-decide a
local reversible detail when simplicity, provenance and generated performance
clearly determine it under D0028. They report a boundary instead of silently
changing a cross-repository contract.

The central agent verifies the base, diff, tests and oracle before integration.
Merge small verified slices frequently into the target repository's main
integration line. A task is not complete merely because it has a commit: it is
complete when the verified commit is merged and the relevant CI or repository
gate has passed.

After a successful merge, the coordinator removes the task worktree, deletes
the local task branch, and deletes the remote task branch if one was published.
The coordinator first verifies that the worktree is clean and records the
merged commit in the laboratory. An abandoned task follows the same cleanup
only after its last commit, report and failure state are recorded. Never force
delete a dirty worktree or an unmerged branch without explicit authorization.

## Rejected

Repo-local roadmaps and mirrored contracts are rejected because they drift and
create production churn. Flexible shared evolution is rejected because it
makes a consumer unable to identify the interface it was tested against.
Persistent lane branches are rejected because frequent small merges provide a
shorter and more auditable integration path. A permanent scheduler or cleanup
service is rejected. The central agent performs explicit lifecycle actions.

## Reversal condition

Write a successor if additive contract revisions repeatedly prevent useful
parallel work, if frequent integration causes measured instability despite
independent slices, or if the cleanup protocol loses a committed result or
leaves remote task branches accumulating.
