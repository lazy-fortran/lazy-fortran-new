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
need readelf

"$ROOT/scripts/check_pins.sh" >/dev/null

manifest="$ROOT/tests/fixtures/l2-first-executable-v0.toml"
standard="$(resolve_repo standard-new)"
frontend="$(resolve_repo fortfront-new)"
compiler="$(resolve_repo ffc-new)"
backend="$(resolve_repo fortback-new)"
mkdir -p "$ROOT/.cache"
run_dir="$ROOT/.cache/l2-run"
rm -rf "$run_dir"
mkdir -p "$run_dir"
trap 'rm -rf "$run_dir"' EXIT

IFS=$'\t' read -r source golden mir_oracle negative malformed_mir out_of_scope_mir \
    oracle trace evidence_manifest fo_version fo_sha256 \
    standard_commit frontend_commit compiler_commit backend_commit \
    central_contracts fixture_runtime_oracle fixture_lab_commit runtime_oracle qemu_version \
    readelf_version lab_commit \
    runtime_exit_status host_os host_architecture lc_all lang worktree_state \
    evidence_mir_path evidence_artifact_path <<EOF
$(python3 - "$manifest" "$ROOT" <<'PY'
import sys
import tomllib
from pathlib import Path

manifest = tomllib.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
root = Path(sys.argv[2])
evidence = tomllib.loads((root / manifest["evidence_manifest"]).read_text(encoding="utf-8"))
if manifest["runtime_oracle"] != evidence["runtime_oracle"]:
    raise SystemExit("fixture and evidence runtime oracle differ")
if manifest["runtime_exit_status"] != evidence["runtime_exit_status"]:
    raise SystemExit("fixture and evidence runtime exit status differ")
if manifest["lab_commit"] != evidence["lab_commit"]:
    raise SystemExit("fixture and evidence laboratory commit differ")
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
    evidence["fo_version"],
    evidence["fo_sha256"],
    manifest["standard_component_commit"],
    manifest["frontend_component_commit"],
    manifest["compiler_component_commit"],
    manifest["backend_component_commit"],
    ",".join(manifest["central_contracts"]),
    manifest["runtime_oracle"],
    manifest["lab_commit"],
    evidence["runtime_oracle"],
    evidence["qemu_version"],
    evidence["readelf_version"],
    evidence["lab_commit"],
    evidence["runtime_exit_status"],
    evidence["host_os"],
    evidence["host_architecture"],
    evidence["lc_all"],
    evidence["lang"],
    evidence["worktree_state"],
    evidence["mir"],
    evidence["artifact"],
))))
PY
)
EOF

need "$runtime_oracle"
[ "$fixture_runtime_oracle" = "$runtime_oracle" ]
[ "$fixture_lab_commit" = "$lab_commit" ]
[ "$(uname -s)" = "$host_os" ]
[ "$(uname -m)" = "$host_architecture" ]
[ "${LC_ALL:-}" = "$lc_all" ]
[ "${LANG:-}" = "$lang" ]
[ "$(git -C "$ROOT" cat-file -t "$lab_commit" 2>/dev/null)" = "commit" ]
git -C "$ROOT" merge-base --is-ancestor "$lab_commit" HEAD
git -C "$ROOT" diff --quiet "$lab_commit" HEAD -- tests/e2e contracts scripts tests/fixtures/l2-first-executable-v0.sx
[ "$(fo version | awk '{print $2}')" = "$fo_version" ]
[ "$(sha256sum "$(command -v fo)" | awk '{print $1}')" = "$fo_sha256" ]
[ "$($runtime_oracle --version | head -n1)" = "$qemu_version" ]
[ "$(readelf --version | head -n1)" = "$readelf_version" ]

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

python3 - "$ROOT" "$lab_commit" "$evidence_manifest" <<'PY'
import subprocess
import sys
import tomllib
from pathlib import Path

