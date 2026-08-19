#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib.sh"

frontend="$(resolve_repo fortfront-new)"
ffc="$(resolve_repo ffc-new)"
backend="$(resolve_repo fortback-new)"
oracle="$ROOT/tests/e2e/oracle_generated_print_expression_power_literal.py"
run_dir="$(mktemp -d)"

bash "$ROOT/scripts/check-contracts.sh" >/dev/null
bash "$ROOT/scripts/check_pins.sh" >/dev/null
bash "$ROOT/tests/e2e/check-generated-print-expression-power-four.sh" >/dev/null

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
    python3 - "$source" "$ast" "$mutated_ast" <<'PY'
import re, sys
source, original, mutated = sys.argv[1:]
text = open(source, encoding="utf-8").read()
exponent = int(re.search(r"x \*\* (\d+)", text).group(1))
ast = open(original, encoding="utf-8").read()
ast = ast.replace(f"(right {exponent})", f"(right {exponent + 1})", 1)
open(mutated, "w", encoding="utf-8").write(ast)
PY
    if python3 "$oracle" "$mutated_ast" "$mir" "$elf" "$source" >/dev/null 2>&1; then
        printf 'power-literal AST mutation was accepted: %s\n' "$source" >&2; exit 1
    fi
    sed '0,/(opcode pow)/s//(opcode load)/' "$mir" > "$mutated_mir"
    if python3 "$oracle" "$ast" "$mutated_mir" "$elf" "$source" >/dev/null 2>&1; then
        printf 'power-literal MIR mutation was accepted: %s\n' "$source" >&2; exit 1
    fi
    cp "$elf" "$mutated_elf"
    dd if=/dev/zero of="$mutated_elf" bs=1 count=1 conv=notrunc status=none
    if python3 "$oracle" "$ast" "$mir" "$mutated_elf" "$source" >/dev/null 2>&1; then
        printf 'power-literal ELF mutation was accepted: %s\n' "$source" >&2; exit 1
    fi
}

run_negative() {
    local source="$1" stem="$2"
    local ast="$run_dir/$stem.ast.sx"
    if (cd "$frontend" && fo exec fortfront-program-unit-v2 "$source" "$ast") >/dev/null 2>&1; then
        printf 'power-literal negative accepted: %s\n' "$source" >&2; exit 1
    fi
    [ ! -e "$ast" ] || { printf 'power-literal negative wrote AST: %s\n' "$source" >&2; exit 1; }
}

run_positive "$ROOT/tests/fixtures/l3-print-expression-power-literal-v0.f90" expression-power-literal-first
run_positive "$ROOT/tests/fixtures/l3-print-expression-power-literal-wide-v0.f90" expression-power-literal-second
run_positive "$ROOT/tests/fixtures/l3-print-expression-power-literal-large-v0.f90" expression-power-literal-large
run_negative "$ROOT/tests/negative/l3-print-expression-power-literal-v0-missing-operand.f90" missing-operand
run_negative "$ROOT/tests/negative/l3-print-expression-power-literal-v0-variable-exponent.f90" variable-exponent
run_negative "$ROOT/tests/negative/l3-print-expression-power-literal-v0-negative-exponent.f90" negative-exponent
run_negative "$ROOT/tests/negative/l3-print-expression-power-literal-v0-write.f90" write

printf '%s\n' 'generic power-literal-expression PASS'
