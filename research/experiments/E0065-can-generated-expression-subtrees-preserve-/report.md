# E0065: Recursive expression subtrees

Status: accepted

## Question

Can explicit expression-role nodes be extended with deterministic name,
literal and operator children while preserving source provenance for real
Fortran witnesses?

## Result

Yes, for the declared witnesses. The operation reused the generated E0064
forest and attached 28 token-level leaves to eight expression-role nodes. The
leaves comprise 10 names, 10 literals and 8 operators. Every leaf retains a
StandardIR rule, source page, byte span and document hash.

The generated child chains contain 28 parent links with zero link errors. All
eight known witness queries locate the declared role and source range, while
an unknown role query is rejected. The generated Fortran modules and test
compile with `-ffree-line-length-none -Wall -Wextra -Werror` and pass at
runtime. A malformed `end do` mutation remains rejected by the predecessor
operation.

| Metric | Value |
|---|---:|
| Witness files | 5 |
| Expression witnesses | 8 |
| Base expression nodes | 125 |
| Token leaves | 28 |
| Name leaves | 10 |
| Literal leaves | 10 |
| Operator leaves | 8 |
| Source-linked leaves | 28 |
| Subtree parent links | 28 |
| Subtree link errors | 0 |
| Maximum subtree depth | 6 |
| Known witness queries | 8 |
| Unknown witness rejected | 1 |
| Fortran compile status | 0 |
| Runtime test status | 0 |
| Malformed nesting rejected | 1 |

This validates token-level recursive expression subtrees and source-linked
witness queries for the declared corpus. It does not establish complete
operator-precedence parsing, all literal variants, semantic analysis or
complete AST coverage. The subtree wiring remains generated. No model calls
were made.

## Reproduction

`research/experiments/E0065-can-generated-expression-subtrees-preserve-/analyse.sh`

The witness manifest records source identities, physical spans, expression
roles and exact leaf-kind counts. The operation consumes the generated E0064
expression module. Generated payloads remain in the ignored cache. The gate
summary is `artifacts/runs/E0065/R000001-summary.toml`.

## Boundary

The next experiment should add operator-precedence-shaped subtrees and broader
literal variants. The architecture remains generator-owned; the local token
recognizer remains a bounded implementation hole until a larger corpus and
independent behavioral checks justify a broader claim.
