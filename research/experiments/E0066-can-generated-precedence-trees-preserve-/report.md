# E0066: Generated precedence-shaped expression trees

Status: accepted

## Question

Can generated expression-role nodes represent binary precedence, unary
operators and array constructors as source-linked structural trees over real
Fortran witnesses?

## Result

Yes, for the declared witnesses. The operation reused the E0064 expression
forest and added 10 precedence nodes and 17 literal/name leaves across seven
expression witnesses. The six binary nodes, three unary nodes and one array
constructor are ordinary nodes in the same flat generated array; their child
links encode precedence and nesting directly.

Every added node retains a StandardIR rule, source page, byte span and source
document hash. The generated operation produced 27 source-linked nodes and 27
parent links with zero link errors. All seven known precedence queries found
their generated roots, an unknown query was rejected, and the maximum tree
depth was 8.

| Metric | Value |
|---|---:|
| Witness files | 4 |
| Expression witnesses | 7 |
| Internal nodes | 10 |
| Leaf nodes | 17 |
| Binary nodes | 6 |
| Unary nodes | 3 |
| Array-constructor nodes | 1 |
| Name nodes | 6 |
| Literal nodes | 11 |
| Source-linked nodes | 27 |
| Parent links | 27 |
| Link errors | 0 |
| Tree mismatches | 0 |
| Known precedence queries | 7 |
| Unknown query rejected | 1 |
| Maximum tree depth | 8 |
| Fortran compile status | 0 |
| Runtime test status | 0 |
| Malformed nesting rejected | 1 |

The generated Fortran was compiled with
`-ffree-line-length-none -Wall -Wextra -Werror`. No model calls were made.
The negative control changed a construct terminator and was rejected.

This validates the structural representation and its deterministic wiring for
the declared operator and literal families. It does not establish complete
expression parsing, all Fortran operators, all literal forms, or semantic
analysis. The initial local recognizer remains deliberately bounded; the
architecture and source linkage are the result under test.

## Reproduction

`research/experiments/E0066-can-generated-precedence-trees-preserve-/analyse.sh`

The corpus manifest declares source identities, witness spans, expected node
counts, root rules, kind counts and depths. The operation consumes the pinned
E0064 expression module, validates predecessor hashes, compiles and executes
the generated operation, and writes its gate summary to
`artifacts/runs/E0066/R000001-summary.toml`.

Generated Fortran and compiler products remain in the ignored `.cache/runs`
directory. The run record is `R000075` in `research/runs/2026-08.jsonl`.

## Decision consequence

D0032 is confirmed: precedence belongs in generated structural nesting, not a
runtime precedence table or a second expression IR. D0028 applies: the next
slice is chosen autonomously while simplicity, direct generated traversal,
source provenance and performance continue to agree.

## Boundary

The next slice should enlarge the real-source expression corpus and exercise
more literal and operator families while preserving the same independent
oracle. After that, the useful boundary is parser acceptance over a larger
source set, followed by semantic facts and constraints. A model should enter
only if the enlarged evidence shows that a local constructive hole cannot be
handled mechanically with a compact general rule; it must not own the wiring.
