#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/../.." && pwd)
run_file_glob=("$repo_root"/research/runs/*.jsonl)
paper_dir="$script_dir"
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

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

# The paper's two pin lists must agree. Without this check, a manuscript can
# regenerate from newer run records while pins.toml silently reports an older
# study.
awk '
    /^run_ids[[:space:]]*=[[:space:]]*\[/ {inside=1; next}
    inside && /^\]/ {exit}
    inside {gsub(/[",]/, "", $1); if ($1 != "") print $1}
' "$paper_dir/pins.toml" | sort >"$tmp_dir/pins-runs"
grep -v '^[[:space:]]*#' "$paper_dir/runs.txt" | sed '/^[[:space:]]*$/d' | sort >"$tmp_dir/report-runs"
diff -u "$tmp_dir/pins-runs" "$tmp_dir/report-runs" >/dev/null || \
    die "paper pins.toml run_ids differ from runs.txt"

awk '
    /^standard_new_commits[[:space:]]*=[[:space:]]*\[/ {inside=1; next}
    inside && /^\]/ {exit}
    inside {gsub(/[",]/, "", $1); if ($1 != "") print $1}
' "$paper_dir/pins.toml" | sort -u >"$tmp_dir/pins-commits"
while IFS= read -r run_id; do
    [[ -z "$run_id" || "$run_id" == \#* ]] && continue
    standard_commit=$(metric "$run_id" '(.standard_new_commit // .standard_commit // "")')
    [[ -n "$standard_commit" ]] || die "run has no standard-new commit: $run_id"
    grep -Fxq "$standard_commit" "$tmp_dir/pins-commits" || \
        die "run standard-new commit is absent from pins.toml: $run_id $standard_commit"
    mapfile -t run_artifacts < <(run_json "$run_id" | jq -r '(.artifact? // empty), (.artifacts[]? // empty)')
    ((${#run_artifacts[@]} > 0)) || die "run has no artifact path: $run_id"
    for artifact in "${run_artifacts[@]}"; do
        [[ -f "$repo_root/$artifact" ]] || die "run artifact is missing: $run_id $artifact"
    done
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
assert_run R000058 '.status == "verification_failure" and .experiment == "E0049" and .verification.zero_model_calls == true and .verification.source_resolution_records == 182 and .verification.errata_repairs == 8 and .verification.resolved_projection_records == 70 and .verification.expansion_records == 100 and .verification.family_resolution_conflicts == 3 and .verification.conflict_set_difference == 0 and .verification.final_syntax_records == 522 and .verification.representation_selection == "deferred_D0024" and .verification.negative_control == "observed_failure"'
assert_run R000059 '.status == "accepted" and .experiment == "E0050" and .verification.zero_model_calls == true and .verification.candidate_strategies == 3 and .verification.overlap_terms == 3 and .verification.r401_records == 80 and .verification.r403_records == 20 and .verification.candidate_rows == 9 and .verification.lossy_alias_precedence_rows == 3 and .verification.lossless_expansion_precedence_rows == 3 and .verification.lossless_unresolved_composite_rows == 3 and .verification.parser_ready_candidates == 1 and .verification.representation_selection == "deferred_D0024_D0026" and .verification.independent_difference == 0 and .verification.negative_control == "observed_failure"'
assert_run R000060 '.status == "verification_failure" and .experiment == "E0051" and .verification.zero_model_calls == true and .verification.final_syntax_records == 522 and .verification.antlr_definitions == 502 and .verification.bison_definitions == 502 and .verification.treesitter_definitions == 502 and .verification.antlr_status == 1 and .verification.antlr_unresolved_rule_names == 103 and .verification.bison_status == 1 and .verification.bison_unresolved_symbol_names == 103 and .verification.treesitter_status == 1 and .verification.treesitter_structural_error == 1 and .verification.antlr_bison_unresolved_set_difference == 0 and .verification.target_status_agreement == 1 and .verification.negative_control == "observed_failure"'
assert_run R000061 '.status == "verification_failure" and .experiment == "E0052" and .verification.zero_model_calls == true and .verification.final_syntax_records == 522 and .verification.errata_repairs == 8 and .verification.grouped_optional_repairs == 2 and .verification.antlr_definitions == 502 and .verification.bison_definitions == 502 and .verification.treesitter_definitions == 502 and .verification.antlr_status == 1 and .verification.bison_status == 1 and .verification.treesitter_status == 1 and .verification.treesitter_structural_error == 0 and .verification.antlr_unresolved_rule_names == 103 and .verification.bison_unresolved_symbol_names == 103 and .verification.antlr_bison_unresolved_set_difference == 0 and .verification.negative_control == "observed_failure"'
assert_run R000062 '.status == "accepted" and .experiment == "E0053" and .verification.zero_model_calls == true and .verification.unresolved_target_names == 103 and .verification.r401_unresolved == 80 and .verification.r403_unresolved == 17 and .verification.expansion_unresolved == 97 and .verification.lexical_unresolved == 3 and .verification.metavariable_unresolved == 1 and .verification.unicode_unresolved == 2 and .verification.source_metadata_records == 6 and .verification.open_decision_groups == 2 and .verification.negative_control == "observed_failure"'
assert_run R000063 '.status == "accepted" and .experiment == "E0054" and .verification.zero_model_calls == true and .verification.candidate_strategies == 3 and .verification.residue_terms == 5 and .verification.candidate_rows == 15 and .verification.lexical_rows == 3 and .verification.unicode_rows == 2 and .verification.primitive_export_rows == 3 and .verification.schema_export_rows == 3 and .verification.unresolved_rows == 5 and .verification.complete_projection_candidates == 0 and .verification.representation_selection == "deferred_D0027" and .verification.negative_control == "observed_failure"'
assert_run R000064 '.status == "verification_failure" and .experiment == "E0055" and .verification.zero_model_calls == true and .verification.source_syntax_records == 522 and .verification.generated_syntax_records == 519 and .verification.r401_expansions == 80 and .verification.r403_expansions == 20 and .verification.compositional_overlaps == 3 and .verification.lexical_schema_records == 5 and .verification.lexical_schema_projected == 3 and .verification.unresolved_schema_records == 2 and .verification.antlr_status == 1 and .verification.bison_status == 1 and .verification.treesitter_status == 1 and .verification.antlr_unresolved == 0 and .verification.bison_unresolved == 0 and .verification.treesitter_structural_error == 1 and .verification.target_boundary == "verification_failure_structural_target" and .verification.negative_control == "observed_failure"'
assert_run R000065 '.status == "verification_failure" and .experiment == "E0056" and .verification.zero_model_calls == true and .verification.normalized_antlr_status == 0 and .verification.normalized_bison_status == 0 and .verification.normalized_treesitter_status == 1 and .verification.left_recursion_groups == 3 and .verification.nullable_rules_inlined == 5 and .verification.treesitter_conflict_groups == 13 and .verification.antlr_warnings == 18 and .verification.bison_warnings == 206 and .verification.normalized_unresolved_names == 0 and .verification.target_boundary == "verification_failure_remaining_target_structure" and .verification.negative_control == "observed_failure"'
assert_run R000066 '.status == "accepted" and .experiment == "E0057" and .verification.zero_model_calls == true and .verification.source_syntax_records == 522 and .verification.composite_syntax_records == 519 and .verification.unique_lhs == 499 and .verification.dispatch_rows == 519 and .verification.generated_procedures == 499 and .verification.duplicate_dispatch_labels == 0 and .verification.provenance_rows == 519 and .verification.unresolved_references == 0 and .verification.fortran_compile_status == 0 and .verification.target_boundary == "wiring_skeleton_compiled" and .verification.negative_control == "observed_failure"'
assert_run R000067 '.status == "accepted" and .experiment == "E0058" and .verification.zero_model_calls == true and .verification.composite_syntax_records == 519 and .verification.diagnostic_rows == 519 and .verification.source_span_rows == 519 and .verification.known_lookup == 1 and .verification.unknown_lookup_rejected == 1 and .verification.fortran_compile_status == 0 and .verification.runtime_test_status == 0 and .verification.target_boundary == "source_linked_lookup_compiled_and_tested" and .verification.negative_control == "observed_failure"'
assert_run R000068 '.status == "accepted" and .experiment == "E0059" and .verification.zero_model_calls == true and .verification.corpus_files == 5 and .verification.expected_units == 8 and .verification.classified_units == 8 and .verification.source_linked_units == 8 and .verification.unit_mismatches == 0 and .verification.gfortran_accepted == 5 and .verification.fortran_compile_status == 0 and .verification.runtime_test_status == 0 and .verification.target_boundary == "top_level_local_operation_validated" and .verification.negative_control == "observed_failure"'
assert_run R000069 '.status == "accepted" and .experiment == "E0060" and .verification.zero_model_calls == true and .verification.corpus_files == 5 and .verification.expected_witnesses == 10 and .verification.classified_witnesses == 10 and .verification.source_linked_witnesses == 10 and .verification.witness_mismatches == 0 and .verification.fortran_compile_status == 0 and .verification.runtime_test_status == 0 and .verification.target_boundary == "statement_witness_operation_validated" and .verification.negative_control == "observed_failure"'
assert_run R000070 '.status == "accepted" and .experiment == "E0061" and .verification.zero_model_calls == true and .verification.corpus_files == 5 and .verification.expected_meaningful_lines == 72 and .verification.classified_meaningful_lines == 72 and .verification.source_linked_lines == 72 and .verification.line_mismatches == 0 and .verification.gfortran_accepted == 5 and .verification.fortran_compile_status == 0 and .verification.runtime_test_status == 0 and .verification.unsupported_mutation_rejected == 1 and .verification.target_boundary == "complete_source_operation_validated" and .verification.negative_control == "observed_failure"'
assert_run R000071 '.status == "accepted" and .experiment == "E0062" and .verification.zero_model_calls == true and .verification.corpus_files == 5 and .verification.physical_meaningful_lines == 75 and .verification.expected_logical_statements == 73 and .verification.classified_logical_statements == 73 and .verification.source_linked_statements == 73 and .verification.continuation_joins == 2 and .verification.nesting_errors == 0 and .verification.max_nesting_depth == 2 and .verification.statement_mismatches == 0 and .verification.gfortran_accepted == 5 and .verification.fortran_compile_status == 0 and .verification.runtime_test_status == 0 and .verification.malformed_nesting_rejected == 1 and .verification.target_boundary == "logical_construct_operation_validated" and .verification.negative_control == "observed_failure"'
assert_run R000072 '.status == "accepted" and .experiment == "E0063" and .verification.zero_model_calls == true and .verification.corpus_files == 5 and .verification.logical_statements == 73 and .verification.ast_nodes == 73 and .verification.source_linked_nodes == 73 and .verification.root_nodes == 5 and .verification.parent_links == 68 and .verification.child_links == 68 and .verification.ast_link_errors == 0 and .verification.max_ast_depth == 4 and .verification.fortran_compile_status == 0 and .verification.runtime_test_status == 0 and .verification.malformed_nesting_rejected == 1 and .verification.target_boundary == "source_linked_ast_forest_validated" and .verification.negative_control == "observed_failure"'
assert_run R000073 '.status == "accepted" and .experiment == "E0064" and .verification.zero_model_calls == true and .verification.corpus_files == 5 and .verification.statement_nodes == 73 and .verification.expression_nodes == 52 and .verification.total_nodes == 125 and .verification.source_linked_nodes == 125 and .verification.root_nodes == 5 and .verification.parent_links == 120 and .verification.child_links == 120 and .verification.ast_link_errors == 0 and .verification.max_ast_depth == 5 and .verification.query_hits == 5 and .verification.unknown_query_rejected == 1 and .verification.fortran_compile_status == 0 and .verification.runtime_test_status == 0 and .verification.malformed_nesting_rejected == 1 and .verification.target_boundary == "source_linked_expression_ast_query_validated" and .verification.negative_control == "observed_failure"'
assert_run R000074 '.status == "accepted" and .experiment == "E0065" and .verification.zero_model_calls == true and .verification.witness_files == 5 and .verification.expression_witnesses == 8 and .verification.base_expression_nodes == 125 and .verification.leaf_nodes == 28 and .verification.name_nodes == 10 and .verification.literal_nodes == 10 and .verification.operator_nodes == 8 and .verification.source_linked_leaves == 28 and .verification.subtree_parent_links == 28 and .verification.subtree_link_errors == 0 and .verification.max_subtree_depth == 6 and .verification.known_witness_queries == 8 and .verification.unknown_witness_rejected == 1 and .verification.fortran_compile_status == 0 and .verification.runtime_test_status == 0 and .verification.malformed_nesting_rejected == 1 and .verification.target_boundary == "source_linked_token_subtrees_validated" and .verification.negative_control == "observed_failure"'
assert_run R000075 '.status == "accepted" and .experiment == "E0066" and .verification.zero_model_calls == true and .verification.witness_files == 4 and .verification.expression_witnesses == 7 and .verification.internal_nodes == 10 and .verification.leaf_nodes == 17 and .verification.binary_nodes == 6 and .verification.unary_nodes == 3 and .verification.array_nodes == 1 and .verification.name_nodes == 6 and .verification.literal_nodes == 11 and .verification.source_linked_nodes == 27 and .verification.subtree_parent_links == 27 and .verification.subtree_link_errors == 0 and .verification.tree_mismatches == 0 and .verification.precedence_query_hits == 7 and .verification.unknown_query_rejected == 1 and .verification.max_tree_depth == 8 and .verification.fortran_compile_status == 0 and .verification.runtime_test_status == 0 and .verification.malformed_nesting_rejected == 1 and .verification.target_boundary == "source_linked_precedence_trees_validated" and .verification.negative_control == "observed_failure"'
assert_run R000076 '.status == "accepted" and .experiment == "E0067" and .verification.zero_model_calls == true and .verification.witness_files == 6 and .verification.expression_witnesses == 9 and .verification.gfortran_accepted == 6 and .verification.internal_nodes == 23 and .verification.leaf_nodes == 31 and .verification.binary_nodes == 20 and .verification.unary_nodes == 1 and .verification.array_nodes == 0 and .verification.function_reference_nodes == 2 and .verification.name_nodes == 18 and .verification.literal_nodes == 13 and .verification.source_linked_nodes == 54 and .verification.subtree_parent_links == 54 and .verification.subtree_link_errors == 0 and .verification.tree_mismatches == 0 and .verification.coverage_query_hits == 9 and .verification.unknown_query_rejected == 1 and .verification.max_expression_depth == 8 and .verification.fortran_compile_status == 0 and .verification.runtime_test_status == 0 and .verification.unsupported_operator_rejected == 1 and .verification.target_boundary == "source_linked_expression_coverage_validated" and .verification.negative_control == "observed_failure"'
assert_run R000077 '.status == "accepted" and .experiment == "E0068" and .verification.zero_model_calls == true and .verification.corpus_files == 5 and .verification.expected_meaningful_lines == 72 and .verification.accepted_records == 72 and .verification.source_linked_records == 72 and .verification.unsupported_records == 1 and .verification.diagnostic_records == 1 and .verification.diagnostic_provenance == 1 and .verification.complete_file_mismatches == 0 and .verification.gfortran_accepted == 5 and .verification.gfortran_mutation_rejected == 1 and .verification.fortran_compile_status == 0 and .verification.runtime_test_status == 0 and .verification.target_boundary == "lossless_complete_source_acceptance_validated" and .verification.negative_control == "observed_failure"'
assert_run R000078 '.status == "accepted" and .experiment == "E0069" and .verification.zero_model_calls == true and .verification.unresolved_names == 181 and .verification.candidate_spans == 9 and .verification.alias_names == 0 and .verification.lexical_class_names == 2 and .verification.metavariable_names == 1 and .verification.semantic_role_names == 4 and .verification.ambiguous_names == 0 and .verification.unresolved_after_patterns == 174 and .verification.source_linked_candidates == 9 and .verification.independent_difference == 0 and .verification.negative_control == "observed_failure" and .verification.target_boundary == "deterministic_normative_prose_evidence_measured"'
assert_run R000079 '.status == "accepted" and .experiment == "E0070" and .verification.zero_model_calls == true and .verification.unresolved_names == 181 and .verification.logical_units == 5064 and .verification.table_rows == 39 and .verification.candidate_spans == 42 and .verification.candidate_names == 30 and .verification.new_names_over_e0069 == 23 and .verification.alias_names == 0 and .verification.lexical_class_names == 7 and .verification.metavariable_names == 1 and .verification.semantic_role_names == 22 and .verification.ambiguous_names == 0 and .verification.unresolved_after_patterns == 151 and .verification.source_linked_candidates == 42 and .verification.independent_difference == 0 and .verification.negative_control == "observed_failure" and .verification.target_boundary == "bounded_normative_prose_evidence_measured"'
assert_run R000080 '.status == "accepted" and .experiment == "E0071" and .verification.zero_model_calls == true and .verification.candidate_spans == 42 and .verification.accepted_records == 37 and .verification.retained_records == 5 and .verification.accepted_alias_records == 0 and .verification.accepted_lexical_class_records == 7 and .verification.accepted_metavariable_records == 1 and .verification.accepted_semantic_role_records == 29 and .verification.source_hash_matches == 42 and .verification.source_evidence_matches == 42 and .verification.candidate_inventory_difference == 0 and .verification.independent_difference == 0 and .verification.negative_control == "observed_failure" and .verification.target_boundary == "source_controlled_bounded_prose_adjudication"'
assert_run R000081 '.status == "accepted" and .experiment == "E0072" and .verification.zero_model_calls == true and .verification.d0019_records == 182 and .verification.adjudicated_relation_records == 37 and .verification.merged_fact_records == 219 and .verification.retained_relations == 5 and .verification.unresolved_records == 151 and .verification.semantic_facts_not_parser_aliases == 29 and .verification.parser_projection_records == 11 and .verification.source_hash_matches == 219 and .verification.projection_difference == 0 and .verification.independent_difference == 0 and .verification.negative_control == "observed_failure" and .verification.target_boundary == "d0019_adjudicated_relation_composition"'
assert_run R000082 '.status == "accepted" and .experiment == "E0073" and .verification.zero_model_calls == true and .verification.composite_fact_records == 219 and .verification.semantic_fact_records == 29 and .verification.parser_projection_records == 11 and .verification.target_fragment_records == 11 and .verification.target_provenance_records == 55 and .verification.semantic_target_leaks == 0 and .verification.ebnf_status == 0 and .verification.antlr_status == 0 and .verification.bison_status == 0 and .verification.treesitter_status == 0 and .verification.direct_fortran_status == 0 and .verification.independent_difference == 0 and .verification.negative_control == "observed_failure" and .verification.target_boundary == "all_target_fragments_valid"'
assert_run R000083 '.status == "accepted" and .experiment == "E0074" and .verification.zero_model_calls == true and .verification.source_syntax_records == 522 and .verification.integrated_syntax_records == 522 and .verification.alias_records == 3 and .verification.alias_reference_rewrites == 6 and .verification.semantic_fact_records == 29 and .verification.semantic_alias_overlap == 1 and .verification.semantic_projection_leaks == 0 and .verification.unresolved_reference_occurrences == 466 and .verification.unresolved_unique_names == 178 and .verification.export_ebnf_status == 0 and .verification.export_antlr_status == 0 and .verification.export_bison_status == 0 and .verification.export_treesitter_status == 0 and .verification.antlr_validate_status == 1 and .verification.bison_validate_status == 1 and .verification.treesitter_validate_status == 1 and .verification.dispatch_rows == 522 and .verification.dispatch_provenance_rows == 522 and .verification.dispatch_label_collisions == 0 and .verification.direct_fortran_status == 0 and .verification.independent_difference == 0 and .verification.negative_control == "observed_failure" and .verification.wiring_boundary == "integrated_dispatch_compiled"'
assert_run R000084 '.status == "accepted" and .experiment == "E0075" and .verification.zero_model_calls == true and .verification.residue_records == 178 and .verification.semantic_role_records == 18 and .verification.lexical_class_records == 8 and .verification.metavariable_records == 1 and .verification.unresolved_records == 151 and .verification.missing_fact_records == 0 and .verification.additional_alias_records == 0 and .verification.source_hash_matches == 178 and .verification.source_evidence_records == 178 and .verification.semantic_projection_leaks == 0 and .verification.independent_difference == 0 and .verification.negative_control == "observed_failure"'
assert_run R000085 '.status == "accepted" and .experiment == "E0076" and .verification.zero_model_calls == true and .verification.unresolved_denominator == 151 and .verification.logical_units == 5064 and .verification.candidate_spans == 3 and .verification.candidate_names == 3 and .verification.alias_candidates == 0 and .verification.lexical_candidates == 0 and .verification.metavariable_candidates == 0 and .verification.semantic_role_candidates == 3 and .verification.unresolved_after_patterns == 148 and .verification.source_linked_candidates == 3 and .verification.independent_difference == 0 and .verification.negative_control == "observed_failure"'
assert_run R000086 '.status == "accepted" and .experiment == "E0077" and .verification.zero_model_calls == true and .verification.candidate_spans == 3 and .verification.accepted_records == 0 and .verification.retained_records == 3 and .verification.accepted_semantic_role_records == 0 and .verification.source_hash_matches == 3 and .verification.source_evidence_matches == 3 and .verification.candidate_inventory_difference == 0 and .verification.independent_difference == 0 and .verification.negative_control == "observed_failure"'
assert_run R000087 '.status == "accepted" and .experiment == "E0078" and .verification.zero_model_calls == true and .verification.residue_records == 151 and .verification.retained_candidate_records == 3 and .verification.unresolved_no_evidence_records == 148 and .verification.source_hash_matches == 151 and .verification.parser_target_records == 0 and .verification.parser_leaks == 0 and .verification.integrated_syntax_records == 522 and .verification.dispatch_rows == 522 and .verification.dispatch_provenance_rows == 522 and .verification.integrated_hash_difference == 0 and .verification.dispatch_hash_difference == 0 and .verification.export_antlr_validator_status == 1 and .verification.export_bison_validator_status == 1 and .verification.export_treesitter_validator_status == 1 and .verification.direct_fortran_status == 0 and .verification.independent_difference == 0 and .verification.negative_control == "observed_failure"'
assert_run R000088 '.status == "accepted" and .experiment == "E0079" and .verification.zero_model_calls == true and .verification.profile_rows == 151 and .verification.profile_parser_targets == 0 and .verification.profile_source_hashes == 151 and .verification.complete_source_files == 5 and .verification.complete_accepted_records == 72 and .verification.complete_source_linked_records == 72 and .verification.ast_source_files == 5 and .verification.ast_nodes == 73 and .verification.ast_source_linked_nodes == 73 and .verification.ast_parent_links == 68 and .verification.ast_child_links == 68 and .verification.ast_link_errors == 0 and .verification.diagnostic_records == 1 and .verification.diagnostic_source_linked == 1 and .verification.gfortran_complete_accepted == 5 and .verification.gfortran_ast_accepted == 5 and .verification.fortran_compile_status == 0 and .verification.runtime_test_status == 0 and .verification.independent_difference == 0 and .verification.negative_control == "observed_failure"'
assert_run R000089 '.status == "accepted" and .experiment == "E0080" and .verification.zero_model_calls == true and .verification.profile_rows == 151 and .verification.profile_parser_targets == 0 and .verification.expression_source_files == 6 and .verification.expression_witnesses == 9 and .verification.gfortran_accepted == 6 and .verification.internal_nodes == 23 and .verification.leaf_nodes == 31 and .verification.binary_nodes == 20 and .verification.unary_nodes == 1 and .verification.array_nodes == 0 and .verification.function_reference_nodes == 2 and .verification.name_nodes == 18 and .verification.literal_nodes == 13 and .verification.source_linked_nodes == 54 and .verification.subtree_parent_links == 54 and .verification.subtree_link_errors == 0 and .verification.tree_mismatches == 0 and .verification.coverage_query_hits == 9 and .verification.unknown_query_rejected == 1 and .verification.max_expression_depth == 8 and .verification.fortran_compile_status == 0 and .verification.runtime_test_status == 0 and .verification.unsupported_operator_rejected == 1 and .verification.independent_difference == 0 and .verification.negative_control == "observed_failure"'
assert_run R000090 '.status == "accepted" and .experiment == "E0081" and .verification.zero_model_calls == true and .verification.unresolved_names == 181 and .verification.candidate_spans == 266 and .verification.definition_candidate_spans == 3 and .verification.relation_candidate_spans == 7 and .verification.constraint_candidate_spans == 256 and .verification.core0_closure_members == 345 and .verification.core0_constraint_records == 287 and .verification.accepted_standardir_facts == 0 and .verification.independent_candidate_difference == 0 and .verification.independent_constraint_difference == 0 and .verification.negative_control == "observed_failure"'
assert_run R000091 '.status == "accepted" and .experiment == "E0082" and .verification.zero_model_calls == true and .verification.candidate_spans == 266 and .verification.accepted_records == 10 and .verification.accepted_lexical_class_records == 2 and .verification.accepted_metavariable_records == 1 and .verification.accepted_semantic_role_records == 7 and .verification.retained_constraint_candidates == 256 and .verification.unresolved_body_constraint_records == 287 and .verification.accepted_standardir_resolution_facts == 10 and .verification.formalized_constraint_bodies == 0 and .verification.parser_projection_records == 0 and .verification.source_linked_candidates == 266 and .verification.source_linked_constraints == 287 and .verification.independent_candidate_difference == 0 and .verification.independent_constraint_difference == 0 and .verification.negative_control == "observed_failure"'
assert_run R000092 '.status == "accepted" and .experiment == "E0083" and .verification.zero_model_calls == true and .verification.eligible_constraints == 287 and .verification.selected_constraints == 8 and .verification.normalized_predicates == 8 and .verification.resolved_constraints == 8 and .verification.unresolved_constraints == 279 and .verification.disputed_constraints == 0 and .verification.source_hash_matches == 287 and .verification.source_evidence_matches == 8 and .verification.required_fact_records == 10 and .verification.provided_fact_records == 8 and .verification.dependency_edges == 18 and .verification.topological_order_difference == 0 and .verification.independent_normalization_difference == 0 and .verification.parser_projection_records == 0 and .verification.negative_control == "observed_failure"'
assert_run R000093 '.status == "accepted" and .experiment == "E0084" and .verification.zero_model_calls == true and .verification.eligible_constraints == 287 and .verification.selected_constraints == 6 and .verification.normalized_predicates == 6 and .verification.resolved_constraints == 6 and .verification.unresolved_constraints == 281 and .verification.disputed_constraints == 0 and .verification.source_hash_matches == 287 and .verification.source_evidence_matches == 6 and .verification.required_fact_records == 16 and .verification.provided_fact_records == 6 and .verification.dependency_edges == 22 and .verification.topological_order_difference == 0 and .verification.independent_normalization_difference == 0 and .verification.parser_projection_records == 0 and .verification.negative_control == "observed_failure"'

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
composite_resolution_records=$(metric R000058 '.verification.source_resolution_records')
composite_normalized_names=$(metric R000058 '.verification.normalized_reference_names')
composite_projection_records=$(metric R000058 '.verification.resolved_projection_records')
composite_projection_occurrences=$(metric R000058 '.verification.projection_reference_replacements')
composite_expansions=$(metric R000058 '.verification.expansion_records')
composite_unresolved_expansions=$(metric R000058 '.verification.unresolved_expansion_records')
composite_conflicts=$(metric R000058 '.verification.family_resolution_conflicts')
composite_conflict_difference=$(metric R000058 '.verification.conflict_set_difference')
composite_syntax_records=$(metric R000058 '.verification.final_syntax_records')
composite_source_matches=$(metric R000058 '.verification.source_hash_matches')
composite_status=$(metric R000058 '.verification.composition_status')
composite_negative_control=$(metric R000058 '.verification.negative_control')
candidate_strategies=$(metric R000059 '.verification.candidate_strategies')
candidate_overlap_terms=$(metric R000059 '.verification.overlap_terms')
candidate_rows=$(metric R000059 '.verification.candidate_rows')
candidate_lossy=$(metric R000059 '.verification.lossy_alias_precedence_rows')
candidate_expansion_lossless=$(metric R000059 '.verification.lossless_expansion_precedence_rows')
candidate_unresolved_lossless=$(metric R000059 '.verification.lossless_unresolved_composite_rows')
candidate_parser_ready=$(metric R000059 '.verification.parser_ready_candidates')
candidate_selection=$(metric R000059 '.verification.representation_selection')
candidate_difference=$(metric R000059 '.verification.independent_difference')
candidate_negative_control=$(metric R000059 '.verification.negative_control')
target_antlr_definitions=$(metric R000060 '.verification.antlr_definitions')
target_bison_definitions=$(metric R000060 '.verification.bison_definitions')
target_treesitter_definitions=$(metric R000060 '.verification.treesitter_definitions')
target_antlr_status=$(metric R000060 '.verification.antlr_status')
target_antlr_unresolved=$(metric R000060 '.verification.antlr_unresolved_rule_names')
target_bison_status=$(metric R000060 '.verification.bison_status')
target_bison_unresolved=$(metric R000060 '.verification.bison_unresolved_symbol_names')
target_treesitter_status=$(metric R000060 '.verification.treesitter_status')
target_treesitter_structural=$(metric R000060 '.verification.treesitter_structural_error')
target_set_difference=$(metric R000060 '.verification.antlr_bison_unresolved_set_difference')
target_status_agreement=$(metric R000060 '.verification.target_status_agreement')
target_negative_control=$(metric R000060 '.verification.negative_control')
grouped_errata_repairs=$(metric R000061 '.verification.errata_repairs')
grouped_optional_repairs=$(metric R000061 '.verification.grouped_optional_repairs')
grouped_antlr_status=$(metric R000061 '.verification.antlr_status')
grouped_bison_status=$(metric R000061 '.verification.bison_status')
grouped_treesitter_status=$(metric R000061 '.verification.treesitter_status')
grouped_treesitter_structural=$(metric R000061 '.verification.treesitter_structural_error')
grouped_antlr_unresolved=$(metric R000061 '.verification.antlr_unresolved_rule_names')
grouped_bison_unresolved=$(metric R000061 '.verification.bison_unresolved_symbol_names')
grouped_set_difference=$(metric R000061 '.verification.antlr_bison_unresolved_set_difference')
grouped_negative_control=$(metric R000061 '.verification.negative_control')
residual_target_names=$(metric R000062 '.verification.unresolved_target_names')
residual_r401=$(metric R000062 '.verification.r401_unresolved')
residual_r403=$(metric R000062 '.verification.r403_unresolved')
residual_expansion=$(metric R000062 '.verification.expansion_unresolved')
residual_lexical=$(metric R000062 '.verification.lexical_unresolved')
residual_metavariable=$(metric R000062 '.verification.metavariable_unresolved')
residual_unicode=$(metric R000062 '.verification.unicode_unresolved')
residual_metadata=$(metric R000062 '.verification.source_metadata_records')
residual_open_decisions=$(metric R000062 '.verification.open_decision_groups')
residual_negative_control=$(metric R000062 '.verification.negative_control')
lexical_candidate_strategies=$(metric R000063 '.verification.candidate_strategies')
lexical_candidate_residue=$(metric R000063 '.verification.residue_terms')
lexical_candidate_rows=$(metric R000063 '.verification.candidate_rows')
lexical_candidate_lexical=$(metric R000063 '.verification.lexical_rows')
lexical_candidate_unicode=$(metric R000063 '.verification.unicode_rows')
lexical_candidate_primitive=$(metric R000063 '.verification.primitive_export_rows')
lexical_candidate_schema=$(metric R000063 '.verification.schema_export_rows')
lexical_candidate_unresolved=$(metric R000063 '.verification.unresolved_rows')
lexical_candidate_complete=$(metric R000063 '.verification.complete_projection_candidates')
lexical_candidate_selection=$(metric R000063 '.verification.representation_selection')
lexical_candidate_negative=$(metric R000063 '.verification.negative_control')
accepted_projection_source=$(metric R000064 '.verification.source_syntax_records')
accepted_projection_generated=$(metric R000064 '.verification.generated_syntax_records')
accepted_projection_r401=$(metric R000064 '.verification.r401_expansions')
accepted_projection_r403=$(metric R000064 '.verification.r403_expansions')
accepted_projection_overlaps=$(metric R000064 '.verification.compositional_overlaps')
accepted_projection_lexical=$(metric R000064 '.verification.lexical_schema_records')
accepted_projection_lexical_projected=$(metric R000064 '.verification.lexical_schema_projected')
accepted_projection_lexical_unresolved=$(metric R000064 '.verification.unresolved_schema_records')
accepted_projection_antlr=$(metric R000064 '.verification.antlr_status')
accepted_projection_bison=$(metric R000064 '.verification.bison_status')
accepted_projection_treesitter=$(metric R000064 '.verification.treesitter_status')
accepted_projection_antlr_unresolved=$(metric R000064 '.verification.antlr_unresolved')
accepted_projection_bison_unresolved=$(metric R000064 '.verification.bison_unresolved')
accepted_projection_treesitter_structural=$(metric R000064 '.verification.treesitter_structural_error')
accepted_projection_target_boundary=$(metric R000064 '.verification.target_boundary')
accepted_projection_negative=$(metric R000064 '.verification.negative_control')
normalized_target_antlr=$(metric R000065 '.verification.normalized_antlr_status')
normalized_target_bison=$(metric R000065 '.verification.normalized_bison_status')
normalized_target_treesitter=$(metric R000065 '.verification.normalized_treesitter_status')
normalized_target_recursion=$(metric R000065 '.verification.left_recursion_groups')
normalized_target_nullable=$(metric R000065 '.verification.nullable_rules_inlined')
normalized_target_conflicts=$(metric R000065 '.verification.treesitter_conflict_groups')
normalized_target_antlr_warnings=$(metric R000065 '.verification.antlr_warnings')
normalized_target_bison_warnings=$(metric R000065 '.verification.bison_warnings')
normalized_target_unresolved=$(metric R000065 '.verification.normalized_unresolved_names')
normalized_target_boundary=$(metric R000065 '.verification.target_boundary')
normalized_target_next_conflict=$(metric R000065 '.verification.treesitter_first_unresolved_conflict')
normalized_target_negative=$(metric R000065 '.verification.negative_control')
direct_source=$(metric R000066 '.verification.source_syntax_records')
direct_composite=$(metric R000066 '.verification.composite_syntax_records')
direct_lhs=$(metric R000066 '.verification.unique_lhs')
direct_dispatch=$(metric R000066 '.verification.dispatch_rows')
direct_procedures=$(metric R000066 '.verification.generated_procedures')
direct_duplicates=$(metric R000066 '.verification.duplicate_dispatch_labels')
direct_provenance=$(metric R000066 '.verification.provenance_rows')
direct_unresolved=$(metric R000066 '.verification.unresolved_references')
direct_compile=$(metric R000066 '.verification.fortran_compile_status')
direct_boundary=$(metric R000066 '.verification.target_boundary')
direct_negative=$(metric R000066 '.verification.negative_control')
diagnostic_records=$(metric R000067 '.verification.composite_syntax_records')
diagnostic_rows=$(metric R000067 '.verification.diagnostic_rows')
diagnostic_spans=$(metric R000067 '.verification.source_span_rows')
diagnostic_known=$(metric R000067 '.verification.known_lookup')
diagnostic_unknown=$(metric R000067 '.verification.unknown_lookup_rejected')
diagnostic_compile=$(metric R000067 '.verification.fortran_compile_status')
diagnostic_runtime=$(metric R000067 '.verification.runtime_test_status')
diagnostic_boundary=$(metric R000067 '.verification.target_boundary')
diagnostic_negative=$(metric R000067 '.verification.negative_control')
local_corpus_files=$(metric R000068 '.verification.corpus_files')
local_expected_units=$(metric R000068 '.verification.expected_units')
local_classified_units=$(metric R000068 '.verification.classified_units')
local_source_linked_units=$(metric R000068 '.verification.source_linked_units')
local_unit_mismatches=$(metric R000068 '.verification.unit_mismatches')
local_gfortran_accepted=$(metric R000068 '.verification.gfortran_accepted')
local_compile=$(metric R000068 '.verification.fortran_compile_status')
local_runtime=$(metric R000068 '.verification.runtime_test_status')
local_boundary=$(metric R000068 '.verification.target_boundary')
local_negative=$(metric R000068 '.verification.negative_control')
statement_corpus_files=$(metric R000069 '.verification.corpus_files')
statement_expected=$(metric R000069 '.verification.expected_witnesses')
statement_classified=$(metric R000069 '.verification.classified_witnesses')
statement_linked=$(metric R000069 '.verification.source_linked_witnesses')
statement_mismatches=$(metric R000069 '.verification.witness_mismatches')
statement_compile=$(metric R000069 '.verification.fortran_compile_status')
statement_runtime=$(metric R000069 '.verification.runtime_test_status')
statement_boundary=$(metric R000069 '.verification.target_boundary')
statement_negative=$(metric R000069 '.verification.negative_control')
complete_corpus_files=$(metric R000070 '.verification.corpus_files')
complete_expected_lines=$(metric R000070 '.verification.expected_meaningful_lines')
complete_classified_lines=$(metric R000070 '.verification.classified_meaningful_lines')
complete_linked_lines=$(metric R000070 '.verification.source_linked_lines')
complete_mismatches=$(metric R000070 '.verification.line_mismatches')
complete_gfortran_accepted=$(metric R000070 '.verification.gfortran_accepted')
complete_compile=$(metric R000070 '.verification.fortran_compile_status')
complete_runtime=$(metric R000070 '.verification.runtime_test_status')
complete_mutation=$(metric R000070 '.verification.unsupported_mutation_rejected')
complete_boundary=$(metric R000070 '.verification.target_boundary')
construct_corpus_files=$(metric R000071 '.verification.corpus_files')
construct_physical_lines=$(metric R000071 '.verification.physical_meaningful_lines')
construct_logical=$(metric R000071 '.verification.expected_logical_statements')
construct_classified=$(metric R000071 '.verification.classified_logical_statements')
construct_linked=$(metric R000071 '.verification.source_linked_statements')
construct_joins=$(metric R000071 '.verification.continuation_joins')
construct_nesting_errors=$(metric R000071 '.verification.nesting_errors')
construct_max_depth=$(metric R000071 '.verification.max_nesting_depth')
construct_gfortran_accepted=$(metric R000071 '.verification.gfortran_accepted')
construct_compile=$(metric R000071 '.verification.fortran_compile_status')
construct_runtime=$(metric R000071 '.verification.runtime_test_status')
construct_mutation=$(metric R000071 '.verification.malformed_nesting_rejected')
construct_boundary=$(metric R000071 '.verification.target_boundary')
ast_corpus_files=$(metric R000072 '.verification.corpus_files')
ast_logical=$(metric R000072 '.verification.logical_statements')
ast_nodes=$(metric R000072 '.verification.ast_nodes')
ast_linked=$(metric R000072 '.verification.source_linked_nodes')
ast_roots=$(metric R000072 '.verification.root_nodes')
ast_parents=$(metric R000072 '.verification.parent_links')
ast_children=$(metric R000072 '.verification.child_links')
ast_errors=$(metric R000072 '.verification.ast_link_errors')
ast_depth=$(metric R000072 '.verification.max_ast_depth')
ast_compile=$(metric R000072 '.verification.fortran_compile_status')
ast_runtime=$(metric R000072 '.verification.runtime_test_status')
ast_mutation=$(metric R000072 '.verification.malformed_nesting_rejected')
ast_boundary=$(metric R000072 '.verification.target_boundary')
expression_statement_nodes=$(metric R000073 '.verification.statement_nodes')
expression_nodes=$(metric R000073 '.verification.expression_nodes')
expression_total_nodes=$(metric R000073 '.verification.total_nodes')
expression_linked_nodes=$(metric R000073 '.verification.source_linked_nodes')
expression_roots=$(metric R000073 '.verification.root_nodes')
expression_parents=$(metric R000073 '.verification.parent_links')
expression_children=$(metric R000073 '.verification.child_links')
expression_errors=$(metric R000073 '.verification.ast_link_errors')
expression_depth=$(metric R000073 '.verification.max_ast_depth')
expression_queries=$(metric R000073 '.verification.query_hits')
expression_unknown=$(metric R000073 '.verification.unknown_query_rejected')
expression_compile=$(metric R000073 '.verification.fortran_compile_status')
expression_runtime=$(metric R000073 '.verification.runtime_test_status')
expression_mutation=$(metric R000073 '.verification.malformed_nesting_rejected')
expression_boundary=$(metric R000073 '.verification.target_boundary')
subtree_files=$(metric R000074 '.verification.witness_files')
subtree_witnesses=$(metric R000074 '.verification.expression_witnesses')
subtree_leaves=$(metric R000074 '.verification.leaf_nodes')
subtree_names=$(metric R000074 '.verification.name_nodes')
subtree_literals=$(metric R000074 '.verification.literal_nodes')
subtree_operators=$(metric R000074 '.verification.operator_nodes')
subtree_linked=$(metric R000074 '.verification.source_linked_leaves')
subtree_parents=$(metric R000074 '.verification.subtree_parent_links')
subtree_errors=$(metric R000074 '.verification.subtree_link_errors')
subtree_depth=$(metric R000074 '.verification.max_subtree_depth')
subtree_queries=$(metric R000074 '.verification.known_witness_queries')
subtree_unknown=$(metric R000074 '.verification.unknown_witness_rejected')
subtree_compile=$(metric R000074 '.verification.fortran_compile_status')
subtree_runtime=$(metric R000074 '.verification.runtime_test_status')
subtree_mutation=$(metric R000074 '.verification.malformed_nesting_rejected')
subtree_boundary=$(metric R000074 '.verification.target_boundary')
precedence_files=$(metric R000075 '.verification.witness_files')
precedence_witnesses=$(metric R000075 '.verification.expression_witnesses')
precedence_internal=$(metric R000075 '.verification.internal_nodes')
precedence_leaves=$(metric R000075 '.verification.leaf_nodes')
precedence_binary=$(metric R000075 '.verification.binary_nodes')
precedence_unary=$(metric R000075 '.verification.unary_nodes')
precedence_arrays=$(metric R000075 '.verification.array_nodes')
precedence_names=$(metric R000075 '.verification.name_nodes')
precedence_literals=$(metric R000075 '.verification.literal_nodes')
precedence_linked=$(metric R000075 '.verification.source_linked_nodes')
precedence_parents=$(metric R000075 '.verification.subtree_parent_links')
precedence_errors=$(metric R000075 '.verification.subtree_link_errors')
precedence_mismatches=$(metric R000075 '.verification.tree_mismatches')
precedence_queries=$(metric R000075 '.verification.precedence_query_hits')
precedence_unknown=$(metric R000075 '.verification.unknown_query_rejected')
precedence_depth=$(metric R000075 '.verification.max_tree_depth')
precedence_compile=$(metric R000075 '.verification.fortran_compile_status')
precedence_runtime=$(metric R000075 '.verification.runtime_test_status')
precedence_mutation=$(metric R000075 '.verification.malformed_nesting_rejected')
precedence_boundary=$(metric R000075 '.verification.target_boundary')
coverage_files=$(metric R000076 '.verification.witness_files')
coverage_witnesses=$(metric R000076 '.verification.expression_witnesses')
coverage_gfortran=$(metric R000076 '.verification.gfortran_accepted')
coverage_internal=$(metric R000076 '.verification.internal_nodes')
coverage_leaves=$(metric R000076 '.verification.leaf_nodes')
coverage_binary=$(metric R000076 '.verification.binary_nodes')
coverage_unary=$(metric R000076 '.verification.unary_nodes')
coverage_arrays=$(metric R000076 '.verification.array_nodes')
coverage_calls=$(metric R000076 '.verification.function_reference_nodes')
coverage_names=$(metric R000076 '.verification.name_nodes')
coverage_literals=$(metric R000076 '.verification.literal_nodes')
coverage_linked=$(metric R000076 '.verification.source_linked_nodes')
coverage_parents=$(metric R000076 '.verification.subtree_parent_links')
coverage_errors=$(metric R000076 '.verification.subtree_link_errors')
coverage_mismatches=$(metric R000076 '.verification.tree_mismatches')
coverage_queries=$(metric R000076 '.verification.coverage_query_hits')
coverage_unknown=$(metric R000076 '.verification.unknown_query_rejected')
coverage_depth=$(metric R000076 '.verification.max_expression_depth')
coverage_compile=$(metric R000076 '.verification.fortran_compile_status')
coverage_runtime=$(metric R000076 '.verification.runtime_test_status')
coverage_mutation=$(metric R000076 '.verification.unsupported_operator_rejected')
coverage_boundary=$(metric R000076 '.verification.target_boundary')
acceptance_files=$(metric R000077 '.verification.corpus_files')
acceptance_expected=$(metric R000077 '.verification.expected_meaningful_lines')
acceptance_records=$(metric R000077 '.verification.accepted_records')
acceptance_linked=$(metric R000077 '.verification.source_linked_records')
acceptance_unsupported=$(metric R000077 '.verification.unsupported_records')
acceptance_diagnostics=$(metric R000077 '.verification.diagnostic_records')
acceptance_provenance=$(metric R000077 '.verification.diagnostic_provenance')
acceptance_mismatches=$(metric R000077 '.verification.complete_file_mismatches')
acceptance_gfortran=$(metric R000077 '.verification.gfortran_accepted')
acceptance_mutation=$(metric R000077 '.verification.gfortran_mutation_rejected')
acceptance_compile=$(metric R000077 '.verification.fortran_compile_status')
acceptance_runtime=$(metric R000077 '.verification.runtime_test_status')
acceptance_boundary=$(metric R000077 '.verification.target_boundary')
prose_unresolved=$(metric R000078 '.verification.unresolved_names')
prose_candidates=$(metric R000078 '.verification.candidate_spans')
prose_aliases=$(metric R000078 '.verification.alias_names')
prose_lexical=$(metric R000078 '.verification.lexical_class_names')
prose_metavariable=$(metric R000078 '.verification.metavariable_names')
prose_semantic=$(metric R000078 '.verification.semantic_role_names')
prose_ambiguous=$(metric R000078 '.verification.ambiguous_names')
prose_residue=$(metric R000078 '.verification.unresolved_after_patterns')
prose_linked=$(metric R000078 '.verification.source_linked_candidates')
prose_difference=$(metric R000078 '.verification.independent_difference')
prose_negative=$(metric R000078 '.verification.negative_control')
prose_boundary=$(metric R000078 '.verification.target_boundary')
bounded_logical_units=$(metric R000079 '.verification.logical_units')
bounded_table_rows=$(metric R000079 '.verification.table_rows')
bounded_candidates=$(metric R000079 '.verification.candidate_spans')
bounded_candidate_names=$(metric R000079 '.verification.candidate_names')
bounded_new_names=$(metric R000079 '.verification.new_names_over_e0069')
bounded_aliases=$(metric R000079 '.verification.alias_names')
bounded_lexical=$(metric R000079 '.verification.lexical_class_names')
bounded_metavariable=$(metric R000079 '.verification.metavariable_names')
bounded_semantic=$(metric R000079 '.verification.semantic_role_names')
bounded_ambiguous=$(metric R000079 '.verification.ambiguous_names')
bounded_residue=$(metric R000079 '.verification.unresolved_after_patterns')
bounded_linked=$(metric R000079 '.verification.source_linked_candidates')
bounded_difference=$(metric R000079 '.verification.independent_difference')
bounded_negative=$(metric R000079 '.verification.negative_control')
bounded_boundary=$(metric R000079 '.verification.target_boundary')
adjudicated_candidates=$(metric R000080 '.verification.candidate_spans')
adjudicated_accepted=$(metric R000080 '.verification.accepted_records')
adjudicated_retained=$(metric R000080 '.verification.retained_records')
adjudicated_aliases=$(metric R000080 '.verification.accepted_alias_records')
adjudicated_lexical=$(metric R000080 '.verification.accepted_lexical_class_records')
adjudicated_metavariable=$(metric R000080 '.verification.accepted_metavariable_records')
adjudicated_semantic=$(metric R000080 '.verification.accepted_semantic_role_records')
adjudicated_hashes=$(metric R000080 '.verification.source_hash_matches')
adjudicated_evidence=$(metric R000080 '.verification.source_evidence_matches')
adjudicated_inventory_difference=$(metric R000080 '.verification.candidate_inventory_difference')
adjudicated_difference=$(metric R000080 '.verification.independent_difference')
adjudicated_negative=$(metric R000080 '.verification.negative_control')
adjudicated_boundary=$(metric R000080 '.verification.target_boundary')
composition_d0019=$(metric R000081 '.verification.d0019_records')
composition_relations=$(metric R000081 '.verification.adjudicated_relation_records')
composition_merged=$(metric R000081 '.verification.merged_fact_records')
composition_retained=$(metric R000081 '.verification.retained_relations')
composition_unresolved=$(metric R000081 '.verification.unresolved_records')
composition_semantic=$(metric R000081 '.verification.semantic_facts_not_parser_aliases')
composition_projection=$(metric R000081 '.verification.parser_projection_records')
composition_hashes=$(metric R000081 '.verification.source_hash_matches')
composition_projection_difference=$(metric R000081 '.verification.projection_difference')
composition_difference=$(metric R000081 '.verification.independent_difference')
composition_negative=$(metric R000081 '.verification.negative_control')
composition_boundary=$(metric R000081 '.verification.target_boundary')
sidecar_facts=$(metric R000082 '.verification.composite_fact_records')
sidecar_semantic=$(metric R000082 '.verification.semantic_fact_records')
sidecar_projection=$(metric R000082 '.verification.parser_projection_records')
sidecar_fragments=$(metric R000082 '.verification.target_fragment_records')
sidecar_provenance=$(metric R000082 '.verification.target_provenance_records')
sidecar_leaks=$(metric R000082 '.verification.semantic_target_leaks')
sidecar_ebnf=$(metric R000082 '.verification.ebnf_status')
sidecar_antlr=$(metric R000082 '.verification.antlr_status')
sidecar_bison=$(metric R000082 '.verification.bison_status')
sidecar_treesitter=$(metric R000082 '.verification.treesitter_status')
sidecar_fortran=$(metric R000082 '.verification.direct_fortran_status')
sidecar_difference=$(metric R000082 '.verification.independent_difference')
sidecar_negative=$(metric R000082 '.verification.negative_control')
sidecar_boundary=$(metric R000082 '.verification.target_boundary')
integration_source=$(metric R000083 '.verification.source_syntax_records')
integration_syntax=$(metric R000083 '.verification.integrated_syntax_records')
integration_aliases=$(metric R000083 '.verification.alias_records')
integration_rewrites=$(metric R000083 '.verification.alias_reference_rewrites')
integration_semantic=$(metric R000083 '.verification.semantic_fact_records')
integration_overlap=$(metric R000083 '.verification.semantic_alias_overlap')
integration_leaks=$(metric R000083 '.verification.semantic_projection_leaks')
integration_unresolved_occurrences=$(metric R000083 '.verification.unresolved_reference_occurrences')
integration_unresolved_names=$(metric R000083 '.verification.unresolved_unique_names')
integration_export_ebnf=$(metric R000083 '.verification.export_ebnf_status')
integration_export_antlr=$(metric R000083 '.verification.export_antlr_status')
integration_export_bison=$(metric R000083 '.verification.export_bison_status')
integration_export_treesitter=$(metric R000083 '.verification.export_treesitter_status')
integration_antlr=$(metric R000083 '.verification.antlr_validate_status')
integration_bison=$(metric R000083 '.verification.bison_validate_status')
integration_treesitter=$(metric R000083 '.verification.treesitter_validate_status')
integration_dispatch=$(metric R000083 '.verification.dispatch_rows')
integration_dispatch_provenance=$(metric R000083 '.verification.dispatch_provenance_rows')
integration_collisions=$(metric R000083 '.verification.dispatch_label_collisions')
integration_fortran=$(metric R000083 '.verification.direct_fortran_status')
integration_difference=$(metric R000083 '.verification.independent_difference')
integration_negative=$(metric R000083 '.verification.negative_control')
integration_boundary=$(metric R000083 '.verification.wiring_boundary')
residue_records=$(metric R000084 '.verification.residue_records')
residue_semantic=$(metric R000084 '.verification.semantic_role_records')
residue_lexical=$(metric R000084 '.verification.lexical_class_records')
residue_metavariable=$(metric R000084 '.verification.metavariable_records')
residue_unresolved=$(metric R000084 '.verification.unresolved_records')
residue_missing=$(metric R000084 '.verification.missing_fact_records')
residue_aliases=$(metric R000084 '.verification.additional_alias_records')
residue_hashes=$(metric R000084 '.verification.source_hash_matches')
residue_evidence=$(metric R000084 '.verification.source_evidence_records')
residue_leaks=$(metric R000084 '.verification.semantic_projection_leaks')
residue_difference=$(metric R000084 '.verification.independent_difference')
residue_negative=$(metric R000084 '.verification.negative_control')
prose_unresolved=$(metric R000085 '.verification.unresolved_denominator')
prose_units=$(metric R000085 '.verification.logical_units')
prose_spans=$(metric R000085 '.verification.candidate_spans')
prose_names=$(metric R000085 '.verification.candidate_names')
prose_aliases=$(metric R000085 '.verification.alias_candidates')
prose_lexical=$(metric R000085 '.verification.lexical_candidates')
prose_metavariable=$(metric R000085 '.verification.metavariable_candidates')
prose_semantic=$(metric R000085 '.verification.semantic_role_candidates')
prose_residue=$(metric R000085 '.verification.unresolved_after_patterns')
prose_linked=$(metric R000085 '.verification.source_linked_candidates')
prose_difference=$(metric R000085 '.verification.independent_difference')
prose_negative=$(metric R000085 '.verification.negative_control')
candidate_adjudication_spans=$(metric R000086 '.verification.candidate_spans')
candidate_adjudication_accepted=$(metric R000086 '.verification.accepted_records')
candidate_adjudication_retained=$(metric R000086 '.verification.retained_records')
candidate_adjudication_semantic=$(metric R000086 '.verification.accepted_semantic_role_records')
candidate_adjudication_hashes=$(metric R000086 '.verification.source_hash_matches')
candidate_adjudication_evidence=$(metric R000086 '.verification.source_evidence_matches')
candidate_adjudication_inventory=$(metric R000086 '.verification.candidate_inventory_difference')
candidate_adjudication_difference=$(metric R000086 '.verification.independent_difference')
candidate_adjudication_negative=$(metric R000086 '.verification.negative_control')
retained_composition_residue=$(metric R000087 '.verification.residue_records')
retained_composition_retained=$(metric R000087 '.verification.retained_candidate_records')
retained_composition_no_evidence=$(metric R000087 '.verification.unresolved_no_evidence_records')
retained_composition_hashes=$(metric R000087 '.verification.source_hash_matches')
retained_composition_parser_targets=$(metric R000087 '.verification.parser_target_records')
retained_composition_leaks=$(metric R000087 '.verification.parser_leaks')
retained_composition_syntax=$(metric R000087 '.verification.integrated_syntax_records')
retained_composition_dispatch=$(metric R000087 '.verification.dispatch_rows')
retained_composition_dispatch_provenance=$(metric R000087 '.verification.dispatch_provenance_rows')
retained_composition_syntax_difference=$(metric R000087 '.verification.integrated_hash_difference')
retained_composition_dispatch_difference=$(metric R000087 '.verification.dispatch_hash_difference')
retained_composition_antlr=$(metric R000087 '.verification.export_antlr_validator_status')
retained_composition_bison=$(metric R000087 '.verification.export_bison_validator_status')
retained_composition_treesitter=$(metric R000087 '.verification.export_treesitter_validator_status')
retained_composition_fortran=$(metric R000087 '.verification.direct_fortran_status')
retained_composition_difference=$(metric R000087 '.verification.independent_difference')
retained_composition_negative=$(metric R000087 '.verification.negative_control')
complete_parser_profile_rows=$(metric R000088 '.verification.profile_rows')
complete_parser_profile_targets=$(metric R000088 '.verification.profile_parser_targets')
complete_parser_profile_hashes=$(metric R000088 '.verification.profile_source_hashes')
complete_parser_files=$(metric R000088 '.verification.complete_source_files')
complete_parser_accepted=$(metric R000088 '.verification.complete_accepted_records')
complete_parser_linked=$(metric R000088 '.verification.complete_source_linked_records')
complete_parser_ast_files=$(metric R000088 '.verification.ast_source_files')
complete_parser_ast_nodes=$(metric R000088 '.verification.ast_nodes')
complete_parser_ast_linked=$(metric R000088 '.verification.ast_source_linked_nodes')
complete_parser_ast_parents=$(metric R000088 '.verification.ast_parent_links')
complete_parser_ast_children=$(metric R000088 '.verification.ast_child_links')
complete_parser_ast_errors=$(metric R000088 '.verification.ast_link_errors')
complete_parser_diagnostics=$(metric R000088 '.verification.diagnostic_records')
complete_parser_diagnostic_linked=$(metric R000088 '.verification.diagnostic_source_linked')
complete_parser_gfortran_complete=$(metric R000088 '.verification.gfortran_complete_accepted')
complete_parser_gfortran_ast=$(metric R000088 '.verification.gfortran_ast_accepted')
complete_parser_compile=$(metric R000088 '.verification.fortran_compile_status')
complete_parser_runtime=$(metric R000088 '.verification.runtime_test_status')
complete_parser_difference=$(metric R000088 '.verification.independent_difference')
complete_parser_negative=$(metric R000088 '.verification.negative_control')
expression_facade_profile_rows=$(metric R000089 '.verification.profile_rows')
expression_facade_profile_targets=$(metric R000089 '.verification.profile_parser_targets')
expression_facade_files=$(metric R000089 '.verification.expression_source_files')
expression_facade_witnesses=$(metric R000089 '.verification.expression_witnesses')
expression_facade_gfortran=$(metric R000089 '.verification.gfortran_accepted')
expression_facade_internal=$(metric R000089 '.verification.internal_nodes')
expression_facade_leaf=$(metric R000089 '.verification.leaf_nodes')
expression_facade_binary=$(metric R000089 '.verification.binary_nodes')
expression_facade_unary=$(metric R000089 '.verification.unary_nodes')
expression_facade_array=$(metric R000089 '.verification.array_nodes')
expression_facade_calls=$(metric R000089 '.verification.function_reference_nodes')
expression_facade_names=$(metric R000089 '.verification.name_nodes')
expression_facade_literals=$(metric R000089 '.verification.literal_nodes')
expression_facade_linked=$(metric R000089 '.verification.source_linked_nodes')
expression_facade_parents=$(metric R000089 '.verification.subtree_parent_links')
expression_facade_errors=$(metric R000089 '.verification.subtree_link_errors')
expression_facade_mismatches=$(metric R000089 '.verification.tree_mismatches')
expression_facade_queries=$(metric R000089 '.verification.coverage_query_hits')
expression_facade_unknown=$(metric R000089 '.verification.unknown_query_rejected')
expression_facade_depth=$(metric R000089 '.verification.max_expression_depth')
expression_facade_compile=$(metric R000089 '.verification.fortran_compile_status')
expression_facade_runtime=$(metric R000089 '.verification.runtime_test_status')
expression_facade_mutation=$(metric R000089 '.verification.unsupported_operator_rejected')
expression_facade_difference=$(metric R000089 '.verification.independent_difference')
expression_facade_negative=$(metric R000089 '.verification.negative_control')
semantic_inventory_unresolved=$(metric R000090 '.verification.unresolved_names')
semantic_inventory_spans=$(metric R000090 '.verification.candidate_spans')
semantic_inventory_definition_spans=$(metric R000090 '.verification.definition_candidate_spans')
semantic_inventory_relation_spans=$(metric R000090 '.verification.relation_candidate_spans')
semantic_inventory_constraint_spans=$(metric R000090 '.verification.constraint_candidate_spans')
semantic_inventory_definition_names=$(metric R000090 '.verification.definition_candidate_names')
semantic_inventory_relation_names=$(metric R000090 '.verification.relation_candidate_names')
semantic_inventory_constraint_names=$(metric R000090 '.verification.constraint_candidate_names')
semantic_inventory_ambiguous=$(metric R000090 '.verification.ambiguous_names')
semantic_inventory_residue=$(metric R000090 '.verification.unresolved_after_patterns')
semantic_inventory_members=$(metric R000090 '.verification.core0_closure_members')
semantic_inventory_constraints=$(metric R000090 '.verification.core0_constraint_records')
semantic_inventory_linked_candidates=$(metric R000090 '.verification.source_linked_candidates')
semantic_inventory_linked_constraints=$(metric R000090 '.verification.source_linked_constraints')
semantic_inventory_facts=$(metric R000090 '.verification.accepted_standardir_facts')
semantic_inventory_difference=$(metric R000090 '.verification.independent_candidate_difference')
semantic_inventory_constraint_difference=$(metric R000090 '.verification.independent_constraint_difference')
semantic_inventory_negative=$(metric R000090 '.verification.negative_control')
semantic_adjudication_candidates=$(metric R000091 '.verification.candidate_spans')
semantic_adjudication_accepted=$(metric R000091 '.verification.accepted_records')
semantic_adjudication_lexical=$(metric R000091 '.verification.accepted_lexical_class_records')
semantic_adjudication_metavariable=$(metric R000091 '.verification.accepted_metavariable_records')
semantic_adjudication_semantic=$(metric R000091 '.verification.accepted_semantic_role_records')
semantic_adjudication_retained=$(metric R000091 '.verification.retained_constraint_candidates')
semantic_adjudication_constraints=$(metric R000091 '.verification.unresolved_body_constraint_records')
semantic_adjudication_linked_candidates=$(metric R000091 '.verification.source_linked_candidates')
semantic_adjudication_linked_constraints=$(metric R000091 '.verification.source_linked_constraints')
semantic_adjudication_facts=$(metric R000091 '.verification.accepted_standardir_resolution_facts')
semantic_adjudication_formalized=$(metric R000091 '.verification.formalized_constraint_bodies')
semantic_adjudication_projections=$(metric R000091 '.verification.parser_projection_records')
semantic_adjudication_difference=$(metric R000091 '.verification.independent_candidate_difference')
semantic_adjudication_constraint_difference=$(metric R000091 '.verification.independent_constraint_difference')
semantic_adjudication_evidence=$(metric R000091 '.verification.source_evidence_matches')
semantic_adjudication_negative=$(metric R000091 '.verification.negative_control')
constraint_formalization_eligible=$(metric R000092 '.verification.eligible_constraints')
constraint_formalization_selected=$(metric R000092 '.verification.selected_constraints')
constraint_formalization_predicates=$(metric R000092 '.verification.normalized_predicates')
constraint_formalization_resolved=$(metric R000092 '.verification.resolved_constraints')
constraint_formalization_unresolved=$(metric R000092 '.verification.unresolved_constraints')
constraint_formalization_disputed=$(metric R000092 '.verification.disputed_constraints')
constraint_formalization_hashes=$(metric R000092 '.verification.source_hash_matches')
constraint_formalization_evidence=$(metric R000092 '.verification.source_evidence_matches')
constraint_formalization_required=$(metric R000092 '.verification.required_fact_records')
constraint_formalization_provided=$(metric R000092 '.verification.provided_fact_records')
constraint_formalization_edges=$(metric R000092 '.verification.dependency_edges')
constraint_formalization_order_difference=$(metric R000092 '.verification.topological_order_difference')
constraint_formalization_difference=$(metric R000092 '.verification.independent_normalization_difference')
constraint_formalization_projections=$(metric R000092 '.verification.parser_projection_records')
constraint_formalization_negative=$(metric R000092 '.verification.negative_control')
cross_clause_eligible=$(metric R000093 '.verification.eligible_constraints')
cross_clause_selected=$(metric R000093 '.verification.selected_constraints')
cross_clause_predicates=$(metric R000093 '.verification.normalized_predicates')
cross_clause_resolved=$(metric R000093 '.verification.resolved_constraints')
cross_clause_unresolved=$(metric R000093 '.verification.unresolved_constraints')
cross_clause_disputed=$(metric R000093 '.verification.disputed_constraints')
cross_clause_hashes=$(metric R000093 '.verification.source_hash_matches')
cross_clause_evidence=$(metric R000093 '.verification.source_evidence_matches')
cross_clause_required=$(metric R000093 '.verification.required_fact_records')
cross_clause_provided=$(metric R000093 '.verification.provided_fact_records')
cross_clause_edges=$(metric R000093 '.verification.dependency_edges')
cross_clause_order_difference=$(metric R000093 '.verification.topological_order_difference')
cross_clause_difference=$(metric R000093 '.verification.independent_normalization_difference')
cross_clause_projections=$(metric R000093 '.verification.parser_projection_records')
cross_clause_negative=$(metric R000093 '.verification.negative_control')

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

## E0049 unified partial composite input

| Quantity | Value |
|---|---:|
| Source resolution records | $composite_resolution_records |
| Normalized reference names | $composite_normalized_names |
| Accepted projection records | $composite_projection_records |
| Projection reference replacements | $composite_projection_occurrences |
| R401/R403 inventory records | $composite_expansions |
| Non-overlapping expansion refs retained unresolved | $composite_unresolved_expansions |
| R402/R403 overlap records | $composite_conflicts |
| Independent conflict-set difference | $composite_conflict_difference |
| Final syntax records | $composite_syntax_records |
| Records with source hash | $composite_source_matches |
| Composition status | $composite_status |
| Controlled family mutation | $composite_negative_control |

## E0050 pending representation comparison

| Quantity | Value |
|---|---:|
| Candidate strategies | $candidate_strategies |
| R402/R403 overlap terms | $candidate_overlap_terms |
| Candidate matrix rows | $candidate_rows |
| Lossy alias-precedence rows | $candidate_lossy |
| Lossless expansion-precedence rows | $candidate_expansion_lossless |
| Lossless unresolved-composite rows | $candidate_unresolved_lossless |
| Parser-ready candidates | $candidate_parser_ready |
| Representation selection | $candidate_selection |
| Independent difference | $candidate_difference |
| Controlled mutation | $candidate_negative_control |

## E0051 independent target-tool validation

| Quantity | Value |
|---|---:|
| ANTLR4 definitions | $target_antlr_definitions |
| Bison definitions | $target_bison_definitions |
| tree-sitter definitions | $target_treesitter_definitions |
| ANTLR4 exit status | $target_antlr_status |
| ANTLR4 unresolved names | $target_antlr_unresolved |
| Bison exit status | $target_bison_status |
| Bison unresolved names | $target_bison_unresolved |
| tree-sitter exit status | $target_treesitter_status |
| tree-sitter structural error | $target_treesitter_structural |
| ANTLR4/Bison unresolved-set difference | $target_set_difference |
| All target statuses reject | $target_status_agreement |
| Controlled definition mutation | $target_negative_control |

## E0052 grouped erratum composition

| Quantity | Value |
|---|---:|
| Errata repairs | $grouped_errata_repairs |
| Optional grouping witnesses | $grouped_optional_repairs |
| ANTLR4 exit status | $grouped_antlr_status |
| Bison exit status | $grouped_bison_status |
| tree-sitter exit status | $grouped_treesitter_status |
| tree-sitter structural error | $grouped_treesitter_structural |
| ANTLR4 unresolved names | $grouped_antlr_unresolved |
| Bison unresolved names | $grouped_bison_unresolved |
| ANTLR4/Bison unresolved-set difference | $grouped_set_difference |
| Controlled grouping mutation | $grouped_negative_control |

## E0053 source-provenance residue partition

| Quantity | Value |
|---|---:|
| Unresolved target names | $residual_target_names |
| R401 expansion names | $residual_r401 |
| R403 expansion names | $residual_r403 |
| Expansion names total | $residual_expansion |
| Lexical-class names | $residual_lexical |
| Metavariable names | $residual_metavariable |
| Ambiguous Unicode or quotation names | $residual_unicode |
| Source metadata records | $residual_metadata |
| Open decision groups | $residual_open_decisions |
| Controlled bucket mutation | $residual_negative_control |

## External behavioral baseline

| Quantity | Value |
|---|---:|
| Fixed fixtures | $(metric R000050 '.verification.cases_declared') |
| Compiler invocations | $(metric R000050 '.verification.compiler_invocations') |
| Cases with agreement across LFortran, Flang, and gfortran | $(metric R000050 '.verification.all_three_agree_cases') |
| Cases with disagreement | $(metric R000050 '.verification.disagreement_cases') |

## E0055 accepted deterministic projection

| Quantity | Value |
|---|---:|
| Source syntax records | $accepted_projection_source |
| Generated syntax records | $accepted_projection_generated |
| R401 typed expansions | $accepted_projection_r401 |
| R403 typed expansions | $accepted_projection_r403 |
| Compositional overlap records | $accepted_projection_overlaps |
| Lexical schema records | $accepted_projection_lexical |
| Lexical schema records projected | $accepted_projection_lexical_projected |
| Lexical records retained unresolved | $accepted_projection_lexical_unresolved |
| ANTLR4 exit status | $accepted_projection_antlr |
| Bison exit status | $accepted_projection_bison |
| tree-sitter exit status | $accepted_projection_treesitter |
| ANTLR4 unresolved names | $accepted_projection_antlr_unresolved |
| Bison unresolved names | $accepted_projection_bison_unresolved |
| tree-sitter structural error | $accepted_projection_treesitter_structural |
| Target boundary | $accepted_projection_target_boundary |
| Controlled projection mutation | $accepted_projection_negative |

## E0056 deterministic target-export normalization

| Quantity | Value |
|---|---:|
| ANTLR4 exit status | $normalized_target_antlr |
| Bison exit status | $normalized_target_bison |
| tree-sitter exit status | $normalized_target_treesitter |
| Left-recursion groups normalized | $normalized_target_recursion |
| Nullable wrappers inlined | $normalized_target_nullable |
| Explicit tree-sitter conflict groups | $normalized_target_conflicts |
| ANTLR4 warnings retained | $normalized_target_antlr_warnings |
| Bison warnings retained | $normalized_target_bison_warnings |
| Unresolved target names | $normalized_target_unresolved |
| Next tree-sitter conflict | $normalized_target_next_conflict |
| Target boundary | $normalized_target_boundary |
| Controlled normalizer mutation | $normalized_target_negative |

## E0057 deterministic direct-parser wiring

| Quantity | Value |
|---|---:|
| Source syntax records | $direct_source |
| Composite syntax records | $direct_composite |
| Unique left-hand sides | $direct_lhs |
| Dispatch rows | $direct_dispatch |
| Generated procedures | $direct_procedures |
| Duplicate dispatch labels | $direct_duplicates |
| Provenance rows | $direct_provenance |
| Unresolved references | $direct_unresolved |
| Fortran compile status | $direct_compile |
| Wiring boundary | $direct_boundary |
| Controlled wiring mutation | $direct_negative |

## E0058 source-linked diagnostic lookup

| Quantity | Value |
|---|---:|
| Composite syntax records | $diagnostic_records |
| Diagnostic rows | $diagnostic_rows |
| Rows with page, byte span, and source hash | $diagnostic_spans |
| Known source lookup | $diagnostic_known |
| Unknown source rejected | $diagnostic_unknown |
| Fortran compile status | $diagnostic_compile |
| Runtime test status | $diagnostic_runtime |
| Diagnostic boundary | $diagnostic_boundary |
| Controlled span mutation | $diagnostic_negative |

## E0059 generated top-level parser operation

| Quantity | Value |
|---|---:|
| Real corpus files | $local_corpus_files |
| Expected top-level units | $local_expected_units |
| Classified units | $local_classified_units |
| Source-linked units | $local_source_linked_units |
| Unit mismatches | $local_unit_mismatches |
| GNU Fortran accepted files | $local_gfortran_accepted |
| Fortran compile status | $local_compile |
| Runtime test status | $local_runtime |
| Parser-operation boundary | $local_boundary |
| Controlled unit mutation | $local_negative |

## E0060 generated statement operation

| Quantity | Value |
|---|---:|
| Real corpus files | $statement_corpus_files |
| Expected statement witnesses | $statement_expected |
| Classified witnesses | $statement_classified |
| Source-linked witnesses | $statement_linked |
| Witness mismatches | $statement_mismatches |
| Fortran compile status | $statement_compile |
| Runtime test status | $statement_runtime |
| Statement-operation boundary | $statement_boundary |
| Controlled statement mutation | $statement_negative |

## E0061 generated complete-source operation

| Quantity | Value |
|---|---:|
| Real corpus files | $complete_corpus_files |
| Expected meaningful lines | $complete_expected_lines |
| Classified meaningful lines | $complete_classified_lines |
| Source-linked lines | $complete_linked_lines |
| Line mismatches | $complete_mismatches |
| GNU Fortran accepted files | $complete_gfortran_accepted |
| Fortran compile status | $complete_compile |
| Runtime test status | $complete_runtime |
| Unsupported mutation rejected | $complete_mutation |
| Complete-source boundary | $complete_boundary |

## E0062 generated logical-statement operation

| Quantity | Value |
|---|---:|
| Real corpus files | $construct_corpus_files |
| Meaningful physical lines | $construct_physical_lines |
| Logical statements | $construct_logical |
| Classified logical statements | $construct_classified |
| Source-linked statements | $construct_linked |
| Continuation joins | $construct_joins |
| Nesting errors | $construct_nesting_errors |
| Maximum nesting depth | $construct_max_depth |
| GNU Fortran accepted files | $construct_gfortran_accepted |
| Fortran compile status | $construct_compile |
| Runtime test status | $construct_runtime |
| Malformed nesting rejected | $construct_mutation |
| Logical-construct boundary | $construct_boundary |

## E0063 generated source-linked AST forest

| Quantity | Value |
|---|---:|
| Real corpus files | $ast_corpus_files |
| Logical statements | $ast_logical |
| AST nodes | $ast_nodes |
| Source-linked nodes | $ast_linked |
| Root nodes | $ast_roots |
| Parent links | $ast_parents |
| Child links | $ast_children |
| AST link errors | $ast_errors |
| Maximum AST depth | $ast_depth |
| Fortran compile status | $ast_compile |
| Runtime test status | $ast_runtime |
| Malformed nesting rejected | $ast_mutation |
| Source-linked AST boundary | $ast_boundary |

## E0064 generated expression AST children and source queries

| Quantity | Value |
|---|---:|
| Statement nodes | $expression_statement_nodes |
| Expression nodes | $expression_nodes |
| Total nodes | $expression_total_nodes |
| Source-linked nodes | $expression_linked_nodes |
| Root nodes | $expression_roots |
| Parent links | $expression_parents |
| Child links | $expression_children |
| AST link errors | $expression_errors |
| Maximum AST depth | $expression_depth |
| Known query hits | $expression_queries |
| Unknown query rejected | $expression_unknown |
| Fortran compile status | $expression_compile |
| Runtime test status | $expression_runtime |
| Malformed nesting rejected | $expression_mutation |
| Expression AST query boundary | $expression_boundary |

## E0065 generated recursive expression subtrees

| Quantity | Value |
|---|---:|
| Witness files | $subtree_files |
| Expression witnesses | $subtree_witnesses |
| Token leaves | $subtree_leaves |
| Name leaves | $subtree_names |
| Literal leaves | $subtree_literals |
| Operator leaves | $subtree_operators |
| Source-linked leaves | $subtree_linked |
| Subtree parent links | $subtree_parents |
| Subtree link errors | $subtree_errors |
| Maximum subtree depth | $subtree_depth |
| Known witness queries | $subtree_queries |
| Unknown witness rejected | $subtree_unknown |
| Fortran compile status | $subtree_compile |
| Runtime test status | $subtree_runtime |
| Malformed nesting rejected | $subtree_mutation |
| Recursive subtree boundary | $subtree_boundary |

## E0066 generated precedence-shaped expression trees

| Quantity | Value |
|---|---:|
| Witness files | $precedence_files |
| Expression witnesses | $precedence_witnesses |
| Internal nodes | $precedence_internal |
| Leaf nodes | $precedence_leaves |
| Binary nodes | $precedence_binary |
| Unary nodes | $precedence_unary |
| Array-constructor nodes | $precedence_arrays |
| Name nodes | $precedence_names |
| Literal nodes | $precedence_literals |
| Source-linked nodes | $precedence_linked |
| Parent links | $precedence_parents |
| Link errors | $precedence_errors |
| Tree mismatches | $precedence_mismatches |
| Known precedence queries | $precedence_queries |
| Unknown query rejected | $precedence_unknown |
| Maximum tree depth | $precedence_depth |
| Fortran compile status | $precedence_compile |
| Runtime test status | $precedence_runtime |
| Malformed nesting rejected | $precedence_mutation |
| Precedence tree boundary | $precedence_boundary |

## E0067 generated expression operator and literal coverage

| Quantity | Value |
|---|---:|
| Witness files | $coverage_files |
| Expression witnesses | $coverage_witnesses |
| GNU Fortran syntax-accepted files | $coverage_gfortran |
| Internal nodes | $coverage_internal |
| Leaf nodes | $coverage_leaves |
| Binary nodes | $coverage_binary |
| Unary nodes | $coverage_unary |
| Array-constructor nodes | $coverage_arrays |
| Function-reference nodes | $coverage_calls |
| Name nodes | $coverage_names |
| Literal nodes | $coverage_literals |
| Source-linked nodes | $coverage_linked |
| Parent links | $coverage_parents |
| Link errors | $coverage_errors |
| Tree mismatches | $coverage_mismatches |
| Known coverage queries | $coverage_queries |
| Unknown query rejected | $coverage_unknown |
| Maximum expression depth | $coverage_depth |
| Fortran compile status | $coverage_compile |
| Runtime test status | $coverage_runtime |
| Unsupported operator rejected | $coverage_mutation |
| Expression coverage boundary | $coverage_boundary |

## E0068 lossless complete-source acceptance

| Quantity | Value |
|---|---:|
| Corpus files | $acceptance_files |
| Expected meaningful lines | $acceptance_expected |
| Accepted records | $acceptance_records |
| Source-linked accepted records | $acceptance_linked |
| Unsupported residue records | $acceptance_unsupported |
| Diagnostic records | $acceptance_diagnostics |
| Diagnostics with provenance | $acceptance_provenance |
| Complete-file mismatches | $acceptance_mismatches |
| GNU Fortran accepted files | $acceptance_gfortran |
| GNU Fortran mutation rejected | $acceptance_mutation |
| Fortran compile status | $acceptance_compile |
| Runtime test status | $acceptance_runtime |
| Lossless acceptance boundary | $acceptance_boundary |

## E0069 deterministic normative-prose evidence inventory

| Quantity | Value |
|---|---:|
| E0022 unresolved names | $prose_unresolved |
| Candidate source spans | $prose_candidates |
| Direct-alias names | $prose_aliases |
| Lexical-class names | $prose_lexical |
| Metavariable names | $prose_metavariable |
| Semantic-role names | $prose_semantic |
| Ambiguous names | $prose_ambiguous |
| Unresolved after exact patterns | $prose_residue |
| Source-linked candidates | $prose_linked |
| Independent candidate-set difference | $prose_difference |
| Controlled mutation | $prose_negative |
| Normative-prose boundary | $prose_boundary |

## E0070 bounded normative-prose evidence inventory

| Quantity | Value |
|---|---:|
| E0022 unresolved names | $prose_unresolved |
| Bounded logical units | $bounded_logical_units |
| Bounded table rows | $bounded_table_rows |
| Candidate source spans | $bounded_candidates |
| Names with candidate evidence | $bounded_candidate_names |
| New names over E0069 | $bounded_new_names |
| Direct-alias names | $bounded_aliases |
| Lexical-class names | $bounded_lexical |
| Metavariable names | $bounded_metavariable |
| Semantic-role names | $bounded_semantic |
| Ambiguous names | $bounded_ambiguous |
| Unresolved after bounded patterns | $bounded_residue |
| Source-linked candidates | $bounded_linked |
| Independent candidate-set difference | $bounded_difference |
| Controlled mutation | $bounded_negative |
| Normative-prose boundary | $bounded_boundary |

## E0071 source-controlled normative-prose adjudication

| Quantity | Value |
|---|---:|
| Candidate spans | $adjudicated_candidates |
| Accepted typed relations | $adjudicated_accepted |
| Retained candidate/residue records | $adjudicated_retained |
| Accepted alias records | $adjudicated_aliases |
| Accepted lexical-class records | $adjudicated_lexical |
| Accepted metavariable records | $adjudicated_metavariable |
| Accepted semantic-role records | $adjudicated_semantic |
| Records with source hash | $adjudicated_hashes |
| Records with source evidence | $adjudicated_evidence |
| Candidate inventory difference | $adjudicated_inventory_difference |
| Independent difference | $adjudicated_difference |
| Controlled mutation | $adjudicated_negative |
| Adjudication boundary | $adjudicated_boundary |

## E0072 D0019 and adjudicated-relation composition

| Quantity | Value |
|---|---:|
| D0019 base records | $composition_d0019 |
| Adjudicated relation records | $composition_relations |
| Merged fact records | $composition_merged |
| Retained adjudicated candidates | $composition_retained |
| E0070 unresolved residue | $composition_unresolved |
| Semantic facts excluded from parser aliases | $composition_semantic |
| Parser projection records | $composition_projection |
| Records with source hash | $composition_hashes |
| Parser projection difference | $composition_projection_difference |
| Independent difference | $composition_difference |
| Controlled mutation | $composition_negative |
| Composition boundary | $composition_boundary |

## E0073 parser-resolution sidecar target validation

| Quantity | Value |
|---|---:|
| Composite fact records | $sidecar_facts |
| Semantic-role fact records | $sidecar_semantic |
| Parser-projection records | $sidecar_projection |
| Records emitted per target | $sidecar_fragments |
| Target provenance instances | $sidecar_provenance |
| Semantic target leaks | $sidecar_leaks |
| EBNF status | $sidecar_ebnf |
| ANTLR4 status | $sidecar_antlr |
| Bison status | $sidecar_bison |
| tree-sitter status | $sidecar_treesitter |
| Direct Fortran status | $sidecar_fortran |
| Independent difference | $sidecar_difference |
| Controlled mutation | $sidecar_negative |
| Target boundary | $sidecar_boundary |

## E0074 full-syntax alias integration

| Quantity | Value |
|---|---:|
| Source syntax records | $integration_source |
| Integrated syntax records | $integration_syntax |
| Accepted alias records | $integration_aliases |
| Alias reference rewrites | $integration_rewrites |
| Semantic fact records | $integration_semantic |
| Source-term alias/semantic overlap | $integration_overlap |
| Semantic projection leaks | $integration_leaks |
| Unresolved reference occurrences | $integration_unresolved_occurrences |
| Unresolved unique names | $integration_unresolved_names |
| EBNF export status | $integration_export_ebnf |
| ANTLR4 export status | $integration_export_antlr |
| Bison export status | $integration_export_bison |
| tree-sitter export status | $integration_export_treesitter |
| ANTLR4 validator status | $integration_antlr |
| Bison validator status | $integration_bison |
| tree-sitter validator status | $integration_treesitter |
| Direct dispatch rows | $integration_dispatch |
| Dispatch provenance rows | $integration_dispatch_provenance |
| Dispatch label collisions | $integration_collisions |
| Direct Fortran status | $integration_fortran |
| Independent difference | $integration_difference |
| Controlled mutation | $integration_negative |
| Wiring boundary | $integration_boundary |

## E0075 post-alias residue classification

| Quantity | Value |
|---|---:|
| Residue records | $residue_records |
| Semantic-role records | $residue_semantic |
| Lexical-class records | $residue_lexical |
| Metavariable records | $residue_metavariable |
| Unresolved records | $residue_unresolved |
| Missing fact records | $residue_missing |
| Additional alias records | $residue_aliases |
| Records with source hash | $residue_hashes |
| Records with source evidence | $residue_evidence |
| Semantic projection leaks | $residue_leaks |
| Independent difference | $residue_difference |
| Controlled mutation | $residue_negative |

## E0076 deterministic prose evidence for unresolved residue

| Quantity | Value |
|---|---:|
| Unresolved denominator | $prose_unresolved |
| Logical units | $prose_units |
| Candidate spans | $prose_spans |
| Candidate names | $prose_names |
| Alias candidates | $prose_aliases |
| Lexical candidates | $prose_lexical |
| Metavariable candidates | $prose_metavariable |
| Semantic-role candidates | $prose_semantic |
| Names unresolved after patterns | $prose_residue |
| Source-linked candidates | $prose_linked |
| Independent difference | $prose_difference |
| Controlled mutation | $prose_negative |

## E0077 source-controlled candidate adjudication

| Quantity | Value |
|---|---:|
| Candidate spans | $candidate_adjudication_spans |
| Accepted records | $candidate_adjudication_accepted |
| Retained records | $candidate_adjudication_retained |
| Accepted semantic-role records | $candidate_adjudication_semantic |
| Records with source hash | $candidate_adjudication_hashes |
| Records with source evidence | $candidate_adjudication_evidence |
| Candidate inventory difference | $candidate_adjudication_inventory |
| Independent difference | $candidate_adjudication_difference |
| Controlled mutation | $candidate_adjudication_negative |

## E0078 retained-residue composition

| Quantity | Value |
|---|---:|
| Residue records | $retained_composition_residue |
| Retained contextual candidates | $retained_composition_retained |
| Unresolved without evidence | $retained_composition_no_evidence |
| Records with source hash | $retained_composition_hashes |
| Residue parser targets | $retained_composition_parser_targets |
| Parser leaks | $retained_composition_leaks |
| Integrated syntax records | $retained_composition_syntax |
| Dispatch rows | $retained_composition_dispatch |
| Dispatch provenance rows | $retained_composition_dispatch_provenance |
| Integrated hash difference | $retained_composition_syntax_difference |
| Dispatch hash difference | $retained_composition_dispatch_difference |
| ANTLR4 validator status | $retained_composition_antlr |
| Bison validator status | $retained_composition_bison |
| tree-sitter validator status | $retained_composition_treesitter |
| Direct Fortran status | $retained_composition_fortran |
| Independent difference | $retained_composition_difference |
| Controlled mutation | $retained_composition_negative |

## E0079 generated complete-parser facade

| Quantity | Value |
|---|---:|
| Profile rows | $complete_parser_profile_rows |
| Profile parser targets | $complete_parser_profile_targets |
| Profile source hashes | $complete_parser_profile_hashes |
| Complete-source files | $complete_parser_files |
| Accepted complete-source records | $complete_parser_accepted |
| Source-linked complete-source records | $complete_parser_linked |
| AST corpus files | $complete_parser_ast_files |
| AST nodes | $complete_parser_ast_nodes |
| Source-linked AST nodes | $complete_parser_ast_linked |
| AST parent links | $complete_parser_ast_parents |
| AST child links | $complete_parser_ast_children |
| AST link errors | $complete_parser_ast_errors |
| Diagnostic records | $complete_parser_diagnostics |
| Source-linked diagnostics | $complete_parser_diagnostic_linked |
| GNU Fortran complete-source files accepted | $complete_parser_gfortran_complete |
| GNU Fortran AST files accepted | $complete_parser_gfortran_ast |
| Fortran compile status | $complete_parser_compile |
| Runtime test status | $complete_parser_runtime |
| Independent difference | $complete_parser_difference |
| Controlled mutation | $complete_parser_negative |

## E0080 generated expression and precedence facade

| Quantity | Value |
|---|---:|
| Profile rows | $expression_facade_profile_rows |
| Profile parser targets | $expression_facade_profile_targets |
| Expression source files | $expression_facade_files |
| Expression witnesses | $expression_facade_witnesses |
| GNU Fortran files accepted | $expression_facade_gfortran |
| Internal nodes | $expression_facade_internal |
| Leaf nodes | $expression_facade_leaf |
| Binary nodes | $expression_facade_binary |
| Unary nodes | $expression_facade_unary |
| Array-constructor nodes | $expression_facade_array |
| Function-reference nodes | $expression_facade_calls |
| Name nodes | $expression_facade_names |
| Literal nodes | $expression_facade_literals |
| Source-linked nodes | $expression_facade_linked |
| Parent links | $expression_facade_parents |
| Link errors | $expression_facade_errors |
| Tree mismatches | $expression_facade_mismatches |
| Known queries | $expression_facade_queries |
| Unknown queries rejected | $expression_facade_unknown |
| Maximum expression depth | $expression_facade_depth |
| Fortran compile status | $expression_facade_compile |
| Runtime test status | $expression_facade_runtime |
| Unsupported operator rejected | $expression_facade_mutation |
| Independent difference | $expression_facade_difference |
| Controlled mutation | $expression_facade_negative |

## E0081 Core 0 semantic candidate inventory

| Quantity | Value |
|---|---:|
| Unresolved-name denominator | $semantic_inventory_unresolved |
| Candidate spans | $semantic_inventory_spans |
| Definition candidate spans | $semantic_inventory_definition_spans |
| Relation candidate spans | $semantic_inventory_relation_spans |
| Constraint candidate spans | $semantic_inventory_constraint_spans |
| Definition candidate names | $semantic_inventory_definition_names |
| Relation candidate names | $semantic_inventory_relation_names |
| Constraint candidate names | $semantic_inventory_constraint_names |
| Ambiguous names | $semantic_inventory_ambiguous |
| Names unresolved after patterns | $semantic_inventory_residue |
| Core 0 closure members | $semantic_inventory_members |
| Core 0-associated numbered constraints | $semantic_inventory_constraints |
| Source-linked candidates | $semantic_inventory_linked_candidates |
| Source-linked constraints | $semantic_inventory_linked_constraints |
| Accepted StandardIR facts | $semantic_inventory_facts |
| Independent candidate difference | $semantic_inventory_difference |
| Independent constraint difference | $semantic_inventory_constraint_difference |
| Controlled mutation | $semantic_inventory_negative |

## E0082 source-controlled semantic adjudication

| Quantity | Value |
|---|---:|
| Candidate spans adjudicated | $semantic_adjudication_candidates |
| Accepted typed records | $semantic_adjudication_accepted |
| Accepted lexical-class records | $semantic_adjudication_lexical |
| Accepted metavariable records | $semantic_adjudication_metavariable |
| Accepted semantic-role records | $semantic_adjudication_semantic |
| Retained modal constraint candidates | $semantic_adjudication_retained |
| Unresolved-body constraint records | $semantic_adjudication_constraints |
| Source-linked candidates | $semantic_adjudication_linked_candidates |
| Source-linked constraints | $semantic_adjudication_linked_constraints |
| Accepted StandardIR resolution facts | $semantic_adjudication_facts |
| Formalized constraint bodies | $semantic_adjudication_formalized |
| Parser projection records | $semantic_adjudication_projections |
| Source evidence matches | $semantic_adjudication_evidence |
| Independent candidate difference | $semantic_adjudication_difference |
| Independent constraint difference | $semantic_adjudication_constraint_difference |
| Controlled mutation | $semantic_adjudication_negative |

## E0083 bounded Core 0 constraint formalization

| Quantity | Value |
|---|---:|
| Eligible constraints | $constraint_formalization_eligible |
| Selected constraints | $constraint_formalization_selected |
| Normalized predicates | $constraint_formalization_predicates |
| Resolved constraints | $constraint_formalization_resolved |
| Unresolved constraints | $constraint_formalization_unresolved |
| Disputed constraints | $constraint_formalization_disputed |
| Source-hash matches | $constraint_formalization_hashes |
| Source-evidence matches | $constraint_formalization_evidence |
| Required fact records | $constraint_formalization_required |
| Provided fact records | $constraint_formalization_provided |
| Dependency edges | $constraint_formalization_edges |
| Topological-order difference | $constraint_formalization_order_difference |
| Independent normalization difference | $constraint_formalization_difference |
| Parser projection records | $constraint_formalization_projections |
| Controlled mutation | $constraint_formalization_negative |

## E0084 deterministic cross-clause fact formalization

| Quantity | Value |
|---|---:|
| Eligible constraints | $cross_clause_eligible |
| Selected constraints | $cross_clause_selected |
| Normalized predicates | $cross_clause_predicates |
| Resolved constraints | $cross_clause_resolved |
| Unresolved constraints | $cross_clause_unresolved |
| Disputed constraints | $cross_clause_disputed |
| Source-hash matches | $cross_clause_hashes |
| Source-evidence matches | $cross_clause_evidence |
| Required fact records | $cross_clause_required |
| Provided fact records | $cross_clause_provided |
| Dependency edges | $cross_clause_edges |
| Topological-order difference | $cross_clause_order_difference |
| Independent normalization difference | $cross_clause_difference |
| Parser projection records | $cross_clause_projections |
| Controlled mutation | $cross_clause_negative |

## E0054 D0027 lexical candidate comparison

| Quantity | Value |
|---|---:|
| Candidate strategies | $lexical_candidate_strategies |
| Residue terms | $lexical_candidate_residue |
| Candidate matrix rows | $lexical_candidate_rows |
| Lexical rows projected | $lexical_candidate_lexical |
| Ambiguous Unicode rows retained | $lexical_candidate_unicode |
| Primitive lexer export rows | $lexical_candidate_primitive |
| Schema lexical-fact rows | $lexical_candidate_schema |
| Retained-unresolved rows | $lexical_candidate_unresolved |
| Complete projection candidates | $lexical_candidate_complete |
| Representation selection | $lexical_candidate_selection |
| Controlled candidate mutation | $lexical_candidate_negative |

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
rendered=${rendered//@COMPOSITE_SYNTAX_RECORDS@/$composite_syntax_records}
rendered=${rendered//@COMPOSITE_CONFLICTS@/$composite_conflicts}
rendered=${rendered//@COMPOSITE_STATUS@/$composite_status}
rendered=${rendered//@CANDIDATE_STRATEGIES@/$candidate_strategies}
rendered=${rendered//@CANDIDATE_OVERLAP_TERMS@/$candidate_overlap_terms}
rendered=${rendered//@CANDIDATE_SELECTION@/$candidate_selection}
rendered=${rendered//@TARGET_UNRESOLVED_NAMES@/$target_antlr_unresolved}
rendered=${rendered//@RESIDUAL_TARGET_NAMES@/$residual_target_names}
rendered=${rendered//@RESIDUAL_R401@/$residual_r401}
rendered=${rendered//@RESIDUAL_R403@/$residual_r403}
rendered=${rendered//@RESIDUAL_EXPANSION@/$residual_expansion}
rendered=${rendered//@RESIDUAL_LEXICAL@/$residual_lexical}
rendered=${rendered//@RESIDUAL_METAVARIABLE@/$residual_metavariable}
rendered=${rendered//@RESIDUAL_UNICODE@/$residual_unicode}
rendered=${rendered//@LEXICAL_CANDIDATE_STRATEGIES@/$lexical_candidate_strategies}
rendered=${rendered//@LEXICAL_CANDIDATE_RESIDUE@/$lexical_candidate_residue}
rendered=${rendered//@LEXICAL_CANDIDATE_ROWS@/$lexical_candidate_rows}
rendered=${rendered//@LEXICAL_CANDIDATE_LEXICAL@/$lexical_candidate_lexical}
rendered=${rendered//@LEXICAL_CANDIDATE_UNICODE@/$lexical_candidate_unicode}
rendered=${rendered//@LEXICAL_CANDIDATE_PRIMITIVE@/$lexical_candidate_primitive}
rendered=${rendered//@LEXICAL_CANDIDATE_SCHEMA@/$lexical_candidate_schema}
rendered=${rendered//@LEXICAL_CANDIDATE_UNRESOLVED@/$lexical_candidate_unresolved}
rendered=${rendered//@LEXICAL_CANDIDATE_COMPLETE@/$lexical_candidate_complete}
rendered=${rendered//@LEXICAL_CANDIDATE_SELECTION@/$lexical_candidate_selection}
rendered=${rendered//@LEXICAL_CANDIDATE_NEGATIVE@/$lexical_candidate_negative}
rendered=${rendered//@ACCEPTED_PROJECTION_SOURCE@/$accepted_projection_source}
rendered=${rendered//@ACCEPTED_PROJECTION_GENERATED@/$accepted_projection_generated}
rendered=${rendered//@ACCEPTED_PROJECTION_R401@/$accepted_projection_r401}
rendered=${rendered//@ACCEPTED_PROJECTION_R403@/$accepted_projection_r403}
rendered=${rendered//@ACCEPTED_PROJECTION_OVERLAPS@/$accepted_projection_overlaps}
rendered=${rendered//@ACCEPTED_PROJECTION_LEXICAL@/$accepted_projection_lexical}
rendered=${rendered//@ACCEPTED_PROJECTION_LEXICAL_PROJECTED@/$accepted_projection_lexical_projected}
rendered=${rendered//@ACCEPTED_PROJECTION_LEXICAL_UNRESOLVED@/$accepted_projection_lexical_unresolved}
rendered=${rendered//@ACCEPTED_PROJECTION_ANTLR@/$accepted_projection_antlr}
rendered=${rendered//@ACCEPTED_PROJECTION_BISON@/$accepted_projection_bison}
rendered=${rendered//@ACCEPTED_PROJECTION_TREESITTER@/$accepted_projection_treesitter}
rendered=${rendered//@ACCEPTED_PROJECTION_ANTLR_UNRESOLVED@/$accepted_projection_antlr_unresolved}
rendered=${rendered//@ACCEPTED_PROJECTION_BISON_UNRESOLVED@/$accepted_projection_bison_unresolved}
rendered=${rendered//@ACCEPTED_PROJECTION_TREESITTER_STRUCTURAL@/$accepted_projection_treesitter_structural}
rendered=${rendered//@ACCEPTED_PROJECTION_TARGET_BOUNDARY@/$accepted_projection_target_boundary}
rendered=${rendered//@ACCEPTED_PROJECTION_NEGATIVE@/$accepted_projection_negative}
rendered=${rendered//@NORMALIZED_TARGET_RECURSION@/$normalized_target_recursion}
rendered=${rendered//@NORMALIZED_TARGET_NULLABLE@/$normalized_target_nullable}
rendered=${rendered//@NORMALIZED_TARGET_CONFLICTS@/$normalized_target_conflicts}
rendered=${rendered//@NORMALIZED_TARGET_NEXT_CONFLICT@/$normalized_target_next_conflict}
rendered=${rendered//@NORMALIZED_TARGET_UNRESOLVED@/$normalized_target_unresolved}
rendered=${rendered//@DIRECT_SOURCE@/$direct_source}
rendered=${rendered//@DIRECT_COMPOSITE@/$direct_composite}
rendered=${rendered//@DIRECT_LHS@/$direct_lhs}
rendered=${rendered//@DIRECT_DISPATCH@/$direct_dispatch}
rendered=${rendered//@DIRECT_PROCEDURES@/$direct_procedures}
rendered=${rendered//@DIRECT_COMPILE@/$direct_compile}
rendered=${rendered//@DIRECT_BOUNDARY@/$direct_boundary}
rendered=${rendered//@DIAGNOSTIC_ROWS@/$diagnostic_rows}
rendered=${rendered//@DIAGNOSTIC_SPANS@/$diagnostic_spans}
rendered=${rendered//@DIAGNOSTIC_COMPILE@/$diagnostic_compile}
rendered=${rendered//@DIAGNOSTIC_RUNTIME@/$diagnostic_runtime}
rendered=${rendered//@LOCAL_CORPUS_FILES@/$local_corpus_files}
rendered=${rendered//@LOCAL_EXPECTED_UNITS@/$local_expected_units}
rendered=${rendered//@LOCAL_CLASSIFIED_UNITS@/$local_classified_units}
rendered=${rendered//@LOCAL_SOURCE_LINKED_UNITS@/$local_source_linked_units}
rendered=${rendered//@LOCAL_COMPILE@/$local_compile}
rendered=${rendered//@LOCAL_RUNTIME@/$local_runtime}
rendered=${rendered//@LOCAL_BOUNDARY@/$local_boundary}
rendered=${rendered//@STATEMENT_CORPUS_FILES@/$statement_corpus_files}
rendered=${rendered//@STATEMENT_EXPECTED@/$statement_expected}
rendered=${rendered//@STATEMENT_CLASSIFIED@/$statement_classified}
rendered=${rendered//@STATEMENT_LINKED@/$statement_linked}
rendered=${rendered//@STATEMENT_COMPILE@/$statement_compile}
rendered=${rendered//@STATEMENT_RUNTIME@/$statement_runtime}
rendered=${rendered//@STATEMENT_BOUNDARY@/$statement_boundary}
rendered=${rendered//@COMPLETE_CORPUS_FILES@/$complete_corpus_files}
rendered=${rendered//@COMPLETE_EXPECTED_LINES@/$complete_expected_lines}
rendered=${rendered//@COMPLETE_CLASSIFIED_LINES@/$complete_classified_lines}
rendered=${rendered//@COMPLETE_LINKED_LINES@/$complete_linked_lines}
rendered=${rendered//@COMPLETE_COMPILE@/$complete_compile}
rendered=${rendered//@COMPLETE_RUNTIME@/$complete_runtime}
rendered=${rendered//@COMPLETE_BOUNDARY@/$complete_boundary}
rendered=${rendered//@CONSTRUCT_CORPUS_FILES@/$construct_corpus_files}
rendered=${rendered//@CONSTRUCT_PHYSICAL_LINES@/$construct_physical_lines}
rendered=${rendered//@CONSTRUCT_LOGICAL@/$construct_logical}
rendered=${rendered//@CONSTRUCT_CLASSIFIED@/$construct_classified}
rendered=${rendered//@CONSTRUCT_LINKED@/$construct_linked}
rendered=${rendered//@CONSTRUCT_COMPILE@/$construct_compile}
rendered=${rendered//@CONSTRUCT_RUNTIME@/$construct_runtime}
rendered=${rendered//@CONSTRUCT_BOUNDARY@/$construct_boundary}
rendered=${rendered//@AST_CORPUS_FILES@/$ast_corpus_files}
rendered=${rendered//@AST_LOGICAL@/$ast_logical}
rendered=${rendered//@AST_NODES@/$ast_nodes}
rendered=${rendered//@AST_LINKED@/$ast_linked}
rendered=${rendered//@AST_COMPILE@/$ast_compile}
rendered=${rendered//@AST_RUNTIME@/$ast_runtime}
rendered=${rendered//@AST_BOUNDARY@/$ast_boundary}
rendered=${rendered//@EXPRESSION_NODES@/$expression_nodes}
rendered=${rendered//@EXPRESSION_TOTAL@/$expression_total_nodes}
rendered=${rendered//@EXPRESSION_LINKED@/$expression_linked_nodes}
rendered=${rendered//@EXPRESSION_QUERIES@/$expression_queries}
rendered=${rendered//@EXPRESSION_UNKNOWN@/$expression_unknown}
rendered=${rendered//@EXPRESSION_COMPILE@/$expression_compile}
rendered=${rendered//@EXPRESSION_RUNTIME@/$expression_runtime}
rendered=${rendered//@EXPRESSION_BOUNDARY@/$expression_boundary}
rendered=${rendered//@SUBTREE_LEAVES@/$subtree_leaves}
rendered=${rendered//@SUBTREE_LINKED@/$subtree_linked}
rendered=${rendered//@SUBTREE_QUERIES@/$subtree_queries}
rendered=${rendered//@SUBTREE_UNKNOWN@/$subtree_unknown}
rendered=${rendered//@SUBTREE_COMPILE@/$subtree_compile}
rendered=${rendered//@SUBTREE_RUNTIME@/$subtree_runtime}
rendered=${rendered//@SUBTREE_BOUNDARY@/$subtree_boundary}
rendered=${rendered//@PRECEDENCE_FILES@/$precedence_files}
rendered=${rendered//@PRECEDENCE_WITNESSES@/$precedence_witnesses}
rendered=${rendered//@PRECEDENCE_INTERNAL@/$precedence_internal}
rendered=${rendered//@PRECEDENCE_LEAVES@/$precedence_leaves}
rendered=${rendered//@PRECEDENCE_BINARY@/$precedence_binary}
rendered=${rendered//@PRECEDENCE_UNARY@/$precedence_unary}
rendered=${rendered//@PRECEDENCE_ARRAYS@/$precedence_arrays}
rendered=${rendered//@PRECEDENCE_NAMES@/$precedence_names}
rendered=${rendered//@PRECEDENCE_LITERALS@/$precedence_literals}
rendered=${rendered//@PRECEDENCE_LINKED@/$precedence_linked}
rendered=${rendered//@PRECEDENCE_PARENTS@/$precedence_parents}
rendered=${rendered//@PRECEDENCE_ERRORS@/$precedence_errors}
rendered=${rendered//@PRECEDENCE_MISMATCHES@/$precedence_mismatches}
rendered=${rendered//@PRECEDENCE_QUERIES@/$precedence_queries}
rendered=${rendered//@PRECEDENCE_UNKNOWN@/$precedence_unknown}
rendered=${rendered//@PRECEDENCE_DEPTH@/$precedence_depth}
rendered=${rendered//@PRECEDENCE_COMPILE@/$precedence_compile}
rendered=${rendered//@PRECEDENCE_RUNTIME@/$precedence_runtime}
rendered=${rendered//@PRECEDENCE_MUTATION@/$precedence_mutation}
rendered=${rendered//@PRECEDENCE_BOUNDARY@/$precedence_boundary}
rendered=${rendered//@COVERAGE_FILES@/$coverage_files}
rendered=${rendered//@COVERAGE_WITNESSES@/$coverage_witnesses}
rendered=${rendered//@COVERAGE_GFORTRAN@/$coverage_gfortran}
rendered=${rendered//@COVERAGE_INTERNAL@/$coverage_internal}
rendered=${rendered//@COVERAGE_LEAVES@/$coverage_leaves}
rendered=${rendered//@COVERAGE_BINARY@/$coverage_binary}
rendered=${rendered//@COVERAGE_UNARY@/$coverage_unary}
rendered=${rendered//@COVERAGE_ARRAYS@/$coverage_arrays}
rendered=${rendered//@COVERAGE_CALLS@/$coverage_calls}
rendered=${rendered//@COVERAGE_NAMES@/$coverage_names}
rendered=${rendered//@COVERAGE_LITERALS@/$coverage_literals}
rendered=${rendered//@COVERAGE_LINKED@/$coverage_linked}
rendered=${rendered//@COVERAGE_PARENTS@/$coverage_parents}
rendered=${rendered//@COVERAGE_ERRORS@/$coverage_errors}
rendered=${rendered//@COVERAGE_MISMATCHES@/$coverage_mismatches}
rendered=${rendered//@COVERAGE_QUERIES@/$coverage_queries}
rendered=${rendered//@COVERAGE_UNKNOWN@/$coverage_unknown}
rendered=${rendered//@COVERAGE_DEPTH@/$coverage_depth}
rendered=${rendered//@COVERAGE_COMPILE@/$coverage_compile}
rendered=${rendered//@COVERAGE_RUNTIME@/$coverage_runtime}
rendered=${rendered//@COVERAGE_MUTATION@/$coverage_mutation}
rendered=${rendered//@COVERAGE_BOUNDARY@/$coverage_boundary}
rendered=${rendered//@ACCEPTANCE_FILES@/$acceptance_files}
rendered=${rendered//@ACCEPTANCE_EXPECTED@/$acceptance_expected}
rendered=${rendered//@ACCEPTANCE_RECORDS@/$acceptance_records}
rendered=${rendered//@ACCEPTANCE_LINKED@/$acceptance_linked}
rendered=${rendered//@ACCEPTANCE_UNSUPPORTED@/$acceptance_unsupported}
rendered=${rendered//@ACCEPTANCE_DIAGNOSTICS@/$acceptance_diagnostics}
rendered=${rendered//@ACCEPTANCE_PROVENANCE@/$acceptance_provenance}
rendered=${rendered//@ACCEPTANCE_MISMATCHES@/$acceptance_mismatches}
rendered=${rendered//@ACCEPTANCE_GFORTRAN@/$acceptance_gfortran}
rendered=${rendered//@ACCEPTANCE_MUTATION@/$acceptance_mutation}
rendered=${rendered//@ACCEPTANCE_COMPILE@/$acceptance_compile}
rendered=${rendered//@ACCEPTANCE_RUNTIME@/$acceptance_runtime}
rendered=${rendered//@ACCEPTANCE_BOUNDARY@/$acceptance_boundary}
rendered=${rendered//@PROSE_UNRESOLVED@/$prose_unresolved}
rendered=${rendered//@PROSE_CANDIDATES@/$prose_candidates}
rendered=${rendered//@PROSE_ALIASES@/$prose_aliases}
rendered=${rendered//@PROSE_LEXICAL@/$prose_lexical}
rendered=${rendered//@PROSE_METAVARIABLE@/$prose_metavariable}
rendered=${rendered//@PROSE_SEMANTIC@/$prose_semantic}
rendered=${rendered//@PROSE_AMBIGUOUS@/$prose_ambiguous}
rendered=${rendered//@PROSE_RESIDUE@/$prose_residue}
rendered=${rendered//@PROSE_LINKED@/$prose_linked}
rendered=${rendered//@PROSE_DIFFERENCE@/$prose_difference}
rendered=${rendered//@PROSE_NEGATIVE@/$prose_negative}
rendered=${rendered//@CANDIDATE_ADJUDICATION_SPANS@/$candidate_adjudication_spans}
rendered=${rendered//@CANDIDATE_ADJUDICATION_ACCEPTED@/$candidate_adjudication_accepted}
rendered=${rendered//@CANDIDATE_ADJUDICATION_RETAINED@/$candidate_adjudication_retained}
rendered=${rendered//@CANDIDATE_ADJUDICATION_SEMANTIC@/$candidate_adjudication_semantic}
rendered=${rendered//@CANDIDATE_ADJUDICATION_HASHES@/$candidate_adjudication_hashes}
rendered=${rendered//@CANDIDATE_ADJUDICATION_EVIDENCE@/$candidate_adjudication_evidence}
rendered=${rendered//@CANDIDATE_ADJUDICATION_INVENTORY@/$candidate_adjudication_inventory}
rendered=${rendered//@CANDIDATE_ADJUDICATION_DIFFERENCE@/$candidate_adjudication_difference}
rendered=${rendered//@CANDIDATE_ADJUDICATION_NEGATIVE@/$candidate_adjudication_negative}
rendered=${rendered//@RETAINED_COMPOSITION_RESIDUE@/$retained_composition_residue}
rendered=${rendered//@RETAINED_COMPOSITION_RETAINED@/$retained_composition_retained}
rendered=${rendered//@RETAINED_COMPOSITION_NO_EVIDENCE@/$retained_composition_no_evidence}
rendered=${rendered//@RETAINED_COMPOSITION_HASHES@/$retained_composition_hashes}
rendered=${rendered//@RETAINED_COMPOSITION_PARSER_TARGETS@/$retained_composition_parser_targets}
rendered=${rendered//@RETAINED_COMPOSITION_LEAKS@/$retained_composition_leaks}
rendered=${rendered//@RETAINED_COMPOSITION_SYNTAX@/$retained_composition_syntax}
rendered=${rendered//@RETAINED_COMPOSITION_DISPATCH@/$retained_composition_dispatch}
rendered=${rendered//@RETAINED_COMPOSITION_DISPATCH_PROVENANCE@/$retained_composition_dispatch_provenance}
rendered=${rendered//@RETAINED_COMPOSITION_SYNTAX_DIFFERENCE@/$retained_composition_syntax_difference}
rendered=${rendered//@RETAINED_COMPOSITION_DISPATCH_DIFFERENCE@/$retained_composition_dispatch_difference}
rendered=${rendered//@RETAINED_COMPOSITION_ANTLR@/$retained_composition_antlr}
rendered=${rendered//@RETAINED_COMPOSITION_BISON@/$retained_composition_bison}
rendered=${rendered//@RETAINED_COMPOSITION_TREESITTER@/$retained_composition_treesitter}
rendered=${rendered//@RETAINED_COMPOSITION_FORTRAN@/$retained_composition_fortran}
rendered=${rendered//@RETAINED_COMPOSITION_DIFFERENCE@/$retained_composition_difference}
rendered=${rendered//@RETAINED_COMPOSITION_NEGATIVE@/$retained_composition_negative}
rendered=${rendered//@COMPLETE_PARSER_PROFILE_ROWS@/$complete_parser_profile_rows}
rendered=${rendered//@COMPLETE_PARSER_PROFILE_TARGETS@/$complete_parser_profile_targets}
rendered=${rendered//@COMPLETE_PARSER_PROFILE_HASHES@/$complete_parser_profile_hashes}
rendered=${rendered//@COMPLETE_PARSER_FILES@/$complete_parser_files}
rendered=${rendered//@COMPLETE_PARSER_ACCEPTED@/$complete_parser_accepted}
rendered=${rendered//@COMPLETE_PARSER_LINKED@/$complete_parser_linked}
rendered=${rendered//@COMPLETE_PARSER_AST_FILES@/$complete_parser_ast_files}
rendered=${rendered//@COMPLETE_PARSER_AST_NODES@/$complete_parser_ast_nodes}
rendered=${rendered//@COMPLETE_PARSER_AST_LINKED@/$complete_parser_ast_linked}
rendered=${rendered//@COMPLETE_PARSER_AST_PARENTS@/$complete_parser_ast_parents}
rendered=${rendered//@COMPLETE_PARSER_AST_CHILDREN@/$complete_parser_ast_children}
rendered=${rendered//@COMPLETE_PARSER_AST_ERRORS@/$complete_parser_ast_errors}
rendered=${rendered//@COMPLETE_PARSER_DIAGNOSTICS@/$complete_parser_diagnostics}
rendered=${rendered//@COMPLETE_PARSER_DIAGNOSTIC_LINKED@/$complete_parser_diagnostic_linked}
rendered=${rendered//@COMPLETE_PARSER_GFORTRAN_COMPLETE@/$complete_parser_gfortran_complete}
rendered=${rendered//@COMPLETE_PARSER_GFORTRAN_AST@/$complete_parser_gfortran_ast}
rendered=${rendered//@COMPLETE_PARSER_COMPILE@/$complete_parser_compile}
rendered=${rendered//@COMPLETE_PARSER_RUNTIME@/$complete_parser_runtime}
rendered=${rendered//@COMPLETE_PARSER_DIFFERENCE@/$complete_parser_difference}
rendered=${rendered//@COMPLETE_PARSER_NEGATIVE@/$complete_parser_negative}
rendered=${rendered//@EXPRESSION_FACADE_PROFILE_ROWS@/$expression_facade_profile_rows}
rendered=${rendered//@EXPRESSION_FACADE_PROFILE_TARGETS@/$expression_facade_profile_targets}
rendered=${rendered//@EXPRESSION_FACADE_FILES@/$expression_facade_files}
rendered=${rendered//@EXPRESSION_FACADE_WITNESSES@/$expression_facade_witnesses}
rendered=${rendered//@EXPRESSION_FACADE_GFORTRAN@/$expression_facade_gfortran}
rendered=${rendered//@EXPRESSION_FACADE_INTERNAL@/$expression_facade_internal}
rendered=${rendered//@EXPRESSION_FACADE_LEAF@/$expression_facade_leaf}
rendered=${rendered//@EXPRESSION_FACADE_BINARY@/$expression_facade_binary}
rendered=${rendered//@EXPRESSION_FACADE_UNARY@/$expression_facade_unary}
rendered=${rendered//@EXPRESSION_FACADE_ARRAY@/$expression_facade_array}
rendered=${rendered//@EXPRESSION_FACADE_CALLS@/$expression_facade_calls}
rendered=${rendered//@EXPRESSION_FACADE_NAMES@/$expression_facade_names}
rendered=${rendered//@EXPRESSION_FACADE_LITERALS@/$expression_facade_literals}
rendered=${rendered//@EXPRESSION_FACADE_LINKED@/$expression_facade_linked}
rendered=${rendered//@EXPRESSION_FACADE_PARENTS@/$expression_facade_parents}
rendered=${rendered//@EXPRESSION_FACADE_ERRORS@/$expression_facade_errors}
rendered=${rendered//@EXPRESSION_FACADE_MISMATCHES@/$expression_facade_mismatches}
rendered=${rendered//@EXPRESSION_FACADE_QUERIES@/$expression_facade_queries}
rendered=${rendered//@EXPRESSION_FACADE_UNKNOWN@/$expression_facade_unknown}
rendered=${rendered//@EXPRESSION_FACADE_DEPTH@/$expression_facade_depth}
rendered=${rendered//@EXPRESSION_FACADE_COMPILE@/$expression_facade_compile}
rendered=${rendered//@EXPRESSION_FACADE_RUNTIME@/$expression_facade_runtime}
rendered=${rendered//@EXPRESSION_FACADE_MUTATION@/$expression_facade_mutation}
rendered=${rendered//@EXPRESSION_FACADE_DIFFERENCE@/$expression_facade_difference}
rendered=${rendered//@EXPRESSION_FACADE_NEGATIVE@/$expression_facade_negative}
rendered=${rendered//@SEMANTIC_INVENTORY_UNRESOLVED@/$semantic_inventory_unresolved}
rendered=${rendered//@SEMANTIC_INVENTORY_SPANS@/$semantic_inventory_spans}
rendered=${rendered//@SEMANTIC_INVENTORY_DEFINITION_SPANS@/$semantic_inventory_definition_spans}
rendered=${rendered//@SEMANTIC_INVENTORY_RELATION_SPANS@/$semantic_inventory_relation_spans}
rendered=${rendered//@SEMANTIC_INVENTORY_CONSTRAINT_SPANS@/$semantic_inventory_constraint_spans}
rendered=${rendered//@SEMANTIC_INVENTORY_DEFINITION_NAMES@/$semantic_inventory_definition_names}
rendered=${rendered//@SEMANTIC_INVENTORY_RELATION_NAMES@/$semantic_inventory_relation_names}
rendered=${rendered//@SEMANTIC_INVENTORY_CONSTRAINT_NAMES@/$semantic_inventory_constraint_names}
rendered=${rendered//@SEMANTIC_INVENTORY_AMBIGUOUS@/$semantic_inventory_ambiguous}
rendered=${rendered//@SEMANTIC_INVENTORY_RESIDUE@/$semantic_inventory_residue}
rendered=${rendered//@SEMANTIC_INVENTORY_MEMBERS@/$semantic_inventory_members}
rendered=${rendered//@SEMANTIC_INVENTORY_CONSTRAINTS@/$semantic_inventory_constraints}
rendered=${rendered//@SEMANTIC_INVENTORY_LINKED_CANDIDATES@/$semantic_inventory_linked_candidates}
rendered=${rendered//@SEMANTIC_INVENTORY_LINKED_CONSTRAINTS@/$semantic_inventory_linked_constraints}
rendered=${rendered//@SEMANTIC_INVENTORY_FACTS@/$semantic_inventory_facts}
rendered=${rendered//@SEMANTIC_INVENTORY_DIFFERENCE@/$semantic_inventory_difference}
rendered=${rendered//@SEMANTIC_INVENTORY_CONSTRAINT_DIFFERENCE@/$semantic_inventory_constraint_difference}
rendered=${rendered//@SEMANTIC_INVENTORY_NEGATIVE@/$semantic_inventory_negative}
rendered=${rendered//@CORE0_ADJUDICATION_CANDIDATES@/$semantic_adjudication_candidates}
rendered=${rendered//@CORE0_ADJUDICATION_ACCEPTED@/$semantic_adjudication_accepted}
rendered=${rendered//@CORE0_ADJUDICATION_LEXICAL@/$semantic_adjudication_lexical}
rendered=${rendered//@CORE0_ADJUDICATION_METAVARIABLE@/$semantic_adjudication_metavariable}
rendered=${rendered//@CORE0_ADJUDICATION_SEMANTIC@/$semantic_adjudication_semantic}
rendered=${rendered//@CORE0_ADJUDICATION_RETAINED@/$semantic_adjudication_retained}
rendered=${rendered//@CORE0_ADJUDICATION_CONSTRAINTS@/$semantic_adjudication_constraints}
rendered=${rendered//@CORE0_ADJUDICATION_LINKED_CANDIDATES@/$semantic_adjudication_linked_candidates}
rendered=${rendered//@CORE0_ADJUDICATION_LINKED_CONSTRAINTS@/$semantic_adjudication_linked_constraints}
rendered=${rendered//@CORE0_ADJUDICATION_FACTS@/$semantic_adjudication_facts}
rendered=${rendered//@CORE0_ADJUDICATION_FORMALIZED@/$semantic_adjudication_formalized}
rendered=${rendered//@CORE0_ADJUDICATION_PROJECTIONS@/$semantic_adjudication_projections}
rendered=${rendered//@CORE0_ADJUDICATION_EVIDENCE@/$semantic_adjudication_evidence}
rendered=${rendered//@CORE0_ADJUDICATION_DIFFERENCE@/$semantic_adjudication_difference}
rendered=${rendered//@CORE0_ADJUDICATION_CONSTRAINT_DIFFERENCE@/$semantic_adjudication_constraint_difference}
rendered=${rendered//@CORE0_ADJUDICATION_NEGATIVE@/$semantic_adjudication_negative}
rendered=${rendered//@CONSTRAINT_FORMALIZATION_ELIGIBLE@/$constraint_formalization_eligible}
rendered=${rendered//@CONSTRAINT_FORMALIZATION_SELECTED@/$constraint_formalization_selected}
rendered=${rendered//@CONSTRAINT_FORMALIZATION_PREDICATES@/$constraint_formalization_predicates}
rendered=${rendered//@CONSTRAINT_FORMALIZATION_RESOLVED@/$constraint_formalization_resolved}
rendered=${rendered//@CONSTRAINT_FORMALIZATION_UNRESOLVED@/$constraint_formalization_unresolved}
rendered=${rendered//@CONSTRAINT_FORMALIZATION_DISPUTED@/$constraint_formalization_disputed}
rendered=${rendered//@CONSTRAINT_FORMALIZATION_HASHES@/$constraint_formalization_hashes}
rendered=${rendered//@CONSTRAINT_FORMALIZATION_EVIDENCE@/$constraint_formalization_evidence}
rendered=${rendered//@CONSTRAINT_FORMALIZATION_REQUIRED@/$constraint_formalization_required}
rendered=${rendered//@CONSTRAINT_FORMALIZATION_PROVIDED@/$constraint_formalization_provided}
rendered=${rendered//@CONSTRAINT_FORMALIZATION_EDGES@/$constraint_formalization_edges}
rendered=${rendered//@CONSTRAINT_FORMALIZATION_ORDER_DIFFERENCE@/$constraint_formalization_order_difference}
rendered=${rendered//@CONSTRAINT_FORMALIZATION_DIFFERENCE@/$constraint_formalization_difference}
rendered=${rendered//@CONSTRAINT_FORMALIZATION_PROJECTIONS@/$constraint_formalization_projections}
rendered=${rendered//@CONSTRAINT_FORMALIZATION_NEGATIVE@/$constraint_formalization_negative}
rendered=${rendered//@CROSS_CLAUSE_ELIGIBLE@/$cross_clause_eligible}
rendered=${rendered//@CROSS_CLAUSE_SELECTED@/$cross_clause_selected}
rendered=${rendered//@CROSS_CLAUSE_PREDICATES@/$cross_clause_predicates}
rendered=${rendered//@CROSS_CLAUSE_RESOLVED@/$cross_clause_resolved}
rendered=${rendered//@CROSS_CLAUSE_UNRESOLVED@/$cross_clause_unresolved}
rendered=${rendered//@CROSS_CLAUSE_DISPUTED@/$cross_clause_disputed}
rendered=${rendered//@CROSS_CLAUSE_HASHES@/$cross_clause_hashes}
rendered=${rendered//@CROSS_CLAUSE_EVIDENCE@/$cross_clause_evidence}
rendered=${rendered//@CROSS_CLAUSE_REQUIRED@/$cross_clause_required}
rendered=${rendered//@CROSS_CLAUSE_PROVIDED@/$cross_clause_provided}
rendered=${rendered//@CROSS_CLAUSE_EDGES@/$cross_clause_edges}
rendered=${rendered//@CROSS_CLAUSE_ORDER_DIFFERENCE@/$cross_clause_order_difference}
rendered=${rendered//@CROSS_CLAUSE_DIFFERENCE@/$cross_clause_difference}
rendered=${rendered//@CROSS_CLAUSE_PROJECTIONS@/$cross_clause_projections}
rendered=${rendered//@CROSS_CLAUSE_NEGATIVE@/$cross_clause_negative}
rendered=${rendered//@PROSE_BOUNDARY@/$prose_boundary}
rendered=${rendered//@BOUNDED_LOGICAL_UNITS@/$bounded_logical_units}
rendered=${rendered//@BOUNDED_TABLE_ROWS@/$bounded_table_rows}
rendered=${rendered//@BOUNDED_CANDIDATES@/$bounded_candidates}
rendered=${rendered//@BOUNDED_CANDIDATE_NAMES@/$bounded_candidate_names}
rendered=${rendered//@BOUNDED_NEW_NAMES@/$bounded_new_names}
rendered=${rendered//@BOUNDED_ALIASES@/$bounded_aliases}
rendered=${rendered//@BOUNDED_LEXICAL@/$bounded_lexical}
rendered=${rendered//@BOUNDED_METAVARIABLE@/$bounded_metavariable}
rendered=${rendered//@BOUNDED_SEMANTIC@/$bounded_semantic}
rendered=${rendered//@BOUNDED_AMBIGUOUS@/$bounded_ambiguous}
rendered=${rendered//@BOUNDED_RESIDUE@/$bounded_residue}
rendered=${rendered//@BOUNDED_LINKED@/$bounded_linked}
rendered=${rendered//@BOUNDED_DIFFERENCE@/$bounded_difference}
rendered=${rendered//@BOUNDED_NEGATIVE@/$bounded_negative}
rendered=${rendered//@BOUNDED_BOUNDARY@/$bounded_boundary}
rendered=${rendered//@ADJUDICATED_CANDIDATES@/$adjudicated_candidates}
rendered=${rendered//@ADJUDICATED_ACCEPTED@/$adjudicated_accepted}
rendered=${rendered//@ADJUDICATED_RETAINED@/$adjudicated_retained}
rendered=${rendered//@ADJUDICATED_ALIASES@/$adjudicated_aliases}
rendered=${rendered//@ADJUDICATED_LEXICAL@/$adjudicated_lexical}
rendered=${rendered//@ADJUDICATED_METAVARIABLE@/$adjudicated_metavariable}
rendered=${rendered//@ADJUDICATED_SEMANTIC@/$adjudicated_semantic}
rendered=${rendered//@ADJUDICATED_HASHES@/$adjudicated_hashes}
rendered=${rendered//@ADJUDICATED_EVIDENCE@/$adjudicated_evidence}
rendered=${rendered//@ADJUDICATED_INVENTORY_DIFFERENCE@/$adjudicated_inventory_difference}
rendered=${rendered//@ADJUDICATED_DIFFERENCE@/$adjudicated_difference}
rendered=${rendered//@ADJUDICATED_NEGATIVE@/$adjudicated_negative}
rendered=${rendered//@ADJUDICATED_BOUNDARY@/$adjudicated_boundary}
rendered=${rendered//@COMPOSITION_D0019@/$composition_d0019}
rendered=${rendered//@COMPOSITION_RELATIONS@/$composition_relations}
rendered=${rendered//@COMPOSITION_MERGED@/$composition_merged}
rendered=${rendered//@COMPOSITION_RETAINED@/$composition_retained}
rendered=${rendered//@COMPOSITION_UNRESOLVED@/$composition_unresolved}
rendered=${rendered//@COMPOSITION_SEMANTIC@/$composition_semantic}
rendered=${rendered//@COMPOSITION_PROJECTION@/$composition_projection}
rendered=${rendered//@COMPOSITION_HASHES@/$composition_hashes}
rendered=${rendered//@COMPOSITION_PROJECTION_DIFFERENCE@/$composition_projection_difference}
rendered=${rendered//@COMPOSITION_DIFFERENCE@/$composition_difference}
rendered=${rendered//@COMPOSITION_NEGATIVE@/$composition_negative}
rendered=${rendered//@COMPOSITION_BOUNDARY@/$composition_boundary}
rendered=${rendered//@SIDECAR_FACTS@/$sidecar_facts}
rendered=${rendered//@SIDECAR_SEMANTIC@/$sidecar_semantic}
rendered=${rendered//@SIDECAR_PROJECTION@/$sidecar_projection}
rendered=${rendered//@SIDECAR_FRAGMENTS@/$sidecar_fragments}
rendered=${rendered//@SIDECAR_PROVENANCE@/$sidecar_provenance}
rendered=${rendered//@SIDECAR_LEAKS@/$sidecar_leaks}
rendered=${rendered//@SIDECAR_EBNF@/$sidecar_ebnf}
rendered=${rendered//@SIDECAR_ANTLR@/$sidecar_antlr}
rendered=${rendered//@SIDECAR_BISON@/$sidecar_bison}
rendered=${rendered//@SIDECAR_TREESITTER@/$sidecar_treesitter}
rendered=${rendered//@SIDECAR_FORTRAN@/$sidecar_fortran}
rendered=${rendered//@SIDECAR_DIFFERENCE@/$sidecar_difference}
rendered=${rendered//@SIDECAR_NEGATIVE@/$sidecar_negative}
rendered=${rendered//@SIDECAR_BOUNDARY@/$sidecar_boundary}
rendered=${rendered//@INTEGRATION_SOURCE@/$integration_source}
rendered=${rendered//@INTEGRATION_SYNTAX@/$integration_syntax}
rendered=${rendered//@INTEGRATION_ALIASES@/$integration_aliases}
rendered=${rendered//@INTEGRATION_REWRITES@/$integration_rewrites}
rendered=${rendered//@INTEGRATION_SEMANTIC@/$integration_semantic}
rendered=${rendered//@INTEGRATION_OVERLAP@/$integration_overlap}
rendered=${rendered//@INTEGRATION_LEAKS@/$integration_leaks}
rendered=${rendered//@INTEGRATION_UNRESOLVED_OCCURRENCES@/$integration_unresolved_occurrences}
rendered=${rendered//@INTEGRATION_UNRESOLVED_NAMES@/$integration_unresolved_names}
rendered=${rendered//@INTEGRATION_EXPORT_EBNF@/$integration_export_ebnf}
rendered=${rendered//@INTEGRATION_EXPORT_ANTLR@/$integration_export_antlr}
rendered=${rendered//@INTEGRATION_EXPORT_BISON@/$integration_export_bison}
rendered=${rendered//@INTEGRATION_EXPORT_TREESITTER@/$integration_export_treesitter}
rendered=${rendered//@INTEGRATION_ANTLR@/$integration_antlr}
rendered=${rendered//@INTEGRATION_BISON@/$integration_bison}
rendered=${rendered//@INTEGRATION_TREESITTER@/$integration_treesitter}
rendered=${rendered//@INTEGRATION_DISPATCH@/$integration_dispatch}
rendered=${rendered//@INTEGRATION_DISPATCH_PROVENANCE@/$integration_dispatch_provenance}
rendered=${rendered//@INTEGRATION_COLLISIONS@/$integration_collisions}
rendered=${rendered//@INTEGRATION_FORTRAN@/$integration_fortran}
rendered=${rendered//@INTEGRATION_DIFFERENCE@/$integration_difference}
rendered=${rendered//@INTEGRATION_NEGATIVE@/$integration_negative}
rendered=${rendered//@INTEGRATION_BOUNDARY@/$integration_boundary}
rendered=${rendered//@RESIDUE_RECORDS@/$residue_records}
rendered=${rendered//@RESIDUE_SEMANTIC@/$residue_semantic}
rendered=${rendered//@RESIDUE_LEXICAL@/$residue_lexical}
rendered=${rendered//@RESIDUE_METAVARIABLE@/$residue_metavariable}
rendered=${rendered//@RESIDUE_UNRESOLVED@/$residue_unresolved}
rendered=${rendered//@RESIDUE_MISSING@/$residue_missing}
rendered=${rendered//@RESIDUE_ALIASES@/$residue_aliases}
rendered=${rendered//@RESIDUE_HASHES@/$residue_hashes}
rendered=${rendered//@RESIDUE_EVIDENCE@/$residue_evidence}
rendered=${rendered//@RESIDUE_LEAKS@/$residue_leaks}
rendered=${rendered//@RESIDUE_DIFFERENCE@/$residue_difference}
rendered=${rendered//@RESIDUE_NEGATIVE@/$residue_negative}
rendered=${rendered//@PROSE_UNRESOLVED@/$prose_unresolved}
rendered=${rendered//@PROSE_UNITS@/$prose_units}
rendered=${rendered//@PROSE_SPANS@/$prose_spans}
rendered=${rendered//@PROSE_NAMES@/$prose_names}
rendered=${rendered//@PROSE_ALIASES@/$prose_aliases}
rendered=${rendered//@PROSE_LEXICAL@/$prose_lexical}
rendered=${rendered//@PROSE_METAVARIABLE@/$prose_metavariable}
rendered=${rendered//@PROSE_SEMANTIC@/$prose_semantic}
rendered=${rendered//@PROSE_RESIDUE@/$prose_residue}
rendered=${rendered//@PROSE_LINKED@/$prose_linked}
rendered=${rendered//@PROSE_DIFFERENCE@/$prose_difference}
rendered=${rendered//@PROSE_NEGATIVE@/$prose_negative}
{
    printf '%s\n\n' "$rendered"
    cat "$results"
} > "$paper_dir/paper.md"

printf 'standard-to-grammar: regenerated results.md and paper.md\n'
