# M3 Core 0 closure audit v2

Status: `NEEDS EVIDENCE` for full M3; the deterministic audit itself passes.

Revision: `b50036a1e916bda74ab49c6e17eeb7660c39cab2`

Audit run: `E0181/R000002` (`R000074`)

## Command

```text
E0123_RETRY_ROWS=.cache/runs/E0123/R000001/rows.jsonl \
E0123_RETRY_TRAJECTORY=.cache/runs/E0123/R000001/trajectory.jsonl \
E0123_ANALYSIS_OUTDIR=.cache/runs/E0181/R000002/analysis \
research/experiments/E0123-can-a-bounded-fresh-retry-resolve-the-re/analyse.sh
```

The command reproduced the deterministic merge, validation and witness gates
against the immutable 53-row retry and 234-row predecessor-control split.

## Result

The merge selected all 287 rows, replaced exactly 53 rows and observed the
negative control failure. Validation accepted 280 rows at the schema/source
gate, retained 4 hard failures, 2 unresolved rows and one reference-only
occurrence, and promoted zero semantic facts. The witness gate reports 117
self-consistent rows, 94 disputed rows, 69 unwitnessed rows, 7 not-applicable
rows and zero promoted rows.

The residual row identities are `C601@1`, `C603@1`, `C719@1` and `C738@1`
(`hard_failure`); `C1579@1` and `C1586@1` (`unresolved`); and `C704@2`
(`reference-only`). The two unresolved rows already have bounded promoted
contracts, and `C704@2` is a duplicate reference occurrence. The precise
remaining blocker is therefore complete-ledger witness closure: 94 disputed
and 69 unwitnessed rows remain outside the promoted bounded slices. Full M3
cannot be promoted from this audit.

The next executable task is
`T-M3-core0-witness-coverage-reconciliation`: reconcile the 13 promoted
bounded slices against the retained witness rows and isolate any remaining
source-backed residual without starting another model experiment or promoting
a model fact. Its initial inventory command is:

```text
jq -s 'map(select(.status == "disputed" or .status == "unwitnessed")) | {rows: length, by_status: (group_by(.status) | map({status: .[0].status, count: length})), row_keys: map(.row_key)}' .cache/runs/E0181/R000002/analysis/witness/witnesses.jsonl
```

Inputs and generated summaries:

- report: `.cache/runs/E0181/R000002/analysis/report.json`, SHA-256 `95aeb1c96a4b864160535517725384e000975d5472f9248ceb76c320b5e71813`;
- merged summary: `.cache/runs/E0181/R000002/analysis/merged/summary.json`, SHA-256 `f285c9bb6d1f7a4fcff785ec3bf01a128620bb7f585b355ef3c91e063b5a44db`;
- validation summary: `.cache/runs/E0181/R000002/analysis/validate/summary.tsv`, SHA-256 `85659aa3135b1de92cecda491f3edc827ae589b0e406612f2b68662836d77760`;
- witness summary: `.cache/runs/E0181/R000002/analysis/witness/summary.json`, SHA-256 `88408fed4657051583fe8c42e921239579409e6c254760663f2538f0afda05d7`.
