#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib.sh"

frontend="$(resolve_repo fortfront-new)"
ffc="$(resolve_repo ffc-new)"
backend="$(resolve_repo fortback-new)"
oracle="$ROOT/tests/e2e/oracle_generated_print_list_literals.py"
run_dir="$(mktemp -d)"

printf '%s\n' 'generic print-list-literals: contract gate'
bash "$ROOT/scripts/check-contracts.sh" >/dev/null
bash "$ROOT/scripts/check_pins.sh" >/dev/null

printf '%s\n' 'generic print-list-literals: preserving prior list route'
bash "$ROOT/tests/e2e/check-generated-print-list.sh" >/dev/null

run_positive() {
    local source="$1" stem="$2"
    local ast="$run_dir/$stem.ast.sx" mir="$run_dir/$stem.mir.sx" elf="$run_dir/$stem.elf"
    (cd "$frontend" && fo exec fortfront-program-unit-v2 "$source" "$ast") >/dev/null
    (cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$ast" "$mir") >/dev/null
    (cd "$backend" && fo exec fortback-mir-v0 "$mir" "$elf") >/dev/null
    python3 "$oracle" "$ast" "$mir" "$elf" "$source"

    local mutated_ast="$run_dir/$stem.mutated.ast.sx"
    local mutated_mir="$run_dir/$stem.mutated.mir.sx"
    sed '0,/(value 20)/s//(value 99)/' "$ast" >"$mutated_ast"
    if python3 "$oracle" "$mutated_ast" "$mir" "$elf" "$source" >/dev/null 2>&1; then
        printf 'literal-list AST mutation was accepted: %s\n' "$source" >&2
        exit 1
    fi
    sed '0,/(literal 20)/s//(literal 99)/' "$mir" >"$mutated_mir"
    if python3 "$oracle" "$ast" "$mutated_mir" "$elf" "$source" >/dev/null 2>&1; then
        printf 'literal-list MIR mutation was accepted: %s\n' "$source" >&2
        exit 1
    fi
}

run_negative() {
    local source="$1" stem="$2"
    local output="$run_dir/$stem.ast.sx"
    if (cd "$frontend" && fo exec fortfront-program-unit-v2 "$source" "$output") >/dev/null 2>&1; then
        printf 'literal-list negative accepted: %s\n' "$source" >&2
        exit 1
    fi
    [ ! -e "$output" ] || {
        printf 'literal-list negative wrote AST: %s\n' "$source" >&2
        exit 1
    }
}

run_positive "$ROOT/tests/fixtures/l3-print-list-literals-v0.f90" novel-three
run_positive "$ROOT/tests/fixtures/l3-print-list-literals-wide-v0.f90" novel-five
run_negative "$ROOT/tests/negative/l3-print-list-literals-v0-trailing-comma.f90" trailing
run_negative "$ROOT/tests/negative/l3-print-list-literals-v0-real.f90" real
run_negative "$ROOT/tests/negative/l3-print-list-literals-v0-write.f90" write
run_negative "$ROOT/tests/negative/l3-print-list-literals-v0-name.f90" name

printf '%s\n' 'generic print-list-literals PASS'
