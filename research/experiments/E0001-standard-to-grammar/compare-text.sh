#!/usr/bin/env bash
# Compare representative canonical production lines with the independent
# helpy/pdf extractor. This is deliberately a differential check, not the
# normative definition of any production.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
pdf="${1:-$root/.cache/j3-24-007.pdf}"
canonical="${2:-$root/.cache/runs/E0001/R000003/j3-24-007.canonical.txt}"
index="${3:-$root/.cache/runs/E0001/R000003/j3-24-007.pages.index}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

page_slice() {
    local page="$1" start length
    read -r start length < <(awk -v page="$page" \
        '$1 == "page" && $2 == page { print $4, $6; exit }' "$index")
    dd if="$canonical" of="$tmp/page-$page.txt" bs=1 skip="$start" \
        count="$length" status=none
}

page_slice 53
page_slice 54
helpy pdf read --file "$pdf" --mode text --pages 53-54 --max-bytes 262144 \
    >"$tmp/helpy.txt"

grep -aFqx '5 R501 program is program-unit' "$tmp/page-53.txt"
grep -aFqx '6 [ program-unit ] ...' "$tmp/page-53.txt"
grep -aFqx '1 R504 specification-part is [ use-stmt ] ...' "$tmp/page-54.txt"
grep -aFqx '2 [ import-stmt ] ...' "$tmp/page-54.txt"

grep -aEq 'R501[[:space:]]+program[[:space:]]+is[[:space:]]+program-unit' \
    "$tmp/helpy.txt"
grep -aEq '\[ program-unit \][[:space:]]+\.\.\.' "$tmp/helpy.txt"
grep -aEq 'R504[[:space:]]+specification-part[[:space:]]+is' "$tmp/helpy.txt"
grep -aEq '\[ import-stmt \][[:space:]]+\.\.\.' "$tmp/helpy.txt"

printf '%s\n' 'text differential: four canonical production continuations agree'
