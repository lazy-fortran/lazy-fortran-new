# D0178. Require a changed-name control before source-name promotion

Date: 2026-08-18
Status: accepted

## Context

D0177 deliberately promoted only the exact `y` witness because the current
producer recognizes a bounded exact witness set. A changed source name is the
smallest next test that can distinguish source-derived handling from another
hard-coded case.

## Decision

Freeze one additive contract using:

```fortran
program p
  integer :: z
end program p
```

Reuse the generated `frontend-ast-v1` schema, the malformed `integer ::`
neighbour, and the promoted `y` source as the changed-name control. Require
the future producer to accept `z`, preserve the exact integer declaration
span bytes 10 through 24, and keep the existing `x` and `y` witnesses green.
The expected source-hash label is
`l3-raw-program-variable-name-z-v1`, so the result cannot silently reuse the
`y` fixture's source label.

This is a frontend boundary contract, not a semantic fact. Its witness is
model-generated and therefore carries `origin llm`; only the deterministic
central oracle and independent review can promote the resulting claim. No
general identifier grammar, declarations, symbols, semantics, MIR or model
promotion path is included.

## Rejected

Adding multiple entities, arbitrary identifier syntax, case-folding claims,
semantic name resolution, or a new AST schema revision is outside this slice.

## Reversal condition

Split or reverse this contract if `z` cannot be accepted without changing the
v1 schema or the existing x/y observables, or if the independent changed-name
oracle is not sufficient to distinguish source-derived handling from a finite
hard-coded witness set.
