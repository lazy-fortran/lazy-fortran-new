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
`2bb1bdd1fe0f75164b8de4bfd1c1c6db9d710cca`. The bounded parser-quality
slice validates program-name matching, identifier boundaries, and exact
root/header spans for program and module witnesses. The deterministic
`frontend-ast-v0` generator, checked-in generated records, canonical SX
serialization, schema-derived dispatcher and freshness/negative tests are
also integrated. Only the
first two steps depend on M2. Diagnostic and semantic
slices may run in parallel once their StandardIR records and provenance fields
are pinned.
The `mir-v0` producer boundary must not be changed inside a frontend slice.

The bounded source-witness set now includes program, module and subroutine
terminator/name variants. The subroutine slice is integrated at
`fortfront-new` commit `f3fc7145ba4afdc7e27fdd1fd726cafd937be0b5` with exact
identifier-boundary, name-matching, span and malformed-input controls; it does
not change `frontend-ast-v0` or `mir-v0`.
The function witness slice is integrated at
`fortfront-new` commit `7bb9eae735c21f94bb123c3c6c4048f29b6bcb7e` with the same
bounded terminator, name, span and rejection controls; it also leaves
`frontend-ast-v0` and `mir-v0` unchanged.

The generated AST visitor continuation is integrated at
`fortfront-new` commit `bd6436e532aa75e664b4967c4d95b810fc9ab59b`. Visitor
callbacks and preorder traversal are generated from the schema, omitted
callbacks are safe, and freshness, malformed-schema and nested-order controls
pass. This is structural AST wiring only; lexer, parser, semantic, lowering
and `mir-v0` work remain separate gates.

E0119 is complete for its first AST/wiring slice and is reported as `R000192`.
Its typed AST input was the laboratory contract
`contracts/frontend-ast-v0.sxs` with fixed witness
`contracts/fixtures/frontend-ast-v0.sx`; the generated output and its
regeneration command remain in `fortfront-new`, while the experiment and
provenance remain here. The schema-derived AST utility gate is now integrated
at `f931acfd99640eeda95a89b8dd56df89581ad97e`; it counts nested record kinds
and handles empty and invalid query inputs. The next substantive frontend gate
is the lexer/parser, followed by semantic and lowering gates. None of these
structural steps may change `mir-v0` or add hand-maintained language-wide
dispatch.

The lexer-facing lexical-fact classifier is integrated at
`c704f047fadc64b771279111becff78ed2c835f3`. It consumes caller-supplied
source-backed facts, validates provenance before lookup, and reports scalar,
ambiguity, processor-defined and invalid-input states. It is a classifier
boundary only. The following UTF-8 span boundary is integrated at
`fortfront-new` commit `2bb1bdd1fe0f75164b8de4bfd1c1c6db9d710cca`: it iterates source scalars by byte offsets,
classifies a span through those facts, retains the matched fact, and gives
no-match, unsupported, ambiguous and invalid-fact states distinct from an
empty span. It remains a lexer-facing classifier boundary only; source
tokenization and grammar dispatch remain pending.

## Exit and handoff

The lane passes a typed, source-linked result with accepted/rejected status,
diagnostics and an explicit root kind. It must retain unresolved StandardIR
rows as unsupported rather than silently accepting them. Validate contract
fixtures with `scripts/check-contracts.sh` and run the production repository's
full Fortran gates before integration.
