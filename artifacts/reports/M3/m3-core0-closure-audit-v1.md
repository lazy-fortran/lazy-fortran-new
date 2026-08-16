# M3 Core 0 closure audit v1

Status: `NEEDS EVIDENCE`
Revision: `bb7e0a8202712255596dc79abac61ca92fb54005`
Audit run: `E0181/R000001` (`R000032`)

## Claim tested

The complete Core 0 semantic ledger satisfies the M3 closure gate after the
retained E0123 merge, validation and witness analysis.

## Command

```text
E0123_RETRY_ROWS=.cache/runs/E0123/R000001/rows.jsonl \
E0123_RETRY_TRAJECTORY=.cache/runs/E0123/R000001/trajectory.jsonl \
E0123_ANALYSIS_OUTDIR=.cache/runs/E0181/R000001/analysis \
research/experiments/E0123-can-a-bounded-fresh-retry-resolve-the-re/analyse.sh
```

The command reproduced the deterministic merge, validation and witness gates
with no new model execution. Its complete denominator is 287 row keys: 53
retry rows and 234 immutable predecessor controls.

## Result

The merge is exact: 287 selected rows, 53 replacements, zero duplicate rows,
and the negative control fails as expected. Validation reports 280
schema/source-gate-accepted rows, 4 hard failures, 2 unresolved rows, one
reference-only row and zero semantic promotions. The witness gate reports 117
self-consistent rows, 94 disputed rows, 69 unwitnessed rows, 7 not-applicable
rows and zero promoted rows.

The deterministic audit therefore does not close full M3. The six promoted
bounded contracts remain valid bounded evidence, but they do not replace the
complete-ledger witness and promotion requirement. E0172 remains abandoned;
no model experiment is restarted by this audit.

Inputs and generated report: `.cache/runs/E0181/R000001/analysis/report.json`
(SHA-256 `95aeb1c96a4b864160535517725384e000975d5472f9248ceb76c320b5e71813`).
