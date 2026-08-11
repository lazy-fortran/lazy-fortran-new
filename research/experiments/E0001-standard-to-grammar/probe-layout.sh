#!/usr/bin/env bash
# Verify the first layout hypothesis against one clause-5 page and one held-out
# page. The expected snippets are read from J3/24-007, not from another
# implementation of the probe.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
pdf="${1:-$root/.cache/j3-24-007.pdf}"
standard="${2:-$root/../standard-new}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

(cd "$standard" && fo exec --no-build pdftext "$pdf" 53) >"$tmp/page53.layout"
(cd "$standard" && fo exec --no-build pdftext "$pdf" 54) >"$tmp/page54.layout"

text_from_layout() {
    awk '$1 == "text-byte" { printf "%c", $3 }' "$1"
}

text53="$(text_from_layout "$tmp/page53.layout")"
text54="$(text_from_layout "$tmp/page54.layout")"

grep -Fqx 'R501programisprogram-unit' <<<"$text53"
grep -Fqx '[ program-unit ] ...' <<<"$text53"
grep -Fqx '4R504specification-partis[ use-stmt ] ...' <<<"$text54"
grep -Fqx '[ import-stmt ] ...' <<<"$text54"

awk '
    $1 == "glyph" && $2 == 387 {
        if ($4 < 57.82 || $4 > 57.84 || $5 < 262.20 || $5 > 262.22) exit 1
        found = 1
    }
    END { exit !found }
' "$tmp/page53.layout"

awk '
    $1 == "glyph" && $2 == 413 {
        if ($5 < 274.16 || $5 > 274.18) exit 1
        found = 1
    }
    END { exit !found }
' "$tmp/page53.layout"

printf '%s\n' 'layout probe: positive'
printf '%s\n' '  page 53: R501 and its continuation retain distinct geometry rows'
printf '%s\n' '  page 54: held-out R504 continuation is recoverable'
