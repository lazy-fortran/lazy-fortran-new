#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

python3 - "${tmp}/base.jsonl" "${tmp}/retry.jsonl" <<'PY'
import json
import sys

base = [
    {"row_key": "C1@1", "status": "accepted"},
    {"row_key": "C2@1", "status": "unresolved"},
    {"row_key": "C3@1", "status": "hard_failure"},
]
retry = [
    {"row_key": "C2@1", "status": "accepted"},
    {"row_key": "C3@1", "status": "unresolved"},
]
for path, rows in zip(sys.argv[1:], (base, retry)):
    with open(path, "w", encoding="utf-8") as stream:
        for row in rows:
            stream.write(json.dumps(row) + "\n")
PY

python3 "${root}/merge-retry.py" "${tmp}/base.jsonl" "${tmp}/retry.jsonl" \
    --replace-status unresolved --replace-status hard_failure \
    --outdir "${tmp}/valid" >/dev/null
python3 - "${tmp}/valid/summary.json" <<'PY'
import json
import sys

summary = json.load(open(sys.argv[1], encoding="utf-8"))
assert summary["replacement_set_exact"] is True
assert summary["expected_retry_rows"] == 2
assert summary["selected_accepted"] == 2
PY

if python3 "${root}/merge-retry.py" "${tmp}/base.jsonl" "${tmp}/retry.jsonl" \
    --replace-status unresolved --outdir "${tmp}/wrong-status" >/dev/null 2>&1; then
    echo "missing retry status was accepted" >&2
    exit 1
fi

python3 - "${tmp}/short-retry.jsonl" <<'PY'
import json
import sys

with open(sys.argv[1], "w", encoding="utf-8") as stream:
    stream.write(json.dumps({"row_key": "C2@1", "status": "accepted"}) + "\n")
PY
if python3 "${root}/merge-retry.py" "${tmp}/base.jsonl" "${tmp}/short-retry.jsonl" \
    --replace-status unresolved --replace-status hard_failure \
    --outdir "${tmp}/short" >/dev/null 2>&1; then
    echo "incomplete retry set was accepted" >&2
    exit 1
fi

echo "merge-retry exact-set checks: ok"
