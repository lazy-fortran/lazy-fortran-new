#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/../../.." && pwd)"
canon="${CANONICAL_TEXT:-$root/../lazy-fortran-new/.cache/runs/E0001/R000003/j3-24-007.canonical.txt}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cp "$canon" "$tmp/tampered.txt"
printf 'tampered-window\n' >> "$tmp/tampered.txt"
if CANONICAL_TEXT="$tmp/tampered.txt" "$here/analyse.sh" "$tmp/out" >"$tmp/log" 2>&1; then
  echo 'tampered source window was accepted' >&2
  exit 1
fi
grep -q 'canonical hash mismatch' "$tmp/log"
echo 'E0104 negative control passed: tampered source/hash rejected'
