# D0039. A disposable local browser for generated run artifacts

Date: 2026-08-13
Status: superseded by D0082

## Context

The generated artifacts of a run are now large enough that reading them with
`less` and `rg` costs real time. `.cache/runs/E0074/R000001` holds 182 KB of
canonical StandardIR SX, 112 KB of EBNF, 128 KB of ANTLR4, 149 KB of Bison,
a tree-sitter `grammar.js`, 298 KB of generated Fortran dispatch, and the TSV
and validator logs that justify them. `.cache/runs/E0013/R000002` holds the
523-record canonical SX the whole chain derives from. Papers and the run ledger
report counts over these files. The files themselves are only ever read by
whoever wrote the extractor.

Three specific costs. Canonical SX is one form per line, so a single record is a
2 KB line no pager wraps usefully, and its `(source ...)` provenance sits at the
end of that line. The relation between a run directory (`E0074/R000001`), its
artifact manifests (`artifacts/runs/E0074/R000001-summary.toml`) and its ledger
run (`R000083` in `research/runs/2026-08.jsonl`) is a three-hop join done by
hand every time. And comparing the same production across the SX, EBNF, ANTLR,
Bison and tree-sitter projections means five terminal panes and five different
manglings of the rule name.

AGENTS.md forbids growing a service, a database, a dashboard or an
orchestration framework, and requires a decision record before adding a tool
that future pain proves necessary. This record is that gate, taken before the
code rather than after it.

## Decision

Add `scripts/browse.sh` and `scripts/browse/`, a read-only local viewer for
artifacts that already exist in the gitignored run cache, under these bounds.
Each bound is checkable, and a violation of any of them means the tool is
removed rather than repaired.

1. **It stores nothing.** It has no database and writes no index or
   configuration to disk. The index is rebuilt in memory on every start from the
   run directory, `artifacts/runs/*.toml` and `research/runs/*.jsonl`, so no
   output of this tool can become the input of anything else.
2. **It writes nothing.** The process opens files for reading only. `git status`
   is unaffected by any session.
3. **It is local and bounded.** It binds `127.0.0.1`, answers `GET` and `HEAD`
   only, and serves file content exclusively from one allowlisted root
   (`.cache/runs` by default) after a lexical check and a `realpath`
   containment check. It is started for a task and killed after it, not run as
   a daemon or a service.
4. **It has no dependencies.** TypeScript executed directly by Node's type
   stripping, `node:http`, plain DOM on the client, and highlighting written
   here as a small tokenizer per format. There is no package manifest to
   install from and nothing vendored.
5. **It is not a gate.** No CI job and no repository check depends on it, so
   deleting the directory can never make a run, a paper or a gate fail.
6. **It generates no artifacts.** It renders SX, EBNF, ANTLR4, Bison,
   tree-sitter and generated Fortran that a run already produced. It does not
   transform them, does not derive grammar from anything, and does not write a
   form the provenance gate would have to account for.

SX is treated as a first class format rather than as text: the reader mirrors
the lexical rules of the canonical Fortran reader in `standard-new`
(`src/fortsx.f90`), which recognizes lists, bare atoms terminated by whitespace
or `)`, and quoted atoms with `\"` and `\\` as the only escapes, with no comment
syntax. Both a raw view and a per-record structured tree are offered, and no
other reading of the format is invented here.

The tool's own correctness is checked by `scripts/browse.sh selftest`, which
tests the allowlist against escape attempts, the run-to-manifest-to-ledger
provenance join, and file discovery, each against fixtures built for the test
rather than against the repository's own state.

## Rejected

**Static HTML generated into the cache** was the obvious no-service option and
is rejected because it fails bound 1: it puts a derived copy of every artifact
next to the artifact, which then has a hash, an age and a staleness question,
and the provenance gate would have to say something about it.

**A `rg` and `less` recipe in AGENTS.md** is rejected on evidence rather than
taste: it is what is being done today, and it does not give a structured view of
a 2 KB canonical SX line or resolve the three-hop provenance join. A recipe
cannot expand a tree.

**A framework and a package manifest** (Express, Vite, a bundler, highlight.js
or Shiki) is rejected because a `package.json` in this repository is a supply
chain, a lockfile and an update duty attached to a tool whose entire value is
that it can be deleted without consequence. Highlighting five known formats is a
few hundred lines of tokenizer. A general highlighter is several megabytes of
someone else's release cadence.

**Serving the repository root, or any path the client asks for**, is rejected
because a viewer with no allowlist would read `~/.ssh` for anyone who could
reach the port, and because the boundary is the only part of this tool worth
testing carefully.

**Persisting a browsing session, adding run comparison, editing, re-running an
experiment or triggering generation** are rejected outright. Each of them is the
step that turns a viewer into the dashboard or orchestration framework AGENTS.md
names, and none of them is needed to read an artifact.

## Reversal condition

Delete the tool if any of these is observed. It grows persistent state, a
dependency manifest, or a write path. Anything else in the repository, a gate, a
paper's numbers, a run script, comes to depend on it. It is left running as a
service, or reachable from anything but the loopback interface. Or it stops
paying: if over a few weeks the artifacts are still read with `rg` and the
browser is not started, it was a preference and not a need, and the honest
outcome is `git rm`.

Reverse the no-dependency bound specifically if a format that matters here,
lossless highlighting of generated Fortran being the plausible case, turns out
to need a real grammar-driven highlighter. That is a new record naming the
dependency, its licence and its size, not a quiet `npm install`.
