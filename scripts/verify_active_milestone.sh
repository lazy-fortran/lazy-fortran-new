#!/usr/bin/env bash
# Verify the currently declared central milestone. The command is deliberately
# fail-closed while the end-to-end runner is still being built.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

[ -f "$ROOT/STATUS.md" ] || die 'missing STATUS.md'
[ -f "$ROOT/MILESTONES.md" ] || die 'missing MILESTONES.md'
grep -q '^L0 ' "$ROOT/STATUS.md" || die 'STATUS.md has no active L0 milestone'
"$ROOT/scripts/check_pins.sh"
"$ROOT/scripts/check-contracts.sh"
"$ROOT/scripts/run_e2e.sh" "$@"
