# D0071 — Separate the generated frontend AST contract

Date: 2026-08-14
Status: accepted

## Context

`contracts/frontend-v0.sxs` describes the frontend result exchanged with
downstream tools: status, root kind, diagnostics and diagnostic count. It does
not describe the typed AST records that the generated frontend must construct.
E0119 therefore needs an authoritative schema for the first generated
program-declaration slice. Keeping that schema implicit in `fortfront-new`
would make generated types and wiring impossible to audit against a central
source.

## Decision

Add `contracts/frontend-ast-v0.sxs` and its fixed witness
`contracts/fixtures/frontend-ast-v0.sx` to the laboratory contract registry.
The schema owns source spans, program roots, program declarations and the
bounded program-unit handoff used by E0119. The laboratory owns the schema,
fixture, version and provenance; `fortfront-new` owns the generator and
generated Fortran output. The AST contract remains separate from
`frontend-v0`, and generated wiring must be derived from the schema rather than
from local model or fragment decisions.

## Rejected

- Extending `frontend-v0` with AST records, because it would mix the result
  exchange boundary with the internal typed-tree boundary.
- Defining the AST only in `fortfront-new`, because that would make the
  authoritative schema and generated wiring diverge across repositories.
- Maintaining a second AST schema beside the laboratory contract, because
  duplicate schemas would create an unmeasured source of disagreement.

## Reversal condition

Write a successor if the first generator cannot consume this schema without
language-specific special cases, if the schema duplicates the result boundary
in practice, or if a measured generated frontend requires a different typed
boundary that is simpler and preserves source provenance without a second
authoritative schema.
