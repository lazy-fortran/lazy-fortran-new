#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib.sh"

standard="$(resolve_repo standard-new)"
frontend="$(resolve_repo fortfront-new)"
ffc="$(resolve_repo ffc-new)"
backend="$(resolve_repo fortback-new)"
source_file="$ROOT/tests/fixtures/l3-declaration-v0.f90"
main_source_file="$ROOT/tests/fixtures/l3-ast-program-root-name-main-v1.f90"
real_source_file="$ROOT/tests/fixtures/l3-ast-program-real-type-main-v1.f90"
double_source_file="$ROOT/tests/fixtures/l3-ast-program-double-precision-main-v1.f90"
complex_source_file="$ROOT/tests/fixtures/l3-ast-program-complex-type-main-v1.f90"
logical_source_file="$ROOT/tests/fixtures/l3-ast-program-logical-type-main-v1.f90"
character_source_file="$ROOT/tests/fixtures/l3-ast-program-character-type-main-v1.f90"
assignment_source_file="$ROOT/tests/fixtures/l3-ast-program-integer-assignment-v1.f90"
expression_assignment_source_file="$ROOT/tests/fixtures/l3-ast-program-integer-add-assignment-v1.f90"
multiplication_assignment_source_file="$ROOT/tests/fixtures/l3-ast-program-integer-multiply-assignment-v1.f90"
division_assignment_source_file="$ROOT/tests/fixtures/l3-ast-program-integer-divide-assignment-v1.f90"
subtraction_assignment_source_file="$ROOT/tests/fixtures/l3-ast-program-integer-subtract-assignment-v1.f90"
literal_assignment_source_file="$ROOT/tests/fixtures/l3-ast-program-integer-literal-7-assignment-v1.f90"
literal_boundary_source_file="$ROOT/tests/fixtures/l3-ast-program-integer-literal-2047-assignment-v1.f90"
variable_expression_source_file="$ROOT/tests/fixtures/l3-ast-program-integer-variable-add-assignment-v1.f90"
sequence_source_file="$ROOT/tests/fixtures/l3-ast-program-integer-two-assignment-v1.f90"
sequence_three_source_file="$ROOT/tests/fixtures/l3-ast-program-integer-three-assignment-v1.f90"
sequence_four_source_file="$ROOT/tests/fixtures/l3-ast-program-integer-four-assignment-v1.f90"
sequence_five_source_file="$ROOT/tests/fixtures/l3-ast-program-integer-five-assignment-v1.f90"
sequence_six_source_file="$ROOT/tests/fixtures/l3-ast-program-integer-six-assignment-v1.f90"
sequence_seven_source_file="$ROOT/tests/fixtures/l3-ast-program-integer-seven-assignment-v1.f90"
sequence_eight_source_file="$ROOT/tests/fixtures/l3-ast-program-integer-eight-assignment-v1.f90"
sequence_nine_source_file="$ROOT/tests/fixtures/l3-ast-program-integer-nine-assignment-v1.f90"
sequence_ten_source_file="$ROOT/tests/fixtures/l3-ast-program-integer-ten-assignment-v1.f90"
stop_source_file="$ROOT/tests/fixtures/l3-ast-program-stop-7-v1.f90"
print_source_file="$ROOT/tests/fixtures/l3-ast-program-print-7-v1.f90"
print_two_item_source_file="$ROOT/tests/fixtures/l3-ast-program-print-two-item-v1.f90"
print_three_item_source_file="$ROOT/tests/fixtures/l3-ast-program-print-three-item-v1.f90"
print_four_item_source_file="$ROOT/tests/fixtures/l3-ast-program-print-four-item-v1.f90"
print_five_item_source_file="$ROOT/tests/fixtures/l3-ast-program-print-five-item-v1.f90"
print_six_item_source_file="$ROOT/tests/fixtures/l3-ast-program-print-six-item-v1.f90"
print_seven_item_source_file="$ROOT/tests/fixtures/l3-ast-program-print-seven-item-v1.f90"
print_eight_item_source_file="$ROOT/tests/fixtures/l3-ast-program-print-eight-item-v1.f90"
print_nine_item_source_file="$ROOT/tests/fixtures/l3-ast-program-print-nine-item-v1.f90"
print_ten_item_source_file="$ROOT/tests/fixtures/l3-ast-program-print-ten-item-v1.f90"
print_generic_item_source_file="$ROOT/tests/fixtures/l3-ast-program-print-generic-items-v1.f90"
print_variable_source_file="$ROOT/tests/fixtures/l3-ast-program-print-variable-v1.f90"
print_variable_23_source_file="$ROOT/tests/fixtures/l3-ast-program-print-variable-23-v1.f90"
print_variable_expression_source_file="$ROOT/tests/fixtures/l3-ast-program-print-variable-expression-v1.f90"
print_variable_multiply_expression_source_file="$ROOT/tests/fixtures/l3-ast-program-print-variable-multiply-expression-v1.f90"
print_variable_subtract_expression_source_file="$ROOT/tests/fixtures/l3-ast-program-print-variable-subtract-expression-v1.f90"
print_variable_divide_expression_source_file="$ROOT/tests/fixtures/l3-ast-program-print-variable-divide-expression-v1.f90"
print_variable_power_expression_source_file="$ROOT/tests/fixtures/l3-ast-program-print-variable-power-expression-v1.f90"
print_variable_power_value_source_file="$ROOT/tests/fixtures/l3-ast-program-print-variable-power-value-v1.f90"
print_variable_two_item_source_file="$ROOT/tests/fixtures/l3-ast-program-print-variable-two-item-v1.f90"
print_variable_three_item_source_file="$ROOT/tests/fixtures/l3-ast-program-print-variable-three-item-v1.f90"
print_variable_four_item_source_file="$ROOT/tests/fixtures/l3-ast-program-print-variable-four-item-v1.f90"
print_variable_five_item_source_file="$ROOT/tests/fixtures/l3-ast-program-print-variable-five-item-v1.f90"
print_variable_six_item_source_file="$ROOT/tests/fixtures/l3-ast-program-print-variable-six-item-v1.f90"
negative_file="$ROOT/tests/negative/l3-ast-program-root-name-mismatch-v1.f90"
negative_declaration_file="$ROOT/tests/negative/l3-declaration-v0-missing-entity.f90"
negative_real_file="$ROOT/tests/negative/l3-ast-program-real-type-missing-entity-v1.f90"
negative_double_file="$ROOT/tests/negative/l3-ast-program-double-precision-missing-entity-v1.f90"
negative_complex_file="$ROOT/tests/negative/l3-ast-program-complex-type-missing-entity-v1.f90"
negative_logical_file="$ROOT/tests/negative/l3-ast-program-logical-type-missing-entity-v1.f90"
negative_character_file="$ROOT/tests/negative/l3-ast-program-character-type-missing-entity-v1.f90"
negative_assignment_file="$ROOT/tests/negative/l3-ast-program-integer-assignment-missing-rhs-v1.f90"
negative_assignment_name_file="$ROOT/tests/negative/l3-ast-program-integer-assignment-wrong-variable-v1.f90"
negative_expression_file="$ROOT/tests/negative/l3-ast-program-integer-add-assignment-missing-operand-v1.f90"
negative_expression_operator_file="$ROOT/tests/negative/l3-ast-program-integer-add-assignment-wrong-operator-v1.f90"
negative_multiplication_file="$ROOT/tests/negative/l3-ast-program-integer-multiply-assignment-missing-operand-v1.f90"
negative_multiplication_operator_file="$ROOT/tests/negative/l3-ast-program-integer-multiply-assignment-wrong-operator-v1.f90"
negative_division_file="$ROOT/tests/negative/l3-ast-program-integer-divide-assignment-missing-operand-v1.f90"
negative_division_operator_file="$ROOT/tests/negative/l3-ast-program-integer-divide-assignment-wrong-operator-v1.f90"
negative_subtraction_file="$ROOT/tests/negative/l3-ast-program-integer-subtract-assignment-missing-operand-v1.f90"
negative_subtraction_operator_file="$ROOT/tests/negative/l3-ast-program-integer-subtract-assignment-wrong-operator-v1.f90"
negative_literal_range_file="$ROOT/tests/negative/l3-ast-program-integer-literal-2048-assignment-v1.f90"
negative_literal_form_file="$ROOT/tests/negative/l3-ast-program-real-literal-assignment-v1.f90"
negative_variable_expression_file="$ROOT/tests/negative/l3-ast-program-integer-variable-multiply-assignment-v1.f90"
negative_sequence_files=(
    "$ROOT/tests/negative/l3-ast-program-integer-two-assignment-swapped-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-integer-two-assignment-wrong-variable-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-integer-two-assignment-missing-second-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-integer-two-assignment-wrong-operator-v1.f90"
)
negative_sequence_three_files=(
    "$ROOT/tests/negative/l3-ast-program-integer-three-assignment-wrong-operator-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-integer-three-assignment-missing-third-v1.f90"
)
negative_sequence_four_files=(
    "$ROOT/tests/negative/l3-ast-program-integer-four-assignment-wrong-operator-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-integer-four-assignment-missing-fourth-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-integer-four-assignment-wrong-variable-v1.f90"
)
negative_sequence_five_files=(
    "$ROOT/tests/negative/l3-ast-program-integer-five-assignment-wrong-operator-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-integer-five-assignment-missing-fifth-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-integer-five-assignment-wrong-variable-v1.f90"
)
negative_sequence_six_files=(
    "$ROOT/tests/negative/l3-ast-program-integer-six-assignment-wrong-operator-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-integer-six-assignment-missing-sixth-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-integer-six-assignment-wrong-variable-v1.f90"
)
negative_sequence_ten_files=(
    "$ROOT/tests/negative/l3-ast-program-integer-ten-assignment-wrong-operator-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-integer-ten-assignment-missing-tenth-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-integer-ten-assignment-wrong-variable-v1.f90"
)
negative_stop_files=(
    "$ROOT/tests/negative/l3-ast-program-stop-8-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-stop-missing-code-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-error-stop-7-v1.f90"
)
negative_print_files=(
    "$ROOT/tests/negative/l3-ast-program-write-7-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-print-missing-item-v1.f90"
)
negative_print_two_item_files=(
    "$ROOT/tests/negative/l3-ast-program-print-two-item-missing-second-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-write-two-item-v1.f90"
)
negative_print_three_item_files=(
    "$ROOT/tests/negative/l3-ast-program-print-three-item-missing-third-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-write-three-item-v1.f90"
)
negative_print_four_item_files=(
    "$ROOT/tests/negative/l3-ast-program-print-four-item-missing-fourth-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-write-four-item-v1.f90"
)
negative_print_five_item_files=(
    "$ROOT/tests/negative/l3-ast-program-print-five-item-missing-fifth-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-write-five-item-v1.f90"
)
negative_print_six_item_files=(
    "$ROOT/tests/negative/l3-ast-program-print-six-item-missing-sixth-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-write-six-item-v1.f90"
)
negative_print_seven_item_files=(
    "$ROOT/tests/negative/l3-ast-program-print-seven-item-missing-seventh-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-write-seven-item-v1.f90"
)
negative_print_eight_item_files=(
    "$ROOT/tests/negative/l3-ast-program-print-eight-item-missing-eighth-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-write-eight-item-v1.f90"
)
negative_print_nine_item_files=(
    "$ROOT/tests/negative/l3-ast-program-print-nine-item-missing-ninth-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-write-nine-item-v1.f90"
)
negative_print_ten_item_files=(
    "$ROOT/tests/negative/l3-ast-program-print-ten-item-missing-tenth-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-write-ten-item-v1.f90"
)
negative_print_generic_item_files=(
    "$ROOT/tests/negative/l3-ast-program-print-generic-items-missing-third-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-write-generic-items-v1.f90"
)
negative_print_variable_files=(
    "$ROOT/tests/negative/l3-ast-program-print-variable-missing-assignment-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-print-variable-wrong-name-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-write-variable-v1.f90"
)
negative_print_variable_23_files=(
    "$ROOT/tests/negative/l3-ast-program-print-variable-23-missing-assignment-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-print-variable-23-wrong-name-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-write-variable-23-v1.f90"
)
negative_print_variable_expression_files=(
    "$ROOT/tests/negative/l3-ast-program-print-variable-expression-wrong-name-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-print-variable-expression-wrong-operator-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-write-variable-expression-v1.f90"
)
negative_print_variable_multiply_expression_files=(
    "$ROOT/tests/negative/l3-ast-program-print-variable-multiply-expression-wrong-name-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-print-variable-multiply-expression-wrong-operator-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-write-variable-multiply-expression-v1.f90"
)
negative_print_variable_subtract_expression_files=(
    "$ROOT/tests/negative/l3-ast-program-print-variable-subtract-expression-wrong-name-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-print-variable-subtract-expression-wrong-operator-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-write-variable-subtract-expression-v1.f90"
)
negative_print_variable_divide_expression_files=(
    "$ROOT/tests/negative/l3-ast-program-print-variable-divide-expression-wrong-name-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-print-variable-divide-expression-wrong-operator-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-write-variable-divide-expression-v1.f90"
)
negative_print_variable_power_expression_files=(
    "$ROOT/tests/negative/l3-ast-program-print-variable-power-expression-wrong-name-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-print-variable-power-expression-wrong-operator-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-write-variable-power-expression-v1.f90"
)
negative_print_variable_power_value_files=(
    "$ROOT/tests/negative/l3-ast-program-print-variable-power-value-wrong-name-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-print-variable-power-value-wrong-operator-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-write-variable-power-value-v1.f90"
)
negative_print_variable_two_item_files=(
    "$ROOT/tests/negative/l3-ast-program-print-variable-two-item-missing-second-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-print-variable-two-item-wrong-second-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-write-variable-two-item-v1.f90"
)
negative_print_variable_three_item_files=(
    "$ROOT/tests/negative/l3-ast-program-print-variable-three-item-wrong-second-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-print-variable-three-item-wrong-third-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-write-variable-three-item-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-print-variable-three-item-malformed-v1.f90"
)
negative_print_variable_four_item_files=(
    "$ROOT/tests/negative/l3-ast-program-print-variable-four-item-wrong-second-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-print-variable-four-item-wrong-fourth-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-write-variable-four-item-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-print-variable-four-item-malformed-v1.f90"
)
negative_print_variable_five_item_files=(
    "$ROOT/tests/negative/l3-ast-program-print-variable-five-item-wrong-second-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-print-variable-five-item-wrong-fifth-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-write-variable-five-item-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-print-variable-five-item-malformed-v1.f90"
)
negative_print_variable_six_item_files=(
    "$ROOT/tests/negative/l3-ast-program-print-variable-six-item-wrong-second-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-print-variable-six-item-wrong-sixth-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-write-variable-six-item-v1.f90"
    "$ROOT/tests/negative/l3-ast-program-print-variable-six-item-malformed-v1.f90"
)
oracle="$ROOT/tests/e2e/oracle_generated_chain.py"

