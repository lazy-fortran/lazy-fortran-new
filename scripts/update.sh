#!/usr/bin/env bash
# Fast-forward every clean checkout in repos.toml. Dirty ones are reported and
# left alone.
#
# Deliberately fast-forward only. A script that can merge or rebase someone's
# work is a script that can lose it, and the convenience is not worth it.

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
need git

for want in repos oracle; do
    while IFS=$'\t' read -r name _ path _; do
        [ -n "$name" ] || continue
        dir="$(resolve_repo "$path")"
        [ -d "$dir/.git" ] || continue

        if [ -n "$(git -C "$dir" status --porcelain)" ]; then
            note "dirty  $name (skipped)"
            continue
        fi
        if ! GIT_TERMINAL_PROMPT=0 git -C "$dir" fetch --quiet --all --prune; then
            warn "fetch failed: $name"
            continue
        fi
        before=$(git -C "$dir" rev-parse --short HEAD)
        if git -C "$dir" merge --ff-only --quiet '@{upstream}' 2>/dev/null; then
            after=$(git -C "$dir" rev-parse --short HEAD)
            if [ "$before" = "$after" ]; then
                note "same   $name $after"
            else
                note "update $name $before -> $after"
            fi
        else
            note "diverged $name (no fast-forward; left alone)"
        fi
    done < <(repos_list "$want")
done
