#!/usr/bin/env bash
# Execute the central L0 slice against the pinned standard-new checkout.
# Outputs go to the ignored cache; reviewed expectations stay in git.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib.sh"
need python3
need sha256sum

"$ROOT/scripts/check_pins.sh" >/dev/null

manifest="$ROOT/tests/fixtures/l0-lexical-slice.toml"
component="$(resolve_repo standard-new)"
run_dir=$(mktemp -d "$ROOT/.cache/l0-run.XXXXXX")

read -r source_path schema_path golden_path negative_path oracle_path expected_roundtrip expected_schema negative_diagnostic <<EOF
$(python3 - "$manifest" "$ROOT" <<'PY'
import sys
import tomllib
from pathlib import Path

manifest = tomllib.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
root = Path(sys.argv[2])
print(
    root / manifest["source"],
    root / manifest["schema"],
    root / manifest["roundtrip_golden"],
    root / manifest["negative"],
    root / manifest["oracle"],
    manifest["roundtrip_sha256"],
    manifest["generated_schema_sha256"],
    manifest["negative_diagnostic"],
)
PY
)
EOF

roundtrip="$run_dir/lexical-facts.roundtrip.sx"
schema_one="$run_dir/schema_v0_generated.one.f90"
schema_two="$run_dir/schema_v0_generated.two.f90"
roundtrip_two="$run_dir/lexical-facts.roundtrip.two.sx"

(cd "$component" && fo exec sxroundtrip "$source_path" "$roundtrip") \
    >"$run_dir/roundtrip.log" 2>&1
(cd "$component" && fo exec sxroundtrip "$source_path" "$roundtrip_two") \
    >"$run_dir/roundtrip-two.log" 2>&1
(cd "$component" && fo exec sxschema "$schema_path" "$schema_one" standardir_schema) \
    >"$run_dir/schema.log" 2>&1
(cd "$component" && fo exec sxschema "$schema_path" "$schema_two" standardir_schema) \
    >"$run_dir/schema-two.log" 2>&1

cmp "$roundtrip" "$roundtrip_two"
cmp "$roundtrip" "$golden_path"
cmp "$schema_one" "$schema_two"
[ "$(sha256sum "$roundtrip" | awk '{print $1}')" = "$expected_roundtrip" ]
[ "$(sha256sum "$schema_one" | awk '{print $1}')" = "$expected_schema" ]

python3 "$oracle_path" "$manifest" "$source_path" "$roundtrip" \
    "$golden_path" "$schema_one" >"$run_dir/oracle.log"

if (cd "$component" && fo exec sxroundtrip "$negative_path" "$run_dir/negative.sx") \
    >"$run_dir/negative.log" 2>&1; then
    printf '%s\n' 'negative fixture was accepted' >&2
    exit 1
fi
grep -Fq "$negative_diagnostic" "$run_dir/negative.log" || {
    printf 'negative diagnostic did not contain %s\n' "$negative_diagnostic" >&2
    exit 1
}

mutated="$run_dir/lexical-facts.mutated.sx"
python3 - "$source_path" "$mutated" <<'PY'
from pathlib import Path
import sys

source = Path(sys.argv[1]).read_text(encoding="utf-8")
needle = "source-sha256 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
if needle not in source:
    raise SystemExit("mutation needle not found")
Path(sys.argv[2]).write_text(source.replace(needle, "source-sha256 MUTATED", 1), encoding="utf-8")
PY
(cd "$component" && fo exec sxroundtrip "$mutated" "$run_dir/mutated.roundtrip.sx") \
    >"$run_dir/mutated.log" 2>&1
if python3 "$oracle_path" "$manifest" "$mutated" "$run_dir/mutated.roundtrip.sx" \
    "$golden_path" "$schema_one" >"$run_dir/mutation-oracle.log" 2>&1; then
    printf '%s\n' 'source mutation was accepted by the oracle' >&2
    exit 1
fi

python3 - "$run_dir/trace.json" "$manifest" "$component" "$source_path" \
    "$roundtrip" "$schema_one" "$run_dir/oracle.log" "$negative_path" \
    "$run_dir/negative.log" "$run_dir/mutation-oracle.log" <<'PY'
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
    component,
    source,
    roundtrip,
    schema,
    oracle_log,
    negative,
    negative_log,
    mutation_log,
) = sys.argv[1:]
manifest = tomllib.loads(Path(manifest_path).read_text(encoding="utf-8"))
trace = {
    "milestone": "L0",
    "fixture": manifest["id"],
    "component": manifest["component"],
    "component_commit": manifest["component_commit"],
    "source": {"path": manifest["source"], "sha256": digest(source)},
    "schema": {"path": manifest["schema"], "sha256": digest(manifest["schema"])},
    "outputs": {
        "roundtrip": {"sha256": digest(roundtrip)},
        "generated_schema": {"sha256": digest(schema)},
    },
    "oracle": {
        "path": manifest["oracle"],
        "result": Path(oracle_log).read_text(encoding="utf-8").strip(),
    },
    "negative": {
        "path": manifest["negative"],
        "diagnostic": manifest["negative_diagnostic"],
        "result": "rejected",
    },
    "mutation": {
        "source": manifest["source"],
        "result": "rejected by independent oracle",
    },
    "origin": "MECHANICAL",
}
Path(trace_path).write_text(json.dumps(trace, indent=2) + "\n", encoding="utf-8")
print(json.dumps(trace, sort_keys=True))
PY

printf 'L0 PASS\ntrace %s\n' "$run_dir/trace.json"
