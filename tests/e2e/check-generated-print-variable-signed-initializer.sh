#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib.sh"

frontend="$(resolve_repo fortfront-new)"
ffc="$(resolve_repo ffc-new)"
backend="$(resolve_repo fortback-new)"
oracle="$ROOT/tests/e2e/oracle_generated_print_variable_signed_initializer.py"
run_dir="$(mktemp -d)"

bash "$ROOT/tests/e2e/check-generated-print-list-signed-literal.sh" >/dev/null

run_positive() {
    local source="$1" stem="$2"
    local ast="$run_dir/$stem.ast.sx" mir="$run_dir/$stem.mir.sx" elf="$run_dir/$stem.elf"
    (cd "$frontend" && fo exec fortfront-program-unit-v2 "$source" "$ast") >/dev/null
    (cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$ast" "$mir") >/dev/null
    (cd "$backend" && fo exec fortback-mir-v0 "$mir" "$elf") >/dev/null
    python3 "$oracle" "$ast" "$mir" "$elf" "$source"

    local value
    value="$(sed -n 's/^  x = \(-[0-9][0-9]*\)$/\1/p' "$source")"
    local mutated_ast="$run_dir/$stem.mutated.ast.sx"
    local mutated_mir="$run_dir/$stem.mutated.mir.sx"
    local mutated_elf="$run_dir/$stem.mutated.elf"
    sed "0,/(left-operand $value)/s//(left-operand -1)/" "$ast" > "$mutated_ast"
    if python3 "$oracle" "$mutated_ast" "$mir" "$elf" "$source" >/dev/null 2>&1; then
        printf 'signed initializer AST mutation was accepted: %s\n' "$source" >&2
        exit 1
    fi
    sed "0,/(literal $value)/s//(literal -1)/" "$mir" > "$mutated_mir"
    if python3 "$oracle" "$ast" "$mutated_mir" "$elf" "$source" >/dev/null 2>&1; then
        printf 'signed initializer MIR mutation was accepted: %s\n' "$source" >&2
        exit 1
    fi
    cp "$elf" "$mutated_elf"
    dd if=/dev/zero of="$mutated_elf" bs=1 count=1 conv=notrunc status=none
    if python3 "$oracle" "$ast" "$mir" "$mutated_elf" "$source" >/dev/null 2>&1; then
        printf 'signed initializer ELF mutation was accepted: %s\n' "$source" >&2
        exit 1
    fi
}

run_negative() {
    local source="$1" stem="$2"
    local ast="$run_dir/$stem.ast.sx"
    if (cd "$frontend" && fo exec fortfront-program-unit-v2 "$source" "$ast") >/dev/null 2>&1; then
        printf 'signed initializer negative accepted: %s\n' "$source" >&2
        exit 1
    fi
    [ ! -e "$ast" ] || { printf 'signed initializer negative wrote AST: %s\n' "$source" >&2; exit 1; }
}

run_positive "$ROOT/tests/fixtures/l3-print-variable-signed-initializer-v0.f90" one
run_positive "$ROOT/tests/fixtures/l3-print-variable-signed-initializer-boundary-v0.f90" boundary
run_negative "$ROOT/tests/negative/l3-print-variable-signed-initializer-out-of-range-v0.f90" out-of-range
run_negative "$ROOT/tests/negative/l3-print-variable-signed-initializer-real-v0.f90" real

printf '%s\n' 'generated print-variable signed initializer PASS'
