# Post-C745 M3 residual selection

Selection status: `PASS`; no semantic fact is selected or promoted by this
audit. The next candidate row is `C746@1`; its source binding remains the
subject of the next bounded contract-selection task.

The exact partition command is:

```text
jq -s -c 'def promoted: ["C1106","C702","C601","C603","C721","C725","C718","C723","C729","C719","C738","C1579","C1586","C717","C720","C722","C724","C726","C731","C732","C733","C735","C743","C744","C745"]; def is_promoted($id): any(promoted[]; . == $id); map(select((.status == "disputed" or .status == "unwitnessed") and (is_promoted(.constraint_id) | not))) | {rows: length, by_status: (group_by(.status) | map({status: .[0].status, count: length})), first_row: .[0].row_key, first_constraint: .[0].constraint_id}' .cache/runs/E0181/R000002/analysis/witness/witnesses.jsonl
```

It returns 146 residual rows: 84 `disputed` and 62 `unwitnessed`, with
`C746@1` first. The pinned witness ledger is SHA-256
`77c6758a0eb52587c7847420bd72e56560b1e1cb5cb0d6acc5d0e69229e53b1b` as
recorded by the predecessor selection; the canonical
source, pages index and StandardIR inputs remain the pinned E0207 inputs. The
row is marked `unwitnessed` because its current witness evaluator reports
that the subset relation is unsupported; no model output is converted into a
source-backed fact.

The next task must inspect C746's normative source occurrence and existing
StandardIR witnesses, then define one bounded contract or record that no
eligible source-backed property is available. It must not resume E0172,
perform general semantic work or close full M3.
