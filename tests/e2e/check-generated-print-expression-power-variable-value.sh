#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib.sh"

frontend="$(resolve_repo fortfront-new)"
ffc="$(resolve_repo ffc-new)"
backend="$(resolve_repo fortback-new)"
oracle="$ROOT/tests/e2e/oracle_generated_print_expression_power_variable_value.py"
run_dir="$(mktemp -d)"

bash "$ROOT/scripts/check-contracts.sh" >/dev/null
bash "$ROOT/scripts/check_pins.sh" >/dev/null
bash "$ROOT/tests/e2e/check-generated-print-expression-power-variable.sh" >/dev/null

run_positive() {
    local source="$1" stem="$2"
    local ast="$run_dir/$stem.ast.sx" mir="$run_dir/$stem.mir.sx" elf="$run_dir/$stem.elf"
    (cd "$frontend" && fo exec fortfront-program-unit-v2 "$source" "$ast") >/dev/null
    (cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$ast" "$mir") >/dev/null
    (cd "$backend" && fo exec fortback-mir-v0 "$mir" "$elf") >/dev/null
    python3 "$oracle" "$ast" "$mir" "$elf" "$source"
    local mutated_mir="$run_dir/$stem.mutated.mir.sx"
    sed '0,/(opcode pow)/s//(opcode load)/' "$mir" > "$mutated_mir"
    if python3 "$oracle" "$ast" "$mutated_mir" "$elf" "$source" >/dev/null 2>&1; then
        printf 'power-variable-value MIR mutation was accepted: %s\n' "$source" >&2
        exit 1
    fi
}

run_negative() {
    local source="$1" stem="$2"
    local ast="$run_dir/$stem.ast.sx"
    if (cd "$frontend" && fo exec fortfront-program-unit-v2 "$source" "$ast") >/dev/null 2>&1; then
        printf 'power-variable-value negative accepted: %s\n' "$source" >&2
        exit 1
    fi
    [ ! -e "$ast" ] || { printf 'power-variable-value negative wrote AST: %s\n' "$source" >&2; exit 1; }
}

run_positive "$ROOT/tests/fixtures/l3-print-expression-power-variable-value-v0.f90" value-first
run_positive "$ROOT/tests/fixtures/l3-print-expression-power-variable-value-wide-v0.f90" value-second
run_negative "$ROOT/tests/negative/l3-print-expression-power-variable-v0-missing-operand.f90" missing-operand
run_negative "$ROOT/tests/negative/l3-print-expression-power-variable-v0-variable-exponent.f90" variable-exponent
run_negative "$ROOT/tests/negative/l3-print-expression-power-variable-v0-negative-exponent.f90" negative-exponent
run_negative "$ROOT/tests/negative/l3-print-expression-power-variable-v0-write.f90" write

printf '%s\n' 'generic power-variable-value-expression PASS'
