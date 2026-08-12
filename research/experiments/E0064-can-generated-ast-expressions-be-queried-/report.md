# E0064: Expression-shaped AST children and source queries

Status: accepted

## Question

Can the generated source-linked statement forest be extended with
expression-shaped child nodes and deterministic kind/rule queries without
losing provenance or introducing model-owned wiring?

## Result

Yes, for the declared corpus. The operation reused 73 validated statement
nodes and attached 52 expression-role children, producing 125 nodes in total.
Every node retained a StandardIR rule, source page, byte span and document
hash. The expression roles were `designator`, `expr`, `logical-expr`,
`loop-control`, `do-variable`, `case-expr`, `case-selector` and
`output-item`.

The flat node array has 120 parent links and 120 child links with zero link
errors. A generated kind/rule query found `output-item`/`R1217` in each of the
five files and returned its source reference. An unknown kind/rule query was
rejected. The generated Fortran modules and test compile with
`-ffree-line-length-none -Wall -Wextra -Werror` and pass at runtime. A
malformed `end do` mutation remains rejected by the predecessor operation.

| Metric | Value |
|---|---:|
| Corpus files | 5 |
| Statement nodes | 73 |
| Expression nodes | 52 |
| Total nodes | 125 |
| Source-linked nodes | 125 |
| Root nodes | 5 |
| Parent links | 120 |
| Child links | 120 |
| AST link errors | 0 |
| Maximum AST depth | 5 |
| Known query hits | 5 |
| Unknown query rejected | 1 |
| Fortran compile status | 0 |
| Runtime test status | 0 |
| Malformed nesting rejected | 1 |

This validates expression-role composition and source-linked lookup for the
declared construct corpus. It does not establish recursive operator-precedence
trees, complete expression parsing, semantic analysis or complete AST
coverage. The wiring and query traversal remain generated facts. No model
calls were made.

## Reproduction

`research/experiments/E0064-can-generated-ast-expressions-be-queried-/analyse.sh`

The expression manifest records source identities, statement totals,
expression-role counts, expected links and depth. The operation consumes the
generated E0063 AST module. Generated payloads remain in the ignored cache.
The gate summary is `artifacts/runs/E0064/R000001-summary.toml`.

## Boundary

The next experiment should compose recursive expression children for the
declared operators and literals, preserving source ranges and StandardIR
rules, then extend the query checks to those subtrees. The architecture remains
generator-owned and the local expression recognizer remains a bounded
implementation hole.
