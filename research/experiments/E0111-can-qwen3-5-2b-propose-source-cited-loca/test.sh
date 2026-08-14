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
python3 "$exp/validate-responses.py" "$tmp/tampered.jsonl" \
    --e0110 "$root/.cache/runs/E0110/R000001/classifications.tsv" \
    --outdir "$tmp/rejected"
if ! grep -q $'strict_validator_rejects\t1' "$tmp/rejected/summary.tsv"; then
    echo "E0111: tampered citation was not rejected" >&2
    exit 1
fi
echo "E0111 fixture and tampered-citation gates passed"

python3 "$exp/prepare-prompts.py" --outdir "$tmp/pointer-prompts" \
    --e0110 "$root/.cache/runs/E0110/R000001/classifications.tsv" --pointer-mode
python3 "$exp/mock-responses.py" "$tmp/pointer-prompts/prompts.jsonl" "$tmp/pointer-responses.jsonl" \
    --e0110 "$root/.cache/runs/E0110/R000001/classifications.tsv" \
    --canonical "$root/.cache/runs/E0001/R000003/j3-24-007.canonical.txt" --pointer-mode
python3 "$exp/validate-responses.py" "$tmp/pointer-responses.jsonl" \
    --e0110 "$root/.cache/runs/E0110/R000001/classifications.tsv" \
    --prompts "$tmp/pointer-prompts/prompts.jsonl" --pointer-mode \
    --outdir "$tmp/pointer-validated"
echo "E0111 deterministic pointer-citation gate passed"

python3 "$exp/prepare-prompts.py" --outdir "$tmp/pointer-only-prompts" \
    --e0110 "$root/.cache/runs/E0110/R000001/classifications.tsv" \
    --pointer-only --full-retrieval --window-bytes 768 --max-windows 8
python3 "$exp/mock-responses.py" "$tmp/pointer-only-prompts/prompts.jsonl" "$tmp/pointer-only-responses.jsonl" \
    --e0110 "$root/.cache/runs/E0110/R000001/classifications.tsv" \
    --canonical "$root/.cache/runs/E0001/R000003/j3-24-007.canonical.txt" --pointer-only
python3 "$exp/validate-responses.py" "$tmp/pointer-only-responses.jsonl" \
    --e0110 "$root/.cache/runs/E0110/R000001/classifications.tsv" \
    --prompts "$tmp/pointer-only-prompts/prompts.jsonl" --pointer-only \
    --outdir "$tmp/pointer-only-validated"
echo "E0113 full-retrieval pointer-only gate passed"
python3 "$exp/test-iterative.py"
python3 "$exp/test-reasoning-control.py"
