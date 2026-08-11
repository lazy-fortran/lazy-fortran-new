# D0001. Cross-repository wiring without git submodules

Date: 2026-08-11
Status: accepted

## Context

The program spans five production repositories plus a set of oracle checkouts.
Something has to record which repositories exist, where they live, and what
state they are in. The existing workspace already had a `ROADMAP.md` at
`~/code/lazy-fortran/` doing this by hand, with a table of commit hashes typed
into a document, and it notes itself that the workspace root is not a git
repository and the file cannot be committed.

## Decision

One flat `repos.toml` listing production repositories and oracles, with
`scripts/bootstrap.sh` to clone what is missing, `scripts/update.sh` to
fast-forward clean checkouts, and `scripts/status.sh` to report state.
Checkouts are siblings of this repository, not nested inside it.

Experiments pin exact commits in their manifests. That is where reproducibility
lives, rather than in a submodule pointer.

## Rejected

**Git submodules.** They would give pinning for free, but they make every
routine operation (branch, pull, rebase) carry a submodule step, and detached
HEADs in working checkouts are a constant nuisance for repositories under
active development in parallel. The pinning they provide is also the wrong
granularity: an experiment needs a commit per repository at the moment it ran,
not a repository-wide pointer that moves when anyone commits.

**A workspace tool.** Repo, meta, mu-repo and friends solve a bigger problem
than this one has. Three scripts totalling a few hundred lines are less to
maintain than a dependency.

**Nothing at all, as now.** Rejected because the hand-maintained table already
demonstrated the failure mode.

## Reversal condition

If the number of repositories exceeds roughly ten, or if pinning by manifest
turns out to be routinely skipped in practice, revisit. Skipped pinning is
detectable: an experiment manifest with an empty or non-exact `repos` block.
