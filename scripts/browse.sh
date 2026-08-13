#!/usr/bin/env bash
# Read-only local browser for the generated artifacts in .cache/runs.
#
# Decision record: research/decisions/D0039-disposable-local-artifact-browser.md.
# The tool writes nothing, stores nothing, binds loopback only and is not part
# of any gate. Delete scripts/browse.sh and scripts/browse/ and nothing here
# fails.
#
#   scripts/browse.sh serve --run E0074/R000001
#   scripts/browse.sh index --run R000083
#   scripts/browse.sh selftest

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

need node

# Type stripping runs .mts directly. It is on by default from Node 22.18;
# older runtimes need the flag, and anything older than 22.6 has neither.
node_major=$(node -p 'process.versions.node.split(".")[0]')
node_minor=$(node -p 'process.versions.node.split(".")[1]')
if [ "$node_major" -lt 22 ] || { [ "$node_major" -eq 22 ] && [ "$node_minor" -lt 6 ]; }; then
    die "node 22.6 or newer is required for TypeScript type stripping (found $(node --version))"
fi
strip=()
if [ "$node_major" -eq 22 ] && [ "$node_minor" -lt 18 ]; then
    strip=(--experimental-strip-types --no-warnings)
fi

case "${1:-}" in
    selftest)
        shift
        exec node "${strip[@]}" "$ROOT/scripts/browse/selftest.mts" "$@"
        ;;
    serve | index | -h | --help | "")
        exec node "${strip[@]}" "$ROOT/scripts/browse/main.mts" "$@"
        ;;
    *)
        die "unknown command: $1 (expected serve, index or selftest)"
        ;;
esac
