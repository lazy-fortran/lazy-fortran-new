# M3 Core 0 witness coverage reconciliation v2

Status: PASS for coverage accounting only
Origin: MECHANICAL

The exact E0181 witness ledger remains the source of the residual inventory.
After bounded C717 promotion, the deterministic partition leaves 157 rows
outside promoted contracts: 90 disputed and 67 unwitnessed. No semantic fact
is promoted by this reconciliation, and full M3 remains open.

Regenerate with:

```text
jq -s 'def promoted: ["C1106","C702","C601","C603","C721","C725","C718","C723","C729","C719","C738","C1579","C1586","C717"]; def is_promoted($id): any(promoted[]; . == $id); map(select((.status == "disputed" or .status == "unwitnessed") and (is_promoted(.constraint_id) | not))) | {rows: length, by_status: (group_by(.status) | map({status: .[0].status, count: length})), row_keys: map(.row_key)}' .cache/runs/E0181/R000002/analysis/witness/witnesses.jsonl
```

Observed result: `rows=157`, `disputed=90`, `unwitnessed=67`.
