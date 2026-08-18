#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib.sh"

frontend="$(resolve_repo fortfront-new)"
ffc="$(resolve_repo ffc-new)"
backend="$(resolve_repo fortback-new)"
oracle="$ROOT/tests/e2e/oracle_generated_print_list.py"
run_dir="$(mktemp -d)"

printf '%s\n' 'generic print-list: contract gate'
bash "$ROOT/scripts/check-contracts.sh" >/dev/null

printf '%s\n' 'generic print-list: preserving prior generated chain'
bash "$ROOT/tests/e2e/check-generated-chain.sh" >/dev/null

run_positive() {
    local source="$1" stem="$2"
    local ast="$run_dir/$stem.ast.sx" mir="$run_dir/$stem.mir.sx" elf="$run_dir/$stem.elf"
    (cd "$frontend" && fo exec fortfront-program-unit-v2 "$source" "$ast") >/dev/null
    (cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$ast" "$mir") >/dev/null
    (cd "$backend" && fo exec fortback-mir-v0 "$mir" "$elf") >/dev/null
    python3 "$oracle" "$ast" "$mir" "$elf" "$source"
}

run_negative() {
    local source="$1" stem="$2" output="$run_dir/$stem.ast.sx"
    if (cd "$frontend" && fo exec fortfront-program-unit-v2 "$source" "$output") >/dev/null 2>&1; then
        printf 'generic print-list negative accepted: %s\n' "$source" >&2
        exit 1
    fi
    [ ! -e "$output" ] || {
        printf 'generic print-list negative wrote AST: %s\n' "$source" >&2
        exit 1
    }
}

run_positive "$ROOT/tests/fixtures/l3-print-list-v0.f90" mixed-three
run_positive "$ROOT/tests/fixtures/l3-print-list-wide-v0.f90" mixed-five
run_negative "$ROOT/tests/negative/l3-print-list-v0-empty.f90" empty
run_negative "$ROOT/tests/negative/l3-print-list-v0-missing-item.f90" missing-item
run_negative "$ROOT/tests/negative/l3-print-list-v0-write.f90" write
run_negative "$ROOT/tests/negative/l3-print-list-v0-wrong-name.f90" wrong-name

printf '%s\n' 'generic print-list PASS'
