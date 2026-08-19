#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib.sh"

frontend="$(resolve_repo fortfront-new)"
ffc="$(resolve_repo ffc-new)"
backend="$(resolve_repo fortback-new)"
oracle="$ROOT/tests/e2e/oracle_generated_print_list.py"
run_dir="$(mktemp -d)"

bash "$ROOT/tests/e2e/check-generated-print-list-cardinality.sh" >/dev/null

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
    local first_value
    first_value="$(sed -n 's/.*print \*, \([-0-9][0-9]*\).*/\1/p' "$source")"
    sed "0,/(value $first_value)/s//(value 999)/" "$ast" > "$mutated_ast"
    if python3 "$oracle" "$mutated_ast" "$mir" "$elf" "$source" >/dev/null 2>&1; then
        printf 'signed-list AST mutation was accepted: %s\n' "$source" >&2
        exit 1
    fi
    sed "0,/(literal $first_value)/s//(literal 999)/" "$mir" > "$mutated_mir"
    if python3 "$oracle" "$ast" "$mutated_mir" "$elf" "$source" >/dev/null 2>&1; then
        printf 'signed-list MIR mutation was accepted: %s\n' "$source" >&2
        exit 1
    fi
    cp "$elf" "$mutated_elf"
    dd if=/dev/zero of="$mutated_elf" bs=1 count=1 conv=notrunc status=none
    if python3 "$oracle" "$ast" "$mir" "$mutated_elf" "$source" >/dev/null 2>&1; then
        printf 'signed-list ELF mutation was accepted: %s\n' "$source" >&2
        exit 1
    fi
}

run_negative() {
    local source="$1" stem="$2"
    local ast="$run_dir/$stem.ast.sx"
    if (cd "$frontend" && fo exec fortfront-program-unit-v2 "$source" "$ast") >/dev/null 2>&1; then
        printf 'signed-list negative accepted: %s\n' "$source" >&2
        exit 1
    fi
    [ ! -e "$ast" ] || { printf 'signed-list negative wrote AST: %s\n' "$source" >&2; exit 1; }
}

run_positive "$ROOT/tests/fixtures/l3-print-list-signed-literal-one-v0.f90" one
run_positive "$ROOT/tests/fixtures/l3-print-list-signed-literal-boundary-v0.f90" boundary
run_negative "$ROOT/tests/negative/l3-print-list-signed-literal-out-of-range-v0.f90" out-of-range
run_negative "$ROOT/tests/negative/l3-print-list-signed-literal-real-v0.f90" real

printf '%s\n' 'generic print-list-signed-literal PASS'
