#!/usr/bin/env bash
# Run the central end-to-end fixture runner. Until the L0 runner exists this
# command fails closed; no component-local command is silently substituted.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

runner="$ROOT/tests/e2e/run-l0.sh"
[ -x "$runner" ] || die "L0 runner is not implemented: $runner"
exec "$runner" "$@"
