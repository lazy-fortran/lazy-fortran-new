#!/usr/bin/env bash
# Check that the component revisions named by STATUS.md are present, clean and
# exactly checked out. This is a control-plane check; it never fetches or
# changes a component repository.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
need git

STATUS="$ROOT/STATUS.md"
[ -f "$STATUS" ] || die "missing central status: $STATUS"

pin_for() {
    local component="$1"
    awk -F'|' -v needle="| $component |" '
        index($0, needle) {
            value = $4
            gsub(/[[:space:]`]/, "", value)
            print value
            exit
        }' "$STATUS"
}

repo_commit() {
    local repo_name="$1"
    awk -v target="repos.$repo_name" '
        /^\[/ {
            section = $0
            gsub(/^\[|\][[:space:]]*$/, "", section)
        }
        section == target && /^[[:space:]]*commit[[:space:]]*=/ {
            value = $0
            sub(/^[^=]*=[[:space:]]*/, "", value)
            gsub(/^"|"[[:space:]]*$/, "", value)
            print value
            exit
        }' "$ROOT/repos.toml"
}

failures=0
checked=0
while IFS=$'\t' read -r name _ path _; do
    [ -n "$name" ] || continue
    [ "$name" = laboratory ] && continue
    component="$path"
    pin=$(pin_for "$component")
    canonical=$(repo_commit "$name")
    if [ -z "$canonical" ]; then
        printf 'FAIL %s: no commit pin in repos.toml\n' "$component" >&2
        failures=$((failures + 1))
        continue
    fi
    if [ "$pin" != "$canonical" ]; then
        printf 'FAIL %s: STATUS.md pin %s differs from repos.toml pin %s\n' \
            "$component" "${pin:-<empty>}" "$canonical" >&2
        failures=$((failures + 1))
        continue
    fi
    if [ -z "$pin" ] || [[ "$pin" == \[* ]]; then
        printf 'FAIL %s: no concrete pin in STATUS.md\n' "$component" >&2
        failures=$((failures + 1))
        continue
    fi
    if [[ ! "$pin" =~ ^[0-9a-f]{7,64}$ ]]; then
        printf 'FAIL %s: invalid pin: %s\n' "$component" "$pin" >&2
        failures=$((failures + 1))
        continue
    fi
    dir=$(resolve_repo "$path")
    if [ ! -d "$dir/.git" ]; then
        printf 'FAIL %s: checkout absent: %s\n' "$component" "$dir" >&2
        failures=$((failures + 1))
        continue
    fi
    if [ -n "$(git -C "$dir" status --porcelain)" ]; then
        printf 'FAIL %s: checkout is dirty\n' "$component" >&2
        failures=$((failures + 1))
        continue
    fi
    actual=$(git -C "$dir" rev-parse HEAD)
    resolved=$(git -C "$dir" rev-parse "$pin^{commit}" 2>/dev/null || true)
    if [ "$resolved" != "$actual" ]; then
        printf 'FAIL %s: HEAD %s does not match pin %s\n' "$component" "$actual" "$pin" >&2
        failures=$((failures + 1))
        continue
    fi
    checked=$((checked + 1))
    printf 'PASS %s %s clean\n' "$component" "$actual"
done < <(repos_list repos)

[ "$checked" -gt 0 ] || die "no production component pins checked"
printf 'component pins: %d checked, %d failures\n' "$checked" "$failures"
exit "$failures"
