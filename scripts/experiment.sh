#!/usr/bin/env bash
# Allocate and inspect experiments.
#
# Usage:
#   experiment.sh new "<question>"   allocate the next E-number from the template
#   experiment.sh list               experiments with status and run counts
#   experiment.sh runs E0003         run IDs belonging to one experiment

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

EXP="$ROOT/research/experiments"
RUNS="$ROOT/research/runs"

next_id() {
    local last
    last=$(find "$EXP" -maxdepth 1 -name 'E[0-9][0-9][0-9][0-9]-*' -printf '%f\n' 2>/dev/null \
           | sed 's/^E\([0-9]*\)-.*/\1/' | sort -n | tail -1)
    printf 'E%04d\n' $(( 10#${last:-0} + 1 ))
}

slugify() {
    printf '%s' "$1" | tr '[:upper:]' '[:lower:]' \
        | sed 's/[^a-z0-9]\+/-/g; s/^-//; s/-$//' | cut -c1-40
}

cmd_new() {
    local question="$1"
    [ -n "$question" ] || die 'usage: experiment.sh new "<question>"'
    local id slug dir
    id=$(next_id)
    slug=$(slugify "$question")
    dir="$EXP/$id-$slug"
    [ -e "$dir" ] && die "already exists: $dir"

    mkdir -p "$dir"
    sed -e "s|@ID@|$id|" \
        -e "s|@QUESTION@|$question|" \
        -e "s|@DATE@|$(date -u +%Y-%m-%d)|" \
        "$EXP/TEMPLATE.yaml" > "$dir/manifest.yaml"

    note "created $dir/manifest.yaml"
    note ''
    note 'Before running anything:'
    note '  - state the question so it can come out either way'
    note '  - pin every repository commit the result depends on'
    note '  - name the metrics now, not after seeing the data'
}

cmd_list() {
    printf '%-8s %-10s %-6s %s\n' ID STATUS RUNS QUESTION
    local d id status runs question
    for d in "$EXP"/E[0-9][0-9][0-9][0-9]-*/; do
        [ -d "$d" ] || continue
        id=$(basename "$d" | cut -d- -f1)
        status=$(awk -F': *' '/^status:/{print $2; exit}' "$d/manifest.yaml" 2>/dev/null)
        question=$(awk '/^question:/{getline; sub(/^[ \t]*/,""); print; exit}' \
                   "$d/manifest.yaml" 2>/dev/null)
        runs=$(grep -ho "\"experiment\":\"$id\"" "$RUNS"/*.jsonl 2>/dev/null | wc -l)
        printf '%-8s %-10s %-6s %s\n' "$id" "${status:-?}" "$runs" "${question:-?}"
    done
}

cmd_runs() {
    local id="$1"
    [ -n "$id" ] || die 'usage: experiment.sh runs E0003'
    grep -ho "\"run\":\"[^\"]*\"" \
        <(grep -h "\"experiment\":\"$id\"" "$RUNS"/*.jsonl 2>/dev/null) \
        | sed 's/.*:"//; s/"//' | sort
}

case "${1:-}" in
    new)  shift; cmd_new "${1:-}" ;;
    list) cmd_list ;;
    runs) shift; cmd_runs "${1:-}" ;;
    *)    sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//' ;;
esac
