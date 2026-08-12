#!/usr/bin/env bash
# Compute and independently check the Core 0 syntax dependency closure.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
standard="${STANDARD_NEW:-$root/../standard-new}"
input="${1:-$root/.cache/runs/E0013/R000002/j3-24-007.standardir.sx}"
roots="${2:-$root/research/experiments/E0014-core0-profile/roots.jsonl}"
output="${3:-$root/.cache/runs/E0014/R000001/j3-24-007.dependencies.sx}"
roundtrip="${4:-$root/.cache/runs/E0014/R000001/j3-24-007.dependencies.roundtrip.sx}"
source_hash="${5:-7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2}"

mkdir -p "$(dirname "$output")"
test "$(sha256sum "$input" | cut -d' ' -f1)" = \
    "c2e9514487c5d62e8a6124c0c70e6ab06778f5418443961495ce3afe6a6aafb7"
jq -e -s 'length == 17 and all(.[]; .kind == "profile-root" and .profile == "core0-v1" and .origin == "HUMAN")' \
    "$roots" >/dev/null
jq -e -s 'all(.[]; (.rule | test("^R[0-9]+$")))' "$roots" >/dev/null

(cd "$standard" && fo exec sxdependencies "$input" "$roots" core0-v1 \
    "$source_hash" "$output")
(cd "$standard" && fo exec sxroundtrip "$output" "$roundtrip")
cmp -s "$output" "$roundtrip"

grep -Fqx \
    "(dependencies (format 1) (origin MECHANICAL) (source (document J3-24-007) (source-sha256 $source_hash)))" \
    "$output"
test "$(wc -l < "$input")" = 523
test "$(rg -c '^\(syntax ' "$input")" = 522
test "$(rg -c '^\(dependency ' "$output")" = 502
test "$(rg -c '^\(profile core0-v1 \(root ' "$output")" = 17
test "$(rg -c '^\(profile core0-v1 \(member ' "$output")" = 345
test "$(wc -l < "$output")" = 866
test "$(rg -c 'occurrences [2-9][0-9]*\)\)$' "$output")" = 20
grep -Fqx \
    '(summary (source-records 522) (unique-rules 502) (duplicate-rule-ids 20) (closure-rules 345) (unresolved-references 249))' \
    "$output"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
awk '
    match($0, /^\(syntax (R[0-9]+) \(lhs ([^)]*)\)/, m) {
        print "RULE\t" m[1] "\t" m[2]
    }
    match($0, /^\(syntax (R[0-9]+) /, m) {
        line = $0
        while (match(line, /\(ref [^)]*\)/)) {
            ref = substr(line, RSTART, RLENGTH)
            sub(/^\(ref /, "", ref)
            sub(/\)$/, "", ref)
            print "EDGE\t" m[1] "\t" ref
            line = substr(line, RSTART + RLENGTH)
        }
    }
' "$input" > "$tmp/graph.tsv"

root_list="$(jq -r '.rule' "$roots" | paste -sd, -)"
ROOTS="$root_list" awk -F '\t' '
    $1 == "RULE" {
        id = $2
        name = $3
        if (!(id in rule_seen)) {
            rule_seen[id] = 1
            order[++rule_count] = id
        }
        key = name SUBSEP id
        if (!(key in lhs_seen)) {
            lhs_seen[key] = 1
            lhs_count[name]++
            lhs_id[name, lhs_count[name]] = id
        }
        next
    }
    $1 == "EDGE" {
        key = $2 SUBSEP $3
        if (!(key in edge_seen)) {
            edge_seen[key] = 1
            edge_count[$2]++
            edge_name[$2, edge_count[$2]] = $3
        }
        next
    }
    END {
        root_count = split(ENVIRON["ROOTS"], root, ",")
        for (i = 1; i <= root_count; i++) {
            if (!(root[i] in rule_seen)) exit 2
            selected[root[i]] = 1
            queue[++tail] = root[i]
        }
        unresolved = 0
        for (head = 1; head <= tail; head++) {
            id = queue[head]
            if (processed[id]) continue
            processed[id] = 1
            for (i = 1; i <= edge_count[id]; i++) {
                name = edge_name[id, i]
                if (!(name in lhs_count)) {
                    unresolved++
                } else if (lhs_count[name] != 1) {
                    exit 3
                } else {
                    target = lhs_id[name, 1]
                    if (!selected[target]) {
                        selected[target] = 1
                        queue[++tail] = target
                    }
                }
            }
        }
        for (i = 1; i <= rule_count; i++)
            if (selected[order[i]]) print order[i]
        print "COUNT\t" tail > "/dev/stderr"
        print "UNRESOLVED\t" unresolved > "/dev/stderr"
    }
' "$tmp/graph.tsv" > "$tmp/independent-members" 2> "$tmp/independent-summary"

rg -o '^\(profile core0-v1 \(member [^)]+' "$output" \
    | sed 's/^.*(member //' | sort > "$tmp/tool-members"
sort "$tmp/independent-members" > "$tmp/independent-members.sorted"
cmp -s "$tmp/tool-members" "$tmp/independent-members.sorted"
grep -Fqx $'COUNT\t345' "$tmp/independent-summary"
grep -Fqx $'UNRESOLVED\t249' "$tmp/independent-summary"

printf '%s\n' 'E0014 oracle: 502 unique rules, 345 closure members, 20 repeated IDs, and 249 unresolved references agree independently'
