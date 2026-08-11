#!/usr/bin/env bash
# Report where every repository in repos.toml stands.
#
# This is the only place cross-repository state is reported. It is generated
# rather than written down, because a table of commit hashes typed into a
# document is stale the day after it is typed.

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section() {
    local want="$1" title="$2" any=0
    printf '\n%s\n' "$title"
    while IFS=$'\t' read -r name url path clone; do
        [ -n "$name" ] || continue
        any=1
        repo_state "$name" "$(resolve_repo "$path")"
    done < <(repos_list "$want")
    [ "$any" = 1 ] || printf '  (none)\n'
}

printf 'workspace: %s\n' "$WORK"
section repos  'production'
section oracle 'oracles'
printf '\n'
