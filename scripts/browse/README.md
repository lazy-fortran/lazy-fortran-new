# Research library browser

This directory contains the unified, read-only research library accepted by
D0082, which supersedes the run-only view in D0039. It reads lab metadata, the
four sibling production repositories, and existing files from `.cache/runs`;
it writes no state and binds only to loopback. Repository files and run records
remain authoritative.

From the repository root:

```sh
scripts/browse.sh selftest
scripts/browse.sh index --run E0074/R000001
scripts/browse.sh serve --run E0074/R000001
```

Open `http://127.0.0.1:7373/` after starting the server. The default page is
the library overview. It provides lane-level evidence progress, active-run
heartbeats and ETA, four clickable pipeline views, a searchable rule register,
a case browser for prompts/responses/gates, and a source library for
StandardIR/frontend/MIR/TargetIR code and pinned ISA/ABI/microarchitecture
material. The existing run view displays canonical SX as raw text and a
structural tree, plus EBNF, ANTLR4, Bison, tree-sitter, generated Fortran,
metrics, logs, and provenance.

The server rebuilds projections on each request. Refresh the library after new
run directories or source commits are added; no generated index is written.
Use `Ctrl-C` to stop it. A run can be selected by `E0074/R000001` or by its
ledger ID such as `R000083`.

On narrow screens, the file list moves behind the `files` button, flow nodes
stack vertically, and the source list sits above the highlighted source. The
`wrap` control soft-wraps long grammar lines and hides line numbers while it is
on, because a wrapped line no longer occupies one visual row.
