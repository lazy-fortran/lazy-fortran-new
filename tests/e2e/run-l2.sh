#!/usr/bin/env bash
# Execute the first central executable slice:
# frontend-v0 SX -> FFC MIR-v0 SX -> fortback RV64 Linux ELF -> QEMU.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib.sh"
export LC_ALL=C
export LANG=C
need python3
need sha256sum
need git
need qemu-riscv64
need readelf

"$ROOT/scripts/check_pins.sh" >/dev/null

manifest="$ROOT/tests/fixtures/l2-first-executable-v0.toml"
standard="$(resolve_repo standard-new)"
frontend="$(resolve_repo fortfront-new)"
compiler="$(resolve_repo ffc-new)"
backend="$(resolve_repo fortback-new)"
run_dir=$(mktemp -d "$ROOT/.cache/l2-run.XXXXXX")
trap 'rm -rf "$run_dir"' EXIT

IFS=$'\t' read -r source golden mir_oracle negative malformed_mir out_of_scope_mir \
    oracle trace evidence_manifest fo_version fo_sha256 \
    standard_commit frontend_commit compiler_commit backend_commit \
    central_contracts <<EOF
$(python3 - "$manifest" "$ROOT" <<'PY'
import sys
import tomllib
from pathlib import Path

manifest = tomllib.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
root = Path(sys.argv[2])
print("\t".join(map(str, (
    root / manifest["source"],
    root / manifest["golden_mir"],
    root / manifest["mir_oracle"],
    root / manifest["negative"],
    root / manifest["negative_mir_malformed"],
    root / manifest["negative_mir_out_of_scope"],
    root / manifest["oracle"],
    root / manifest["trace"],
    root / manifest["evidence_manifest"],
    "0.3.2",
    "0e9ac6a20523f9919b75569e15e830011e8b69fa649e7a8c71b54ba18f131a68",
    manifest["standard_component_commit"],
    manifest["frontend_component_commit"],
    manifest["compiler_component_commit"],
    manifest["backend_component_commit"],
    ",".join(manifest["central_contracts"]),
))))
PY
)
EOF

[ "$(fo version | awk '{print $2}')" = "$fo_version" ]
[ "$(sha256sum "$(command -v fo)" | awk '{print $1}')" = "$fo_sha256" ]
[ "$(qemu-riscv64 --version | head -n1)" = "qemu-riscv64 version 11.0.3" ]
[ "$(readelf --version | head -n1)" = "GNU readelf (GNU Binutils) 2.47" ]

python3 - "$evidence_manifest" "$source" "$negative" "$malformed_mir" "$out_of_scope_mir" <<'PY'
import hashlib
import sys
import tomllib
from pathlib import Path

manifest = tomllib.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
paths = {
    "source_sha256": Path(sys.argv[2]),
    "negative_sha256": Path(sys.argv[3]),
    "negative_mir_malformed_sha256": Path(sys.argv[4]),
    "negative_mir_out_of_scope_sha256": Path(sys.argv[5]),
}
for field, path in paths.items():
    actual = hashlib.sha256(path.read_bytes()).hexdigest()
    if actual != manifest[field]:
        raise SystemExit(f"{field} differs from evidence manifest")
PY

for repo in "$standard" "$frontend" "$compiler" "$backend"; do
    (cd "$repo" && fo clean) >"$run_dir/$(basename "$repo")-clean.log" 2>&1
done
actual_standard_commit=$(git -C "$standard" rev-parse HEAD)
actual_frontend_commit=$(git -C "$frontend" rev-parse HEAD)
actual_compiler_commit=$(git -C "$compiler" rev-parse HEAD)
actual_backend_commit=$(git -C "$backend" rev-parse HEAD)
[ "$actual_standard_commit" = "$standard_commit" ]
[ "$actual_frontend_commit" = "$frontend_commit" ]
[ "$actual_compiler_commit" = "$compiler_commit" ]
[ "$actual_backend_commit" = "$backend_commit" ]

mir="$run_dir/l2.mir.sx"
mir_two="$run_dir/l2.two.mir.sx"
artifact="$run_dir/l2.elf"
artifact_two="$run_dir/l2.two.elf"
negative_output="$run_dir/negative.mir.sx"

(cd "$compiler" && fo exec ffc-lower-frontend-v0 "$source" "$mir") \
    >"$run_dir/ffc.log" 2>&1
(cd "$compiler" && fo exec ffc-lower-frontend-v0 "$source" "$mir_two") \
    >"$run_dir/ffc-two.log" 2>&1
cmp "$mir" "$mir_two"
python3 - "$mir" "$golden" <<'PY'
import sys
from pathlib import Path

actual = Path(sys.argv[1]).read_bytes()
expected = Path(sys.argv[2]).read_bytes()
if expected.endswith(b"\n"):
    expected = expected[:-1]
if actual != expected:
    raise SystemExit("MIR output differs from the reviewed golden")
PY

if (cd "$compiler" && fo exec ffc-lower-frontend-v0 "$negative" "$negative_output") \
    >"$run_dir/ffc-negative.log" 2>&1; then
    printf '%s\n' 'negative frontend fixture was accepted' >&2
    exit 1
