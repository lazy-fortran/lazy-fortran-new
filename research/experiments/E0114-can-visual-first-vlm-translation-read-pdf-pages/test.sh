#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
exp="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/e0114-test.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

python3 "$exp/prepare-pages.py" \
    --pdf "$root/.cache/j3-24-007.pdf" \
    --e0110 "$root/.cache/runs/E0110/R000001/accepted-definitions.tsv" \
    --outdir "$tmp/pages" --dpi 100
python3 - "$exp/run-vlm.py" "$tmp/pages/tasks.jsonl" \
    "$root/.cache/runs/E0110/R000001/accepted-definitions.tsv" \
    "$root/.cache/runs/E0001/R000003/j3-24-007.canonical.txt" <<'PY'
import importlib.util
import sys
from pathlib import Path

module_path, tasks, e0110, canonical = sys.argv[1:]
spec = importlib.util.spec_from_file_location("e0114_vlm", module_path)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
rows = module.oracle_rows(e0110, canonical)
assert len(rows) == 6
assert len(Path(tasks).read_text(encoding="utf-8").splitlines()) == 6
print("E0114 visual page/oracle fixture passed")
PY
