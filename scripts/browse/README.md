# Disposable artifact browser

This directory contains the client and server implementation accepted by
D0039. It reads existing files from `.cache/runs`, writes no state, and binds
only to loopback.

From the repository root:

```sh
scripts/browse.sh selftest
scripts/browse.sh index --run E0074/R000001
scripts/browse.sh serve --run E0074/R000001
```

Open `http://127.0.0.1:7373/` after starting the server. Use `Ctrl-C` to stop
it. The browser displays canonical SX as raw text and a structural tree, plus
EBNF, ANTLR4, Bison, tree-sitter, generated Fortran, metrics, logs, and
provenance. A run can be selected by `E0074/R000001` or by its ledger ID such
as `R000083`.

The server rebuilds the file view on each request. Restart it when new run
directories are added so the run selector discovers them.

On a screen narrower than the breakpoints in `style.css`, the file list moves
behind the `files` button and the SX record list sits above the tree rather than
beside it. `wrap` soft-wraps long grammar lines; it hides the line numbers while
it is on, because a wrapped line no longer occupies one visual row. Neither is a
different view of the artifact, and neither is remembered between sessions.