root, lab_commit, evidence_path = map(Path, sys.argv[1:])
lab_commit = str(lab_commit)
protected = (
    "tests/e2e/run-l2.sh",
    "tests/e2e/oracle_l2.py",
    "contracts/frontend-v0.sxs",
    "contracts/mir-v0.sxs",
    "tests/fixtures/l2-first-executable-v0.toml",
    "tests/fixtures/l2-first-executable-v0.sx",
    "tests/golden/l2-first-executable-v0.mir.sx",
    "tests/golden/l2-first-executable-v0.oracle.toml",
    "tests/negative/l2-first-executable-v0-rejected.sx",
    "tests/negative/l2-mir-v0-malformed.sx",
    "tests/negative/l2-mir-v0-out-of-scope.sx",
)
for relative in protected:
    current = (root / relative).read_bytes()
    expected = subprocess.check_output(
        ["git", "-C", str(root), "show", f"{lab_commit}:{relative}"]
    )
    if relative == "tests/fixtures/l2-first-executable-v0.toml":
        current_doc = tomllib.loads(current.decode("utf-8"))
        expected_doc = tomllib.loads(expected.decode("utf-8"))
        current_doc.pop("lab_commit", None)
        expected_doc.pop("lab_commit", None)
        if current_doc != expected_doc:
            raise SystemExit(f"protected laboratory input changed: {relative}")
        continue
    if current != expected:
        raise SystemExit(f"protected laboratory input changed: {relative}")

current_evidence = tomllib.loads(Path(evidence_path).read_text(encoding="utf-8"))
source_evidence = tomllib.loads(
    subprocess.check_output(
        ["git", "-C", str(root), "show", f"{lab_commit}:{evidence_path.relative_to(root)}"],
        text=True,
    )
)
for key in source_evidence:
    if key not in {"lab_commit", "mir", "artifact"} and current_evidence.get(key) != source_evidence[key]:
        raise SystemExit(f"evidence field changed after laboratory pin: {key}")
PY

for repo in "$standard" "$frontend" "$compiler" "$backend"; do
    (cd "$repo" && fo clean) >"$run_dir/$(basename "$repo")-clean.log" 2>&1
done
for repo in "$ROOT" "$standard" "$frontend" "$compiler" "$backend"; do
    [ -z "$(git -C "$repo" status --porcelain --untracked-files=normal)" ]
done
actual_standard_commit=$(git -C "$standard" rev-parse HEAD)
actual_frontend_commit=$(git -C "$frontend" rev-parse HEAD)
actual_compiler_commit=$(git -C "$compiler" rev-parse HEAD)
actual_backend_commit=$(git -C "$backend" rev-parse HEAD)
[ "$actual_standard_commit" = "$standard_commit" ]
[ "$actual_frontend_commit" = "$frontend_commit" ]
[ "$actual_compiler_commit" = "$compiler_commit" ]
[ "$actual_backend_commit" = "$backend_commit" ]

mir="$ROOT/$evidence_mir_path"
mir_two="$run_dir/l2.two.mir.sx"
artifact="$ROOT/$evidence_artifact_path"
artifact_two="$run_dir/l2.two.elf"
negative_output="$run_dir/negative.mir.sx"
[ "$mir" = "$run_dir/l2.mir.sx" ]
[ "$artifact" = "$run_dir/l2.elf" ]

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
if "$runtime_oracle" "$artifact" >"$run_dir/qemu.log" 2>&1; then
    qemu_status=0
else
    qemu_status=$?
fi
[ "$qemu_status" -eq "$runtime_exit_status" ]

python3 "$oracle" "$manifest" "$source" "$mir" "$golden" "$mir_oracle" "$artifact" \
    "$negative" "$malformed_mir" "$out_of_scope_mir" \
    "$qemu_status" "$fo_version" "$fo_sha256" "$runtime_oracle" \
    "$qemu_version" "$readelf_version" "$host_os" "$host_architecture" \
    "$lc_all" "$lang" "$worktree_state" "$lab_commit" \
    >"$run_dir/oracle.log"

python3 - "$run_dir/trace.json" "$manifest" "$source" "$mir" "$artifact" \
    "$negative" "$malformed_mir" "$out_of_scope_mir" \
    "$actual_standard_commit" "$actual_frontend_commit" \
    "$actual_compiler_commit" "$actual_backend_commit" "$qemu_status" \
    "$fo_version" "$fo_sha256" "$central_contracts" "$runtime_oracle" \
    "$qemu_version" "$readelf_version" "$runtime_exit_status" \
    "$host_os" "$host_architecture" "$lc_all" "$lang" "$worktree_state" \
    "$lab_commit" "$standard" "$frontend" "$compiler" "$backend" \
    "$source" "$mir" "$mir_two" "$golden" "$negative" "$negative_output" \
    "$malformed_mir" "$malformed_output" "$out_of_scope_mir" \
    "$out_of_scope_output" "$artifact" "$artifact_two" \
    "$evidence_mir_path" "$evidence_artifact_path" \
    <<'PY'
import hashlib
import json
import sys
import tomllib
from pathlib import Path


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def command(repository, argv):
    return {
        "cwd_repository": repository,
        "cwd_resolver": "repos.toml",
        "argv_template": argv,
    }


