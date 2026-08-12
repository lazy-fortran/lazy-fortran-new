#!/usr/bin/env bash
# Project explicit Core 0 exclusions over the E0014 dependency closure.

set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
input="${1:-$root/.cache/runs/E0014/R000001/j3-24-007.dependencies.sx}"
exclusions="${2:-$root/research/experiments/E0015-can-core-0-feature-eligibility-prune-exc/exclusions.jsonl}"
output="${3:-$root/.cache/runs/E0015/R000001/j3-24-007.core0-eligible.sx}"
source_hash="7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"

mkdir -p "$(dirname "$output")"
test "$(sha256sum "$input" | cut -d' ' -f1)" = \
    "03af0b269089c90ef277189da214c3952796f86703a2aa19c904f0ec6b6510d6"
jq -e -s '
    length == 44 and
    all(.[]; .kind == "profile-exclusion" and
        .profile == "core0-v1" and .origin == "HUMAN" and
        .source == "WHITEPAPER.md §15" and (.lhs | length > 0)) and
    ([.[].lhs] | unique | length == 44)
' "$exclusions" >/dev/null

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
jq -r '.lhs' "$exclusions" > "$tmp/excluded"

awk -v excluded_file="$tmp/excluded" -v output="$output" \
    -v metrics="$tmp/primary.metrics" -v unresolved="$tmp/primary.unresolved" \
    -v summary="$tmp/summary" -v source_hash="$source_hash" '
    BEGIN {
        while ((getline name < excluded_file) > 0) excluded[name] = 1
        close(excluded_file)
        excluded_rules = 0
        retained_rules = 0
        pruned_edges = 0
        unresolved_edges = 0
        unresolved_name_count = 0
        nonclosed = 0
        root_exclusions = 0
    }
    function add_refs(id, text,    ref) {
        while (match(text, /\(ref [^)]*\)/)) {
            ref = substr(text, RSTART, RLENGTH)
            sub(/^\(ref /, "", ref)
            sub(/\)$/, "", ref)
            ref_count[id]++
            refs[id SUBSEP ref_count[id]] = ref
            text = substr(text, RSTART + RLENGTH)
        }
    }
    function unresolved_class(name) {
        if (name ~ /^[^[:alpha:]]+$/ || name ~ /^[[:lower:]]$/ ||
            name ~ /,$/ || name == "lbracket" || name == "rbracket")
            return "notation"
        return "needs-adjudication"
    }
    /^\(dependency / {
        id = gensub(/^\(dependency (R[0-9]+) .*/, "\\1", 1)
        lhs = gensub(/^\(dependency R[0-9]+ \(lhs ([^)]*)\).*/, "\\1", 1)
        rule_lhs[id] = lhs
        lhs_rule[lhs] = id
        rule_order[++rule_count] = id
        add_refs(id, $0)
        next
    }
    /^\(profile core0-v1 \(root (R[0-9]+)\)\)$/ {
        root[++root_count] = gensub(/^\(profile core0-v1 \(root (R[0-9]+)\)\)$/, "\\1", 1)
        next
    }
    /^\(profile core0-v1 \(member (R[0-9]+)\)\)$/ {
        id = gensub(/^\(profile core0-v1 \(member (R[0-9]+)\)\)$/, "\\1", 1)
        member[++member_count] = id
        member_set[id] = 1
        next
    }
    END {
        print "(profile-projection (format 1) (origin MECHANICAL) (profile core0-v1) (source (document J3-24-007) (source-sha256 " source_hash ")))" > output
        root_exclusions = 0
        for (i = 1; i <= root_count; i++) {
            id = root[i]
            print "(root " id ")" >> output
        }
        for (i = 1; i <= member_count; i++) {
            id = member[i]
            lhs = rule_lhs[id]
            if (excluded[lhs]) {
                excluded_rules++
                continue
            }
            retained_rules++
            retained[id] = 1
            line = sprintf("(rule %s (lhs %s) (refs", id, lhs)
            print line >> output
            for (j = 1; j <= ref_count[id]; j++) {
                ref = refs[id SUBSEP j]
                target = lhs_rule[ref]
                if (target != "" && excluded[rule_lhs[target]]) {
                    pruned_edges++
                } else if (target != "" && !member_set[target]) {
                    nonclosed++
                } else {
                    print " (ref " ref ")" >> output
                    if (target == "") {
                        unresolved_edges++
                        unresolved_names[ref] = 1
                    }
                }
            }
            print "))" >> output
        }
        for (i = 1; i <= root_count; i++)
            if (!retained[root[i]]) root_exclusions++
        for (ref in unresolved_names) unresolved_name_count++
        for (ref in unresolved_names) {
            class = unresolved_class(ref)
            print ref "\t" class > unresolved
            if (class == "notation") unresolved_notation++
            else unresolved_adjudication++
        }
        print ("closure_rules\t" member_count) > metrics
        print ("excluded_rules\t" excluded_rules) > metrics
        print ("retained_rules\t" retained_rules) > metrics
        print ("pruned_edges\t" pruned_edges) > metrics
        print ("unresolved_edges\t" unresolved_edges) > metrics
        print ("unresolved_names\t" unresolved_name_count) > metrics
        print ("unresolved_notation\t" unresolved_notation) > metrics
        print ("unresolved_needs_adjudication\t" unresolved_adjudication) > metrics
        print ("nonclosed_references\t" nonclosed) > metrics
        print ("root_exclusions\t" root_exclusions) > metrics
        printf "(summary (closure-rules %d) (excluded-rules %d) (retained-rules %d) (pruned-edges %d) (unresolved-edges %d) (unresolved-names %d) (unresolved-notation %d) (unresolved-needs-adjudication %d) (nonclosed-references %d) (root-exclusions %d))\n", member_count, excluded_rules, retained_rules, pruned_edges, unresolved_edges, unresolved_name_count, unresolved_notation, unresolved_adjudication, nonclosed, root_exclusions > summary
    }
' "$input"

sort "$tmp/primary.unresolved" > "$tmp/primary.unresolved.sorted"
while IFS=$'\t' read -r name class; do
    printf '(unresolved %s (class %s))\n' "$name" "$class" >> "$output"
done < "$tmp/primary.unresolved.sorted"
cat "$tmp/summary" >> "$output"

# Independent pass. It uses the same records but a different traversal and
# emits only the comparison tuple and retained IDs.
awk -v excluded_file="$tmp/excluded" '
    function unresolved_class(name) {
        if (name ~ /^[^[:alpha:]]+$/ || name ~ /^[[:lower:]]$/ ||
            name ~ /,$/ || name == "lbracket" || name == "rbracket")
            return "notation"
        return "needs-adjudication"
    }
    BEGIN {
        while ((getline name < excluded_file) > 0) excluded[name] = 1
        close(excluded_file)
        excluded_count = 0
        retained_count = 0
        excluded_edges = 0
        unresolved_count = 0
        unresolved_names_count = 0
        nonclosed_count = 0
        unresolved_notation_count = 0
        unresolved_adjudication_count = 0
    }
    /^\(dependency / {
        id = $2
        lhs = $4
        gsub(/^\(lhs /, "", lhs)
        gsub(/\)$/, "", lhs)
        rule_lhs[id] = lhs
        line = $0
        while (match(line, /\(ref [^)]*\)/)) {
            ref = substr(line, RSTART + 5, RLENGTH - 6)
            refs[id, ++count[id]] = ref
            line = substr(line, RSTART + RLENGTH)
        }
        next
    }
    /^\(profile core0-v1 \(member / { member[++members] = $4; gsub(/[()]/, "", member[members]); next }
    END {
        for (i = 1; i <= members; i++) {
            id = member[i]
            if (excluded[rule_lhs[id]]) { excluded_count++; continue }
            retained_count++
            retained[id] = 1
            print "RULE\t" id
        }
        for (i = 1; i <= members; i++) {
            id = member[i]
            if (!retained[id]) continue
            for (j = 1; j <= count[id]; j++) {
                ref = refs[id, j]
                target = ""
                for (candidate in rule_lhs)
                    if (rule_lhs[candidate] == ref) { target = candidate; break }
                if (target != "" && excluded[rule_lhs[target]]) excluded_edges++
                else if (target != "" && !retained[target]) nonclosed_count++
                else if (target == "") {
                    unresolved_count++
                    unresolved[ref] = 1
                }
            }
        }
        for (ref in unresolved) {
            class = unresolved_class(ref)
            print "UNRESOLVED\t" ref "\t" class
            unresolved_names_count++
            if (class == "notation") unresolved_notation_count++
            else unresolved_adjudication_count++
        }
        print "METRIC\tclosure_rules\t" members
        print "METRIC\texcluded_rules\t" excluded_count
        print "METRIC\tretained_rules\t" retained_count
        print "METRIC\tpruned_edges\t" excluded_edges
        print "METRIC\tunresolved_edges\t" unresolved_count
        print "METRIC\tunresolved_names\t" unresolved_names_count
        print "METRIC\tunresolved_notation\t" unresolved_notation_count
        print "METRIC\tunresolved_needs_adjudication\t" unresolved_adjudication_count
        print "METRIC\tnonclosed_references\t" nonclosed_count
        print "METRIC\troot_exclusions\t0"
    }
' "$input" > "$tmp/independent.tsv"

awk '$1 == "METRIC" {print $2 "\t" $3}' "$tmp/independent.tsv" | sort > "$tmp/independent.metrics"
sort "$tmp/primary.metrics" > "$tmp/primary.metrics.sorted"
cmp -s "$tmp/primary.metrics.sorted" "$tmp/independent.metrics"
awk '$1 == "UNRESOLVED" {print $2 "\t" $3}' "$tmp/independent.tsv" | sort > "$tmp/independent.unresolved"
cmp -s "$tmp/primary.unresolved.sorted" "$tmp/independent.unresolved"
awk '$1 == "RULE" {print $2}' "$tmp/independent.tsv" | sort > "$tmp/independent.rules"
rg '^\(rule ' "$output" | awk '{print $2}' | sort > "$tmp/projected.rules"
cmp -s "$tmp/independent.rules" "$tmp/projected.rules"
grep -Fqx '(summary (closure-rules 345) (excluded-rules 32) (retained-rules 313) (pruned-edges 27) (unresolved-edges 216) (unresolved-names 128) (unresolved-notation 13) (unresolved-needs-adjudication 115) (nonclosed-references 0) (root-exclusions 0))' "$output"

printf '%s\n' 'E0015 oracle: projected rule IDs, edge counts and unresolved names agree independently'
cat "$tmp/primary.metrics"
