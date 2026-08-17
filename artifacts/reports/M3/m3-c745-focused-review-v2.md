# M3 C745 focused review v2

Status: `NEEDS FIX`; no bounded C745 or full M3 promotion is authorized by
this review.

The semantic-scope lane passes the current packet: the C745 contract and
validator support 27 typed states, 4 `ACCEPTED`, 1 `REJECTED`, 22
`UNRESOLVED`, 12 rejected mutation controls, an independent human-authored
expected-outcome table, zero model calls, zero semantic promotions and
explicit non-claims.

The reproducibility lane passes the current E0208 packet and all control-plane
links, but finds that the monthly run ledger is not valid JSONL as a whole.
At `research/runs/2026-08.jsonl:592-593`, the historical R000541/R000542
selection records contain unescaped double quotes in their recorded `jq`
command strings. `jq -s` therefore rejects the ledger before it can consume
the valid current R000556 record. The raw records and their semantic content
must be preserved while the canonical ledger serialization is repaired and
the repair is recorded as a correction.

No semantic fact, parser, or full M3 claim is promoted. The current C745
replay remains a valid bounded result, but the evidence packet cannot pass
the final reproducibility gate until the ledger is parseable end-to-end.
