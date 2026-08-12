#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
exec "$root/research/experiments/E0015-can-core-0-feature-eligibility-prune-exc/check-profile-eligibility.sh" "$@"
