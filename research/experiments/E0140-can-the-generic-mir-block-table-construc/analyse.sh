#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
ledger="${E0140_RUNS:-$root/research/runs/2026-08.jsonl}"
outdir="${1:-$root/.cache/runs/E0140/R000251}"

die() { printf 'E0140: %s\n' "$1" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || die 'jq is required'
test -f "$ledger" || die "run ledger is missing: $ledger"
mkdir -p "$outdir"

jq -s -e '
  [.[] | select(.experiment == "E0140")] |
  length == 1 and .[0].repository == "ffc-new" and
  .[0].commit == "5ac3cefe88e8c8a3d71d28533c75686712c4a812" and .[0].status == "accepted" and
  .[0].verification.valid_partition_matrix == true and
  .[0].verification.prefix_sum_oracle == true and
  .[0].verification.failure_output_clearing == true and
  .[0].verification.fo == true and
  .[0].verification.warnings_introduced == 0
' "$ledger" >/dev/null || die 'accepted MIR partition-constructor run with a clean fo gate is missing'

jq -s -r '
  ["run", "repository", "status", "commit", "valid_partition_matrix", "fo", "warnings_introduced"],
  (.[] | select(.experiment == "E0140") |
    [.run, .repository, .status, .commit,
     (.verification.valid_partition_matrix // false), (.verification.fo // false),
     (.verification.warnings_introduced // -1)])
  | @tsv
' "$ledger" >"$outdir/summary.tsv"
printf 'gate\taccepted\n' >>"$outdir/summary.tsv"
printf 'E0140 accepted: %s\n' "$outdir/summary.tsv"
