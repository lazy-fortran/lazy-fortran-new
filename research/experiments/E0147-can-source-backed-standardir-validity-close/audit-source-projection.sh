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
omitted=$(mktemp /tmp/e0147-source-omitted.XXXXXX)
cleanup() {
    rm -f -- "$expected" "$skipped" "$omitted"
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
    match($0, /\(lhs [^)]*/)
    lhs = substr($0, RSTART + 5, RLENGTH - 5)
    match($0, /byte-start [0-9]+/)
    start = substr($0, RSTART + 11, RLENGTH - 11)
    match($0, /byte-length [0-9]+/)
    length_value = substr($0, RSTART + 12, RLENGTH - 12)
    count = alternative_count($0)
    for (i = 1; i <= count; i++)
        print rule ":" i "@" start "+" length_value "\t" rule "\t" lhs "\t" i
}
' "$input" >"$expected"

for log in "$run_dir"/generate-*.log; do
    [[ -f "$log" ]] || continue
    grep -oE 'byte-start=[0-9]+ byte-length=[0-9]+' "$log" || true
done | sort -u >"$skipped"

grep -hE '^root-disposition omitted-declared-root ' "$run_dir"/generate-*.log \
    | sed -E 's/^root-disposition omitted-declared-root ([^ ]+).*/\1/' \
    | sort -u >"$omitted" || true

report="$run_dir/source-projection.tsv"
printf 'format\tstatus\texpected\tcovered\tskipped\tmissing\theader_gaps\tstructure\n' >"$report"

overall=0
for pair in \
    'ebnf:grammar.ebnf' \
    'antlr4:Fortran2023.g4' \
    'bison:fortran2023.y' \
    'tree-sitter:grammar.js'; do
    format=${pair%%:*}
    file=${pair#*:}
    output="$run_dir/$file"
    if [[ ! -f "$output" ]]; then
        printf '%s\tFAIL\t0\t0\t0\t0\t1\tmissing-output\n' "$format" >>"$report"
        overall=1
        continue
    fi

    result=$(python3 - "$format" "$output" "$expected" "$skipped" "$omitted" <<'PY'
import re
import sys

format_name, output_name, expected_name, skipped_name, omitted_name = sys.argv[1:]
lines = open(output_name, encoding="utf-8").read().splitlines()
expected = []
for line in open(expected_name, encoding="utf-8"):
    token, rule, lhs, occurrence = line.rstrip("\n").split("\t")
    expected.append((token, rule, lhs, occurrence))
skipped = set()
for line in open(skipped_name, encoding="utf-8"):
    match = re.fullmatch(r"byte-start=(\d+) byte-length=(\d+)", line.strip())
    if match:
        skipped.add(f"{match.group(1)}+{match.group(2)}")
omitted = {line.strip() for line in open(omitted_name, encoding="utf-8") if line.strip()}

def has_body(index):
    line = lines[index]
    if format_name == "ebnf" and "*)" in line:
        body = line.split("*)", 1)[1].strip()
        if body.rstrip(";").strip():
            return True
    if format_name == "bison" and "*/" in line:
        body = line.split("*/", 1)[1].strip()
        if body:
            return True
    for next_index in range(index + 1, len(lines)):
        body = lines[next_index].strip()
        if not body:
            continue
        if body.startswith("//") or body.startswith("/*") or body.startswith("(*"):
            continue
        return body not in {";", ",", ")"}
    return False

headers = []
for index, line in enumerate(lines):
    if "rule=" in line and "source-lineage=" in line:
        headers.append((index, line, has_body(index)))

covered = 0
skipped_count = 0
missing = 0
for token, rule, lhs, occurrence in expected:
    if lhs in omitted:
        skipped_count += 1
        continue
    if any(token in line and body for _, line, body in headers):
        covered += 1
    else:
        span = token.rsplit("@", 1)[1]
        if span in skipped:
            skipped_count += 1
        else:
            missing += 1

allowed_annotation_gaps = sum(
    not body
    and re.search(r"reason=omitted-before-target-lowering", line)
    and (target := re.search(r"target-lhs=([^ ]+)", line))
    and target.group(1) in omitted
    for _, line, body in headers
)
header_gaps = sum(not body for _, _, body in headers) - allowed_annotation_gaps
if header_gaps:
    structure = "annotation-only"
elif allowed_annotation_gaps:
    structure = "body-bound-with-omitted-witnesses"
else:
    structure = "body-bound"
status = missing == 0 and covered + skipped_count == len(expected) and header_gaps == 0
print(f"{len(expected)}\t{covered}\t{skipped_count}\t{missing}\t{header_gaps}\t{structure}")
sys.exit(0 if status else 1)
PY
    ) || {
        status=FAIL
        overall=1
    }
    if [[ -z "${status-}" ]]; then status=PASS; fi
    printf '%s\t%s\t%s\n' "$format" "$status" "$result" >>"$report"
    unset status
done

# A source-projection witness must reject a real loss of a generated alternative,
# not merely report that its comment disappeared.  Remove one complete EBNF
# alternative and require the same audit to fail.
negative_control=SKIPPED
if [[ "${E0147_SKIP_NEGATIVE:-0}" != 1 ]]; then
    negative_dir=$(mktemp -d /tmp/e0147-source-projection-negative.XXXXXX)
    cleanup_negative() { rm -rf -- "$negative_dir"; }
    trap 'cleanup_negative; cleanup' EXIT
    mkdir -p "$negative_dir/input"
    cp "$input" "$negative_dir/input/standardir.sx"
    cp "$run_dir/grammar.ebnf" "$negative_dir/grammar.ebnf"
    cp "$run_dir/Fortran2023.g4" "$negative_dir/Fortran2023.g4"
    cp "$run_dir/fortran2023.y" "$negative_dir/fortran2023.y"
    cp "$run_dir/grammar.js" "$negative_dir/grammar.js"
    for log in "$run_dir"/generate-*.log; do
        [[ -f "$log" ]] && cp "$log" "$negative_dir/"
    done
    python3 - "$negative_dir/grammar.ebnf" <<'PY'
import re
import sys

path = sys.argv[1]
lines = open(path, encoding="utf-8").read().splitlines(True)
token = None
for line in lines:
    if "rule=" in line and "source-lineage=" in line:
        lineage = re.search(r"source-lineage=(\S+)", line)
        if lineage:
            token = lineage.group(1).split(",", 1)[0]
            break
if token is None:
    raise SystemExit("no body-bound provenance alternative available for negative control")
reduced = [line for line in lines if token not in line]
if len(reduced) == len(lines):
    raise SystemExit("negative control did not remove an alternative")
open(path, "w", encoding="utf-8").writelines(reduced)
PY
    if E0147_SKIP_NEGATIVE=1 bash "$0" "$negative_dir" >/dev/null 2>&1; then
        negative_control=FAILED
        overall=1
    else
        negative_control=PASS
    fi
    printf 'negative-control\t%s\tremoved-body-alternative\n' "$negative_control" >>"$report"
fi

cat "$report"
exit "$overall"
