#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
experiment="$root/research/experiments/E0116-can-bounded-qwen-semantic-proposals-clos"

python3 -m py_compile "$experiment"/*.py
python3 "$experiment/test-semantic.py"
python3 "$experiment/validate.py" --help >/dev/null
printf 'E0116 harness syntax and behavioral gates passed\n'
