# artifacts

**Manifests only. No payloads.**

Nothing external is committed to this repository, not standards documents, not
grammars, not ISA specifications, not corpora, not model traces. Each artifact
gets a small TOML manifest here recording where it came from and what it hashes
to, and `scripts/fetch.sh` turns a manifest into bytes in the gitignored
`.cache/`.

```sh
scripts/fetch.sh --list
scripts/fetch.sh j3-24-007
scripts/fetch.sh --verify j3-24-007     # check the cached copy, no download
```

A hash mismatch is a hard failure with no override flag. An unverified artifact
quietly substituted for a verified one would invalidate every measurement
downstream of it.

## Layout

| Directory | Holds |
|---|---|
| `standards/` | Normative language documents |
| `isa/` | Instruction set specifications and encoding tables |
| `grammars/` | Third-party grammar corpora used as comparisons |
| `benchmark/` | Corpora and benchmark result archives |
| `model/` | Prompt and response payloads referenced by run records |

## Manifest fields

`name`, `title`, `url`, `sha256`, `bytes`, `licence`, `retrieved`, `purpose`.
Add `pages` for documents. Keep it flat: `key = "value"`, no nesting, so the
awk in `scripts/lib.sh` stays a few lines and the repository stays
dependency-free.

## No Git LFS

Because nothing large is stored here at all. LFS solves the problem of
committing big files well; this repository solves it by not committing them.
That also sidesteps the redistribution question entirely for documents like
J3/24-007, which may be downloaded freely but not republished. No repository
under `lazy-fortran/` currently uses LFS, so this matches house practice as
well.
