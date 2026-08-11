#!/usr/bin/env bash
# Clone any repository from repos.toml that is not already a sibling checkout.
#
# Existing checkouts are never touched: this script only ever adds. Updating is
# scripts/update.sh, and it is a separate script so that a bootstrap can never
# move someone's working tree out from under them.
#
# Usage:
#   bootstrap.sh              production repositories only
#   bootstrap.sh --oracles    also clone oracles marked clone = true
#   bootstrap.sh --all        everything, including large ones marked false
#   bootstrap.sh --dry-run    print what would happen

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
need git

sections=(repos)
force_all=0
dry=0

for arg in "$@"; do
    case "$arg" in
        --oracles) sections=(repos oracle) ;;
        --all)     sections=(repos oracle); force_all=1 ;;
        --dry-run) dry=1 ;;
        -h|--help) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *)         die "unknown argument: $arg" ;;
    esac
done

for want in "${sections[@]}"; do
    while IFS=$'\t' read -r name url path clone; do
        [ -n "$name" ] || continue
        dir="$(resolve_repo "$path")"

        if [ "$name" = laboratory ] || [ "$dir" = "$ROOT" ]; then
            continue    # you are standing in it
        fi
        if [ "$clone" = false ] && [ "$force_all" = 0 ]; then
            note "skip   $name (clone = false; use --all)"
            continue
        fi
        if [ -d "$dir/.git" ]; then
            note "have   $name"
            continue
        fi
        if [ -e "$dir" ]; then
            warn "$path exists and is not a git checkout; leaving it alone"
            continue
        fi
        if [ "$dry" = 1 ]; then
            note "would  git clone $url $dir"
            continue
        fi

        note "clone  $name"
        # A missing credential must fail rather than hang on a password prompt.
        if ! GIT_TERMINAL_PROMPT=0 git clone --quiet "$url" "$dir"; then
            warn "clone failed: $name ($url)"
        fi
    done < <(repos_list "$want")
done

note ''
"$ROOT/scripts/status.sh"
