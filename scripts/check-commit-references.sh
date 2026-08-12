#!/usr/bin/env bash
# Verify exact commit pins in active experiment manifests.
#
# Live repository status belongs to scripts/status.sh. This check is for the
# immutable pins that make a reported experiment reproducible. Missing oracle
# checkouts are reported and skipped by default because the full oracle set is
# intentionally not cloned by bootstrap. Use --strict when every named
# checkout is available and must be checked.

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
need git

strict=0
if [ "${1:-}" = "--strict" ]; then
    strict=1
elif [ -n "${1:-}" ]; then
    die 'usage: check-commit-references.sh [--strict]'
fi

repo_dir() {
    case "$1" in
        lazy-fortran-new) printf '%s\n' "$ROOT" ;;
        standard-new) printf '%s\n' "$(resolve_repo standard-new)" ;;
        oracle-standard) printf '%s\n' "$(resolve_repo standard)" ;;
        oracle-fortfront) printf '%s\n' "$(resolve_repo fortfront)" ;;
        oracle-ffc) printf '%s\n' "$(resolve_repo ffc)" ;;
        oracle-fortad) printf '%s\n' "$(resolve_repo fortad)" ;;
        oracle-fluff) printf '%s\n' "$(resolve_repo fluff)" ;;
        oracle-liric) printf '%s\n' "$(resolve_repo liric)" ;;
        oracle-lfortran) printf '%s\n' "$(resolve_repo lfortran)" ;;
        oracle-flang) printf '%s\n' "$(resolve_repo llvm-project)" ;;
        oracle-gcc) printf '%s\n' "$(resolve_repo gcc)" ;;
        oracle-kaby76) printf '%s\n' "$(resolve_repo kaby76-fortran)" ;;
        *) return 1 ;;
    esac
}

fails=0
checked=0
skipped=0

while IFS= read -r manifest; do
    status=$(awk -F': *' '/^status:/{sub(/#.*/, "", $2); gsub(/[[:space:]]/, "", $2); print $2; exit}' "$manifest")
    case "$status" in
        draft|abandoned) continue ;;
        running|reported) ;;
        *)
            printf 'FAIL %s: missing or unknown status\n' "$manifest" >&2
            fails=$((fails + 1))
            continue
            ;;
    esac

    while IFS=$'\t' read -r name hash; do
        [ -n "$name" ] || continue
        if [ -z "$hash" ]; then
            printf 'FAIL %s: empty pin for %s\n' "$manifest" "$name" >&2
            fails=$((fails + 1))
            continue
        fi
        if [[ ! "$hash" =~ ^[0-9a-f]{7,64}$ ]]; then
            printf 'FAIL %s: non-commit pin for %s: %s\n' "$manifest" "$name" "$hash" >&2
            fails=$((fails + 1))
            continue
        fi
        if ! dir=$(repo_dir "$name"); then
            printf 'FAIL %s: no checkout mapping for %s\n' "$manifest" "$name" >&2
            fails=$((fails + 1))
            continue
        fi
        if [ ! -d "$dir/.git" ]; then
            printf 'SKIP %s: checkout absent for %s (%s)\n' "$manifest" "$name" "$dir" >&2
            skipped=$((skipped + 1))
            if [ "$strict" -eq 1 ]; then
                fails=$((fails + 1))
            fi
            continue
        fi
        type=$(git -C "$dir" cat-file -t "${hash}^{commit}" 2>/dev/null || true)
        if [ "$type" != commit ]; then
            printf 'FAIL %s: %s does not resolve in %s\n' "$manifest" "$hash" "$dir" >&2
            fails=$((fails + 1))
        else
            checked=$((checked + 1))
        fi
    done < <(awk '
        /^repos:[[:space:]]*$/ {inside = 1; next}
        inside && /^[^[:space:]]/ {exit}
        inside && /^[[:space:]]+[A-Za-z0-9_-]+:[[:space:]]*/ {
            line = $0
            sub(/^[[:space:]]+/, "", line)
            name = line
            sub(/:.*/, "", name)
            value = line
            sub(/^[^:]*:[[:space:]]*/, "", value)
            gsub(/[[:space:]]*#.*/, "", value)
            gsub(/^"|"$/, "", value)
            print name "\t" value
        }
    ' "$manifest")
done < <(find "$ROOT/research/experiments" -name manifest.yaml -print | sort)

printf 'commit references: %d checked, %d skipped, %d failures\n' "$checked" "$skipped" "$fails"
exit "$fails"
