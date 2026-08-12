#!/usr/bin/env bash
# Enable the repository's versioned Git hooks for this checkout.

set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
git -C "$root" config core.hooksPath .githooks
printf 'enabled versioned hooks in %s\n' "$root"
