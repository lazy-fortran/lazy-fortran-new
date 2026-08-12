# E0067: Generated expression operator and literal coverage

Status: accepted

## Question

Can the same generated flat AST operation extend precedence-shaped expression
trees to power, concatenation, dotted logical operators, character and logical
literals, kind-suffixed real literals, and intrinsic function references over a
broader pinned real-source corpus?

## Result

Yes, for the declared witnesses. The operation covered nine expression
witnesses across six pinned fortfront files. It added 23 internal nodes and 31
leaves to the predecessor AST forest. The internal nodes comprise 20 binary,
one unary and two function-reference nodes; the leaves comprise 18 names and
13 literals. Every generated node retained a StandardIR rule, source page,
byte span and document hash.

The precedence ladder handled power, character concatenation, relational
operators and dotted logical operators with the same deterministic flat-node
representation. Function references are `call-expr` nodes whose children are
the function name and argument expressions. The root of `.not. x == x` is the
relational node, preserving the generated precedence structure rather than
making the unary operator the whole expression root.

| Metric | Value |
|---|---:|
| Witness files | 6 |
| Expression witnesses | 9 |
| GNU Fortran syntax-accepted files | 6 |
| Internal nodes | 23 |
| Leaf nodes | 31 |
| Binary nodes | 20 |
| Unary nodes | 1 |
| Array-constructor nodes | 0 |
| Function-reference nodes | 2 |
| Name nodes | 18 |
| Literal nodes | 13 |
| Source-linked nodes | 54 |
| Parent links | 54 |
| Link errors | 0 |
| Tree mismatches | 0 |
| Known coverage queries | 9 |
| Unknown query rejected | 1 |
| Maximum expression depth | 8 |
| Fortran compile status | 0 |
| Runtime test status | 0 |
| Unsupported `.xor.` operator rejected | 1 |

The generated Fortran was compiled with
`-ffree-line-length-none -Wall -Wextra -Werror`. No model calls were made.
The negative control replaces a supported `.and.` spelling with the
unsupported `.xor.` spelling and is rejected by the tokenizer.

This validates the deterministic operator ladder and function-reference shape
for the declared corpus. It does not establish complete expression parsing,
typed array constructors, user-defined operators, substring designators or
semantic type checking.

## Reproduction

`research/experiments/E0067-can-generated-expression-coverage-/analyse.sh`

The corpus manifest declares source identities, witness spans, expected node
counts, root rules, kind counts and depths. The operation consumes the pinned
E0066 output and the source-linked diagnostic module, checks every source hash,
compiles and executes the generated operation, and writes its gate summary to
`artifacts/runs/E0067/R000001-summary.toml`.

Generated Fortran and compiler products remain in the ignored `.cache/runs`
directory. The run record is `R000076` in `research/runs/2026-08.jsonl`.

## Decision consequence

D0033 is confirmed: the same generated structural ladder handles the declared
operator and literal families without a runtime operator table, a second
expression IR or model-owned wiring. D0028 and D0032 continue to support
autonomous next-slice selection while simplicity, direct traversal, source
provenance and compilation performance agree.

## Boundary

The next boundary is broader parser acceptance over complete real-source files,
including expression roles that are not covered by this local recognizer. A
future slice may add typed array constructors, user-defined operators,
substring designators or semantic facts only after an independent corpus and
oracle justify each extension. A model enters only when a bounded constructive
hole cannot be handled mechanically by a compact general rule; it never owns
the structural wiring.
