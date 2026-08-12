# E0005 report

The contiguous core-syntax extraction gate is met for the declared pages and
representations. Runs R000013 through R000016 are recorded in
`research/runs/2026-08.jsonl`.

Regenerate the checks with:

```text
research/experiments/E0005-core-syntax-extraction/analyse.sh
```

The production-line run recovered 519 production starts and 1,182 retained
records across physical pages 53--580. The StandardIR projection contains 519
syntax objects with source hashes on every object. The SX round-trip is
byte-identical. The normalized projection contains 519 non-empty records and
passes the fixed R501, R516, R601, R603 and R1547 witnesses.

These results establish the contiguous core-syntax extraction gate. They do
not establish semantic Core 0 support or a complete parser input. Unresolved
references and prose restrictions remain governed by D0018 and proposed D0019.
