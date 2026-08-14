# Frontend lane

Owner: `fortfront-new`. Inputs: `standardir-v0`. Output: `frontend-v0` for the
middle end and tools. The repository owns generated lexer/parser/AST code and
behavioral tests. Experiment history and contract revisions remain in the lab.

## Dependency order

1. establish the production scaffold and contract reader.
2. consume closed StandardIR syntax and generate parser/AST APIs.
3. connect source-linked diagnostics and the accepted semantic rule table.
4. lower a declared vertical slice into `mir-v0`.

The bounded program-witness parser, source-linked result boundary, canonical
frontend-v0 SX handoff and reader, typed program-root boundary with canonical
SX, standalone typed program-declaration SX boundary, bounded typed
program-unit aggregate, bounded semantic-table consumer, generic
semantic-witness validator, typed source-linked diagnostic SX boundary,
diagnostic-count and indexed diagnostic queries, and the indexed
program-declaration query are integrated. The current production pin is
`fortfront-new` commit
`4893474cc4b4f3675363a49e5ac4bc5df763e112`. The bounded parser-quality
slice now validates program-name matching, identifier boundaries, and exact
root/header spans for the minimal witness parser. The deterministic
`frontend-ast-v0` generator, checked-in generated records, canonical SX
serialization, schema-derived dispatcher and freshness/negative tests are
also integrated. Only the
first two steps depend on M2. Diagnostic and semantic
slices may run in parallel once their StandardIR records and provenance fields
are pinned.
The `mir-v0` producer boundary must not be changed inside a frontend slice.

The next substantive gate is E0119. Its typed AST input is the laboratory
contract `contracts/frontend-ast-v0.sxs` with fixed witness
`contracts/fixtures/frontend-ast-v0.sx`. The first generated slice must emit
program-root, program-declaration and program-unit records plus deterministic
SX and wiring from that schema; generated output and its regeneration command
belong in `fortfront-new`, while the experiment and provenance remain here.

## Exit and handoff

The lane passes a typed, source-linked result with accepted/rejected status,
diagnostics and an explicit root kind. It must retain unresolved StandardIR
rows as unsupported rather than silently accepting them. Validate contract
fixtures with `scripts/check-contracts.sh` and run the production repository's
full Fortran gates before integration.
