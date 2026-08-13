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
payload_files=(
    "paper.pdf"
    "README.md"
    "paper.md"
    "results.md"
    "pins.toml"
    "runs.txt"
)

payload_sha256() {
    sha256sum "$output/$1" | cut -d' ' -f1
}

payload_bytes() {
    stat -c '%s' "$output/$1"
}

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
    printf 'payload_files = ['
    separator=''
    for file in "${payload_files[@]}"; do
        printf '%s "%s"' "$separator" "$file"
        separator=','
    done
    printf ' ]\n'
    for file in "${payload_files[@]}"; do
        printf '\n[[payload]]\n'
        printf 'path = "%s"\n' "$file"
        printf 'sha256 = "%s"\n' "$(payload_sha256 "$file")"
        printf 'bytes = %s\n' "$(payload_bytes "$file")"
    done
} >"$output/manifest.toml"

printf 'standard-to-grammar: wrote submission bundle to %s\n' "$output"
printf 'standard-to-grammar: PDF SHA-256 %s\n' "$pdf_sha256"
