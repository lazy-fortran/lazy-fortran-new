#!/usr/bin/env bash
# Fast central check for the bounded COMPLEX typed-AST slice.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib.sh"
export LC_ALL=C
export LANG=C

need python3
frontend="$(resolve_repo fortfront-new)"
contract="tests/fixtures/frontend-ast-v1-complex-type-contract.toml"
validator="tests/e2e/validate_frontend_ast_v1_complex_type.py"
run_dir="$ROOT/.cache/fast-checks/frontend-ast-v1-complex-type/$$"
mkdir -p "$run_dir"

python3 "$validator" --contract "$contract"
(cd "$frontend" && fo clean) >"$run_dir/fortfront-clean.log" 2>&1
(cd "$frontend" && fo) >"$run_dir/fortfront-build.log" 2>&1

while IFS=$'\t' read -r case_id source_rel; do
    output="$run_dir/case-$case_id.ast.sx"
    repeat="$run_dir/case-$case_id.repeat.ast.sx"
    source="$ROOT/$source_rel"
    (cd "$frontend" && fo exec fortfront-source-ast-v1 "$source" "$output") \
        >"$run_dir/case-$case_id.log" 2>&1
    (cd "$frontend" && fo exec fortfront-source-ast-v1 "$source" "$repeat") \
        >"$run_dir/case-$case_id-repeat.log" 2>&1
    cmp "$output" "$repeat"
done < <(python3 "$validator" --cases "$contract")

negative="$ROOT/$(python3 "$validator" --negative "$contract")"
if (cd "$frontend" && fo exec fortfront-source-ast-v1 "$negative" \
        "$run_dir/negative.ast.sx") >"$run_dir/negative.log" 2>&1; then
    printf '%s\n' 'malformed COMPLEX declaration was accepted' >&2
    exit 1
fi
[ ! -e "$run_dir/negative.ast.sx" ]

python3 "$validator" --outputs "$contract" "$run_dir"
printf '%s\n' 'frontend AST v1 COMPLEX PASS'
