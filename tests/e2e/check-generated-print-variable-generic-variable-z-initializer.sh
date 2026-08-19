#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib.sh"

frontend="$(resolve_repo fortfront-new)"
ffc="$(resolve_repo ffc-new)"
backend="$(resolve_repo fortback-new)"
oracle="$ROOT/tests/e2e/oracle_generated_print_variable_generic_variable_z_initializer.py"
run_dir="$(mktemp -d)"

bash "$ROOT/tests/e2e/check-generated-print-variable-generic-variable-y-initializer.sh" >/dev/null

run_positive() {
    local source="$1" stem="$2"
    local ast="$run_dir/$stem.ast.sx" mir="$run_dir/$stem.mir.sx" elf="$run_dir/$stem.elf"
    (cd "$frontend" && fo exec fortfront-program-unit-v2 "$source" "$ast") >/dev/null
    (cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$ast" "$mir") >/dev/null
    (cd "$backend" && fo exec fortback-mir-v0 "$mir" "$elf") >/dev/null
    python3 "$oracle" "$ast" "$mir" "$elf" "$source"
    local value mutation
    value="$(sed -n 's/^  z = \(-\?[0-9][0-9]*\)$/\1/p' "$source")"
    mutation="$((value + 1))"
    sed "0,/(left-operand $value)/s//(left-operand $mutation)/" "$ast" > "$run_dir/mutated.ast.sx"
    if python3 "$oracle" "$run_dir/mutated.ast.sx" "$mir" "$elf" "$source" >/dev/null 2>&1; then exit 1; fi
    sed '0,/(output-name z)/s//(output-name y)/' "$ast" > "$run_dir/mutated.ast.sx"
    if python3 "$oracle" "$run_dir/mutated.ast.sx" "$mir" "$elf" "$source" >/dev/null 2>&1; then exit 1; fi
    sed '0,/(storage-key z)/s//(storage-key y)/' "$mir" > "$run_dir/mutated.mir.sx"
    if python3 "$oracle" "$ast" "$run_dir/mutated.mir.sx" "$elf" "$source" >/dev/null 2>&1; then exit 1; fi
    sed "0,/(literal $value)/s//(literal $mutation)/" "$mir" > "$run_dir/mutated.mir.sx"
    if python3 "$oracle" "$ast" "$run_dir/mutated.mir.sx" "$elf" "$source" >/dev/null 2>&1; then exit 1; fi
    cp "$elf" "$run_dir/mutated.elf"
    dd if=/dev/zero of="$run_dir/mutated.elf" bs=1 count=1 conv=notrunc status=none
    if python3 "$oracle" "$ast" "$mir" "$run_dir/mutated.elf" "$source" >/dev/null 2>&1; then exit 1; fi
}

run_negative() {
    local source="$1" stem="$2"
    local ast="$run_dir/$stem.ast.sx"
    if (cd "$frontend" && fo exec fortfront-program-unit-v2 "$source" "$ast") >/dev/null 2>&1; then exit 1; fi
    [ ! -e "$ast" ]
}

run_positive "$ROOT/tests/fixtures/l3-print-variable-generic-variable-z-initializer-v0.f90" positive
run_positive "$ROOT/tests/fixtures/l3-print-variable-generic-variable-z-initializer-signed-v0.f90" signed
run_negative "$ROOT/tests/negative/l3-print-variable-generic-variable-z-initializer-high-v0.f90" high
run_negative "$ROOT/tests/negative/l3-print-variable-generic-variable-z-initializer-wrong-declaration-v0.f90" wrong-declaration
run_negative "$ROOT/tests/negative/l3-print-variable-generic-variable-z-initializer-real-v0.f90" real
run_negative "$ROOT/tests/negative/l3-print-variable-generic-variable-z-initializer-wrong-name-v0.f90" wrong-name

printf '%s\n' 'generated print-variable generic variable-z initializer PASS'
