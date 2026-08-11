#!/usr/bin/env bash
# Fetch a pinned external artifact into the gitignored cache and verify its
# SHA-256 against its manifest.
#
# Nothing external is committed to this repository. artifacts/ holds manifests;
# this script holds the only code that turns a manifest into bytes on disk.
#
# A hash mismatch is a hard failure. It is never a warning, and there is no
# flag to skip it: an unverified artifact silently substituted for a verified
# one would invalidate every measurement downstream of it.
#
# Usage:
#   fetch.sh --list              what is pinned, and whether it is cached
#   fetch.sh <name> [<name>...]  fetch and verify
#   fetch.sh --all
#   fetch.sh --verify <name>     verify the cached copy without downloading
#
# Exit status: 0 all requested artifacts verified; 1 otherwise.

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
need sha256sum

manifest_for() {
    local name="$1" m
    m=$(find "$ROOT/artifacts" -name "$name.toml" -print -quit 2>/dev/null || true)
    [ -n "$m" ] || die "no manifest for '$name' under artifacts/"
    printf '%s\n' "$m"
}

all_manifests() {
    find "$ROOT/artifacts" -name '*.toml' | sort
}

cache_path_for() {
    local manifest="$1" name url ext
    name=$(toml_get "$manifest" name)
    url=$(toml_get "$manifest" url)
    ext="${url##*.}"
    case "$ext" in
        pdf|zip|gz|xz|zst|tar|json|xml|txt) : ;;
        *) ext=bin ;;
    esac
    printf '%s/%s.%s\n' "$CACHE" "$name" "$ext"
}

verify_one() {
    local manifest="$1" file="$2" want got
    want=$(toml_get "$manifest" sha256)
    [ -n "$want" ] || die "manifest has no sha256: $manifest"
    got=$(sha256sum "$file" | cut -d' ' -f1)
    if [ "$want" != "$got" ]; then
        printf 'HASH MISMATCH for %s\n  expected %s\n  actual   %s\n  file     %s\n' \
            "$(toml_get "$manifest" name)" "$want" "$got" "$file" >&2
        return 1
    fi
    return 0
}

do_list() {
    printf '%-16s %-9s %-12s %s\n' NAME CACHED BYTES PURPOSE
    local m name file state
    while read -r m; do
        [ -n "$m" ] || continue
        name=$(toml_get "$m" name)
        file=$(cache_path_for "$m")
        state=absent
        [ -f "$file" ] && state=cached
        printf '%-16s %-9s %-12s %s\n' \
            "$name" "$state" "$(toml_get "$m" bytes)" "$(toml_get "$m" purpose)"
    done < <(all_manifests)
}

do_fetch() {
    local name="$1" verify_only="${2:-0}"
    local manifest file url
    manifest=$(manifest_for "$name")
    file=$(cache_path_for "$manifest")
    url=$(toml_get "$manifest" url)

    mkdir -p "$CACHE"

    if [ -f "$file" ]; then
        if verify_one "$manifest" "$file"; then
            note "ok     $name (cached, verified)"
            return 0
        fi
        [ "$verify_only" = 1 ] && return 1
        warn "cached copy of $name failed verification; re-downloading"
        rm -f "$file"
    elif [ "$verify_only" = 1 ]; then
        die "not cached: $name"
    fi

    note "fetch  $name"
    if command -v curl >/dev/null 2>&1; then
        curl --fail --location --silent --show-error --output "$file.part" "$url" \
            || { rm -f "$file.part"; die "download failed: $url"; }
    elif command -v wget >/dev/null 2>&1; then
        wget --quiet --output-document="$file.part" "$url" \
            || { rm -f "$file.part"; die "download failed: $url"; }
    else
        die "need curl or wget"
    fi
    mv "$file.part" "$file"

    if verify_one "$manifest" "$file"; then
        note "ok     $name (downloaded, verified)"
        return 0
    fi
    # Keep the bad file for inspection but make it unusable as a cache hit.
    mv "$file" "$file.rejected"
    die "verification failed for $name; kept at $file.rejected"
}

[ $# -gt 0 ] || { sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0; }

rc=0
case "$1" in
    --list|-l)
        do_list
        ;;
    --all|-a)
        while read -r m; do
            [ -n "$m" ] || continue
            do_fetch "$(toml_get "$m" name)" || rc=1
        done < <(all_manifests)
        ;;
    --verify)
        shift
        [ $# -gt 0 ] || die "--verify needs an artifact name"
        for n in "$@"; do do_fetch "$n" 1 || rc=1; done
        ;;
    -h|--help)
        sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
        ;;
    -*)
        die "unknown option: $1"
        ;;
    *)
        for n in "$@"; do do_fetch "$n" || rc=1; done
        ;;
esac
exit $rc
