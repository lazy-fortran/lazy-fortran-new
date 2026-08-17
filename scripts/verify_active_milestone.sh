#!/usr/bin/env bash
# Verify the currently declared central milestone. The command is deliberately
# fail-closed while the end-to-end runner is still being built.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

[ -f "$ROOT/STATUS.md" ] || die 'missing STATUS.md'
[ -f "$ROOT/MILESTONES.md" ] || die 'missing MILESTONES.md'
active=$(awk '
    /^## Active milestone$/ {wanted = 1; next}
    wanted && NF {print; exit}
' "$ROOT/STATUS.md")
[ -n "$active" ] || die 'STATUS.md has no active milestone'
"$ROOT/scripts/check_pins.sh"
"$ROOT/scripts/check-contracts.sh"
case "$active" in
    L0\ *) "$ROOT/scripts/run_e2e.sh" "$@" ;;
    L1\ *) "$ROOT/tests/e2e/run-l1.sh" "$@" ;;
    L2\ *) "$ROOT/tests/e2e/run-l2.sh" "$@" ;;
    M1-M2\ *) "$ROOT/tests/e2e/run-m1m2.sh" "$@" ;;
    M3\ *) "$ROOT/tests/e2e/run-m3-c747.sh" --fresh ;;
    *) die "no central runner is implemented for active milestone: $active" ;;
esac
