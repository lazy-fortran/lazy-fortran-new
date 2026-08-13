#!/usr/bin/env bash
# Validate the central versioned SX contract boundary.
#
# This is intentionally a small structural gate. The production schema
# generator owns the full `.sxs` language; the laboratory gate catches missing
# revisions, missing witnesses and malformed central inputs before an agent
# consumes them.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

CONTRACTS_DIR="${CONTRACTS_DIR:-$ROOT/contracts}"
FIXTURES_DIR="$CONTRACTS_DIR/fixtures"
REGISTRY="$CONTRACTS_DIR/registry.sx"

fail() { printf 'FAIL: %s\n' "$*" >&2; return 1; }

balanced() {
    awk '
        BEGIN { depth = 0 }
        {
            line = $0
            gsub(/[^()]/, "", line)
            for (i = 1; i <= length(line); i++) {
                c = substr(line, i, 1)
                if (c == "(") depth++
                if (c == ")") depth--
                if (depth < 0) exit 2
            }
        }
        END { if (depth != 0) exit 2 }
    ' "$1"
}

validate() {
    [ -d "$CONTRACTS_DIR" ] || fail "missing contracts directory: $CONTRACTS_DIR"
    [ -f "$REGISTRY" ] || fail "missing registry: $REGISTRY"
    [ -d "$FIXTURES_DIR" ] || fail "missing fixtures directory: $FIXTURES_DIR"

    local schemas=() schema stem id version fixture
    while IFS= read -r schema; do schemas+=("$schema"); done < <(
        find "$CONTRACTS_DIR" -maxdepth 1 -type f -name '*-v*.sxs' | sort
    )
    [ "${#schemas[@]}" -gt 0 ] || fail "no contract schemas found"

    grep -q '^(contract-registry$' "$REGISTRY" || fail "registry has no contract-registry root"
    balanced "$REGISTRY" || fail "registry is not balanced: $REGISTRY"

    declare -A seen=()
    for schema in "${schemas[@]}"; do
        stem=$(basename "$schema" .sxs)
        if [[ ! "$stem" =~ ^([a-z0-9-]+)-v([0-9]+)$ ]]; then
            fail "invalid contract filename: $(basename "$schema")"
        fi
        id="${BASH_REMATCH[1]}"
        version="${BASH_REMATCH[2]}"
        grep -q "^(schema $stem$" "$schema" || fail "$schema has no matching schema root"
        balanced "$schema" || fail "schema is not balanced: $schema"
        fixture="$FIXTURES_DIR/$stem.sx"
        [ -f "$fixture" ] || fail "missing fixture: $fixture"
        grep -q '^(contract-witness$' "$fixture" || fail "$fixture has no witness root"
        grep -q "  (version $version)" "$fixture" || fail "$fixture has no version $version"
        balanced "$fixture" || fail "fixture is not balanced: $fixture"
        grep -q "  (contract $id)" "$fixture" || fail "$fixture names the wrong contract"
        if [ -n "${seen[$stem]:-}" ]; then
            fail "duplicate contract schema: $stem"
        fi
        seen[$stem]=1
        grep -q "  (contract $id $version " "$REGISTRY" || \
            fail "registry does not cover $stem"
    done

    local registry_count
    registry_count=$(grep -c '^  (contract ' "$REGISTRY")
    [ "$registry_count" -eq "${#schemas[@]}" ] || \
        fail "registry contract count differs from schema count"
    return 0
}

if [ "${1:-}" = "--self-test" ]; then
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    cp -R "$CONTRACTS_DIR" "$tmp/contracts"
    sed -i '$d' "$tmp/contracts/standardir-v0.sxs"
    if CONTRACTS_DIR="$tmp/contracts" "$0" >/dev/null 2>&1; then
        die "contract gate accepted a deliberately unbalanced schema"
    fi
    note "contract checker negative control: observed failure"
    exit 0
fi

validate
note "contract schemas: validated"
