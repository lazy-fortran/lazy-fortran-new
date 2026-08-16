#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
exec "$root/research/experiments/E0123-can-a-bounded-fresh-retry-resolve-the-re/preflight.sh" "$@"
