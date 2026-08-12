#!/usr/bin/env bash
# Regenerate the manuscript and export a venue-neutral PDF into the ignored cache.

set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/../.." && pwd)
output=${1:-"$repo_root/.cache/papers/standard-to-grammar/paper.pdf"}

command -v pandoc >/dev/null || {
    printf 'standard-to-grammar: pandoc is required\n' >&2
    exit 1
}
command -v xelatex >/dev/null || {
    printf 'standard-to-grammar: xelatex is required\n' >&2
    exit 1
}

"$script_dir/analyse.sh"
mkdir -p "$(dirname "$output")"
pandoc "$script_dir/paper.md" \
    --from=gfm \
    --pdf-engine=xelatex \
    -V geometry:margin=1in \
    -V fontsize=10pt \
    -o "$output"
printf 'standard-to-grammar: wrote %s\n' "$output"
