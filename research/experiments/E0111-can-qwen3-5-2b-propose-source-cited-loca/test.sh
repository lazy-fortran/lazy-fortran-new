#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
exp="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/e0111-test.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

python3 "$exp/prepare-prompts.py" --outdir "$tmp/prompts"
python3 "$exp/mock-responses.py" "$tmp/prompts/prompts.jsonl" "$tmp/responses.jsonl" \
    --e0110 "$root/.cache/runs/E0110/R000001/classifications.tsv" \
    --canonical "$root/.cache/runs/E0001/R000003/j3-24-007.canonical.txt"
python3 "$exp/validate-responses.py" "$tmp/responses.jsonl" \
    --e0110 "$root/.cache/runs/E0110/R000001/classifications.tsv" \
    --outdir "$tmp/validated"

python3 - "$tmp/responses.jsonl" "$tmp/tampered.jsonl" <<'PY'
import json
import sys

source, target = sys.argv[1:]
rows = [json.loads(line) for line in open(source, encoding="utf-8")]
for row in rows:
    if row.get("decision") == "proposal":
        row["citation"]["text"] += " tampered"
        break
with open(target, "w", encoding="utf-8") as stream:
    for row in rows:
        stream.write(json.dumps(row) + "\n")
PY
if python3 "$exp/validate-responses.py" "$tmp/tampered.jsonl" \
    --e0110 "$root/.cache/runs/E0110/R000001/classifications.tsv" \
    --outdir "$tmp/rejected"; then
    echo "E0111: tampered citation was accepted" >&2
    exit 1
fi
echo "E0111 fixture and tampered-citation gates passed"
