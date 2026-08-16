# L1 replay — corrected independent scope review

Date: 2026-08-16
Corrected four-file diff SHA-256: `565ae83af5871d6aa527a88c7d1ef819027a66a42e997c0f17b15794161b25eb`
Reviewer: native GPT-5.6 Luna, scope lane

## Verdict

PASS.

The evidence supports only the declared path from the `standard-new`
canonical grammar fixture to the `fortfront-new` grammar-frontier observable:
`PROGRAM` is accepted and `BAD` is rejected. It makes no broader frontend,
parser, compiler, or complete-StandardIR claim.

## Evidence checked

- `tests/e2e/run-l1.sh` passes.
- The two-rule fixture and malformed neighbor are the only source cases.
- Central contract, toolchain, component pins, and committed trace are present.
- Both component checkouts are clean at the declared revisions.
