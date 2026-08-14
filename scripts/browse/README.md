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

Open `http://127.0.0.1:7373/` after starting the server. The default page is a
small document-first landing page with direct entries for the standard,
StandardIR, grammar exports, semantics, MIR, and backend/ISA. It provides
progress by evidence lane, a live-run workspace with ETA and incrementally
published inputs/outputs, a searchable rule dictionary, clickable pipeline
views, and a source library for production code and pinned
ISA/ABI/microarchitecture material. The standard entry opens the pinned PDF in
the page; the other entries open the actual extracted text, SX, grammar,
semantic, MIR and backend artifacts. The existing run view remains available
for canonical SX trees, metrics, logs and provenance.

To follow the current cell directly, use the live view link printed by the
runner or open `#view=live&ref=E0112/R000012/qwen38-27b-pointer-off-a3` while
that cell is active. The browser refreshes only this user-facing view every two
seconds; it never starts, stops or controls the model service.

The server rebuilds projections on each request. Refresh the library after new
run directories or source commits are added; no generated index is written.
Use `Ctrl-C` to stop it. A run can be selected by `E0074/R000001` or by its
ledger ID such as `R000083`.

On narrow screens, the file list moves behind the `files` button, flow nodes
stack vertically, and the source list sits above the highlighted source. The
`wrap` control soft-wraps long grammar lines and hides line numbers while it is
on, because a wrapped line no longer occupies one visual row.
