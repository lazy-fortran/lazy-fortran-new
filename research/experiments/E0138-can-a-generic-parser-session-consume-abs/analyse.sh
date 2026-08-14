#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
ledger="${E0138_RUNS:-$root/research/runs/2026-08.jsonl}"
outdir="${1:-$root/.cache/runs/E0138/R000250}"

die() { printf 'E0138: %s\n' "$1" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || die 'jq is required'
test -f "$ledger" || die "run ledger is missing: $ledger"
mkdir -p "$outdir"

jq -s -e '
  [.[] | select(.experiment == "E0138")] |
  length == 1 and .[0].repository == "fortfront-new" and
  .[0].commit == "268e312dbd8ba11cce00d8581479cf47ec077061" and .[0].status == "accepted" and
  .[0].verification.incremental_matches_batch == true and
  .[0].verification.accepted_outcome == true and
  .[0].verification.rejected_outcome == true and
  .[0].verification.ambiguous_outcome == true and
  .[0].verification.unresolved_outcome == true and
  .[0].verification.fo == true and
  .[0].verification.warnings_introduced == 0
' "$ledger" >/dev/null || die 'accepted parser-session run with a clean fo gate is missing'

jq -s -r '
  ["run", "repository", "status", "commit", "incremental_matches_batch", "fo", "warnings_introduced"],
  (.[] | select(.experiment == "E0138") |
    [.run, .repository, .status, .commit,
     (.verification.incremental_matches_batch // false), (.verification.fo // false),
     (.verification.warnings_introduced // -1)])
  | @tsv
' "$ledger" >"$outdir/summary.tsv"
printf 'gate\taccepted\n' >>"$outdir/summary.tsv"
printf 'E0138 accepted: %s\n' "$outdir/summary.tsv"
