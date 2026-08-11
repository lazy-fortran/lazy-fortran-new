# D0002. Nothing external is vendored

Date: 2026-08-11
Status: accepted

## Context

The program depends on external material that is large, licensed by others, or
both: the Fortran standard as a PDF, third-party grammar corpora, ISA
specifications, conformance corpora, and model traces. The house precedent is
mixed: `~/code/standard/validation/pdfs/` contains an 11.5 MB J3 PDF committed
as a plain git blob, and no repository under `lazy-fortran/` uses Git LFS.

J3 and ISO documents may be downloaded freely and may not be redistributed.
This repository is public.

## Decision

No external artifact is committed. `artifacts/` holds flat TOML manifests with
URL, SHA-256, byte size, licence, retrieval date and purpose.
`scripts/fetch.sh` downloads into a gitignored `.cache/` and verifies the hash.
A mismatch is a hard failure with no override flag. `git status` must be clean
after any fetch.

One mechanism covers standards documents, grammars, ISA specifications and
corpora, so there is no second policy to remember.

## Rejected

**Vendoring J3 drafts in Git LFS.** Simplest for reproducibility, and legally
grey for a public repository. Also introduces LFS, which no sibling repository
uses.

**A private artifacts repository.** Clean legally, but creates an access
asymmetry for outside contributors and a second repository to keep in step.

**Committing derived text instead of the PDF.** The derived text has its own
copyright questions and would make the pipeline unreproducible from the
document down, which is exactly the step E1 measures.

## Consequences

No Git LFS is needed anywhere, because nothing large is stored. Contributors
must fetch before working, and CI must fetch too, deliberately, so a missing
network fails the job rather than silently skipping the check.

## Reversal condition

If a needed artifact ever becomes unavailable at a stable URL, the pinning
model breaks for that artifact and it needs a different answer, most likely a
mirror with its own manifest, not a change of policy. Record it as a new
decision.
