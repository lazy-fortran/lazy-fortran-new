#!/usr/bin/env bash
# Summarize the source-backed grammar producer/consumer handoff.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
ledger="${E0124_RUNS:-$root/research/runs/2026-08.jsonl}"
outdir="${1:-$root/.cache/runs/E0124/R000001}"

die() { printf 'E0124: %s\n' "$1" >&2; exit 1; }

command -v jq >/dev/null 2>&1 || die 'jq is required'
test -f "$ledger" || die "run ledger is missing: $ledger"
mkdir -p "$outdir"

count="$(jq -s '[.[] | select(.experiment == "E0124")] | length' "$ledger")"
test "$count" -eq 2 || die "expected two E0124 rows, found $count"

jq -s -r '
    ["run", "repository", "status", "commit", "fo", "warnings_introduced"] ,
    (.[] | select(.experiment == "E0124") |
      [.run, .repository, .status, .commit,
       (.verification.fo // false),
       (.verification.warnings_introduced // -1)])
    | @tsv
' "$ledger" >"$outdir/summary.tsv"

producer="$(jq -s '[.[] | select(.experiment == "E0124" and .repository == "standard-new")] | length' "$ledger")"
consumer="$(jq -s '[.[] | select(.experiment == "E0124" and .repository == "fortfront-new")] | length' "$ledger")"
test "$producer" -eq 1 || die 'standard-new producer row is missing'
test "$consumer" -eq 1 || die 'fortfront-new consumer row is missing'

if jq -s -e '
    [.[] | select(.experiment == "E0124")] |
    all(.[]; .status == "accepted" and .verification.fo == true and
        .verification.warnings_introduced == 0)
' "$ledger" >/dev/null; then
    printf 'gate\taccepted\n' >>"$outdir/summary.tsv"
    printf 'E0124 accepted: %s\n' "$outdir/summary.tsv"
else
    printf 'gate\tfailed\n' >>"$outdir/summary.tsv"
    printf 'E0124 failed: %s\n' "$outdir/summary.tsv"
    exit 1
fi
