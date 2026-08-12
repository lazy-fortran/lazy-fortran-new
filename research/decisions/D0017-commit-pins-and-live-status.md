# D0017. Immutable experiment pins and live repository status

Date: 2026-08-12
Status: accepted

## Context

The roadmap needs to say where the work is now, while experiments need to say
exactly which source produced their results. A commit hash for the current
branch is not a stable live-status field. Updating the roadmap changes the
commit that the roadmap would name, so an automatic updater would either record
the parent, create a second commit, or loop. None of those makes the roadmap a
reproducible experiment record.

## Decision

Live cross-repository state is reported by `scripts/status.sh`. `ROADMAP.md`
does not contain moving checkout hashes. Its snapshot records the date and
points to the status command.

Every running or reported experiment records exact repository pins in its
manifest. Run and artifact records retain the pins and hashes needed to
reproduce the result. Those historical pins are immutable evidence and are not
updated when a repository advances.

`scripts/check-commit-references.sh` validates the pins in active manifests
against available checkouts. It skips absent optional oracle checkouts by
default and fails for unresolved pins. `--strict` turns absent checkouts into
failures. The versioned `.githooks/pre-commit` hook runs this check and the
staged whitespace check after `scripts/install-hooks.sh` enables it locally.
The hook validates references. It never rewrites a commit ID.

## Rejected

**Put the current `HEAD` hash in the roadmap.** The value becomes stale with
the next commit and is self-referential when the roadmap itself is changed.

**Run a post-commit updater.** It would create another commit after every
commit, require special handling for amend and merge operations, and still
leave the first commit naming its parent or its child.

**Use a mutable tag as an experiment pin.** A moving tag has the same
reproducibility defect as a moving branch. A release tag can be useful as a
human alias, but the manifest still records the commit hash.

## Reversal condition

If the roadmap becomes a generated publication whose inputs and output commit
are managed by an external release process, a successor decision may define a
different snapshot mechanism. Until then, live status and historical evidence
remain separate.
