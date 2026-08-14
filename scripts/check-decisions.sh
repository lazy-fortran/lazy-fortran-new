#!/usr/bin/env bash
# Validate the decision ledger, including successor links and proposed handoffs.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

DECISIONS_DIR="${DECISIONS_DIR:-$ROOT/research/decisions}"

failures=0
fail() {
    printf 'FAIL: %s\n' "$*" >&2
    failures=$((failures + 1))
}

has_relation() {
    local file="$1" relation="$2" target="$3"
    awk -F': *' -v wanted_relation="$relation" -v wanted_target="$target" '
        $1 == wanted_relation {
            count = split($2, values, /[, ]+/)
            for (i = 1; i <= count; i++) {
                if (values[i] == wanted_target) found = 1
            }
        }
        END { exit(found ? 0 : 1) }
    ' "$file"
}

if [ "${1:-}" = "--self-test" ]; then
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    cp "$DECISIONS_DIR"/*.md "$tmp/"
    sed -i 's/^Status: accepted$/Status: invalid/' "$tmp/D0001-no-submodules.md"
    if DECISIONS_DIR="$tmp" "$0" >/dev/null 2>&1; then
        die "decision checker accepted a deliberately invalid status"
    fi
    note "decision checker negative control: observed failure"
    exit 0
fi

shopt -s nullglob
files=("$DECISIONS_DIR"/D[0-9][0-9][0-9][0-9]-*.md)
declare -A paths=()
declare -A statuses=()

for file in "${files[@]}"; do
    base=$(basename "$file")
    if [[ ! "$base" =~ ^(D[0-9]{4})-[a-z0-9][a-z0-9-]*\.md$ ]]; then
        fail "invalid decision filename: $base"
        continue
    fi
    id="${BASH_REMATCH[1]}"
    if [ -n "${paths[$id]:-}" ]; then
        fail "duplicate decision ID $id: $base and $(basename "${paths[$id]}")"
    fi
    paths[$id]="$file"

    # Older accepted records use an em dash after the ID; the template uses a
    # period. Both are title syntax, not a difference in decision content.
    title=$(sed -n -E "1s/^# ${id}(\.| —) //p" "$file")
    [ -n "$title" ] || fail "$base has no matching title heading"
    date=$(awk -F': *' '/^Date:/{print $2; exit}' "$file")
    [[ "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || \
        fail "$base has an invalid Date header"
    status=$(awk -F': *' '/^Status:/{print $2; exit}' "$file")
    case "$status" in
        proposed|accepted|retracted|superseded\ by\ D[0-9][0-9][0-9][0-9]|amended\ by\ D[0-9][0-9][0-9][0-9]) ;;
        *) fail "$base has an invalid Status header: ${status:-<missing>}" ;;
    esac
    statuses[$id]="$status"
    if ! grep -q '^## Context$' "$file" && ! grep -q '^## Evidence$' "$file"; then
        fail "$base is missing section: Context or Evidence"
    fi
    grep -q '^## Decision$' "$file" || fail "$base is missing section: Decision"
    grep -q '^## Rejected' "$file" || fail "$base is missing section: Rejected"
    grep -q '^## Reversal condition$' "$file" || \
        fail "$base is missing section: Reversal condition"
    if [ "$status" = proposed ]; then
        grep -q '^## Decision needed$' "$file" || \
            fail "$base is proposed but has no Decision needed section"
    fi
done

for file in "${files[@]}"; do
    base=$(basename "$file")
    id="${base:0:5}"
    while IFS=$'\t' read -r relation target; do
        [ -n "$relation" ] || continue
        target_file="${paths[$target]:-}"
        if [ -z "$target_file" ]; then
            fail "$base points to missing decision $target"
            continue
        fi
        case "$relation" in
            Supersedes) expected="superseded by $id" ;;
            Amends) expected="amended by $id" ;;
            Retracts) expected="retracted" ;;
            *) expected="" ;;
        esac
        if [ "$relation" = Amends ]; then
            case "${statuses[$target]}" in
                accepted|amended\ by\ D[0-9][0-9][0-9][0-9]) ;;
                *) fail "$base says Amends $target but target status is '${statuses[$target]}'" ;;
            esac
        else
            [ "${statuses[$target]}" = "$expected" ] || \
                fail "$base says $relation $target but target status is '${statuses[$target]}'"
        fi
    done < <(awk -F': *' '
        /^(Supersedes|Amends|Retracts):/ {
            relation = $1
            count = split($2, values, /[, ]+/)
            for (i = 1; i <= count; i++) {
                if (values[i] ~ /^D[0-9][0-9][0-9][0-9]$/) {
                    print relation "\t" values[i]
                }
            }
        }
    ' "$file")

    status="${statuses[$id]}"
    if [[ "$status" =~ ^(superseded|amended)\ by\ (D[0-9]{4})$ ]]; then
        successor="${BASH_REMATCH[2]}"
        successor_file="${paths[$successor]:-}"
        [ -n "$successor_file" ] || fail "$base points to missing successor $successor"
        if [ -n "$successor_file" ]; then
            if [ "${BASH_REMATCH[1]}" = superseded ]; then
                has_relation "$successor_file" Supersedes "$id" || \
                    fail "$base successor $successor lacks Supersedes: $id"
            else
                has_relation "$successor_file" Amends "$id" || \
                    fail "$base successor $successor lacks Amends: $id"
            fi
        fi
    fi
done

[ "$failures" -eq 0 ] || exit 1
note "decision records: ${#files[@]} valid"
