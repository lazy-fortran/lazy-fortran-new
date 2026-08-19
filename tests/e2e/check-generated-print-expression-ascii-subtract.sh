#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib.sh"

frontend="$(resolve_repo fortfront-new)"
ffc="$(resolve_repo ffc-new)"
backend="$(resolve_repo fortback-new)"
oracle="$ROOT/tests/e2e/oracle_generated_print_expression_ascii_subtract.py"
run_dir="$(mktemp -d)"

bash "$ROOT/scripts/check-contracts.sh" >/dev/null
bash "$ROOT/scripts/check_pins.sh" >/dev/null
bash "$ROOT/tests/e2e/check-generated-print-expression-add-constant.sh" >/dev/null

run_positive() {
    local source="$1" stem="$2"
    local ast="$run_dir/$stem.ast.sx" mir="$run_dir/$stem.mir.sx" elf="$run_dir/$stem.elf"
    (cd "$frontend" && fo exec fortfront-program-unit-v2 "$source" "$ast") >/dev/null
    (cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$ast" "$mir") >/dev/null
    (cd "$backend" && fo exec fortback-mir-v0 "$mir" "$elf") >/dev/null
    python3 "$oracle" "$ast" "$mir" "$elf" "$source"
    local mutated_ast="$run_dir/$stem.mutated.ast.sx"
    local mutated_mir="$run_dir/$stem.mutated.mir.sx"
    local mutated_elf="$run_dir/$stem.mutated.elf"
    sed '0,/(right 2)/s//(right 3)/' "$ast" > "$mutated_ast"
    if python3 "$oracle" "$mutated_ast" "$mir" "$elf" "$source" >/dev/null 2>&1; then
        printf 'ASCII subtract AST mutation was accepted: %s\n' "$source" >&2; exit 1
    fi
    sed '0,/(opcode sub)/s//(opcode add)/' "$mir" > "$mutated_mir"
    if python3 "$oracle" "$ast" "$mutated_mir" "$elf" "$source" >/dev/null 2>&1; then
        printf 'ASCII subtract MIR mutation was accepted: %s\n' "$source" >&2; exit 1
    fi
    cp "$elf" "$mutated_elf"
    dd if=/dev/zero of="$mutated_elf" bs=1 count=1 conv=notrunc status=none
    if python3 "$oracle" "$ast" "$mir" "$mutated_elf" "$source" >/dev/null 2>&1; then
        printf 'ASCII subtract ELF mutation was accepted: %s\n' "$source" >&2; exit 1
    fi
}

run_negative() {
    local source="$1" stem="$2"
    local ast="$run_dir/$stem.ast.sx"
    if (cd "$frontend" && fo exec fortfront-program-unit-v2 "$source" "$ast") >/dev/null 2>&1; then
        printf 'ASCII subtract negative accepted: %s\n' "$source" >&2; exit 1
    fi
    [ ! -e "$ast" ] || { printf 'ASCII subtract negative wrote AST: %s\n' "$source" >&2; exit 1; }
}

run_positive "$ROOT/tests/fixtures/l3-print-expression-ascii-subtract-v0.f90" expression-ascii-subtract-first
run_positive "$ROOT/tests/fixtures/l3-print-expression-ascii-subtract-wide-v0.f90" expression-ascii-subtract-second
run_negative "$ROOT/tests/negative/l3-print-expression-ascii-subtract-v0-missing-operand.f90" missing-operand
run_negative "$ROOT/tests/negative/l3-print-expression-ascii-subtract-v0-wrong-operator.f90" wrong-operator
run_negative "$ROOT/tests/negative/l3-print-expression-ascii-subtract-v0-write.f90" write
run_negative "$ROOT/tests/negative/l3-print-expression-ascii-subtract-v0-wrong-name.f90" wrong-name
run_negative "$ROOT/tests/negative/l3-print-expression-ascii-subtract-v0-wrong-right.f90" wrong-right

printf '%s\n' 'generic ASCII subtract-expression PASS'
