#!/usr/bin/env bash
# Replay the bounded typed frontend AST v1 multi-character name.

set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export AST_MANIFEST="$root/tests/fixtures/frontend-ast-v1-name-multichar-replay.toml"
export AST_VALIDATOR="$root/tests/e2e/validate_frontend_ast_v1_name_multichar.py"
export AST_RUN_ROOT="$root/.cache/runs/E0239"
exec "$root/tests/e2e/run-frontend-ast-v1.sh" "$@"
