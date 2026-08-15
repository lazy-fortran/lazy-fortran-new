#!/usr/bin/env bash
set -euo pipefail

run_dir=${1-}
if [[ -z "$run_dir" ]]; then
    printf 'usage: %s RUN-DIRECTORY\n' "$0" >&2
    exit 2
fi

input="$run_dir/input/standardir.sx"
if [[ ! -f "$input" ]]; then
    printf 'missing StandardIR evidence: %s\n' "$input" >&2
    exit 2
fi

expected=$(mktemp /tmp/e0147-source-projection.XXXXXX)
skipped=$(mktemp /tmp/e0147-source-skipped.XXXXXX)
cleanup() {
    rm -f -- "$expected" "$skipped"
}
trap cleanup EXIT

awk '
function alternative_count(line, p, alt, i, c, depth, count) {
    p = index(line, "(rhs (alt ")
    if (!p) return 1
    alt = p + 5
    depth = 1
    count = 0
    for (i = alt + 4; i <= length(line); i++) {
        c = substr(line, i, 1)
        if (c == "(") {
            if (depth == 1) count++
            depth++
        } else if (c == ")") {
            depth--
            if (depth == 0) break
        }
    }
    return count
}
/^[\(]syntax / {
    match($0, /^[\(]syntax [^ ]+/)
    rule = substr($0, RSTART + 8, RLENGTH - 8)
    match($0, /byte-start [0-9]+/)
    start = substr($0, RSTART + 11, RLENGTH - 11)
    match($0, /byte-length [0-9]+/)
    length_value = substr($0, RSTART + 12, RLENGTH - 12)
    count = alternative_count($0)
    for (i = 1; i <= count; i++)
        print rule ":" i "@" start "+" length_value "\t" rule "\t" i
}
' "$input" >"$expected"

for log in "$run_dir"/generate-*.log; do
    [[ -f "$log" ]] || continue
    grep -oE 'byte-start=[0-9]+ byte-length=[0-9]+' "$log" || true
done | sort -u >"$skipped"

report="$run_dir/source-projection.tsv"
{
    printf 'format\tstatus\texpected\tcovered\tskipped\tmissing\theader_gaps\n'
} >"$report"

overall=0
for pair in \
    'ebnf:grammar.ebnf' \
    'antlr4:Fortran2023.g4' \
    'bison:fortran2023.y' \
    'tree-sitter:grammar.js'; do
    format=${pair%%:*}
    file=${pair#*:}
    output="$run_dir/$file"
    expected_count=$(wc -l <"$expected")
    covered=0
    skipped_count=0
    missing=0
    while IFS=$'\t' read -r token lhs occurrence; do
        if grep -Fq "$token" "$output"; then
            covered=$((covered + 1))
        else
            span=${token##*@}
            span_start=${span%%+*}
            span_length=${span#*+}
            if grep -Fq "byte-start=$span_start byte-length=$span_length" "$skipped"; then
                skipped_count=$((skipped_count + 1))
            else
                missing=$((missing + 1))
            fi
        fi
    done <"$expected"
    header_gaps=$(grep -E '^\(\* rule=|^// rule=|^/\* rule=' "$output" | \
        grep -vc 'source-lineage=[^[:space:]]' || true)
    if [[ $missing -ne 0 || $header_gaps -ne 0 || $((covered + skipped_count)) -ne $expected_count ]]; then
        status=FAIL
        overall=1
    else
        status=PASS
    fi
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$format" "$status" \
        "$expected_count" "$covered" "$skipped_count" "$missing" "$header_gaps" >>"$report"
done

cat "$report"
exit "$overall"
