# E0063: Source-linked AST records

Status: accepted

## Question

Can generated logical-statement records be composed into a typed AST node
forest with deterministic parent and child links while preserving every
StandardIR source reference?

## Result

Yes, for the declared corpus. The operation composed 73 logical statements
from five pinned files into 73 typed AST nodes. The forest has five roots and
68 parent links. Every node retains its StandardIR rule, source page, byte
span and document hash.

The node array stores kind, rule, parent, first-child, next-sibling, depth,
physical source range and source reference. E0062 independently checks the
logical statements, continuation joins and construct closure. A malformed
`end do` mutation is rejected by that predecessor operation.

The generated Fortran module and test compile with
`-ffree-line-length-none -Wall -Wextra -Werror` and pass at runtime.

| Metric | Value |
|---|---:|
| Corpus files | 5 |
| Logical statements | 73 |
| AST nodes | 73 |
| Source-linked nodes | 73 |
| Root nodes | 5 |
| Parent links | 68 |
| Child links | 68 |
| AST link errors | 0 |
| Maximum AST depth | 4 |
| Fortran compile status | 0 |
| Runtime test status | 0 |
| Malformed nesting rejected | 1 |

This validates AST-shaped composition and source provenance for the declared
construct corpus. It does not establish expression nodes, semantic facts or
complete language AST coverage. The node forest is a typed local operation.
Compiler-wide wiring and node registration remain generated facts. No model
calls were made.

## Reproduction

`research/experiments/E0063-can-generated-ast-records-preserve-/analyse.sh`

The AST manifest records source identities and expected forest counts. The
operation consumes the generated E0062 logical records. Generated payloads
remain in the ignored cache. The gate summary is
`artifacts/runs/E0063/R000001-summary.toml`.

## Boundary

The next experiment should add expression-shaped child nodes and source-linked
AST query and diagnostic lookups. The architecture remains generator-owned.
The flat node array is accepted by D0031 because it preserves provenance and
gives the generator direct, specialization-friendly traversal. No model calls
were made.
