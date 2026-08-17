#!/usr/bin/env bash
# Replay the bounded L3 integer-declaration source slice.

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export L3_MANIFEST="tests/fixtures/l3-declaration-v0.toml"
export L3_VALIDATOR="$ROOT/tests/e2e/validate_l3_declaration.py"
export L3_RUN_ROOT="$ROOT/.cache/runs/E0234"
exec "$ROOT/tests/e2e/run-l3.sh" "$@"
