#!/usr/bin/env bash
# Build a reproducible handoff bundle for the venue-neutral first paper.

set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/../.." && pwd)
output=${1:-"$repo_root/.cache/papers/standard-to-grammar/submission"}
pdf="$output/paper.pdf"

mkdir -p "$output"
"$script_dir/render.sh" "$pdf"

cp "$script_dir/README.md" "$output/README.md"
cp "$script_dir/paper.md" "$output/paper.md"
cp "$script_dir/results.md" "$output/results.md"
cp "$script_dir/pins.toml" "$output/pins.toml"
cp "$script_dir/runs.txt" "$output/runs.txt"

commit=$(git -C "$repo_root" rev-parse HEAD)
pdf_sha256=$(sha256sum "$pdf" | cut -d' ' -f1)
pdf_bytes=$(stat -c '%s' "$pdf")
generated=$(date -u +%Y-%m-%d)

{
    printf 'name = "standard-to-grammar-submission-bundle"\n'
    printf 'repository_commit = "%s"\n' "$commit"
    printf 'generated = "%s"\n' "$generated"
    printf 'pdf = "paper.pdf"\n'
    printf 'pdf_sha256 = "%s"\n' "$pdf_sha256"
    printf 'pdf_bytes = %s\n' "$pdf_bytes"
    printf 'analysis = "papers/standard-to-grammar/analyse.sh"\n'
    printf 'render = "papers/standard-to-grammar/render.sh"\n'
    printf 'verification = ["scripts/selftest.sh", "scripts/check-decisions.sh", "scripts/check-commit-references.sh"]\n'
} >"$output/manifest.toml"

printf 'standard-to-grammar: wrote submission bundle to %s\n' "$output"
printf 'standard-to-grammar: PDF SHA-256 %s\n' "$pdf_sha256"