(cd "$standard" && fo clean && fo test test_standardir_lexical_generated && \
    fo clean && fo test test_standardir_grammar_fact) > /dev/null 2>&1

mkdir -p "$ROOT/.cache/fast-checks"
run_dir="$(mktemp -d "$ROOT/.cache/fast-checks/generated-chain.XXXXXX")"
trap 'rm -rf "$run_dir"' EXIT
exec 3>&1
exec >"$run_dir/transcript.log"

run_sequence_batch_route() {
    local count="$1"
    local source="$2"
    local expected_status="$3"
    local mode="$4"
    shift 4
    local ast="$run_dir/sequence-${count}.frontend.ast.sx"
    local mir="$run_dir/sequence-${count}.mir.sx"
    local elf="$run_dir/sequence-${count}.program.elf"
    local negative
    local actual_status

    (cd "$frontend" && fo exec fortfront-source-ast-v1 "$source" "$ast") > /dev/null 2>&1
    (cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$ast" "$mir") > /dev/null 2>&1
    (cd "$backend" && fo exec fortback-mir-v0 "$mir" "$elf") > /dev/null 2>&1
    for negative in "$@"; do
        rm -f "$run_dir/negative-sequence-${count}.ast.sx"
        if (cd "$frontend" && fo exec fortfront-source-ast-v1 "$negative" \
                "$run_dir/negative-sequence-${count}.ast.sx") > /dev/null 2>&1; then
            if grep -q '^(assignment-sequence ' "$run_dir/negative-sequence-${count}.ast.sx" && \
                    grep -q "(assignment-count ${count})" "$run_dir/negative-sequence-${count}.ast.sx"; then
                printf 'invalid %s-assignment sequence source was promoted\n' "$count" >&2
                exit 1
            fi
        else
            [ ! -e "$run_dir/negative-sequence-${count}.ast.sx" ]
        fi
    done
    if qemu-riscv64 "$elf" > /dev/null; then
        actual_status=0
    else
        actual_status=$?
    fi
    [ "$actual_status" -eq "$expected_status" ]
    python3 "$oracle" "$ast" "$mir" "$elf" main integer "$mode"
}

ast_file="$run_dir/frontend.ast.sx"
mir_file="$run_dir/mir.sx"
elf_file="$run_dir/program.elf"

(cd "$frontend" && fo exec fortfront-source-ast-v1 "$source_file" "$ast_file") \
    > /dev/null 2>&1
(cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$ast_file" "$mir_file") \
    > /dev/null 2>&1
(cd "$backend" && fo exec fortback-mir-v0 "$mir_file" "$elf_file") \
    > /dev/null 2>&1

if (cd "$frontend" && fo exec fortfront-source-ast-v1 "$negative_file" \
        "$run_dir/negative.ast.sx") > /dev/null 2>&1; then
    printf '%s\n' 'negative source was accepted' >&2
    exit 1
fi
[ ! -e "$run_dir/negative.ast.sx" ]

if (cd "$frontend" && fo exec fortfront-source-ast-v1 "$negative_declaration_file" \
        "$run_dir/negative-declaration.ast.sx") > /dev/null 2>&1; then
    printf '%s\n' 'source with missing declaration entity was accepted' >&2
    exit 1
fi
[ ! -e "$run_dir/negative-declaration.ast.sx" ]

command -v qemu-riscv64 > /dev/null
qemu-riscv64 "$elf_file" > /dev/null

python3 "$oracle" "$ast_file" "$mir_file" "$elf_file"

main_ast_file="$run_dir/main.frontend.ast.sx"
main_mir_file="$run_dir/main.mir.sx"
main_elf_file="$run_dir/main.program.elf"
(cd "$frontend" && fo exec fortfront-source-ast-v1 "$main_source_file" "$main_ast_file") \
    > /dev/null 2>&1
(cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$main_ast_file" "$main_mir_file") \
    > /dev/null 2>&1
(cd "$backend" && fo exec fortback-mir-v0 "$main_mir_file" "$main_elf_file") \
    > /dev/null 2>&1
qemu-riscv64 "$main_elf_file" > /dev/null
python3 "$oracle" "$main_ast_file" "$main_mir_file" "$main_elf_file" main

real_ast_file="$run_dir/real.frontend.ast.sx"
real_mir_file="$run_dir/real.mir.sx"
real_elf_file="$run_dir/real.program.elf"
(cd "$frontend" && fo exec fortfront-source-ast-v1 "$real_source_file" "$real_ast_file") \
    > /dev/null 2>&1
(cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$real_ast_file" "$real_mir_file") \
    > /dev/null 2>&1
(cd "$backend" && fo exec fortback-mir-v0 "$real_mir_file" "$real_elf_file") \
    > /dev/null 2>&1
if (cd "$frontend" && fo exec fortfront-source-ast-v1 "$negative_real_file" \
        "$run_dir/negative-real.ast.sx") > /dev/null 2>&1; then
    printf '%s\n' 'REAL source with missing declaration entity was accepted' >&2
    exit 1
fi
[ ! -e "$run_dir/negative-real.ast.sx" ]
qemu-riscv64 "$real_elf_file" > /dev/null
python3 "$oracle" "$real_ast_file" "$real_mir_file" "$real_elf_file" main real

double_ast_file="$run_dir/double.frontend.ast.sx"
double_mir_file="$run_dir/double.mir.sx"
double_elf_file="$run_dir/double.program.elf"
(cd "$frontend" && fo exec fortfront-source-ast-v1 "$double_source_file" "$double_ast_file") \
    > /dev/null 2>&1
(cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$double_ast_file" "$double_mir_file") \
    > /dev/null 2>&1
(cd "$backend" && fo exec fortback-mir-v0 "$double_mir_file" "$double_elf_file") \
    > /dev/null 2>&1
if (cd "$frontend" && fo exec fortfront-source-ast-v1 "$negative_double_file" \
        "$run_dir/negative-double.ast.sx") > /dev/null 2>&1; then
    printf '%s\n' 'DOUBLE PRECISION source with missing declaration entity was accepted' >&2
    exit 1
fi
[ ! -e "$run_dir/negative-double.ast.sx" ]
qemu-riscv64 "$double_elf_file" > /dev/null
python3 "$oracle" "$double_ast_file" "$double_mir_file" "$double_elf_file" main double-precision

complex_ast_file="$run_dir/complex.frontend.ast.sx"
complex_mir_file="$run_dir/complex.mir.sx"
complex_elf_file="$run_dir/complex.program.elf"
(cd "$frontend" && fo exec fortfront-source-ast-v1 "$complex_source_file" "$complex_ast_file") \
    > /dev/null 2>&1
(cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$complex_ast_file" "$complex_mir_file") \
    > /dev/null 2>&1
(cd "$backend" && fo exec fortback-mir-v0 "$complex_mir_file" "$complex_elf_file") \
    > /dev/null 2>&1
if (cd "$frontend" && fo exec fortfront-source-ast-v1 "$negative_complex_file" \
        "$run_dir/negative-complex.ast.sx") > /dev/null 2>&1; then
    printf '%s\n' 'COMPLEX source with missing declaration entity was accepted' >&2
    exit 1
fi
[ ! -e "$run_dir/negative-complex.ast.sx" ]
qemu-riscv64 "$complex_elf_file" > /dev/null
python3 "$oracle" "$complex_ast_file" "$complex_mir_file" "$complex_elf_file" main complex

logical_ast_file="$run_dir/logical.frontend.ast.sx"
logical_mir_file="$run_dir/logical.mir.sx"
logical_elf_file="$run_dir/logical.program.elf"
(cd "$frontend" && fo exec fortfront-source-ast-v1 "$logical_source_file" "$logical_ast_file") \
    > /dev/null 2>&1
(cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$logical_ast_file" "$logical_mir_file") \
    > /dev/null 2>&1
(cd "$backend" && fo exec fortback-mir-v0 "$logical_mir_file" "$logical_elf_file") \
    > /dev/null 2>&1
if (cd "$frontend" && fo exec fortfront-source-ast-v1 "$negative_logical_file" \
        "$run_dir/negative-logical.ast.sx") > /dev/null 2>&1; then
    printf '%s\n' 'LOGICAL source with missing declaration entity was accepted' >&2
    exit 1
fi
[ ! -e "$run_dir/negative-logical.ast.sx" ]
qemu-riscv64 "$logical_elf_file" > /dev/null
python3 "$oracle" "$logical_ast_file" "$logical_mir_file" "$logical_elf_file" main logical

character_ast_file="$run_dir/character.frontend.ast.sx"
character_mir_file="$run_dir/character.mir.sx"
character_elf_file="$run_dir/character.program.elf"
(cd "$frontend" && fo exec fortfront-source-ast-v1 "$character_source_file" "$character_ast_file") \
    > /dev/null 2>&1
(cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$character_ast_file" "$character_mir_file") \
    > /dev/null 2>&1
(cd "$backend" && fo exec fortback-mir-v0 "$character_mir_file" "$character_elf_file") \
    > /dev/null 2>&1
if (cd "$frontend" && fo exec fortfront-source-ast-v1 "$negative_character_file" \
        "$run_dir/negative-character.ast.sx") > /dev/null 2>&1; then
    printf '%s\n' 'CHARACTER source with missing declaration entity was accepted' >&2
    exit 1
fi
[ ! -e "$run_dir/negative-character.ast.sx" ]
qemu-riscv64 "$character_elf_file" > /dev/null
python3 "$oracle" "$character_ast_file" "$character_mir_file" "$character_elf_file" main character

assignment_ast_file="$run_dir/assignment.frontend.ast.sx"
assignment_mir_file="$run_dir/assignment.mir.sx"
assignment_elf_file="$run_dir/assignment.program.elf"
(cd "$frontend" && fo exec fortfront-source-ast-v1 "$assignment_source_file" "$assignment_ast_file") \
    > /dev/null 2>&1
(cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$assignment_ast_file" "$assignment_mir_file") \
    > /dev/null 2>&1
(cd "$backend" && fo exec fortback-mir-v0 "$assignment_mir_file" "$assignment_elf_file") \
    > /dev/null 2>&1
for negative_assignment in "$negative_assignment_file" "$negative_assignment_name_file"; do
    if (cd "$frontend" && fo exec fortfront-source-ast-v1 "$negative_assignment" \
            "$run_dir/negative-assignment.ast.sx") > /dev/null 2>&1; then
        printf '%s\n' 'invalid assignment source was accepted' >&2
        exit 1
    fi
    [ ! -e "$run_dir/negative-assignment.ast.sx" ]
done
qemu-riscv64 "$assignment_elf_file" > /dev/null
python3 "$oracle" "$assignment_ast_file" "$assignment_mir_file" "$assignment_elf_file" main integer assignment

expression_ast_file="$run_dir/expression-assignment.frontend.ast.sx"
expression_mir_file="$run_dir/expression-assignment.mir.sx"
expression_elf_file="$run_dir/expression-assignment.program.elf"
(cd "$frontend" && fo exec fortfront-source-ast-v1 "$expression_assignment_source_file" \
        "$expression_ast_file") > /dev/null 2>&1
(cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$expression_ast_file" "$expression_mir_file") \
    > /dev/null 2>&1
(cd "$backend" && fo exec fortback-mir-v0 "$expression_mir_file" "$expression_elf_file") \
    > /dev/null 2>&1
for negative_expression in "$negative_expression_file" "$negative_expression_operator_file"; do
    if (cd "$frontend" && fo exec fortfront-source-ast-v1 "$negative_expression" \
            "$run_dir/negative-expression.ast.sx") > /dev/null 2>&1; then
        printf '%s\n' 'invalid expression assignment source was accepted' >&2
        exit 1
    fi
    [ ! -e "$run_dir/negative-expression.ast.sx" ]
done
if qemu-riscv64 "$expression_elf_file" > /dev/null; then
    expression_status=0
else
    expression_status=$?
fi
[ "$expression_status" -eq 3 ]
python3 "$oracle" "$expression_ast_file" "$expression_mir_file" "$expression_elf_file" main integer expression

multiplication_ast_file="$run_dir/multiplication-assignment.frontend.ast.sx"
multiplication_mir_file="$run_dir/multiplication-assignment.mir.sx"
multiplication_elf_file="$run_dir/multiplication-assignment.program.elf"
(cd "$frontend" && fo exec fortfront-source-ast-v1 "$multiplication_assignment_source_file" \
        "$multiplication_ast_file") > /dev/null 2>&1
(cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$multiplication_ast_file" "$multiplication_mir_file") \
    > /dev/null 2>&1
(cd "$backend" && fo exec fortback-mir-v0 "$multiplication_mir_file" "$multiplication_elf_file") \
    > /dev/null 2>&1
for negative_multiplication in "$negative_multiplication_file" "$negative_multiplication_operator_file"; do
    if (cd "$frontend" && fo exec fortfront-source-ast-v1 "$negative_multiplication" \
            "$run_dir/negative-multiplication.ast.sx") > /dev/null 2>&1; then
        printf '%s\n' 'invalid multiplication assignment source was accepted' >&2
        exit 1
    fi
    [ ! -e "$run_dir/negative-multiplication.ast.sx" ]
done
if qemu-riscv64 "$multiplication_elf_file" > /dev/null; then
    multiplication_status=0
else
    multiplication_status=$?
fi
[ "$multiplication_status" -eq 6 ]
python3 "$oracle" "$multiplication_ast_file" "$multiplication_mir_file" "$multiplication_elf_file" main integer multiplication

division_ast_file="$run_dir/division-assignment.frontend.ast.sx"
division_mir_file="$run_dir/division-assignment.mir.sx"
division_elf_file="$run_dir/division-assignment.program.elf"
(cd "$frontend" && fo exec fortfront-source-ast-v1 "$division_assignment_source_file" \
        "$division_ast_file") > /dev/null 2>&1
(cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$division_ast_file" "$division_mir_file") \
    > /dev/null 2>&1
(cd "$backend" && fo exec fortback-mir-v0 "$division_mir_file" "$division_elf_file") \
    > /dev/null 2>&1
for negative_division in "$negative_division_file" "$negative_division_operator_file"; do
    if (cd "$frontend" && fo exec fortfront-source-ast-v1 "$negative_division" \
            "$run_dir/negative-division.ast.sx") > /dev/null 2>&1; then
        printf '%s\n' 'invalid division assignment source was accepted' >&2
        exit 1
    fi
    [ ! -e "$run_dir/negative-division.ast.sx" ]
done
if qemu-riscv64 "$division_elf_file" > /dev/null; then
    division_status=0
else
    division_status=$?
fi
[ "$division_status" -eq 3 ]
python3 "$oracle" "$division_ast_file" "$division_mir_file" "$division_elf_file" main integer division

subtraction_ast_file="$run_dir/subtraction-assignment.frontend.ast.sx"
subtraction_mir_file="$run_dir/subtraction-assignment.mir.sx"
subtraction_elf_file="$run_dir/subtraction-assignment.program.elf"
(cd "$frontend" && fo exec fortfront-source-ast-v1 "$subtraction_assignment_source_file" \
        "$subtraction_ast_file") > /dev/null 2>&1
(cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$subtraction_ast_file" "$subtraction_mir_file") \
    > /dev/null 2>&1
(cd "$backend" && fo exec fortback-mir-v0 "$subtraction_mir_file" "$subtraction_elf_file") \
    > /dev/null 2>&1
for negative_subtraction in "$negative_subtraction_file" "$negative_subtraction_operator_file"; do
    if (cd "$frontend" && fo exec fortfront-source-ast-v1 "$negative_subtraction" \
            "$run_dir/negative-subtraction.ast.sx") > /dev/null 2>&1; then
        printf '%s\n' 'invalid subtraction assignment source was accepted' >&2
        exit 1
    fi
    [ ! -e "$run_dir/negative-subtraction.ast.sx" ]
done
if qemu-riscv64 "$subtraction_elf_file" > /dev/null; then
    subtraction_status=0
else
    subtraction_status=$?
fi
[ "$subtraction_status" -eq 2 ]
python3 "$oracle" "$subtraction_ast_file" "$subtraction_mir_file" "$subtraction_elf_file" main integer subtraction

literal_ast_file="$run_dir/literal-assignment.frontend.ast.sx"
literal_mir_file="$run_dir/literal-assignment.mir.sx"
literal_elf_file="$run_dir/literal-assignment.program.elf"
(cd "$frontend" && fo exec fortfront-source-ast-v1 "$literal_assignment_source_file" \
        "$literal_ast_file") > /dev/null 2>&1
(cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$literal_ast_file" "$literal_mir_file") \
    > /dev/null 2>&1
(cd "$backend" && fo exec fortback-mir-v0 "$literal_mir_file" "$literal_elf_file") \
    > /dev/null 2>&1
for negative_literal in "$negative_literal_range_file" "$negative_literal_form_file"; do
    if (cd "$frontend" && fo exec fortfront-source-ast-v1 "$negative_literal" \
            "$run_dir/negative-literal.ast.sx") > /dev/null 2>&1; then
        printf '%s\n' 'invalid integer literal source was accepted' >&2
        exit 1
    fi
    [ ! -e "$run_dir/negative-literal.ast.sx" ]
done
if qemu-riscv64 "$literal_elf_file" > /dev/null; then
    literal_status=0
else
    literal_status=$?
fi
[ "$literal_status" -eq 7 ]
python3 "$oracle" "$literal_ast_file" "$literal_mir_file" "$literal_elf_file" main integer literal

literal_boundary_ast_file="$run_dir/literal-boundary.frontend.ast.sx"
literal_boundary_mir_file="$run_dir/literal-boundary.mir.sx"
literal_boundary_elf_file="$run_dir/literal-boundary.program.elf"
(cd "$frontend" && fo exec fortfront-source-ast-v1 "$literal_boundary_source_file" \
        "$literal_boundary_ast_file") > /dev/null 2>&1
(cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$literal_boundary_ast_file" \
        "$literal_boundary_mir_file") > /dev/null 2>&1
(cd "$backend" && fo exec fortback-mir-v0 "$literal_boundary_mir_file" \
        "$literal_boundary_elf_file") > /dev/null 2>&1
if qemu-riscv64 "$literal_boundary_elf_file" > /dev/null; then
    literal_boundary_status=0
else
    literal_boundary_status=$?
fi
# POSIX process exit status exposes only the low byte; MIR/ELF checks retain 2047.
[ "$literal_boundary_status" -eq 255 ]
python3 "$oracle" "$literal_boundary_ast_file" "$literal_boundary_mir_file" \
    "$literal_boundary_elf_file" main integer literal-boundary

variable_expression_ast_file="$run_dir/variable-expression.frontend.ast.sx"
variable_expression_mir_file="$run_dir/variable-expression.mir.sx"
variable_expression_elf_file="$run_dir/variable-expression.program.elf"
(cd "$frontend" && fo exec fortfront-source-ast-v1 "$variable_expression_source_file" \
        "$variable_expression_ast_file") > /dev/null 2>&1
(cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$variable_expression_ast_file" \
        "$variable_expression_mir_file") > /dev/null 2>&1
(cd "$backend" && fo exec fortback-mir-v0 "$variable_expression_mir_file" \
        "$variable_expression_elf_file") > /dev/null 2>&1
if (cd "$frontend" && fo exec fortfront-source-ast-v1 "$negative_variable_expression_file" \
        "$run_dir/negative-variable-expression.ast.sx") > /dev/null 2>&1; then
    printf '%s\n' 'invalid variable expression source was accepted' >&2
    exit 1
fi
[ ! -e "$run_dir/negative-variable-expression.ast.sx" ]
if qemu-riscv64 "$variable_expression_elf_file" > /dev/null; then
    variable_expression_status=0
else
    variable_expression_status=$?
fi
[ "$variable_expression_status" -eq 1 ]
python3 "$oracle" "$variable_expression_ast_file" "$variable_expression_mir_file" \
    "$variable_expression_elf_file" main integer variable-expression

sequence_ast_file="$run_dir/sequence.frontend.ast.sx"
sequence_mir_file="$run_dir/sequence.mir.sx"
sequence_elf_file="$run_dir/sequence.program.elf"
(cd "$frontend" && fo exec fortfront-source-ast-v1 "$sequence_source_file" \
        "$sequence_ast_file") > /dev/null 2>&1
(cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$sequence_ast_file" \
        "$sequence_mir_file") > /dev/null 2>&1
(cd "$backend" && fo exec fortback-mir-v0 "$sequence_mir_file" \
        "$sequence_elf_file") > /dev/null 2>&1
for negative_sequence in "${negative_sequence_files[@]}"; do
    rm -f "$run_dir/negative-sequence.ast.sx"
    if (cd "$frontend" && fo exec fortfront-source-ast-v1 "$negative_sequence" \
            "$run_dir/negative-sequence.ast.sx") > /dev/null 2>&1; then
        if grep -q '^(assignment-sequence ' "$run_dir/negative-sequence.ast.sx"; then
            printf '%s\n' 'invalid two-assignment sequence source was promoted' >&2
            exit 1
        fi
    else
        [ ! -e "$run_dir/negative-sequence.ast.sx" ]
    fi
done
if qemu-riscv64 "$sequence_elf_file" > /dev/null; then
    sequence_status=0
else
    sequence_status=$?
fi
[ "$sequence_status" -eq 8 ]
python3 "$oracle" "$sequence_ast_file" "$sequence_mir_file" \
    "$sequence_elf_file" main integer sequence

run_sequence_batch_route 3 "$sequence_three_source_file" 9 sequence-3 \
    "${negative_sequence_three_files[@]}"
run_sequence_batch_route 4 "$sequence_four_source_file" 10 sequence-4 \
    "${negative_sequence_four_files[@]}"
run_sequence_batch_route 5 "$sequence_five_source_file" 11 sequence-5 \
    "${negative_sequence_five_files[@]}"
run_sequence_batch_route 6 "$sequence_six_source_file" 12 sequence-6 \
    "${negative_sequence_six_files[@]}"

run_sequence_batch_route 7 "$sequence_seven_source_file" 13 sequence-7
run_sequence_batch_route 8 "$sequence_eight_source_file" 14 sequence-8
run_sequence_batch_route 9 "$sequence_nine_source_file" 15 sequence-9
run_sequence_batch_route 10 "$sequence_ten_source_file" 16 sequence-10 \
    "${negative_sequence_ten_files[@]}"

stop_ast_file="$run_dir/stop.frontend.ast.sx"
stop_mir_file="$run_dir/stop.mir.sx"
stop_elf_file="$run_dir/stop.program.elf"
(cd "$frontend" && fo exec fortfront-program-unit-v2 "$stop_source_file" \
        "$stop_ast_file") > /dev/null 2>&1
(cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$stop_ast_file" \
        "$stop_mir_file") > /dev/null 2>&1
(cd "$backend" && fo exec fortback-mir-v0 "$stop_mir_file" \
        "$stop_elf_file") > /dev/null 2>&1
for negative_stop in "${negative_stop_files[@]}"; do
    rm -f "$run_dir/negative-stop.ast.sx"
    if (cd "$frontend" && fo exec fortfront-program-unit-v2 "$negative_stop" \
            "$run_dir/negative-stop.ast.sx") > /dev/null 2>&1; then
        printf '%s\n' 'invalid STOP mutation was accepted' >&2
        exit 1
    fi
    [ ! -e "$run_dir/negative-stop.ast.sx" ]
done
if qemu-riscv64 "$stop_elf_file" > /dev/null; then
    stop_status=0
else
    stop_status=$?
fi
[ "$stop_status" -eq 7 ]
python3 "$oracle" "$stop_ast_file" "$stop_mir_file" "$stop_elf_file" p integer stop-7

print_ast_file="$run_dir/print.frontend.ast.sx"
print_mir_file="$run_dir/print.mir.sx"
print_elf_file="$run_dir/print.program.elf"
print_output_file="$run_dir/print.stdout"
(cd "$frontend" && fo exec fortfront-program-unit-v2 "$print_source_file" \
        "$print_ast_file") > /dev/null 2>&1
(cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$print_ast_file" \
        "$print_mir_file") > /dev/null 2>&1
(cd "$backend" && fo exec fortback-mir-v0 "$print_mir_file" \
        "$print_elf_file") > /dev/null 2>&1
for negative_print in "${negative_print_files[@]}"; do
    rm -f "$run_dir/negative-print.ast.sx"
    if (cd "$frontend" && fo exec fortfront-program-unit-v2 "$negative_print" \
            "$run_dir/negative-print.ast.sx") > /dev/null 2>&1; then
        printf '%s\n' 'invalid PRINT mutation was accepted' >&2
        exit 1
    fi
    [ ! -e "$run_dir/negative-print.ast.sx" ]
done
qemu-riscv64 "$print_elf_file" > "$print_output_file"
printf '7\n' | cmp -s - "$print_output_file"
python3 "$oracle" "$print_ast_file" "$print_mir_file" "$print_elf_file" p integer print-7

print_two_item_ast_file="$run_dir/print-two-item.frontend.ast.sx"
print_two_item_mir_file="$run_dir/print-two-item.mir.sx"
print_two_item_elf_file="$run_dir/print-two-item.program.elf"
print_two_item_output_file="$run_dir/print-two-item.stdout"
run_print_literal_route() {
    local count="$1"
    local source="$2"
    local route="$3"
    local error_label="$4"
    local mode="$5"
    shift 5
    local ast="$run_dir/print-${route}.frontend.ast.sx"
    local mir="$run_dir/print-${route}.mir.sx"
    local elf="$run_dir/print-${route}.program.elf"
    local output="$run_dir/print-${route}.stdout"
    local negative
    local value

    (cd "$frontend" && fo exec fortfront-program-unit-v2 "$source" "$ast") \
        > /dev/null 2>&1
    (cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$ast" "$mir") \
        > /dev/null 2>&1
    (cd "$backend" && fo exec fortback-mir-v0 "$mir" "$elf") \
        > /dev/null 2>&1
    for negative in "$@"; do
        rm -f "$run_dir/negative-print-${route}.ast.sx"
        if (cd "$frontend" && fo exec fortfront-program-unit-v2 "$negative" \
                "$run_dir/negative-print-${route}.ast.sx") > /dev/null 2>&1; then
            printf 'invalid %s PRINT mutation was accepted\n' "$error_label" >&2
            exit 1
        fi
        [ ! -e "$run_dir/negative-print-${route}.ast.sx" ]
    done
    qemu-riscv64 "$elf" > "$output"
    {
        for ((value = 7; value <= 6 + count; value++)); do
            printf '%s\n' "$value"
        done
    } | cmp -s - "$output"
    python3 "$oracle" "$ast" "$mir" "$elf" p integer "$mode"
}

run_print_literal_route 2 "$print_two_item_source_file" two-item two-item \
    print-7-8 "${negative_print_two_item_files[@]}"
run_print_literal_route 3 "$print_three_item_source_file" three-item three-item \
    print-7-8-9 "${negative_print_three_item_files[@]}"
run_print_literal_route 4 "$print_four_item_source_file" four-item four-item \
    print-7-8-9-10 "${negative_print_four_item_files[@]}"
run_print_literal_route 5 "$print_five_item_source_file" five-item five-item \
    print-7-8-9-10-11 "${negative_print_five_item_files[@]}"
run_print_literal_route 6 "$print_six_item_source_file" six-item six-item \
    print-7-8-9-10-11-12 "${negative_print_six_item_files[@]}"
run_print_literal_route 7 "$print_seven_item_source_file" seven-item seven-item \
    print-7-8-9-10-11-12-13 "${negative_print_seven_item_files[@]}"
run_print_literal_route 8 "$print_eight_item_source_file" eight-item eight-item \
    print-7-8-9-10-11-12-13-14 "${negative_print_eight_item_files[@]}"
run_print_literal_route 9 "$print_nine_item_source_file" nine-item nine-item \
    print-7-8-9-10-11-12-13-14-15 "${negative_print_nine_item_files[@]}"
run_print_literal_route 10 "$print_ten_item_source_file" ten-item ten-item \
    print-7-8-9-10-11-12-13-14-15-16 "${negative_print_ten_item_files[@]}"
print_generic_item_ast_file="$run_dir/print-generic-items.frontend.ast.sx"
print_generic_item_mir_file="$run_dir/print-generic-items.mir.sx"
print_generic_item_elf_file="$run_dir/print-generic-items.program.elf"
print_generic_item_output_file="$run_dir/print-generic-items.stdout"
(cd "$frontend" && fo exec fortfront-program-unit-v2 "$print_generic_item_source_file" \
        "$print_generic_item_ast_file") > /dev/null 2>&1
(cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$print_generic_item_ast_file" \
        "$print_generic_item_mir_file") > /dev/null 2>&1
(cd "$backend" && fo exec fortback-mir-v0 "$print_generic_item_mir_file" \
        "$print_generic_item_elf_file") > /dev/null 2>&1
for negative_print_generic_item in "${negative_print_generic_item_files[@]}"; do
    rm -f "$run_dir/negative-print-generic-items.ast.sx"
    if (cd "$frontend" && fo exec fortfront-program-unit-v2 "$negative_print_generic_item" \
            "$run_dir/negative-print-generic-items.ast.sx") > /dev/null 2>&1; then
        printf '%s\n' 'invalid generic PRINT mutation was accepted' >&2
        exit 1
    fi
    [ ! -e "$run_dir/negative-print-generic-items.ast.sx" ]
done
qemu-riscv64 "$print_generic_item_elf_file" > "$print_generic_item_output_file"
printf '17\n18\n19\n' | cmp -s - "$print_generic_item_output_file"
python3 "$oracle" "$print_generic_item_ast_file" "$print_generic_item_mir_file" \
    "$print_generic_item_elf_file" p integer print-generic-items

print_variable_ast_file="$run_dir/print-variable.frontend.ast.sx"
print_variable_mir_file="$run_dir/print-variable.mir.sx"
print_variable_elf_file="$run_dir/print-variable.program.elf"
print_variable_output_file="$run_dir/print-variable.stdout"
(cd "$frontend" && fo exec fortfront-program-unit-v2 "$print_variable_source_file" \
        "$print_variable_ast_file") > /dev/null 2>&1
(cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$print_variable_ast_file" \
        "$print_variable_mir_file") > /dev/null 2>&1
(cd "$backend" && fo exec fortback-mir-v0 "$print_variable_mir_file" \
        "$print_variable_elf_file") > /dev/null 2>&1
for negative_print_variable in "${negative_print_variable_files[@]}"; do
    rm -f "$run_dir/negative-print-variable.ast.sx"
    if (cd "$frontend" && fo exec fortfront-program-unit-v2 "$negative_print_variable" \
            "$run_dir/negative-print-variable.ast.sx") > /dev/null 2>&1; then
        printf '%s\n' 'invalid stored-variable PRINT mutation was accepted' >&2
        exit 1
    fi
    [ ! -e "$run_dir/negative-print-variable.ast.sx" ]
done
qemu-riscv64 "$print_variable_elf_file" > "$print_variable_output_file"
printf '17\n' | cmp -s - "$print_variable_output_file"
python3 "$oracle" "$print_variable_ast_file" "$print_variable_mir_file" \
    "$print_variable_elf_file" main integer print-variable "$print_variable_source_file"

print_variable_mutated_ast_file="$run_dir/print-variable.mutated-source.ast.sx"
sed 's/l3-raw-program-v2/l3-mutated-program-v2/' "$print_variable_ast_file" \
    > "$print_variable_mutated_ast_file"
if python3 "$oracle" "$print_variable_mutated_ast_file" "$print_variable_mir_file" \
        "$print_variable_elf_file" main integer print-variable "$print_variable_source_file" \
        > /dev/null 2>&1; then
    printf '%s\n' 'stored-variable AST source mutation was accepted' >&2
    exit 1
fi
print_variable_mutated_file_ast_file="$run_dir/print-variable.mutated-file.ast.sx"
sed "s|(file $print_variable_source_file)|(file /tmp/not-the-positive-fixture.f90)|" \
    "$print_variable_ast_file" > "$print_variable_mutated_file_ast_file"
if python3 "$oracle" "$print_variable_mutated_file_ast_file" "$print_variable_mir_file" \
        "$print_variable_elf_file" main integer print-variable "$print_variable_source_file" \
        > /dev/null 2>&1; then
    printf '%s\n' 'stored-variable AST file mutation was accepted' >&2
    exit 1
fi
print_variable_mutated_span_ast_file="$run_dir/print-variable.mutated-span.ast.sx"
sed 's/(start-byte 37) (end-byte 48)/(start-byte 99) (end-byte 100)/' \
    "$print_variable_ast_file" > "$print_variable_mutated_span_ast_file"
if python3 "$oracle" "$print_variable_mutated_span_ast_file" "$print_variable_mir_file" \
        "$print_variable_elf_file" main integer print-variable "$print_variable_source_file" \
        > /dev/null 2>&1; then
    printf '%s\n' 'stored-variable AST span mutation was accepted' >&2
    exit 1
fi
print_variable_mutated_provenance_ast_file="$run_dir/print-variable.mutated-provenance.ast.sx"
sed 's/(source-hash 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2)/(source-hash mutated-print-source)/' \
    "$print_variable_ast_file" > "$print_variable_mutated_provenance_ast_file"
if python3 "$oracle" "$print_variable_mutated_provenance_ast_file" "$print_variable_mir_file" \
        "$print_variable_elf_file" main integer print-variable "$print_variable_source_file" \
        > /dev/null 2>&1; then
    printf '%s\n' 'stored-variable PRINT provenance mutation was accepted' >&2
    exit 1
fi
print_variable_mutated_mir_file="$run_dir/print-variable.mutated-opcode.mir.sx"
sed 's/(opcode load)/(opcode store)/' "$print_variable_mir_file" \
    > "$print_variable_mutated_mir_file"
if python3 "$oracle" "$print_variable_ast_file" "$print_variable_mutated_mir_file" \
        "$print_variable_elf_file" main integer print-variable "$print_variable_source_file" \
        > /dev/null 2>&1; then
    printf '%s\n' 'stored-variable MIR opcode mutation was accepted' >&2
    exit 1
fi

print_variable_23_ast_file="$run_dir/print-variable-23.frontend.ast.sx"
print_variable_23_mir_file="$run_dir/print-variable-23.mir.sx"
print_variable_23_elf_file="$run_dir/print-variable-23.program.elf"
print_variable_23_output_file="$run_dir/print-variable-23.stdout"
(cd "$frontend" && fo exec fortfront-program-unit-v2 "$print_variable_23_source_file" \
        "$print_variable_23_ast_file") > /dev/null 2>&1
(cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$print_variable_23_ast_file" \
        "$print_variable_23_mir_file") > /dev/null 2>&1
(cd "$backend" && fo exec fortback-mir-v0 "$print_variable_23_mir_file" \
        "$print_variable_23_elf_file") > /dev/null 2>&1
for negative_print_variable_23 in "${negative_print_variable_23_files[@]}"; do
    rm -f "$run_dir/negative-print-variable-23.ast.sx"
    if (cd "$frontend" && fo exec fortfront-program-unit-v2 "$negative_print_variable_23" \
            "$run_dir/negative-print-variable-23.ast.sx") > /dev/null 2>&1; then
        printf '%s\n' 'invalid stored-variable PRINT-23 mutation was accepted' >&2
        exit 1
    fi
    [ ! -e "$run_dir/negative-print-variable-23.ast.sx" ]
done
qemu-riscv64 "$print_variable_23_elf_file" > "$print_variable_23_output_file"
printf '23\n' | cmp -s - "$print_variable_23_output_file"
python3 "$oracle" "$print_variable_23_ast_file" "$print_variable_23_mir_file" \
    "$print_variable_23_elf_file" main integer print-variable "$print_variable_23_source_file"
print_variable_23_mutated_ast_file="$run_dir/print-variable-23.mutated-literal.ast.sx"
sed 's/(left-operand 23)/(left-operand 24)/' "$print_variable_23_ast_file" \
    > "$print_variable_23_mutated_ast_file"
if python3 "$oracle" "$print_variable_23_mutated_ast_file" "$print_variable_23_mir_file" \
        "$print_variable_23_elf_file" main integer print-variable "$print_variable_23_source_file" \
        > /dev/null 2>&1; then
    printf '%s\n' 'stored-variable-23 AST literal mutation was accepted' >&2
    exit 1
fi
print_variable_23_mutated_mir_file="$run_dir/print-variable-23.mutated-opcode.mir.sx"
sed 's/(opcode load)/(opcode store)/' "$print_variable_23_mir_file" \
    > "$print_variable_23_mutated_mir_file"
if python3 "$oracle" "$print_variable_23_ast_file" "$print_variable_23_mutated_mir_file" \
        "$print_variable_23_elf_file" main integer print-variable "$print_variable_23_source_file" \
        > /dev/null 2>&1; then
    printf '%s\n' 'stored-variable-23 MIR opcode mutation was accepted' >&2
    exit 1
fi
print_variable_23_mutated_elf_file="$run_dir/print-variable-23.mutated.elf"
cp "$print_variable_23_elf_file" "$print_variable_23_mutated_elf_file"
printf '\0' | dd of="$print_variable_23_mutated_elf_file" bs=1 seek=0 count=1 conv=notrunc \
    > /dev/null 2>&1
if python3 "$oracle" "$print_variable_23_ast_file" "$print_variable_23_mir_file" \
        "$print_variable_23_mutated_elf_file" main integer print-variable "$print_variable_23_source_file" \
        > /dev/null 2>&1; then
    printf '%s\n' 'stored-variable-23 ELF mutation was accepted' >&2
    exit 1
fi

print_variable_expression_ast_file="$run_dir/print-variable-expression.frontend.ast.sx"
print_variable_expression_mir_file="$run_dir/print-variable-expression.mir.sx"
print_variable_expression_elf_file="$run_dir/print-variable-expression.program.elf"
print_variable_expression_output_file="$run_dir/print-variable-expression.stdout"
(cd "$frontend" && fo exec fortfront-program-unit-v2 "$print_variable_expression_source_file" \
        "$print_variable_expression_ast_file") > /dev/null 2>&1
(cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$print_variable_expression_ast_file" \
        "$print_variable_expression_mir_file") > /dev/null 2>&1
(cd "$backend" && fo exec fortback-mir-v0 "$print_variable_expression_mir_file" \
        "$print_variable_expression_elf_file") > /dev/null 2>&1
for negative_print_variable_expression in "${negative_print_variable_expression_files[@]}"; do
    rm -f "$run_dir/negative-print-variable-expression.ast.sx"
    if (cd "$frontend" && fo exec fortfront-program-unit-v2 "$negative_print_variable_expression" \
            "$run_dir/negative-print-variable-expression.ast.sx") > /dev/null 2>&1; then
        printf '%s\n' 'invalid variable-expression PRINT mutation was accepted' >&2
        exit 1
    fi
    [ ! -e "$run_dir/negative-print-variable-expression.ast.sx" ]
done
qemu-riscv64 "$print_variable_expression_elf_file" > "$print_variable_expression_output_file"
printf '24\n' | cmp -s - "$print_variable_expression_output_file"
python3 "$oracle" "$print_variable_expression_ast_file" "$print_variable_expression_mir_file" \
    "$print_variable_expression_elf_file" main integer print-variable-expression \
    "$print_variable_expression_source_file"
print_variable_expression_mutated_ast_file="$run_dir/print-variable-expression.mutated-literal.ast.sx"
sed 's/(left-operand 23)/(left-operand 24)/' "$print_variable_expression_ast_file" \
    > "$print_variable_expression_mutated_ast_file"
if python3 "$oracle" "$print_variable_expression_mutated_ast_file" \
        "$print_variable_expression_mir_file" "$print_variable_expression_elf_file" \
        main integer print-variable-expression "$print_variable_expression_source_file" \
        > /dev/null 2>&1; then
    printf '%s\n' 'variable-expression AST literal mutation was accepted' >&2
    exit 1
fi
print_variable_expression_mutated_mir_file="$run_dir/print-variable-expression.mutated-opcode.mir.sx"
sed 's/(opcode add)/(opcode load)/' "$print_variable_expression_mir_file" \
    > "$print_variable_expression_mutated_mir_file"
if python3 "$oracle" "$print_variable_expression_ast_file" \
        "$print_variable_expression_mutated_mir_file" "$print_variable_expression_elf_file" \
        main integer print-variable-expression "$print_variable_expression_source_file" \
        > /dev/null 2>&1; then
    printf '%s\n' 'variable-expression MIR opcode mutation was accepted' >&2
    exit 1
fi
print_variable_expression_mutated_elf_file="$run_dir/print-variable-expression.mutated.elf"
cp "$print_variable_expression_elf_file" "$print_variable_expression_mutated_elf_file"
printf '\0' | dd of="$print_variable_expression_mutated_elf_file" bs=1 seek=0 count=1 conv=notrunc \
    > /dev/null 2>&1
if python3 "$oracle" "$print_variable_expression_ast_file" \
        "$print_variable_expression_mir_file" "$print_variable_expression_mutated_elf_file" \
        main integer print-variable-expression "$print_variable_expression_source_file" \
        > /dev/null 2>&1; then
    printf '%s\n' 'variable-expression ELF mutation was accepted' >&2
    exit 1
fi

print_variable_multiply_expression_ast_file="$run_dir/print-variable-multiply-expression.frontend.ast.sx"
print_variable_multiply_expression_mir_file="$run_dir/print-variable-multiply-expression.mir.sx"
print_variable_multiply_expression_elf_file="$run_dir/print-variable-multiply-expression.program.elf"
print_variable_multiply_expression_output_file="$run_dir/print-variable-multiply-expression.stdout"
(cd "$frontend" && fo exec fortfront-program-unit-v2 "$print_variable_multiply_expression_source_file" \
        "$print_variable_multiply_expression_ast_file") > /dev/null 2>&1
(cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$print_variable_multiply_expression_ast_file" \
        "$print_variable_multiply_expression_mir_file") > /dev/null 2>&1
(cd "$backend" && fo exec fortback-mir-v0 "$print_variable_multiply_expression_mir_file" \
        "$print_variable_multiply_expression_elf_file") > /dev/null 2>&1
for negative_print_variable_multiply_expression in "${negative_print_variable_multiply_expression_files[@]}"; do
    rm -f "$run_dir/negative-print-variable-multiply-expression.ast.sx"
    if (cd "$frontend" && fo exec fortfront-program-unit-v2 "$negative_print_variable_multiply_expression" \
            "$run_dir/negative-print-variable-multiply-expression.ast.sx") > /dev/null 2>&1; then
        printf '%s\n' 'invalid variable-multiply-expression PRINT mutation was accepted' >&2
        exit 1
    fi
    [ ! -e "$run_dir/negative-print-variable-multiply-expression.ast.sx" ]
done
qemu-riscv64 "$print_variable_multiply_expression_elf_file" > "$print_variable_multiply_expression_output_file"
printf '46\n' | cmp -s - "$print_variable_multiply_expression_output_file"
python3 "$oracle" "$print_variable_multiply_expression_ast_file" \
    "$print_variable_multiply_expression_mir_file" "$print_variable_multiply_expression_elf_file" \
    main integer print-variable-expression "$print_variable_multiply_expression_source_file"
print_variable_multiply_expression_mutated_ast_file="$run_dir/print-variable-multiply-expression.mutated-operator.ast.sx"
sed 's/(operator \*)/(operator +)/' "$print_variable_multiply_expression_ast_file" \
    > "$print_variable_multiply_expression_mutated_ast_file"
if python3 "$oracle" "$print_variable_multiply_expression_mutated_ast_file" \
        "$print_variable_multiply_expression_mir_file" "$print_variable_multiply_expression_elf_file" \
        main integer print-variable-expression "$print_variable_multiply_expression_source_file" \
        > /dev/null 2>&1; then
    printf '%s\n' 'variable-multiply-expression AST operator mutation was accepted' >&2
    exit 1
fi
print_variable_multiply_expression_mutated_mir_file="$run_dir/print-variable-multiply-expression.mutated-opcode.mir.sx"
sed 's/(opcode mul)/(opcode add)/' "$print_variable_multiply_expression_mir_file" \
    > "$print_variable_multiply_expression_mutated_mir_file"
if python3 "$oracle" "$print_variable_multiply_expression_ast_file" \
        "$print_variable_multiply_expression_mutated_mir_file" "$print_variable_multiply_expression_elf_file" \
        main integer print-variable-expression "$print_variable_multiply_expression_source_file" \
        > /dev/null 2>&1; then
    printf '%s\n' 'variable-multiply-expression MIR opcode mutation was accepted' >&2
    exit 1
fi
print_variable_multiply_expression_mutated_elf_file="$run_dir/print-variable-multiply-expression.mutated.elf"
cp "$print_variable_multiply_expression_elf_file" "$print_variable_multiply_expression_mutated_elf_file"
printf '\0' | dd of="$print_variable_multiply_expression_mutated_elf_file" bs=1 seek=0 count=1 conv=notrunc \
    > /dev/null 2>&1
if python3 "$oracle" "$print_variable_multiply_expression_ast_file" \
        "$print_variable_multiply_expression_mir_file" "$print_variable_multiply_expression_mutated_elf_file" \
        main integer print-variable-expression "$print_variable_multiply_expression_source_file" \
        > /dev/null 2>&1; then
    printf '%s\n' 'variable-multiply-expression ELF mutation was accepted' >&2
    exit 1
fi

for arithmetic_operator in subtract divide; do
    if [ "$arithmetic_operator" = subtract ]; then
        arithmetic_source_file="$print_variable_subtract_expression_source_file"
        arithmetic_negative_files=("${negative_print_variable_subtract_expression_files[@]}")
        arithmetic_output='21\n'
        arithmetic_ast_mutation='s/(operator –)/(operator +)/'
        arithmetic_mir_mutation='s/(opcode sub)/(opcode add)/'
    else
        arithmetic_source_file="$print_variable_divide_expression_source_file"
        arithmetic_negative_files=("${negative_print_variable_divide_expression_files[@]}")
        arithmetic_output='12\n'
        arithmetic_ast_mutation='s/(operator \/)/(operator +)/'
        arithmetic_mir_mutation='s/(opcode div)/(opcode add)/'
    fi
    arithmetic_ast_file="$run_dir/print-variable-$arithmetic_operator-expression.frontend.ast.sx"
    arithmetic_mir_file="$run_dir/print-variable-$arithmetic_operator-expression.mir.sx"
    arithmetic_elf_file="$run_dir/print-variable-$arithmetic_operator-expression.program.elf"
    arithmetic_output_file="$run_dir/print-variable-$arithmetic_operator-expression.stdout"
    (cd "$frontend" && fo exec fortfront-program-unit-v2 "$arithmetic_source_file" \
            "$arithmetic_ast_file") > /dev/null 2>&1
    (cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$arithmetic_ast_file" \
            "$arithmetic_mir_file") > /dev/null 2>&1
    (cd "$backend" && fo exec fortback-mir-v0 "$arithmetic_mir_file" \
            "$arithmetic_elf_file") > /dev/null 2>&1
    for negative_arithmetic in "${arithmetic_negative_files[@]}"; do
        rm -f "$run_dir/negative-print-variable-$arithmetic_operator-expression.ast.sx"
        if (cd "$frontend" && fo exec fortfront-program-unit-v2 "$negative_arithmetic" \
                "$run_dir/negative-print-variable-$arithmetic_operator-expression.ast.sx") > /dev/null 2>&1; then
            printf 'invalid variable-%s-expression PRINT mutation was accepted\n' "$arithmetic_operator" >&2
            exit 1
        fi
        [ ! -e "$run_dir/negative-print-variable-$arithmetic_operator-expression.ast.sx" ]
    done
    qemu-riscv64 "$arithmetic_elf_file" > "$arithmetic_output_file"
    printf "$arithmetic_output" | cmp -s - "$arithmetic_output_file"
    python3 "$oracle" "$arithmetic_ast_file" "$arithmetic_mir_file" \
        "$arithmetic_elf_file" main integer print-variable-expression "$arithmetic_source_file"
    arithmetic_mutated_ast_file="$run_dir/print-variable-$arithmetic_operator-expression.mutated-operator.ast.sx"
    sed "$arithmetic_ast_mutation" "$arithmetic_ast_file" > "$arithmetic_mutated_ast_file"
    if python3 "$oracle" "$arithmetic_mutated_ast_file" "$arithmetic_mir_file" \
            "$arithmetic_elf_file" main integer print-variable-expression "$arithmetic_source_file" \
            > /dev/null 2>&1; then
        printf 'variable-%s-expression AST operator mutation was accepted\n' "$arithmetic_operator" >&2
        exit 1
    fi
    arithmetic_mutated_mir_file="$run_dir/print-variable-$arithmetic_operator-expression.mutated-opcode.mir.sx"
    sed "$arithmetic_mir_mutation" "$arithmetic_mir_file" > "$arithmetic_mutated_mir_file"
    if python3 "$oracle" "$arithmetic_ast_file" "$arithmetic_mutated_mir_file" \
            "$arithmetic_elf_file" main integer print-variable-expression "$arithmetic_source_file" \
            > /dev/null 2>&1; then
        printf 'variable-%s-expression MIR opcode mutation was accepted\n' "$arithmetic_operator" >&2
        exit 1
    fi
    arithmetic_mutated_elf_file="$run_dir/print-variable-$arithmetic_operator-expression.mutated.elf"
    cp "$arithmetic_elf_file" "$arithmetic_mutated_elf_file"
    printf '\0' | dd of="$arithmetic_mutated_elf_file" bs=1 seek=0 count=1 conv=notrunc \
        > /dev/null 2>&1
    if python3 "$oracle" "$arithmetic_ast_file" "$arithmetic_mir_file" \
            "$arithmetic_mutated_elf_file" main integer print-variable-expression "$arithmetic_source_file" \
            > /dev/null 2>&1; then
        printf 'variable-%s-expression ELF mutation was accepted\n' "$arithmetic_operator" >&2
        exit 1
    fi
done

print_variable_power_expression_ast_file="$run_dir/print-variable-power-expression.frontend.ast.sx"
print_variable_power_expression_mir_file="$run_dir/print-variable-power-expression.mir.sx"
print_variable_power_expression_elf_file="$run_dir/print-variable-power-expression.program.elf"
print_variable_power_expression_output_file="$run_dir/print-variable-power-expression.stdout"
(cd "$frontend" && fo exec fortfront-program-unit-v2 "$print_variable_power_expression_source_file" \
        "$print_variable_power_expression_ast_file") > /dev/null 2>&1
(cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$print_variable_power_expression_ast_file" \
        "$print_variable_power_expression_mir_file") > /dev/null 2>&1
(cd "$backend" && fo exec fortback-mir-v0 "$print_variable_power_expression_mir_file" \
        "$print_variable_power_expression_elf_file") > /dev/null 2>&1
for negative_print_variable_power_expression in "${negative_print_variable_power_expression_files[@]}"; do
    rm -f "$run_dir/negative-print-variable-power-expression.ast.sx"
    if (cd "$frontend" && fo exec fortfront-program-unit-v2 "$negative_print_variable_power_expression" \
            "$run_dir/negative-print-variable-power-expression.ast.sx") > /dev/null 2>&1; then
        printf '%s\n' 'invalid variable-power-expression PRINT mutation was accepted' >&2
        exit 1
    fi
    [ ! -e "$run_dir/negative-print-variable-power-expression.ast.sx" ]
done
qemu-riscv64 "$print_variable_power_expression_elf_file" > "$print_variable_power_expression_output_file"
printf '8\n' | cmp -s - "$print_variable_power_expression_output_file"
python3 "$oracle" "$print_variable_power_expression_ast_file" \
    "$print_variable_power_expression_mir_file" "$print_variable_power_expression_elf_file" \
    main integer print-variable-expression "$print_variable_power_expression_source_file"
print_variable_power_expression_mutated_ast_file="$run_dir/print-variable-power-expression.mutated-operator.ast.sx"
sed 's/(operator \*\*)/(operator +)/' "$print_variable_power_expression_ast_file" \
    > "$print_variable_power_expression_mutated_ast_file"
if python3 "$oracle" "$print_variable_power_expression_mutated_ast_file" \
        "$print_variable_power_expression_mir_file" "$print_variable_power_expression_elf_file" \
        main integer print-variable-expression "$print_variable_power_expression_source_file" \
        > /dev/null 2>&1; then
    printf '%s\n' 'variable-power-expression AST operator mutation was accepted' >&2
    exit 1
fi
print_variable_power_expression_mutated_mir_file="$run_dir/print-variable-power-expression.mutated-opcode.mir.sx"
sed 's/(opcode pow)/(opcode add)/' "$print_variable_power_expression_mir_file" \
    > "$print_variable_power_expression_mutated_mir_file"
if python3 "$oracle" "$print_variable_power_expression_ast_file" \
        "$print_variable_power_expression_mutated_mir_file" "$print_variable_power_expression_elf_file" \
        main integer print-variable-expression "$print_variable_power_expression_source_file" \
        > /dev/null 2>&1; then
    printf '%s\n' 'variable-power-expression MIR opcode mutation was accepted' >&2
    exit 1
fi
print_variable_power_expression_mutated_elf_file="$run_dir/print-variable-power-expression.mutated.elf"
cp "$print_variable_power_expression_elf_file" "$print_variable_power_expression_mutated_elf_file"
printf '\0' | dd of="$print_variable_power_expression_mutated_elf_file" bs=1 seek=0 count=1 conv=notrunc \
    > /dev/null 2>&1
if python3 "$oracle" "$print_variable_power_expression_ast_file" \
        "$print_variable_power_expression_mir_file" "$print_variable_power_expression_mutated_elf_file" \
        main integer print-variable-expression "$print_variable_power_expression_source_file" \
        > /dev/null 2>&1; then
    printf '%s\n' 'variable-power-expression ELF mutation was accepted' >&2
    exit 1
fi

print_variable_power_value_ast_file="$run_dir/print-variable-power-value.frontend.ast.sx"
print_variable_power_value_mir_file="$run_dir/print-variable-power-value.mir.sx"
print_variable_power_value_elf_file="$run_dir/print-variable-power-value.program.elf"
print_variable_power_value_output_file="$run_dir/print-variable-power-value.stdout"
(cd "$frontend" && fo exec fortfront-program-unit-v2 "$print_variable_power_value_source_file" \
        "$print_variable_power_value_ast_file") > /dev/null 2>&1
(cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$print_variable_power_value_ast_file" \
        "$print_variable_power_value_mir_file") > /dev/null 2>&1
(cd "$backend" && fo exec fortback-mir-v0 "$print_variable_power_value_mir_file" \
        "$print_variable_power_value_elf_file") > /dev/null 2>&1
for negative_print_variable_power_value in "${negative_print_variable_power_value_files[@]}"; do
    rm -f "$run_dir/negative-print-variable-power-value.ast.sx"
    if (cd "$frontend" && fo exec fortfront-program-unit-v2 "$negative_print_variable_power_value" \
            "$run_dir/negative-print-variable-power-value.ast.sx") > /dev/null 2>&1; then
        printf '%s\n' 'invalid variable-power-value PRINT mutation was accepted' >&2
        exit 1
    fi
    [ ! -e "$run_dir/negative-print-variable-power-value.ast.sx" ]
done
qemu-riscv64 "$print_variable_power_value_elf_file" > "$print_variable_power_value_output_file"
printf '9\n' | cmp -s - "$print_variable_power_value_output_file"
python3 "$oracle" "$print_variable_power_value_ast_file" \
    "$print_variable_power_value_mir_file" "$print_variable_power_value_elf_file" \
    main integer print-variable-expression "$print_variable_power_value_source_file"
print_variable_power_value_mutated_ast_file="$run_dir/print-variable-power-value.mutated-operator.ast.sx"
sed 's/(operator \*\*)/(operator +)/' "$print_variable_power_value_ast_file" \
    > "$print_variable_power_value_mutated_ast_file"
if python3 "$oracle" "$print_variable_power_value_mutated_ast_file" \
        "$print_variable_power_value_mir_file" "$print_variable_power_value_elf_file" \
        main integer print-variable-expression "$print_variable_power_value_source_file" \
        > /dev/null 2>&1; then
    printf '%s\n' 'variable-power-value AST operator mutation was accepted' >&2
    exit 1
fi
print_variable_power_value_mutated_mir_file="$run_dir/print-variable-power-value.mutated-opcode.mir.sx"
sed 's/(opcode pow)/(opcode add)/' "$print_variable_power_value_mir_file" \
    > "$print_variable_power_value_mutated_mir_file"
if python3 "$oracle" "$print_variable_power_value_ast_file" \
        "$print_variable_power_value_mutated_mir_file" "$print_variable_power_value_elf_file" \
        main integer print-variable-expression "$print_variable_power_value_source_file" \
        > /dev/null 2>&1; then
    printf '%s\n' 'variable-power-value MIR opcode mutation was accepted' >&2
    exit 1
fi
print_variable_power_value_mutated_elf_file="$run_dir/print-variable-power-value.mutated.elf"
cp "$print_variable_power_value_elf_file" "$print_variable_power_value_mutated_elf_file"
printf '\0' | dd of="$print_variable_power_value_mutated_elf_file" bs=1 seek=0 count=1 conv=notrunc \
    > /dev/null 2>&1
if python3 "$oracle" "$print_variable_power_value_ast_file" \
        "$print_variable_power_value_mir_file" "$print_variable_power_value_mutated_elf_file" \
        main integer print-variable-expression "$print_variable_power_value_source_file" \
        > /dev/null 2>&1; then
    printf '%s\n' 'variable-power-value ELF mutation was accepted' >&2
    exit 1
fi

for variable_source_file in "$ROOT"/tests/fixtures/l3-ast-program-print-variable-*-item-v1.f90; do
    variable_output_word="${variable_source_file##*-variable-}"
    variable_output_word="${variable_output_word%-item-v1.f90}"
    variable_output_count="$(awk '/^  print \*,/ { print gsub(/x/, "&") }' "$variable_source_file")"
    variable_source_file="$ROOT/tests/fixtures/l3-ast-program-print-variable-${variable_output_word}-item-v1.f90"
    variable_negative_files=(
        "$ROOT"/tests/negative/l3-ast-program-print-variable-${variable_output_word}-item-*.f90
        "$ROOT/tests/negative/l3-ast-program-write-variable-${variable_output_word}-item-v1.f90"
    )
    variable_expected=''
    for ((variable_expected_index = 0; variable_expected_index < variable_output_count; variable_expected_index++)); do
        variable_expected+=$'9\n'
    done
    case "$variable_output_count" in
        2) variable_mode=print-variable-two-item ;;
        3) variable_mode=print-variable-three-item ;;
        4) variable_mode=print-variable-four-item ;;
        5) variable_mode=print-variable-five-item ;;
        6) variable_mode=print-variable-six-item ;;
        *) variable_mode="print-variable-${variable_output_count}-item" ;;
    esac
    variable_base="$run_dir/$variable_mode"
    variable_ast_file="$variable_base.frontend.ast.sx"
    variable_mir_file="$variable_base.mir.sx"
    variable_elf_file="$variable_base.program.elf"
    variable_output_file="$variable_base.stdout"
    (cd "$frontend" && fo exec fortfront-program-unit-v2 "$variable_source_file" \
            "$variable_ast_file") > /dev/null 2>&1
    (cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$variable_ast_file" \
            "$variable_mir_file") > /dev/null 2>&1
    (cd "$backend" && fo exec fortback-mir-v0 "$variable_mir_file" \
            "$variable_elf_file") > /dev/null 2>&1
    for variable_negative_file in "${variable_negative_files[@]}"; do
        [ -f "$variable_negative_file" ] || continue
        rm -f "$run_dir/$variable_mode.negative.ast.sx"
        if (cd "$frontend" && fo exec fortfront-program-unit-v2 "$variable_negative_file" \
                "$run_dir/$variable_mode.negative.ast.sx") > /dev/null 2>&1; then
            printf 'invalid %s PRINT mutation was accepted\n' "$variable_mode" >&2
            exit 1
        fi
        [ ! -e "$run_dir/$variable_mode.negative.ast.sx" ]
    done
    qemu-riscv64 "$variable_elf_file" > "$variable_output_file"
    printf '%s' "$variable_expected" | cmp -s - "$variable_output_file"
    python3 "$oracle" "$variable_ast_file" "$variable_mir_file" "$variable_elf_file" \
        main integer "$variable_mode" "$variable_source_file"
    variable_mutated_ast_file="$variable_base.mutated-output.ast.sx"
    sed "s/(output-name-${variable_output_count} x)/(output-name-${variable_output_count} y)/" \
        "$variable_ast_file" > "$variable_mutated_ast_file"
    if python3 "$oracle" "$variable_mutated_ast_file" "$variable_mir_file" "$variable_elf_file" \
            main integer "$variable_mode" "$variable_source_file" > /dev/null 2>&1; then
        printf 'variable %s AST output mutation was accepted\n' "$variable_mode" >&2
        exit 1
    fi
    variable_mutated_mir_file="$variable_base.mutated-load.mir.sx"
    sed 's/(opcode load)/(opcode add)/'"$variable_output_count" "$variable_mir_file" \
        > "$variable_mutated_mir_file"
    if python3 "$oracle" "$variable_ast_file" "$variable_mutated_mir_file" "$variable_elf_file" \
            main integer "$variable_mode" "$variable_source_file" > /dev/null 2>&1; then
        printf 'variable %s MIR load mutation was accepted\n' "$variable_mode" >&2
        exit 1
    fi
    variable_mutated_elf_file="$variable_base.mutated.elf"
    cp "$variable_elf_file" "$variable_mutated_elf_file"
    printf '\0' | dd of="$variable_mutated_elf_file" bs=1 seek=0 count=1 conv=notrunc \
        > /dev/null 2>&1
    if python3 "$oracle" "$variable_ast_file" "$variable_mir_file" "$variable_mutated_elf_file" \
            main integer "$variable_mode" "$variable_source_file" > /dev/null 2>&1; then
        printf 'variable %s ELF mutation was accepted\n' "$variable_mode" >&2
        exit 1
    fi
done

envelope_five_ast_file="$run_dir/envelope-five.frontend.ast.sx"
envelope_five_mir_file="$run_dir/envelope-five.mir.sx"
envelope_five_elf_file="$run_dir/envelope-five.program.elf"
(cd "$frontend" && fo exec fortfront-program-unit-v2 "$sequence_five_source_file" \
        "$envelope_five_ast_file") > /dev/null 2>&1
(cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$envelope_five_ast_file" \
        "$envelope_five_mir_file") > /dev/null 2>&1
(cd "$backend" && fo exec fortback-mir-v0 "$envelope_five_mir_file" \
        "$envelope_five_elf_file") > /dev/null 2>&1
for negative_envelope_five in "${negative_sequence_five_files[@]}"; do
    rm -f "$run_dir/negative-envelope-five.ast.sx"
    if (cd "$frontend" && fo exec fortfront-program-unit-v2 "$negative_envelope_five" \
            "$run_dir/negative-envelope-five.ast.sx") > /dev/null 2>&1; then
        printf '%s\n' 'invalid five-assignment execution envelope source was accepted' >&2
        exit 1
    fi
    [ ! -e "$run_dir/negative-envelope-five.ast.sx" ]
done
if qemu-riscv64 "$envelope_five_elf_file" > /dev/null; then
    envelope_five_status=0
else
    envelope_five_status=$?
fi
[ "$envelope_five_status" -eq 11 ]
python3 "$oracle" "$envelope_five_ast_file" "$envelope_five_mir_file" \
    "$envelope_five_elf_file" main integer envelope-5

envelope_six_ast_file="$run_dir/envelope-six.frontend.ast.sx"
envelope_six_mir_file="$run_dir/envelope-six.mir.sx"
envelope_six_elf_file="$run_dir/envelope-six.program.elf"
(cd "$frontend" && fo exec fortfront-program-unit-v2 "$sequence_six_source_file" \
        "$envelope_six_ast_file") > /dev/null 2>&1
(cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$envelope_six_ast_file" \
        "$envelope_six_mir_file") > /dev/null 2>&1
(cd "$backend" && fo exec fortback-mir-v0 "$envelope_six_mir_file" \
        "$envelope_six_elf_file") > /dev/null 2>&1
for negative_envelope_six in "${negative_sequence_six_files[@]}"; do
    rm -f "$run_dir/negative-envelope-six.ast.sx"
    if (cd "$frontend" && fo exec fortfront-program-unit-v2 "$negative_envelope_six" \
            "$run_dir/negative-envelope-six.ast.sx") > /dev/null 2>&1; then
        if grep -q '^(program-unit-v2 ' "$run_dir/negative-envelope-six.ast.sx" && \
                grep -q '(assignment-count 6)' "$run_dir/negative-envelope-six.ast.sx"; then
            printf '%s\n' 'invalid six-assignment execution envelope source was promoted' >&2
            exit 1
        fi
    else
        [ ! -e "$run_dir/negative-envelope-six.ast.sx" ]
    fi
done
if qemu-riscv64 "$envelope_six_elf_file" > /dev/null; then
    envelope_six_status=0
else
    envelope_six_status=$?
fi
[ "$envelope_six_status" -eq 12 ]
python3 "$oracle" "$envelope_six_ast_file" "$envelope_six_mir_file" \
    "$envelope_six_elf_file" main integer envelope-6

envelope_ast_file="$run_dir/envelope.frontend.ast.sx"
envelope_mir_file="$run_dir/envelope.mir.sx"
envelope_elf_file="$run_dir/envelope.program.elf"
(cd "$frontend" && fo exec fortfront-program-unit-v2 "$sequence_source_file" \
        "$envelope_ast_file") > /dev/null 2>&1
(cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$envelope_ast_file" \
        "$envelope_mir_file") > /dev/null 2>&1
(cd "$backend" && fo exec fortback-mir-v0 "$envelope_mir_file" \
        "$envelope_elf_file") > /dev/null 2>&1
for negative_envelope in "${negative_sequence_files[@]}"; do
    rm -f "$run_dir/negative-envelope.ast.sx"
    if (cd "$frontend" && fo exec fortfront-program-unit-v2 "$negative_envelope" \
            "$run_dir/negative-envelope.ast.sx") > /dev/null 2>&1; then
        printf '%s\n' 'invalid program execution envelope source was accepted' >&2
        exit 1
    fi
    [ ! -e "$run_dir/negative-envelope.ast.sx" ]
done
if qemu-riscv64 "$envelope_elf_file" > /dev/null; then
    envelope_status=0
else
    envelope_status=$?
fi
[ "$envelope_status" -eq 8 ]
python3 "$oracle" "$envelope_ast_file" "$envelope_mir_file" \
    "$envelope_elf_file" main integer envelope

oracle_route_count="$(grep -c '^generated chain oracle: accepted$' "$run_dir/transcript.log")"
cat "$run_dir/transcript.log" >&3
exec >&3
if [ "$oracle_route_count" -ne 146 ]; then
    printf 'generated chain route count: expected 146, got %s\n' \
        "$oracle_route_count" >&2
    exit 1
fi
printf 'generated chain route count: %s\n' "$oracle_route_count"
printf '%s\n' 'generated compiler chain PASS'