def lab_ref(path):
    return "${LAB}/" + Path(path).relative_to(root).as_posix()


(
    trace_path, manifest_path, source, mir, artifact, negative, malformed_mir,
    out_of_scope_mir,
    standard_commit, frontend_commit, compiler_commit, backend_commit,
    qemu_status, fo_version, fo_sha256, central_contracts, runtime_oracle,
    qemu_version, readelf_version, runtime_exit_status, host_os,
    host_architecture, lc_all, lang, worktree_state, lab_commit, standard,
    frontend, compiler, backend, source, mir, mir_two, golden, negative,
    negative_output, malformed_mir, malformed_output, out_of_scope_mir,
    out_of_scope_output, artifact, artifact_two, evidence_mir_path,
    evidence_artifact_path,
) = sys.argv[1:]
manifest = tomllib.loads(Path(manifest_path).read_text(encoding="utf-8"))
root = Path(trace_path).parents[2]
trace = {
    "milestone": "L2",
    "fixture": manifest["id"],
    "lab_commit": lab_commit,
    "boundary": manifest["boundary"],
    "contracts": central_contracts.split(","),
    "toolchain": {
        "fo_version": fo_version,
        "fo_sha256": fo_sha256,
        "runtime_oracle": runtime_oracle,
        "qemu_riscv64": qemu_version,
        "readelf": readelf_version,
    },
    "reproducibility": {
        "host_os": host_os,
        "host_architecture": host_architecture,
        "locale": {"LC_ALL": lc_all, "LANG": lang},
        "worktree_state": worktree_state,
        "path_aliases": {
            "LAB": {"repository": "lazy-fortran-new", "resolver": "repos.toml"}
        },
        "commands": [
            {
                "cwd_repository": "lazy-fortran-new",
                "cwd_resolver": "current-checkout",
                "argv_template": ["scripts/verify_active_milestone.sh"],
            },
            command("standard-new", ["fo", "clean"]),
            command("fortfront-new", ["fo", "clean"]),
            command("ffc-new", ["fo", "clean"]),
            command("fortback-new", ["fo", "clean"]),
            command("ffc-new", ["fo", "exec", "ffc-lower-frontend-v0", lab_ref(source), lab_ref(mir)]),
            command("ffc-new", ["fo", "exec", "ffc-lower-frontend-v0", lab_ref(source), lab_ref(mir_two)]),
            command("ffc-new", ["fo", "exec", "ffc-lower-frontend-v0", lab_ref(negative), lab_ref(negative_output)]),
            command("fortback-new", ["fo", "exec", "fortback-mir-v0", lab_ref(malformed_mir), lab_ref(malformed_output)]),
            command("fortback-new", ["fo", "exec", "fortback-mir-v0", lab_ref(out_of_scope_mir), lab_ref(out_of_scope_output)]),
            command("fortback-new", ["fo", "exec", "fortback-mir-v0", lab_ref(mir), lab_ref(artifact)]),
            command("fortback-new", ["fo", "exec", "fortback-mir-v0", lab_ref(mir), lab_ref(artifact_two)]),
            {
                "cwd_repository": "lazy-fortran-new",
                "cwd_resolver": "current-checkout",
                "argv_template": ["readelf", "-h", lab_ref(artifact)],
            },
            {
                "cwd_repository": "lazy-fortran-new",
                "cwd_resolver": "current-checkout",
                "argv_template": [runtime_oracle, lab_ref(artifact)],
            },
        ],
    },
    "stages": [
        {
            "component": "ffc-new",
            "commit": compiler_commit,
            "contract": "frontend-v0 -> mir-v0",
            "input": {"path": manifest["source"], "sha256": digest(source)},
            "output": {"path": evidence_mir_path, "sha256": digest(mir)},
            "observable": "canonical MIR-v0 SX",
        },
        {
            "component": "fortback-new",
            "commit": backend_commit,
            "contract": "mir-v0 -> bounded RV64 Linux emission",
            "input": {"path": evidence_mir_path, "sha256": digest(mir)},
            "output": {"path": evidence_artifact_path, "sha256": digest(artifact)},
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
    "runtime": {"oracle": runtime_oracle, "exit_status": int(qemu_status)},
    "origin": "MECHANICAL",
}
Path(trace_path).write_text(json.dumps(trace, indent=2) + "\n", encoding="utf-8")
PY

cmp "$run_dir/trace.json" "$trace"
printf 'L2 central executable slice: PASS\n'
