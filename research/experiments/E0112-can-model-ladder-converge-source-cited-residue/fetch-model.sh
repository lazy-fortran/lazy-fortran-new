#!/usr/bin/env bash
set -euo pipefail

repo="${1:?usage: fetch-model.sh REPO FILE DESTINATION}"
file="${2:?usage: fetch-model.sh REPO FILE DESTINATION}"
destination="${3:?usage: fetch-model.sh REPO FILE DESTINATION}"
mkdir -p "$destination"
hf download "$repo" "$file" --local-dir "$destination"
model="$destination/$file"
test -f "$model" || { echo "E0112: downloaded file absent: $model" >&2; exit 1; }
printf 'repo=%s\nfile=%s\npath=%s\nbytes=%s\nsha256=%s\n' \
    "$repo" "$file" "$model" "$(stat -c '%s' "$model")" "$(sha256sum "$model" | cut -d' ' -f1)"
