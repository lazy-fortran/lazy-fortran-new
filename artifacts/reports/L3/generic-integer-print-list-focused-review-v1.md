# Generic integer PRINT-list focused review

Claim: `L3.generic-integer-print-list.v0` at central revision `13882a2`.

Verifier: `bash tests/e2e/check-generated-print-list.sh`.

The verifier passed the preserved generated-chain replay, the positive mixed
three-item and five-item routes, all four rejected source neighbours, exact
qemu output, and AST/MIR/ELF mutation controls. It also enforces the four
central component pins through `bash scripts/check_pins.sh`.

The independent oracle recomputes all source-case hashes, the normative PDF
hash, and the StandardIR artifact hash; checks the StandardIR source hash,
contract metadata, rules, pages, and every AST source span; and validates AST,
MIR, ELF, and runtime correspondence. Two independent Luna-medium focused
reviewers returned `PASS` at the pinned revision.

Scope remains bounded to list-directed integer `PRINT` with integer literals
and stored variable `x`. This does not promote general I/O, formatted output,
`WRITE`, arrays, non-integer output, general expressions, or full M3 semantics.
