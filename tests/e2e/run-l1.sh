#!/usr/bin/env bash
# Execute the central L1 slice: standard-new canonicalization followed by the
# pinned fortfront-new grammar frontier observable.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib.sh"
need python3
need sha256sum

"$ROOT/scripts/check_pins.sh" >/dev/null

manifest="$ROOT/tests/fixtures/l1-frontend-slice.toml"
standard="$(resolve_repo standard-new)"
frontend="$(resolve_repo fortfront-new)"
run_dir=$(mktemp -d "$ROOT/.cache/l1-run.XXXXXX")

IFS=$'\t' read -r source golden accept_golden reject_golden cases negative oracle start_lhs \
    source_hash roundtrip_hash accept_hash reject_hash negative_diagnostic \
    standard_commit frontend_commit <<EOF
$(python3 - "$manifest" "$ROOT" <<'PY'
import sys
import tomllib
from pathlib import Path

manifest = tomllib.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
root = Path(sys.argv[2])
print("\t".join(map(str, (
    root / manifest["source"],
    root / manifest["golden"],
    root / manifest["accept_golden"],
    root / manifest["reject_golden"],
    root / manifest["cases"],
    root / manifest["negative"],
    root / manifest["oracle"],
    manifest["start_lhs"],
    manifest["source_hash"],
    manifest["roundtrip_sha256"],
    manifest["accept_sha256"],
    manifest["reject_sha256"],
    manifest["negative_diagnostic"],
    manifest["standard_component_commit"],
    manifest["frontend_component_commit"],
))))
PY
)
EOF

roundtrip="$run_dir/standardir.roundtrip.sx"
roundtrip_two="$run_dir/standardir.roundtrip.two.sx"

(cd "$standard" && fo exec sxroundtrip "$source" "$roundtrip") \
    >"$run_dir/standard-roundtrip.log" 2>&1
(cd "$standard" && fo exec sxroundtrip "$source" "$roundtrip_two") \
    >"$run_dir/standard-roundtrip-two.log" 2>&1
cmp "$roundtrip" "$roundtrip_two"
cmp "$roundtrip" "$golden"
[ "$(sha256sum "$source" | awk '{print $1}')" = "$source_hash" ]
[ "$(sha256sum "$roundtrip" | awk '{print $1}')" = "$roundtrip_hash" ]

accept="$run_dir/frontend-accept.txt"
accept_two="$run_dir/frontend-accept.two.txt"
reject="$run_dir/frontend-reject.txt"
reject_two="$run_dir/frontend-reject.two.txt"

while IFS=$'\t' read -r case_id token; do
    [ -n "$case_id" ] || continue
    case "$case_id" in
        accept)
            (cd "$frontend" && fo exec fortfront-grammar-runtime "$roundtrip" "$start_lhs" "$token") \
                >"$accept" 2>"$run_dir/frontend-accept.log"
            (cd "$frontend" && fo exec fortfront-grammar-runtime "$roundtrip" "$start_lhs" "$token") \
                >"$accept_two" 2>"$run_dir/frontend-accept-two.log"
            ;;
        reject)
            (cd "$frontend" && fo exec fortfront-grammar-runtime "$roundtrip" "$start_lhs" "$token") \
                >"$reject" 2>"$run_dir/frontend-reject.log"
            (cd "$frontend" && fo exec fortfront-grammar-runtime "$roundtrip" "$start_lhs" "$token") \
                >"$reject_two" 2>"$run_dir/frontend-reject-two.log"
            ;;
        *)
            printf 'unknown frontend case %s\n' "$case_id" >&2
            exit 1
            ;;
    esac
done < "$cases"
cmp "$accept" "$accept_two"
cmp "$reject" "$reject_two"
cmp "$accept" "$accept_golden"
cmp "$reject" "$reject_golden"
[ "$(sha256sum "$accept" | awk '{print $1}')" = "$accept_hash" ]
[ "$(sha256sum "$reject" | awk '{print $1}')" = "$reject_hash" ]

python3 "$oracle" "$manifest" "$source" "$roundtrip" "$golden" "$accept" "$reject" "$cases" \
    >"$run_dir/oracle.log"

if (cd "$standard" && fo exec sxroundtrip "$negative" "$run_dir/negative.sx") \
    >"$run_dir/negative.log" 2>&1; then
    printf '%s\n' 'negative StandardIR fixture was accepted' >&2
    exit 1
fi
grep -Fq "$negative_diagnostic" "$run_dir/negative.log" || {
    printf 'negative diagnostic did not contain %s\n' "$negative_diagnostic" >&2
    exit 1
}

python3 - "$run_dir/trace.json" "$manifest" "$source" "$roundtrip" "$accept" "$reject" \
    "$run_dir/oracle.log" "$standard" "$frontend" \
    "$standard_commit" "$frontend_commit" <<'PY'
import hashlib
import json
import sys
import tomllib
from pathlib import Path


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


(
    trace_path,
    manifest_path,
    source,
    roundtrip,
    accept,
    reject,
    oracle_log,
    standard,
    frontend,
    standard_commit,
    frontend_commit,
) = sys.argv[1:]
manifest = tomllib.loads(Path(manifest_path).read_text(encoding="utf-8"))
trace = {
    "milestone": "L1",
    "fixture": manifest["id"],
    "stages": [
        {
            "component": "standard-new",
            "commit": standard_commit,
            "input": {"path": manifest["source"], "sha256": digest(source)},
            "output": {"path": "cache/standardir.roundtrip.sx", "sha256": digest(roundtrip)},
            "observable": "canonical StandardIR SX",
        },
        {
            "component": "fortfront-new",
            "commit": frontend_commit,
            "input": {"path": "cache/standardir.roundtrip.sx", "sha256": digest(roundtrip)},
            "outputs": {
                "PROGRAM": {"sha256": digest(accept), "result": "accepted"},
                "BAD": {"sha256": digest(reject), "result": "rejected"},
            },
            "observable": "grammar frontier acceptance/rejection",
        },
    ],
    "oracle": {
        "path": manifest["oracle"],
        "result": Path(oracle_log).read_text(encoding="utf-8").strip(),
    },
    "negative": {
        "path": manifest["negative"],
        "diagnostic": manifest["negative_diagnostic"],
        "result": "rejected",
    },
    "origin": "MECHANICAL",
}
Path(trace_path).write_text(json.dumps(trace, indent=2) + "\n", encoding="utf-8")
print(json.dumps(trace, sort_keys=True))
PY

printf 'L1 PASS\ntrace %s\n' "$run_dir/trace.json"
