#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
exp="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$exp/test-harness.py"
python3 "$exp/test-local-tools.py"
python3 -m py_compile "$exp/e0115_harness.py" "$exp/test-harness.py"
python3 -m py_compile "$exp/run-local-tools.py" "$exp/test-local-tools.py" "$exp/plot.py" "$exp/plot-convergence.py"
echo "E0115 harness syntax and behavioral gates passed"
