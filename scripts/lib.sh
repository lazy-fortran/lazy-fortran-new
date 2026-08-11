# Shared helpers. Sourced, not executed.
#
# The TOML we write here is deliberately flat: [section.name] headers and
# key = "value" lines, nothing nested. That keeps parsing to a few lines of awk
# and avoids a dependency, which is the point. If a real parser ever becomes
# necessary, that is a decision record, not a quiet import.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="${LAZY_FORTRAN_WORKSPACE:-$(dirname "$ROOT")}"
CACHE="$ROOT/.cache"

# Where a checkout actually lives.
#
# This machine has two plausible homes for the oracle repositories: beside this
# one in $WORK, and inside the established $WORK/lazy-fortran workspace, which
# is where the real checkouts are. Prefer the workspace, fall back to the
# sibling, and report the sibling path when neither exists so that bootstrap
# clones somewhere predictable. Override the search root with
# LAZY_FORTRAN_WORKSPACE.
resolve_repo() {
    local path="$1"
    if [ -d "$WORK/lazy-fortran/$path/.git" ]; then
        printf '%s\n' "$WORK/lazy-fortran/$path"
    else
        printf '%s\n' "$WORK/$path"
    fi
}

die()  { printf 'error: %s\n' "$*" >&2; exit 1; }
warn() { printf 'warning: %s\n' "$*" >&2; }
note() { printf '%s\n' "$*"; }

need() {
    command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

# toml_get FILE KEY -> value of a top-level `key = "value"` line
toml_get() {
    awk -v k="$2" '
        $0 ~ "^[ \t]*"k"[ \t]*=" {
            sub(/^[^=]*=[ \t]*/, "")
            gsub(/^"|"[ \t]*$/, "")
            print
            exit
        }' "$1"
}

# repos_list SECTION -> lines of "name<TAB>url<TAB>path<TAB>clone"
# SECTION is "repos" or "oracle".
repos_list() {
    awk -v want="$1" '
        /^\[/ {
            name = ""; sect = ""
            line = $0
            gsub(/^\[|\][ \t]*$/, "", line)
            n = split(line, parts, ".")
            if (n == 2) { sect = parts[1]; name = parts[2] }
            url = ""; path = ""; clone = "true"
            next
        }
        sect == want && /^[ \t]*url[ \t]*=/   { url   = val($0) }
        sect == want && /^[ \t]*path[ \t]*=/  { path  = val($0) }
        sect == want && /^[ \t]*clone[ \t]*=/ { clone = val($0) }
        sect == want && url != "" && path != "" && !done[name]++ {
            printf "%s\t%s\t%s\t%s\n", name, url, path, clone
        }
        function val(s) {
            sub(/^[^=]*=[ \t]*/, "", s)
            gsub(/^"|"[ \t]*$/, "", s)
            gsub(/[ \t]+$/, "", s)
            return s
        }
    ' "$ROOT/repos.toml"
}

# Print the clone/status state of one checkout, aligned.
repo_state() {
    local name="$1" dir="$2"
    if [ ! -d "$dir/.git" ]; then
        if [ -d "$dir" ] && [ "$dir" = "$ROOT" ]; then
            printf '%-18s %-10s %-6s %s\n' "$name" "-" "here" "not yet a git repository"
        else
            printf '%-18s %-10s %s\n' "$name" "-" "absent"
        fi
        return
    fi
    local rev dirty branch
    rev=$(git -C "$dir" rev-parse --short HEAD 2>/dev/null || echo '?')
    branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')
    if [ -n "$(git -C "$dir" status --porcelain 2>/dev/null)" ]; then
        dirty="dirty"
    else
        dirty="clean"
    fi
    printf '%-18s %-10s %-6s %s\n' "$name" "$rev" "$dirty" "$branch"
}
