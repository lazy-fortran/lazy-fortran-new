#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib.sh"

frontend="$(resolve_repo fortfront-new)"
ffc="$(resolve_repo ffc-new)"
backend="$(resolve_repo fortback-new)"
oracle="$ROOT/tests/e2e/oracle_generated_print_variable_generic_power.py"
run_dir="$(mktemp -d)"

run_existing() {
    local source="$1" stem="$2" oracle_path="$3"
    local ast="$run_dir/$stem.ast.sx" mir="$run_dir/$stem.mir.sx" elf="$run_dir/$stem.elf"
    (cd "$frontend" && fo exec fortfront-program-unit-v2 "$source" "$ast") >/dev/null
    (cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$ast" "$mir") >/dev/null
    (cd "$backend" && fo exec fortback-mir-v0 "$mir" "$elf") >/dev/null
    python3 "$oracle_path" "$ast" "$mir" "$elf" "$source"
}

run_existing "$ROOT/tests/fixtures/l3-print-variable-generic-addend-v0.f90" addend \
    "$ROOT/tests/e2e/oracle_generated_print_variable_generic_addend.py"
run_existing "$ROOT/tests/fixtures/l3-print-variable-generic-subtrahend-v0.f90" subtrahend \
    "$ROOT/tests/e2e/oracle_generated_print_variable_generic_subtrahend.py"
run_existing "$ROOT/tests/fixtures/l3-print-variable-generic-multiplier-v0.f90" multiplier \
    "$ROOT/tests/e2e/oracle_generated_print_variable_generic_multiplier.py"
run_existing "$ROOT/tests/fixtures/l3-print-variable-generic-divisor-v0.f90" divisor \
    "$ROOT/tests/e2e/oracle_generated_print_variable_generic_divisor.py"

run_positive() {
    local source="$1" stem="$2"
    local ast="$run_dir/$stem.ast.sx" mir="$run_dir/$stem.mir.sx" elf="$run_dir/$stem.elf"
    (cd "$frontend" && fo exec fortfront-program-unit-v2 "$source" "$ast") >/dev/null
    (cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$ast" "$mir") >/dev/null
    (cd "$backend" && fo exec fortback-mir-v0 "$mir" "$elf") >/dev/null
    python3 "$oracle" "$ast" "$mir" "$elf" "$source"

    local exponent mutation
    exponent="$(sed -n 's/^  x = x \*\* \([0-9][0-9]*\)$/\1/p' "$source" | head -1)"
    mutation="$((exponent + 1))"
    local mutated_ast="$run_dir/$stem.mutated.ast.sx" mutated_mir="$run_dir/$stem.mutated.mir.sx" mutated_elf="$run_dir/$stem.mutated.elf"
    sed "0,/(right-operand $exponent)/s//(right-operand $mutation)/" "$ast" > "$mutated_ast"
    if python3 "$oracle" "$mutated_ast" "$mir" "$elf" "$source" >/dev/null 2>&1; then
        printf 'generic power AST mutation was accepted: %s\n' "$source" >&2; exit 1
    fi
    sed "0,/(literal $exponent)/s//(literal $mutation)/" "$mir" > "$mutated_mir"
    if python3 "$oracle" "$ast" "$mutated_mir" "$elf" "$source" >/dev/null 2>&1; then
        printf 'generic power MIR literal mutation was accepted: %s\n' "$source" >&2; exit 1
    fi
    sed '0,/(opcode pow)/s//(opcode mul)/' "$mir" > "$mutated_mir"
    if python3 "$oracle" "$ast" "$mutated_mir" "$elf" "$source" >/dev/null 2>&1; then
        printf 'generic power MIR opcode mutation was accepted: %s\n' "$source" >&2; exit 1
    fi
    cp "$elf" "$mutated_elf"
    dd if=/dev/zero of="$mutated_elf" bs=1 count=1 conv=notrunc status=none
    if python3 "$oracle" "$ast" "$mir" "$mutated_elf" "$source" >/dev/null 2>&1; then
        printf 'generic power ELF mutation was accepted: %s\n' "$source" >&2; exit 1
    fi
}

run_negative() {
    local source="$1" stem="$2"
    local ast="$run_dir/$stem.ast.sx"
    if (cd "$frontend" && fo exec fortfront-program-unit-v2 "$source" "$ast") >/dev/null 2>&1; then
        printf 'generic power negative accepted: %s\n' "$source" >&2; exit 1
    fi
    [ ! -e "$ast" ] || { printf 'generic power negative wrote AST: %s\n' "$source" >&2; exit 1; }
}

run_positive "$ROOT/tests/fixtures/l3-print-variable-generic-power-v0.f90" positive
run_positive "$ROOT/tests/fixtures/l3-print-variable-generic-power-signed-v0.f90" signed
run_negative "$ROOT/tests/negative/l3-print-variable-generic-power-one-v0.f90" one
run_negative "$ROOT/tests/negative/l3-print-variable-generic-power-out-of-range-v0.f90" out-of-range
run_negative "$ROOT/tests/negative/l3-print-variable-generic-power-wrong-operator-v0.f90" wrong-operator
run_negative "$ROOT/tests/negative/l3-print-variable-generic-power-wrong-name-v0.f90" wrong-name
run_negative "$ROOT/tests/negative/l3-print-variable-generic-power-real-v0.f90" real

printf '%s\n' 'generated print-variable generic power PASS'
