# E0004 report

The broad extraction gate is met for the declared pages and representations.
Runs R000008 through R000012 are recorded in `research/runs/2026-08.jsonl`.

Regenerate the checks with:

```text
research/experiments/E0004-broad-syntax-extraction/analyse.sh
```

The production-line run recovered 494 production starts and 1,049 retained
records. The StandardIR projection contains 494 syntax objects, preserves
source hashes, and retains multi-token, optional, repeated, terminal and
cross-line structures. The SX round-trip is byte-identical. The normalized
projection contains 494 non-empty records and passes the fixed R603, R705,
R706, R871, R1043 and R1136 witnesses.

These results establish the broad extraction gate for pages 67--580. They do
not establish semantic coverage or parser completeness. E0020 and the later
composite parser-input work handle comparison and unresolved references.
