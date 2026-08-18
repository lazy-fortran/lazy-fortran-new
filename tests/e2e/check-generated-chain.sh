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
negative_file="$ROOT/tests/negative/l3-ast-program-root-name-mismatch-v1.f90"
negative_declaration_file="$ROOT/tests/negative/l3-declaration-v0-missing-entity.f90"
negative_real_file="$ROOT/tests/negative/l3-ast-program-real-type-missing-entity-v1.f90"
negative_double_file="$ROOT/tests/negative/l3-ast-program-double-precision-missing-entity-v1.f90"
negative_complex_file="$ROOT/tests/negative/l3-ast-program-complex-type-missing-entity-v1.f90"
negative_logical_file="$ROOT/tests/negative/l3-ast-program-logical-type-missing-entity-v1.f90"
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

printf '%s\n' 'generated compiler chain PASS'
