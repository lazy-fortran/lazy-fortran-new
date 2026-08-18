# D0179. Add a bounded multi-character name and span contract

Date: 2026-08-18
Status: accepted

## Context

E0237 establishes one changed single-character witness, `z`, and behaviorally
replays the promoted `y` control. The next smallest useful boundary test is a
multi-character name whose declaration span changes with the source bytes.

## Decision

Freeze one additive exact source shape:

```fortran
program p
  integer :: alpha
end program p
```

Reuse the generated `frontend-ast-v1` schema and the malformed `integer ::`
neighbour. Require the future producer to emit the variable name `alpha`,
integer type, declaration span bytes 10 through 28, and source-hash label
`l3-raw-program-variable-name-alpha-v1`. Keep the promoted `z` source as the
changed-name control. The witness is model-generated and carries `origin llm`;
the central deterministic oracle remains authoritative.

This is a bounded frontend syntax-shape contract, not a general identifier or
semantic claim. It tests a changed name and span, not arbitrary Fortran.

## Rejected

General identifier parsing, arbitrary declaration lists, symbol resolution,
semantic analysis, MIR, and a new AST schema revision remain outside scope.

## Reversal condition

Split this contract if the v1 schema cannot represent the longer name and
source span without changing existing x/y/z behavior, or if the control and
negative oracle cannot remain independent.
