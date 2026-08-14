#!/usr/bin/env bash
# Focused behavioral and falsifying tests for E0120.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
here="$root/research/experiments/E0120-can-deterministic-normative-constraint-f"
canonical="$root/.cache/runs/E0001/R000003/j3-24-007.canonical.txt"
pages="$root/.cache/runs/E0001/R000003/j3-24-007.pages.index"
constraints="$root/.cache/runs/E0081/R000001/constraint-spans.tsv"
structure="$root/.cache/runs/E0106/R000001/structure.jsonl"
residue="$root/.cache/runs/E0106/R000001/residue-classifications.tsv"
baseline="$root/research/experiments/E0083-can-deterministic-predicate-patterns-for/independent-oracle.tsv"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

run() {
    python3 "$here/analyze.py" --canonical "$1" --pages "$2" --constraints "$3" \
        --structure "$structure" --baseline "$4" --source-oracle "$tmp/oracle.tsv" \
        --residue "$residue" --baseline-hash "${5:-4b3288383fb36b7a1b619fcae7c7affecdbc805d7ba55878feee5d90c3fd2fba}" \
        --outdir "$tmp/out"
}

run "$canonical" "$pages" "$constraints" "$baseline" >"$tmp/positive.log"
grep -q $'eligible_constraints\t287' "$tmp/positive.log"
grep -q $'oracle_predicate_matches\t8' "$tmp/positive.log"
test "$(awk -F '\t' 'NR > 1 {n++} END {print n + 0}' "$tmp/oracle.tsv")" -gt 8

cp "$canonical" "$tmp/tampered.txt"
python3 - "$tmp/tampered.txt" <<'PY'
from pathlib import Path
import sys

data = bytearray(Path(sys.argv[1]).read_bytes())
data[175810] = (data[175810] + 1) % 256
Path(sys.argv[1]).write_bytes(data)
PY
if run "$tmp/tampered.txt" "$pages" "$constraints" "$baseline" >"$tmp/hash.log" 2>&1; then
    echo 'source-byte mutation was accepted' >&2
    exit 1
fi

sed 's/7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2/0000000000000000000000000000000000000000000000000000000000000000/' \
    "$constraints" >"$tmp/bad-constraints.tsv"
if run "$canonical" "$pages" "$tmp/bad-constraints.tsv" "$baseline" >"$tmp/inventory.log" 2>&1; then
    echo 'inventory source-hash mutation was accepted' >&2
    exit 1
fi

sed 's/(le (name-length name) 63)/(le (name-length name) 64)/' \
    "$baseline" >"$tmp/bad-baseline.tsv"
if run "$canonical" "$pages" "$constraints" "$tmp/bad-baseline.tsv" "$(sha256sum "$tmp/bad-baseline.tsv" | cut -d' ' -f1)" >"$tmp/predicate.log" 2>&1; then
    echo 'oracle predicate mutation was accepted' >&2
    exit 1
fi

echo 'E0120 selftest: positive expansion, source-byte, source-hash, and predicate mutations all behaved as expected'
