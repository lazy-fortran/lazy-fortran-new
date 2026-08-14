#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
ledger="${E0137_RUNS:-$root/research/runs/2026-08.jsonl}"
outdir="${1:-$root/.cache/runs/E0137/R000001}"

die() { printf 'E0137: %s\n' "$1" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || die 'jq is required'
test -f "$ledger" || die "run ledger is missing: $ledger"
mkdir -p "$outdir"

jq -s -e '
  [.[] | select(.experiment == "E0137")] |
  length == 1 and .[0].repository == "fortfront-new" and
  .[0].commit == "d27f2bbc6cde7dc351320e4f3de82a61a8f435d6" and
  .[0].status == "accepted" and
  .[0].verification.fact_gated_frontier == true and
  .[0].verification.outcome_preservation == true and
  .[0].verification.fo == true and
  .[0].verification.warnings_introduced == 0
' "$ledger" >/dev/null || die 'accepted fortfront fact-gated frontier run with a clean fo gate is missing'

jq -s -r '
  ["run", "repository", "status", "commit", "fact_gated_frontier", "fo", "warnings_introduced"],
  (.[] | select(.experiment == "E0137") |
    [.run, .repository, .status, .commit,
     (.verification.fact_gated_frontier // false), (.verification.fo // false),
     (.verification.warnings_introduced // -1)])
  | @tsv
' "$ledger" >"$outdir/summary.tsv"
printf 'gate\taccepted\n' >>"$outdir/summary.tsv"
printf 'E0137 accepted: %s\n' "$outdir/summary.tsv"
