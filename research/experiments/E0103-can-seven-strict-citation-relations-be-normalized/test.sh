#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
analyse="$root/research/experiments/E0103-can-seven-strict-citation-relations-be-normalized/analyse.sh"
model="$root/../lazy-fortran-new/.cache/runs/E0101/R000003/model-output.jsonl"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

"$analyse" "$tmp/positive" >"$tmp/positive.log"
cp "$model" "$tmp/tampered-model-output.jsonl"
python3 - "$tmp/tampered-model-output.jsonl" <<'PY'
import json
import sys

path = sys.argv[1]
lines = path and open(path, encoding="utf-8").read().splitlines()
for index, line in enumerate(lines):
    item = json.loads(line)
    if item.get("decision") == "relation":
        item["citation"]["line"] += 1
        lines[index] = json.dumps(item, separators=(",", ":"))
        break
else:
    raise SystemExit("no relation row to tamper")
open(path, "w", encoding="utf-8").write("\n".join(lines) + "\n")
PY
if E0102_MODEL_OUTPUT="$tmp/tampered-model-output.jsonl" "$analyse" "$tmp/negative" >"$tmp/negative.log" 2>&1; then
    printf '%s\n' 'E0103 negative control unexpectedly passed' >&2
    exit 1
fi
E0102_MODEL_OUTPUT="$model" "$analyse" "$tmp/positive-again" >"$tmp/positive-again.log"
cmp "$tmp/positive/summary.tsv" "$tmp/positive-again/summary.tsv"
printf '%s\n' 'E0103 positive run and citation-tamper negative control passed'
