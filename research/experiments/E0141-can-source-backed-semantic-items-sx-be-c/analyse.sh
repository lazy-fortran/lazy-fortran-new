#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
ledger="${E0141_RUNS:-$root/research/runs/2026-08.jsonl}"
outdir="${1:-$root/.cache/runs/E0141/R000252}"

die() { printf 'E0141: %s\n' "$1" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || die 'jq is required'
test -f "$ledger" || die "run ledger is missing: $ledger"
mkdir -p "$outdir"

jq -s -e '
  [.[] | select(.experiment == "E0141")] |
  length == 1 and .[0].repository == "standard-new" and
  .[0].commit == "5121aa5d79b988c1d0a62bae006288801449f64d" and
  .[0].status == "accepted" and
  .[0].verification.canonical_output == true and
  .[0].verification.failure_output_clearing == true and
  .[0].verification.fo == true and
  .[0].verification.warnings_introduced == 0
' "$ledger" >/dev/null || die 'accepted semantic canonicalizer run with a clean fo gate is missing'

jq -s -r '
  ["run", "repository", "status", "commit", "canonical_output", "fo", "warnings_introduced"],
  (.[] | select(.experiment == "E0141") |
    [.run, .repository, .status, .commit,
     (.verification.canonical_output // false), (.verification.fo // false),
     (.verification.warnings_introduced // -1)])
  | @tsv
' "$ledger" >"$outdir/summary.tsv"
printf 'gate\taccepted\n' >>"$outdir/summary.tsv"
printf 'E0141 accepted: %s\n' "$outdir/summary.tsv"
