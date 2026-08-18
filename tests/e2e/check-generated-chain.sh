#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib.sh"

frontend="$(resolve_repo fortfront-new)"
ffc="$(resolve_repo ffc-new)"
backend="$(resolve_repo fortback-new)"
source_file="$ROOT/tests/fixtures/l3-declaration-v0.f90"
negative_file="$ROOT/tests/negative/l3-ast-program-root-name-mismatch-v1.f90"
oracle="$ROOT/tests/e2e/oracle_generated_chain.py"

mkdir -p "$ROOT/.cache/fast-checks"
run_dir="$(mktemp -d "$ROOT/.cache/fast-checks/generated-chain.XXXXXX")"
trap 'rm -rf "$run_dir"' EXIT

ast_file="$run_dir/frontend.ast.sx"
mir_file="$run_dir/mir.sx"
elf_file="$run_dir/program.elf"

(cd "$frontend" && fo exec fortfront-source-ast-v1 "$source_file" "$ast_file") \
    > /dev/null 2>&1
(cd "$ffc" && fo exec ffc-lower-frontend-ast-v1 "$ast_file" "$mir_file") \
    > /dev/null 2>&1
(cd "$backend" && fo exec fortback-mir-v0 "$mir_file" "$elf_file") \
    > /dev/null 2>&1

if (cd "$frontend" && fo exec fortfront-source-ast-v1 "$negative_file" \
        "$run_dir/negative.ast.sx") > /dev/null 2>&1; then
    printf '%s\n' 'negative source was accepted' >&2
    exit 1
fi
[ ! -e "$run_dir/negative.ast.sx" ]

command -v qemu-riscv64 > /dev/null
qemu-riscv64 "$elf_file" > /dev/null

python3 "$oracle" "$ast_file" "$mir_file" "$elf_file"
printf '%s\n' 'generated compiler chain PASS'
