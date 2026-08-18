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
oracle="$ROOT/tests/e2e/oracle_generated_chain.py"

(cd "$standard" && fo clean && fo test test_standardir_lexical_generated && \
    fo clean && fo test test_standardir_grammar_fact) > /dev/null 2>&1

mkdir -p "$ROOT/.cache/fast-checks"
run_dir="$(mktemp -d "$ROOT/.cache/fast-checks/generated-chain.XXXXXX")"
trap 'rm -rf "$run_dir"' EXIT

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

sequence_three_ast_file="$run_dir/sequence-three.frontend.ast.sx"
sequence_three_mir_file="$run_dir/sequence-three.mir.sx"
sequence_three_elf_file="$run_dir/sequence-three.program.elf"
(cd "$frontend" && fo exec fortfront-source-ast-v1 "$sequence_three_source_file" \
        "$sequence_three_ast_file") > /dev/null 2>&1
(cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$sequence_three_ast_file" \
        "$sequence_three_mir_file") > /dev/null 2>&1
(cd "$backend" && fo exec fortback-mir-v0 "$sequence_three_mir_file" \
        "$sequence_three_elf_file") > /dev/null 2>&1
for negative_sequence_three in "${negative_sequence_three_files[@]}"; do
    rm -f "$run_dir/negative-sequence-three.ast.sx"
    if (cd "$frontend" && fo exec fortfront-source-ast-v1 "$negative_sequence_three" \
            "$run_dir/negative-sequence-three.ast.sx") > /dev/null 2>&1; then
        if grep -q '^(assignment-sequence ' "$run_dir/negative-sequence-three.ast.sx" && \
                grep -q '(assignment-count 3)' "$run_dir/negative-sequence-three.ast.sx"; then
            printf '%s\n' 'invalid three-assignment sequence source was promoted' >&2
            exit 1
        fi
    else
        [ ! -e "$run_dir/negative-sequence-three.ast.sx" ]
    fi
done
if qemu-riscv64 "$sequence_three_elf_file" > /dev/null; then
    sequence_three_status=0
else
    sequence_three_status=$?
fi
[ "$sequence_three_status" -eq 9 ]
python3 "$oracle" "$sequence_three_ast_file" "$sequence_three_mir_file" \
    "$sequence_three_elf_file" main integer sequence-3

sequence_four_ast_file="$run_dir/sequence-four.frontend.ast.sx"
sequence_four_mir_file="$run_dir/sequence-four.mir.sx"
sequence_four_elf_file="$run_dir/sequence-four.program.elf"
(cd "$frontend" && fo exec fortfront-source-ast-v1 "$sequence_four_source_file" \
        "$sequence_four_ast_file") > /dev/null 2>&1
(cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$sequence_four_ast_file" \
        "$sequence_four_mir_file") > /dev/null 2>&1
(cd "$backend" && fo exec fortback-mir-v0 "$sequence_four_mir_file" \
        "$sequence_four_elf_file") > /dev/null 2>&1
for negative_sequence_four in "${negative_sequence_four_files[@]}"; do
    rm -f "$run_dir/negative-sequence-four.ast.sx"
    if (cd "$frontend" && fo exec fortfront-source-ast-v1 "$negative_sequence_four" \
            "$run_dir/negative-sequence-four.ast.sx") > /dev/null 2>&1; then
        if grep -q '^(assignment-sequence ' "$run_dir/negative-sequence-four.ast.sx" && \
                grep -q '(assignment-count 4)' "$run_dir/negative-sequence-four.ast.sx"; then
            printf '%s\n' 'invalid four-assignment sequence source was promoted' >&2
            exit 1
        fi
    else
        [ ! -e "$run_dir/negative-sequence-four.ast.sx" ]
    fi
done
if qemu-riscv64 "$sequence_four_elf_file" > /dev/null; then
    sequence_four_status=0
else
    sequence_four_status=$?
fi
[ "$sequence_four_status" -eq 10 ]
python3 "$oracle" "$sequence_four_ast_file" "$sequence_four_mir_file" \
    "$sequence_four_elf_file" main integer sequence-4

sequence_five_ast_file="$run_dir/sequence-five.frontend.ast.sx"
sequence_five_mir_file="$run_dir/sequence-five.mir.sx"
sequence_five_elf_file="$run_dir/sequence-five.program.elf"
(cd "$frontend" && fo exec fortfront-source-ast-v1 "$sequence_five_source_file" \
        "$sequence_five_ast_file") > /dev/null 2>&1
(cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$sequence_five_ast_file" \
        "$sequence_five_mir_file") > /dev/null 2>&1
(cd "$backend" && fo exec fortback-mir-v0 "$sequence_five_mir_file" \
        "$sequence_five_elf_file") > /dev/null 2>&1
for negative_sequence_five in "${negative_sequence_five_files[@]}"; do
    rm -f "$run_dir/negative-sequence-five.ast.sx"
    if (cd "$frontend" && fo exec fortfront-source-ast-v1 "$negative_sequence_five" \
            "$run_dir/negative-sequence-five.ast.sx") > /dev/null 2>&1; then
        if grep -q '^(assignment-sequence ' "$run_dir/negative-sequence-five.ast.sx" && \
                grep -q '(assignment-count 5)' "$run_dir/negative-sequence-five.ast.sx"; then
            printf '%s\n' 'invalid five-assignment sequence source was promoted' >&2
            exit 1
        fi
    else
        [ ! -e "$run_dir/negative-sequence-five.ast.sx" ]
    fi
done
if qemu-riscv64 "$sequence_five_elf_file" > /dev/null; then
    sequence_five_status=0
else
    sequence_five_status=$?
fi
[ "$sequence_five_status" -eq 11 ]
python3 "$oracle" "$sequence_five_ast_file" "$sequence_five_mir_file" \
    "$sequence_five_elf_file" main integer sequence-5

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

printf '%s\n' 'generated compiler chain PASS'
