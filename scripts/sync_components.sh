#!/usr/bin/env bash
# Report the central component pins and verify them. This intentionally does
# not pull, reset, merge or otherwise mutate sibling repositories.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

case "${1:---check}" in
    --check|--report)
        "$ROOT/scripts/status.sh"
        "$ROOT/scripts/check_pins.sh"
        ;;
    -h|--help)
        sed -n '2,5p' "$0" | sed 's/^# \{0,1\}//'
        ;;
    *)
        die 'usage: sync_components.sh [--check|--report]'
        ;;
esac
