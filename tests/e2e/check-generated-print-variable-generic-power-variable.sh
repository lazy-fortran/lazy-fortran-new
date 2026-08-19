#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib.sh"

frontend="$(resolve_repo fortfront-new)"
ffc="$(resolve_repo ffc-new)"
backend="$(resolve_repo fortback-new)"
oracle="$ROOT/tests/e2e/oracle_generated_print_variable_generic_power_variable.py"
run_dir="$(mktemp -d)"

bash "$ROOT/tests/e2e/check-generated-print-variable-generic-power-range.sh" >/dev/null

run_positive() {
    local source="$1" stem="$2"
    local ast="$run_dir/$stem.ast.sx" mir="$run_dir/$stem.mir.sx" elf="$run_dir/$stem.elf"
    (cd "$frontend" && fo exec fortfront-program-unit-v2 "$source" "$ast") >/dev/null
    (cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$ast" "$mir") >/dev/null
    (cd "$backend" && fo exec fortback-mir-v0 "$mir" "$elf") >/dev/null
    python3 "$oracle" "$ast" "$mir" "$elf" "$source"

    local mutated_ast="$run_dir/$stem.mutated.ast.sx" mutated_mir="$run_dir/$stem.mutated.mir.sx" mutated_elf="$run_dir/$stem.mutated.elf"
    sed '0,/(right-operand x)/s//(right-operand y)/' "$ast" > "$mutated_ast"
    if python3 "$oracle" "$mutated_ast" "$mir" "$elf" "$source" >/dev/null 2>&1; then
        printf 'variable power AST mutation was accepted: %s\n' "$source" >&2; exit 1
    fi
    sed '0,/(opcode pow)/s//(opcode mul)/' "$mir" > "$mutated_mir"
    if python3 "$oracle" "$ast" "$mutated_mir" "$elf" "$source" >/dev/null 2>&1; then
        printf 'variable power MIR opcode mutation was accepted: %s\n' "$source" >&2; exit 1
    fi
    sed '0,/(storage-key x)/s//(storage-key y)/' "$mir" > "$mutated_mir"
    if python3 "$oracle" "$ast" "$mutated_mir" "$elf" "$source" >/dev/null 2>&1; then
        printf 'variable power MIR storage mutation was accepted: %s\n' "$source" >&2; exit 1
    fi
    cp "$elf" "$mutated_elf"
    dd if=/dev/zero of="$mutated_elf" bs=1 count=1 conv=notrunc status=none
    if python3 "$oracle" "$ast" "$mir" "$mutated_elf" "$source" >/dev/null 2>&1; then
        printf 'variable power ELF mutation was accepted: %s\n' "$source" >&2; exit 1
    fi
}

run_negative() {
    local source="$1" stem="$2"
    local ast="$run_dir/$stem.ast.sx"
    if (cd "$frontend" && fo exec fortfront-program-unit-v2 "$source" "$ast") >/dev/null 2>&1; then
        printf 'variable power negative accepted: %s\n' "$source" >&2; exit 1
    fi
    [ ! -e "$ast" ] || { printf 'variable power negative wrote AST: %s\n' "$source" >&2; exit 1; }
}

run_positive "$ROOT/tests/fixtures/l3-print-variable-generic-power-variable-v0.f90" value-three
run_positive "$ROOT/tests/fixtures/l3-print-variable-generic-power-variable-value-v0.f90" value-four
run_negative "$ROOT/tests/negative/l3-print-variable-generic-power-variable-negative-v0.f90" negative
run_negative "$ROOT/tests/negative/l3-print-variable-generic-power-variable-real-v0.f90" real
run_negative "$ROOT/tests/negative/l3-print-variable-generic-power-variable-wrong-name-v0.f90" wrong-name
run_negative "$ROOT/tests/negative/l3-print-variable-generic-power-variable-wrong-operator-v0.f90" wrong-operator
run_negative "$ROOT/tests/negative/l3-print-variable-generic-power-variable-wrong-rhs-v0.f90" wrong-rhs

printf '%s\n' 'generated print-variable generic variable power PASS'