fi
[ ! -e "$negative_output" ]
grep -Fq 'ffc-lower-frontend-v0: invalid frontend-v0 input' "$run_dir/ffc-negative.log"

malformed_output="$run_dir/malformed.elf"
if (cd "$backend" && fo exec fortback-mir-v0 "$malformed_mir" "$malformed_output") \
    >"$run_dir/fortback-malformed.log" 2>&1; then
    printf '%s\n' 'malformed MIR fixture was accepted' >&2
    exit 1
fi
[ ! -e "$malformed_output" ]
grep -Fq 'mir-v0: unexpected end of SX input' "$run_dir/fortback-malformed.log"

out_of_scope_output="$run_dir/out-of-scope.elf"
if (cd "$backend" && fo exec fortback-mir-v0 "$out_of_scope_mir" "$out_of_scope_output") \
    >"$run_dir/fortback-out-of-scope.log" 2>&1; then
    printf '%s\n' 'out-of-scope MIR fixture was accepted' >&2
    exit 1
fi
[ ! -e "$out_of_scope_output" ]
grep -Fq 'mir-v0: function is out of scope' "$run_dir/fortback-out-of-scope.log"

(cd "$backend" && fo exec fortback-mir-v0 "$mir" "$artifact") \
    >"$run_dir/fortback.log" 2>&1
(cd "$backend" && fo exec fortback-mir-v0 "$mir" "$artifact_two") \
    >"$run_dir/fortback-two.log" 2>&1
cmp "$artifact" "$artifact_two"
[ -x "$artifact" ]
readelf -h "$artifact" >"$run_dir/readelf.log"
if qemu-riscv64 "$artifact" >"$run_dir/qemu.log" 2>&1; then
    qemu_status=0
else
    qemu_status=$?
fi
[ "$qemu_status" -eq 0 ]

python3 "$oracle" "$manifest" "$source" "$mir" "$golden" "$mir_oracle" "$artifact" \
    "$negative" "$malformed_mir" "$out_of_scope_mir" \
    >"$run_dir/oracle.log"

python3 - "$run_dir/trace.json" "$manifest" "$source" "$mir" "$artifact" \
    "$negative" "$malformed_mir" "$out_of_scope_mir" \
    "$actual_standard_commit" "$actual_frontend_commit" \
    "$actual_compiler_commit" "$actual_backend_commit" "$qemu_status" \
    "$fo_version" "$fo_sha256" "$central_contracts" <<'PY'
import hashlib
import json
import sys
import tomllib
from pathlib import Path


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


(
    trace_path, manifest_path, source, mir, artifact, negative, malformed_mir,
    out_of_scope_mir,
    standard_commit, frontend_commit, compiler_commit, backend_commit,
    qemu_status, fo_version, fo_sha256, central_contracts,
) = sys.argv[1:]
manifest = tomllib.loads(Path(manifest_path).read_text(encoding="utf-8"))
trace = {
    "milestone": "L2",
    "fixture": manifest["id"],
    "boundary": manifest["boundary"],
    "contracts": central_contracts.split(","),
    "toolchain": {
        "fo_version": fo_version,
        "fo_sha256": fo_sha256,
        "qemu_riscv64": "qemu-riscv64 version 11.0.3",
        "readelf": "GNU readelf (GNU Binutils) 2.47",
    },
    "stages": [
        {
            "component": "ffc-new",
            "commit": compiler_commit,
            "contract": "frontend-v0 -> mir-v0",
            "input": {"path": manifest["source"], "sha256": digest(source)},
            "output": {"path": "cache/l2.mir.sx", "sha256": digest(mir)},
            "observable": "canonical MIR-v0 SX",
        },
        {
            "component": "fortback-new",
            "commit": backend_commit,
            "contract": "mir-v0 -> bounded RV64 Linux emission",
            "input": {"path": "cache/l2.mir.sx", "sha256": digest(mir)},
            "output": {"path": "cache/l2.elf", "sha256": digest(artifact)},
            "observable": "deterministic RV64 Linux ELF executable",
        },
    ],
    "upstream_pins": {
        "standard-new": standard_commit,
        "fortfront-new": frontend_commit,
        "ffc-new": compiler_commit,
        "fortback-new": backend_commit,
    },
    "negative": [
        {
            "path": manifest["negative"],
            "sha256": digest(negative),
            "diagnostic": "ffc-lower-frontend-v0: invalid frontend-v0 input",
            "observable": "FFC rejects input without creating output",
        },
        {
            "path": manifest["negative_mir_malformed"],
            "sha256": digest(malformed_mir),
            "diagnostic": "mir-v0: unexpected end of SX input",
            "observable": "fortback rejects malformed MIR without artifact",
        },
        {
            "path": manifest["negative_mir_out_of_scope"],
            "sha256": digest(out_of_scope_mir),
            "diagnostic": "mir-v0: function is out of scope",
            "observable": "fortback rejects out-of-scope MIR without artifact",
        },
    ],
    "runtime": {"oracle": "qemu-riscv64", "exit_status": int(qemu_status)},
    "origin": "MECHANICAL",
}
Path(trace_path).write_text(json.dumps(trace, indent=2) + "\n", encoding="utf-8")
PY

cmp "$run_dir/trace.json" "$trace"
printf 'L2 central executable slice: PASS\n'
