# L1 replay — independent scope review

Date: 2026-08-16
Candidate tracked diff SHA-256: `e57861c7cc12f0e815e1fd09ce3f7275a59865adb7f7233c1373f1a1058d35ab`
Reviewer: native GPT-5.6 Luna, scope lane

## Verdict

PASS.

The candidate supports only the declared narrow path:

```text
standard-new canonical SX/StandardIR fixture
→ fortfront-new grammar-frontier acceptance/rejection
```

The two-rule fixture observes `PROGRAM` accepted and `BAD` rejected. It does
not claim a complete frontend, parser, compiler, or complete StandardIR.

## Evidence checked

- `tests/e2e/run-l1.sh` passes.
- The malformed StandardIR neighbor is rejected.
- Central contract, toolchain, component pins, and committed trace are
  present.
- Both component checkouts are clean at the declared commits.
