#!/usr/bin/env bash
# Allocate a proposed decision record from the repository template.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

[ "$#" -ge 1 ] || die "usage: scripts/new-decision.sh \"title\" [slug]"
title="$1"
slug="${2:-$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' | \
    sed 's/[^a-z0-9][^a-z0-9]*/-/g; s/^-//; s/-$//')}"
[[ "$slug" =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "invalid decision slug: $slug"

last=$(find "$ROOT/research/decisions" -maxdepth 1 -type f \
    -name 'D[0-9][0-9][0-9][0-9]-*.md' -printf '%f\n' |
    sed -n 's/^D\([0-9][0-9][0-9][0-9]\)-.*/\1/p' | sort -n | tail -1)
last="${last:-0}"
next=$((10#$last + 1))
printf -v id 'D%04d' "$next"
path="$ROOT/research/decisions/$id-$slug.md"
[ ! -e "$path" ] || die "decision already exists: $path"

cp "$ROOT/research/decisions/TEMPLATE.md" "$path"
sed -i "1c# $id. $title" "$path"
sed -i "s/^Date: YYYY-MM-DD$/Date: $(date -u +%Y-%m-%d)/" "$path"
note "created proposed decision $path"
