#!/usr/bin/env bash
# The repository's own gates. Runs in CI and before any commit.
#
# Gate 4 is the one that matters most and is easiest to get wrong: it proves
# the hash verifier can actually fail. A gate never observed failing is not
# evidence, which is the lesson fortfront learned the hard way and encoded as
# check-duplication-gate. Every check here that can be given a negative
# control has one.

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

fails=0
check() {   # check NAME; body follows via stdin-less convention
    printf '%-58s' "$1"
}
pass() { printf 'ok\n'; }
fail() { printf 'FAIL\n'; fails=$((fails + 1)); [ -n "${1:-}" ] && printf '  %s\n' "$1"; }

# ---------------------------------------------------------------- 1. syntax
check "1. every script parses"
bad=""
for s in "$ROOT"/scripts/*.sh; do
    bash -n "$s" 2>/dev/null || bad="$bad $(basename "$s")"
done
[ -z "$bad" ] && pass || fail "syntax errors in:$bad"

# ------------------------------------------------------- 2. CLAUDE.md symlink
check "2. CLAUDE.md is a symlink to AGENTS.md"
if [ -L "$ROOT/CLAUDE.md" ] && [ "$(readlink "$ROOT/CLAUDE.md")" = AGENTS.md ]; then
    pass
else
    fail "CLAUDE.md must be a symlink to AGENTS.md, not a copy (see ffc and fortplot, which diverged)"
fi

# --------------------------------------------------------- 3. manifests parse
check "3. every artifact manifest has the required fields"
missing=""
while read -r m; do
    [ -n "$m" ] || continue
    for k in name url sha256 bytes licence retrieved purpose; do
        [ -n "$(toml_get "$m" "$k")" ] || missing="$missing $(basename "$m"):$k"
    done
    # sha256 must look like one
    s=$(toml_get "$m" sha256)
    [[ "$s" =~ ^[0-9a-f]{64}$ ]] || missing="$missing $(basename "$m"):sha256-malformed"
done < <(find "$ROOT/artifacts" -name '*.toml' 2>/dev/null | sort)
[ -z "$missing" ] && pass || fail "missing or malformed:$missing"

# --------------------------------------- 4. NEGATIVE CONTROL: verifier can fail
check "4. the hash verifier rejects a corrupted artifact"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/artifacts/standards" "$tmp/scripts" "$tmp/.cache"
cp "$ROOT/scripts/lib.sh" "$ROOT/scripts/fetch.sh" "$tmp/scripts/"
cp "$ROOT/repos.toml" "$tmp/" 2>/dev/null || true
cat > "$tmp/artifacts/standards/canary.toml" <<'EOF'
name      = "canary"
title     = "negative control"
url       = "file:///dev/null"
sha256    = "0000000000000000000000000000000000000000000000000000000000000000"
bytes     = 3
licence   = "n/a"
retrieved = "1970-01-01"
purpose   = "Proves the verifier can fail"
EOF
printf 'abc' > "$tmp/.cache/canary.bin"
if "$tmp/scripts/fetch.sh" --verify canary >/dev/null 2>&1; then
    fail "verifier accepted a file whose hash does not match its manifest"
else
    pass
fi

# ------------------------------- 5. positive control: verifier accepts a match
check "5. the hash verifier accepts a matching artifact"
good=$(printf 'abc' | sha256sum | cut -d' ' -f1)
sed -i "s/^sha256    = .*/sha256    = \"$good\"/" "$tmp/artifacts/standards/canary.toml"
if "$tmp/scripts/fetch.sh" --verify canary >/dev/null 2>&1; then
    pass
else
    fail "verifier rejected a file whose hash matches its manifest"
fi

# ------------------------------------------------------ 6. nothing large tracked
check "6. no committed file exceeds 1 MB"
big=""
if git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    while read -r f; do
        [ -f "$ROOT/$f" ] || continue
        sz=$(stat -c%s "$ROOT/$f" 2>/dev/null || echo 0)
        [ "$sz" -gt 1048576 ] && big="$big $f($sz)"
    done < <(git -C "$ROOT" ls-files)
fi
[ -z "$big" ] && pass || fail "artifacts/ holds manifests, not payloads:$big"

# ------------------------------------------------------- 7. internal doc links
check "7. relative links in documents resolve"
broken=""
while read -r doc; do
    [ -f "$doc" ] || continue
    while read -r target; do
        [ -n "$target" ] || continue
        case "$target" in
            http*|mailto:*|"#"*) continue ;;
        esac
        t="${target%%#*}"
        [ -n "$t" ] || continue
        [ -e "$(dirname "$doc")/$t" ] || broken="$broken $(basename "$doc")->$t"
    done < <(grep -oE '\]\([^)]+\)' "$doc" | sed 's/^](//; s/)$//')
done < <(find "$ROOT" -name '*.md' -not -path '*/.git/*' -not -path '*/.cache/*')
[ -z "$broken" ] && pass || fail "broken links:$broken"

# ---------------------------------------------------------- 8. index is current
check "8. research/index.md is up to date"
if [ -f "$ROOT/research/index.md" ]; then
    before=$(sha256sum "$ROOT/research/index.md" | cut -d' ' -f1)
    "$ROOT/scripts/index.sh" >/dev/null 2>&1 || true
    after=$(sha256sum "$ROOT/research/index.md" | cut -d' ' -f1)
    # The generation date line changes daily; compare everything else.
    if [ "$before" = "$after" ]; then
        pass
    else
        diff_lines=$(git -C "$ROOT" diff --numstat -- research/index.md 2>/dev/null | awk '{print $1+$2}')
        if [ "${diff_lines:-0}" -le 1 ]; then
            pass    # only the date line moved
        else
            fail "run scripts/index.sh and commit the result"
        fi
    fi
else
    fail "research/index.md missing; run scripts/index.sh"
fi

printf '\n'
if [ "$fails" -eq 0 ]; then
    printf 'all gates passed\n'
else
    printf '%d gate(s) failed\n' "$fails"
fi
exit $(( fails > 0 ))
