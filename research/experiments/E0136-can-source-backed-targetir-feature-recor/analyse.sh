#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
ledger="${E0136_RUNS:-$root/research/runs/2026-08.jsonl}"
outdir="${1:-$root/.cache/runs/E0136/R000001}"

die() { printf 'E0136: %s\n' "$1" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || die 'jq is required'
test -f "$ledger" || die "run ledger is missing: $ledger"
mkdir -p "$outdir"

jq -s -e '
  [.[] | select(.experiment == "E0136")] |
  length == 1 and .[0].repository == "fortback-new" and
  .[0].commit == "403a1ba" and .[0].status == "accepted" and
  .[0].verification.source_query == true and
  .[0].verification.source_identity_preserved == true and
  .[0].verification.fo == true and
  .[0].verification.warnings_introduced == 0
' "$ledger" >/dev/null || die 'accepted fortback provenance-query run with a clean fo gate is missing'

jq -s -r '
  ["run", "repository", "status", "commit", "source_query", "fo", "warnings_introduced"],
  (.[] | select(.experiment == "E0136") |
    [.run, .repository, .status, .commit,
     (.verification.source_query // false), (.verification.fo // false),
     (.verification.warnings_introduced // -1)])
  | @tsv
' "$ledger" >"$outdir/summary.tsv"
printf 'gate\taccepted\n' >>"$outdir/summary.tsv"
printf 'E0136 accepted: %s\n' "$outdir/summary.tsv"
