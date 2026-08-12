#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/../.." && pwd)
run_file_glob=("$repo_root"/research/runs/*.jsonl)
paper_dir="$script_dir"

die() {
    printf 'standard-to-grammar: %s\n' "$1" >&2
    exit 1
}

run_json() {
    local run_id=$1
    jq -s -c --arg run "$run_id" '
        [ .[] | select(.run == $run) ] as $matches
        | if ($matches | length) == 1 then $matches[0]
          else error("run is missing or duplicated: " + $run)
          end
    ' "${run_file_glob[@]}"
}

metric() {
    local run_id=$1
    local expression=$2
    run_json "$run_id" | jq -r "$expression"
}

assert_run() {
    local run_id=$1
    local expression=$2
    if ! run_json "$run_id" | jq -e "$expression" >/dev/null; then
        die "run assertion failed for $run_id: $expression"
    fi
}

while IFS= read -r run_id; do
    [[ -z "$run_id" || "$run_id" == \#* ]] && continue
    [[ "$run_id" =~ ^R[0-9]{6}$ ]] || die "invalid run ID: $run_id"
    run_json "$run_id" >/dev/null
done < "$paper_dir/runs.txt"

source_sha=$(awk -F'"' '/^sha256[[:space:]]*=/{print $2; exit}' \
    "$repo_root/artifacts/standards/j3-24-007.toml")
run_artifact=$(metric R000019 '.artifact')
run_source_sha=$(awk -F'"' '/^source_sha256[[:space:]]*=/{print $2; exit}' \
    "$repo_root/$run_artifact")
[[ "$source_sha" == "$run_source_sha" ]] || \
    die "selected run artifact source hash differs from the pinned source artifact"
[[ "$source_sha" == "$(awk -F'"' '/^source_sha256[[:space:]]*=/{print $2; exit}' \
    "$paper_dir/pins.toml")" ]] || die "paper source hash differs from source artifact"

assert_run R000017 '.status == "accepted" and .verification.zero_model_calls == true and .verification.scope_sets_equal == true and .verification.production_starts == 522'
assert_run R000019 '.status == "accepted" and .verification.zero_model_calls == true and .verification.syntax_objects == 522 and .verification.source_hash_on_every_record == true'
assert_run R000020 '.status == "accepted" and .verification.byte_identical == true'
for run_id in R000025 R000026 R000027 R000028; do
    assert_run "$run_id" '.status == "accepted" and .verification.zero_model_calls == true and .verification.syntax_records == 522 and .verification.production_order_difference == 0 or .verification.lhs_mapping_difference == 0'
done
assert_run R000029 '.status == "accepted" and .verification.independent_difference == 0'
assert_run R000030 '.status == "verification_failure" and .verification.antlr_unresolved_rule_names == 181 and .verification.bison_unresolved_symbol_names == 181'
assert_run R000031 '.status == "accepted" and .verification.unresolved_unique_names == 181 and .verification.unresolved_reference_occurrences == 472 and .verification.unresolved_referring_rules == 346'
assert_run R000050 '.status == "accepted" and .verification.cases_declared == 10 and .verification.all_three_agree_cases == 10 and .verification.disagreement_cases == 0'
assert_run R000052 '.status == "accepted" and .experiment == "E0043" and .verification.zero_model_calls == true and .verification.resolution_records == 182 and .verification.source_hash_matches == 182 and .verification.independent_difference == 0 and .verification.negative_control == "observed_failure"'
assert_run R000053 '.status == "accepted" and .experiment == "E0044" and .verification.zero_model_calls == true and .verification.alias_records == 49 and .verification.explicit_definition_conflicts == 0 and .verification.independent_difference == 0 and .verification.negative_control == "observed_failure"'
assert_run R000054 '.status == "accepted" and .experiment == "E0045" and .verification.zero_model_calls == true and .verification.lexical_class_records == 25 and .verification.unicode_exclusions_retained == 2 and .verification.independent_difference == 0 and .verification.negative_control == "observed_failure"'
assert_run R000055 '.status == "accepted" and .experiment == "E0046" and .verification.zero_model_calls == true and .verification.alias_records == 49 and .verification.lexical_class_records == 25 and .verification.unresolved_records == 107 and .verification.independent_difference == 0 and .verification.negative_control == "observed_failure"'
assert_run R000056 '.status == "accepted" and .experiment == "E0047" and .verification.zero_model_calls == true and .verification.errata_origin == "LLM" and .verification.errata_decision == "D0025" and .verification.source_repair_records == 7 and .verification.input_syntax_records == 522 and .verification.independent_difference == 0 and .verification.negative_control == "observed_failure"'
assert_run R000057 '.status == "accepted" and .experiment == "E0048" and .verification.zero_model_calls == true and .verification.original_audit_unique_names == 181 and .verification.normalized_audit_unique_names == 178 and .verification.expansion_records == 100 and .verification.r401_records == 80 and .verification.r403_records == 20 and .verification.explicit_definition_conflicts == 0 and .verification.independent_difference == 0 and .verification.negative_control == "observed_failure" and .verification.representation_selection == "deferred_D0024"'

document_pages=$(metric R000017 '.verification.pages')
core_pages=$(metric R000017 '.verification.core_pages')
production_starts=$(metric R000017 '.verification.production_starts')
scope_difference=$(metric R000017 '.verification.scope_sets_equal | if . then 0 else 1 end')
production_lines=$(metric R000017 '.verification.production_lines')
continuations=$(metric R000017 '.verification.production_continuations')
syntax_objects=$(metric R000019 '.verification.syntax_objects')
source_hash_records=$(metric R000019 '.verification.source_hash_on_every_record | if . then 522 else 0 end')
roundtrip=$(metric R000020 '.verification.byte_identical | if . then "byte-identical" else "different" end')
projection_count=4
unresolved_names=$(metric R000031 '.verification.unresolved_unique_names')
unresolved_occurrences=$(metric R000031 '.verification.unresolved_reference_occurrences')
unresolved_rules=$(metric R000031 '.verification.unresolved_referring_rules')
resolution_records=$(metric R000052 '.verification.resolution_records')
resolution_aliases=$(metric R000052 '.verification.alias_records')
resolution_lexical=$(metric R000052 '.verification.lexical_class_records')
resolution_metavariable=$(metric R000052 '.verification.metavariable_records')
resolution_unresolved=$(metric R000052 '.verification.unresolved_records')
resolution_source_hash_records=$(metric R000052 '.verification.source_hash_matches')
alias_projection_records=$(metric R000052 '.verification.alias_projection_records')
composite_syntax_witnesses=$(metric R000052 '.verification.composite_syntax_witnesses')
resolution_difference=$(metric R000052 '.verification.independent_difference')
resolution_negative_control=$(metric R000052 '.verification.negative_control')
r402_aliases=$(metric R000053 '.verification.alias_records')
r402_unresolved=$(metric R000053 '.verification.unresolved_records')
r402_source_hash_records=$(metric R000053 '.verification.source_hash_matches')
r402_conflicts=$(metric R000053 '.verification.explicit_definition_conflicts')
r402_projection_records=$(metric R000053 '.verification.alias_projection_records')
r402_syntax_witnesses=$(metric R000053 '.verification.composite_syntax_witnesses')
r402_difference=$(metric R000053 '.verification.independent_difference')
r402_negative_control=$(metric R000053 '.verification.negative_control')
lexical_class_records=$(metric R000054 '.verification.lexical_class_records')
lexical_projection_records=$(metric R000054 '.verification.lexical_projection_records')
unicode_exclusions=$(metric R000054 '.verification.unicode_exclusions_retained')
lexical_syntax_witnesses=$(metric R000054 '.verification.composite_syntax_witnesses')
lexical_difference=$(metric R000054 '.verification.independent_difference')
lexical_negative_control=$(metric R000054 '.verification.negative_control')
combined_aliases=$(metric R000055 '.verification.alias_records')
combined_lexical=$(metric R000055 '.verification.lexical_class_records')
combined_unresolved=$(metric R000055 '.verification.unresolved_records')
combined_witnesses=$(metric R000055 '.verification.composite_syntax_witnesses')
combined_difference=$(metric R000055 '.verification.independent_difference')
combined_negative_control=$(metric R000055 '.verification.negative_control')
errata_repairs=$(metric R000056 '.verification.source_repair_records')
errata_commas=$(metric R000056 '.verification.comma_repairs')
errata_colons=$(metric R000056 '.verification.colon_repairs')
errata_difference=$(metric R000056 '.verification.independent_difference')
errata_negative_control=$(metric R000056 '.verification.negative_control')
normalized_audit_names=$(metric R000057 '.verification.normalized_audit_unique_names')
expansion_records=$(metric R000057 '.verification.expansion_records')
r401_records=$(metric R000057 '.verification.r401_records')
r403_records=$(metric R000057 '.verification.r403_records')
expansion_conflicts=$(metric R000057 '.verification.explicit_definition_conflicts')
expansion_witnesses=$(metric R000057 '.verification.source_witness_matches')
expansion_difference=$(metric R000057 '.verification.independent_difference')
expansion_negative_control=$(metric R000057 '.verification.negative_control')
expansion_representation=$(metric R000057 '.verification.representation_selection' | sed 's/^deferred_D0024$/deferred to D0024/')

results="$paper_dir/results.md"
{
    cat <<EOF
# Generated results

Generated by \`papers/standard-to-grammar/analyse.sh\` from the run IDs in
\`papers/standard-to-grammar/runs.txt\`.

## Extraction and StandardIR

| Quantity | Value |
|---|---:|
| Indexed document pages | $document_pages |
| Selected syntax pages | $core_pages |
| Numbered production starts | $production_starts |
| Production lines | $production_lines |
| Continuation lines | $continuations |
| Full-document versus selected-scope difference | $scope_difference |
| StandardIR syntax objects | $syntax_objects |
| Records with source hash | $source_hash_records |
| StandardIR SX round-trip | $roundtrip |

## Grammar projections

The following rows are extracted from the accepted projection run records.

| Projection | Records | Provenance comments | Source-hash matches | Model calls |
|---|---:|---:|---:|---:|
EOF
    while IFS=: read -r run_id label; do
        printf '| %s | %s | %s | %s | %s |\n' \
            "$label" \
            "$(metric "$run_id" '.verification.syntax_records')" \
            "$(metric "$run_id" '.verification.provenance_comments')" \
            "$(metric "$run_id" '.verification.source_hash_matches')" \
            "$(metric "$run_id" '.verification.zero_model_calls | if . then 0 else "reported" end')"
    done <<'EOF'
R000025:EBNF
R000026:ANTLR4
R000027:Bison
R000028:tree-sitter
EOF
    cat <<EOF

## Comparison boundary

| Quantity | Value |
|---|---:|
| StandardIR unique rules in structural comparison | $(metric R000029 '.verification.standardir_unique_rules') |
| House grammar parser rules | $(metric R000029 '.verification.standard_parser_rules') |
| Kaby76 parser rules | $(metric R000029 '.verification.kaby76_parser_rules') |
| LFortran parser rules | $(metric R000029 '.verification.lfortran_parser_rules') |
| Flang rule IDs | $(metric R000029 '.verification.flang_rule_ids') |
| Unresolved names in target validation | $unresolved_names |
| Unresolved reference occurrences | $unresolved_occurrences |
| Referring rules | $unresolved_rules |
| Target-tool validation result | retained verification failure |

## D0019 resolution boundary

| Quantity | Value |
|---|---:|
| Typed resolution records | $resolution_records |
| Alias records | $resolution_aliases |
| Lexical-class records | $resolution_lexical |
| Metavariable records | $resolution_metavariable |
| Unresolved records retained | $resolution_unresolved |
| Records with source hash | $resolution_source_hash_records |
| Alias projection records | $alias_projection_records |
| Composite SX syntax witnesses | $composite_syntax_witnesses |
| Independent difference | $resolution_difference |
| Controlled negative mutation | $resolution_negative_control |

## D0019 R402 closure

| Quantity | Value |
|---|---:|
| R402 suffix-name aliases | $r402_aliases |
| Unresolved records retained | $r402_unresolved |
| Records with source hash | $r402_source_hash_records |
| Explicit-definition conflicts | $r402_conflicts |
| Alias projection records | $r402_projection_records |
| Composite SX syntax witnesses | $r402_syntax_witnesses |
| Independent difference | $r402_difference |
| Controlled negative mutation | $r402_negative_control |

## D0019 lexical witness slice

| Quantity | Value |
|---|---:|
| Lexical-class records | $lexical_class_records |
| Lexical token projection records | $lexical_projection_records |
| Unicode exclusions retained unresolved | $unicode_exclusions |
| Composite SX syntax witnesses | $lexical_syntax_witnesses |
| Independent difference | $lexical_difference |
| Controlled negative mutation | $lexical_negative_control |

## D0019 combined resolution slice

| Quantity | Value |
|---|---:|
| Alias records | $combined_aliases |
| Lexical-class records | $combined_lexical |
| Unresolved records retained | $combined_unresolved |
| Composite SX syntax witnesses | $combined_witnesses |
| Independent difference | $combined_difference |
| Controlled negative mutation | $combined_negative_control |

## D0025 fixed errata overlay

| Quantity | Value |
|---|---:|
| Errata repairs | $errata_repairs |
| Comma repairs | $errata_commas |
| Colon repairs | $errata_colons |
| Independent difference | $errata_difference |
| Controlled negative mutation | $errata_negative_control |

## D0025 normalization and R401/R403 inventory

| Quantity | Value |
|---|---:|
| Names after the eight-entry errata normalization | $normalized_audit_names |
| Expansion-family records | $expansion_records |
| R401 suffix-list records | $r401_records |
| R403 scalar-prefix records | $r403_records |
| Explicit-definition conflicts | $expansion_conflicts |
| Source witnesses | $expansion_witnesses |
| Independent difference | $expansion_difference |
| Representation selection | $expansion_representation |
| Controlled family mutation | $expansion_negative_control |

## External behavioral baseline

| Quantity | Value |
|---|---:|
| Fixed fixtures | $(metric R000050 '.verification.cases_declared') |
| Compiler invocations | $(metric R000050 '.verification.compiler_invocations') |
| Cases with agreement across LFortran, Flang, and gfortran | $(metric R000050 '.verification.all_three_agree_cases') |
| Cases with disagreement | $(metric R000050 '.verification.disagreement_cases') |

Every table in this file is regenerated by \`papers/standard-to-grammar/analyse.sh\`.
The underlying run records retain the independent oracles and the accepted
failure status.
EOF
} > "$results"

rendered=$(<"$paper_dir/manuscript.template.md")
rendered=${rendered//@PRODUCTION_STARTS@/$production_starts}
rendered=${rendered//@CORE_PAGES@/$core_pages}
rendered=${rendered//@DOCUMENT_PAGES@/$document_pages}
rendered=${rendered//@PROJECTION_COUNT@/$projection_count}
rendered=${rendered//@UNRESOLVED_NAMES@/$unresolved_names}
rendered=${rendered//@UNRESOLVED_OCCURRENCES@/$unresolved_occurrences}
rendered=${rendered//@UNRESOLVED_RULES@/$unresolved_rules}
rendered=${rendered//@RESOLUTION_RECORDS@/$resolution_records}
rendered=${rendered//@RESOLUTION_ALIASES@/$resolution_aliases}
rendered=${rendered//@RESOLUTION_LEXICAL@/$resolution_lexical}
rendered=${rendered//@RESOLUTION_METAVARIABLE@/$resolution_metavariable}
rendered=${rendered//@RESOLUTION_UNRESOLVED@/$resolution_unresolved}
rendered=${rendered//@R402_ALIASES@/$r402_aliases}
rendered=${rendered//@R402_UNRESOLVED@/$r402_unresolved}
rendered=${rendered//@LEXICAL_CLASSES@/$lexical_class_records}
rendered=${rendered//@LEXICAL_PROJECTION@/$lexical_projection_records}
rendered=${rendered//@UNICODE_EXCLUSIONS@/$unicode_exclusions}
rendered=${rendered//@COMBINED_ALIASES@/$combined_aliases}
rendered=${rendered//@COMBINED_LEXICAL@/$combined_lexical}
rendered=${rendered//@COMBINED_UNRESOLVED@/$combined_unresolved}
rendered=${rendered//@COMBINED_WITNESSES@/$combined_witnesses}
rendered=${rendered//@ERRATA_REPAIRS@/$errata_repairs}
rendered=${rendered//@ERRATA_COMMAS@/$errata_commas}
rendered=${rendered//@ERRATA_COLONS@/$errata_colons}
rendered=${rendered//@EXPANSION_AUDIT_NAMES@/$normalized_audit_names}
rendered=${rendered//@EXPANSION_RECORDS@/$expansion_records}
rendered=${rendered//@R401_RECORDS@/$r401_records}
rendered=${rendered//@R403_RECORDS@/$r403_records}
rendered=${rendered//@EXPANSION_REPRESENTATION@/$expansion_representation}
{
    printf '%s\n\n' "$rendered"
    cat "$results"
} > "$paper_dir/paper.md"

printf 'standard-to-grammar: regenerated results.md and paper.md\n'
