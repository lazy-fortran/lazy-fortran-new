#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
ledger="${E0135_RUNS:-$root/research/runs/2026-08.jsonl}"
outdir="${1:-$root/.cache/runs/E0135/R000001}"

die() { printf 'E0135: %s\n' "$1" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || die 'jq is required'
test -f "$ledger" || die "run ledger is missing: $ledger"
mkdir -p "$outdir"

jq -s -e '
  [.[] | select(.experiment == "E0135")] |
  length == 1 and .[0].repository == "ffc-new" and
  .[0].commit == "335629b753f440b2960bf9fef0e6b275094c79ec" and
  .[0].status == "accepted" and
  .[0].verification.multi_block_table == true and
  .[0].verification.single_block_preserved == true and
  .[0].verification.fo == true and
  .[0].verification.warnings_introduced == 0
' "$ledger" >/dev/null || die 'accepted ffc block-table run with a clean fo gate is missing'

jq -s -r '
  ["run", "repository", "status", "commit", "multi_block_table", "fo", "warnings_introduced"],
  (.[] | select(.experiment == "E0135") |
    [.run, .repository, .status, .commit,
     (.verification.multi_block_table // false), (.verification.fo // false),
     (.verification.warnings_introduced // -1)])
  | @tsv
' "$ledger" >"$outdir/summary.tsv"
printf 'gate\taccepted\n' >>"$outdir/summary.tsv"
printf 'E0135 accepted: %s\n' "$outdir/summary.tsv"
