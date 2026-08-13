# D0043. Central roadmap and delegated production slices

Date: 2026-08-13
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

The program has one laboratory and several production repositories. Adding a
roadmap, experiment ledger or model transcript to every production repository
would duplicate planning state and create repository churn. Work now needs to
proceed in parallel on sibling checkouts, including a future `fortback-new`,
while decisions and evidence remain centrally searchable.

## Decision

Keep `lazy-fortran-new/ROADMAP.md` as the sole program roadmap. `standard-new`,
`fortfront-new`, `ffc-new` and `fortback-new` remain production repositories
without local research roadmaps unless later evidence requires a local
implementation plan.

Production repositories own their specifications, implementation, generated
source and behavioral tests. The laboratory owns decisions, experiments, runs,
provenance, external-source manifests, cross-repository contracts and
integration status.

Parallel implementation is delegated as bounded one-shot GPT-5.6 Luna tasks.
Each task receives exactly one sibling production checkout, branch, base commit,
scope, accepted decision IDs and test command. Its working directory is the
assigned production repository, never the laboratory. It may not edit the lab
or another production repository. The task reports its base commit, branch,
resulting commit, changed files, tests, warnings, decisions encountered,
experiment needs and blockers. The central agent then updates lab metadata and
pins the resulting production commit in any experiment that uses it.

No orchestration framework or shared mutable worktree is introduced. Separate
repository checkouts and non-overlapping slices provide the parallelism.

## Rejected

Adding a `ROADMAP.md` to every production repository is rejected because it
duplicates the central phase gates. Letting delegated agents edit decisions or
experiment records directly is rejected because it makes the evidence ledger
race-prone. A permanent task scheduler or service is rejected because explicit
one-shot delegation is sufficient and the lab must remain a searchable file
record.

## Reversal condition

Write a successor if a production repository needs an implementation plan that
cannot be represented as a bounded central slice, or if parallel work
repeatedly produces integration races despite exact commit pins and
non-overlapping scopes.
