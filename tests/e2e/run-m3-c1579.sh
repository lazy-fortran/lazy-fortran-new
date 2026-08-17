#!/usr/bin/env bash
# Run the bounded M3 C1579 semantic-oracle delivery contract.

set -euo pipefail
source "$(dirname "$0")/../../scripts/lib.sh"
export LC_ALL=C
export LANG=C
need python3
need sha256sum
need git
need fo

if [ "$#" -eq 1 ] && [ "$1" = "--fresh" ]; then
    run_number=1
    while :; do
        run_arg=".cache/runs/E0187/R$(printf '%06d' "$run_number")"
        run_dir="$ROOT/$run_arg"
        [ ! -e "$run_dir" ] && break
        run_number=$((run_number + 1))
    done
elif [ "$#" -eq 1 ]; then
    run_arg="$1"
    case "$run_arg" in
        .cache/runs/E0187/*) ;;
        *) die "run directory must be below .cache/runs/E0187" ;;
    esac
    run_dir="$ROOT/$run_arg"
else
    die "usage: $0 .cache/runs/E0187/R<fresh-run>|--fresh"
fi
[ ! -e "$run_dir" ] || die "run directory already exists: $run_dir"
mkdir -p -- "$run_dir"

fixture="$ROOT/tests/fixtures/m3-c1579-source-backed-v0.json"
semantic_input="$ROOT/tests/fixtures/m3-c1579-semantic-items.sx"
canonical_text="$ROOT/.cache/runs/E0001/R000003/j3-24-007.canonical.txt"
standardir="$ROOT/.cache/runs/E0171/R000433-provenance-replay/standardir.sx"
source_pdf="$ROOT/.cache/j3-24-007.pdf"
golden="$ROOT/tests/golden/m3-c1579-semantic-items.sx"
validator="$ROOT/tests/e2e/validate_m3_c1579.py"
manifest="$ROOT/research/experiments/E0187-can-a-deterministic-oracle-enforce-c1579/manifest.yaml"
standard="$(resolve_repo standard-new)"

central_commit="$(git -C "$ROOT" rev-parse HEAD)"
standard_commit="$(git -C "$standard" rev-parse HEAD)"
central_pin="$(python3 - "$manifest" <<'PY'
import re
import sys
from pathlib import Path
text = Path(sys.argv[1]).read_text(encoding="utf-8")
match = re.search(r"(?ms)^repos:\n(?:(?:[ \t]+).*(?:\n|$))*?[ \t]+lazy-fortran-new:[ \t]+\"([0-9a-f]{7,64})\"", text)
if match is None:
    raise SystemExit("manifest has no concrete lazy-fortran-new pin")
print(match.group(1))
PY
)"
[ "$(git -C "$ROOT" cat-file -t "${central_pin}^{commit}" 2>/dev/null || true)" = "commit" ] || die "manifest central pin does not resolve: $central_pin"
functional_paths=(
    contracts/m3-c1579-result-entry-name-oracle-v0.sxs
    contracts/fixtures/m3-c1579-result-entry-name-oracle-v0.sx
    contracts/registry.sx
    tests/e2e/run-m3-c1579.sh
    tests/e2e/validate_m3_c1579.py
    tests/fixtures/m3-c1579-semantic-items.sx
    tests/fixtures/m3-c1579-source-backed-v0.json
    tests/golden/m3-c1579-semantic-items.sx
    artifacts/traces/m3-c1579-source-backed-v0.json
    research/decisions/D0136-twelfth-m3-c1579-result-entry-name-oracle.md
)
git -C "$ROOT" diff --quiet "$central_pin" -- "${functional_paths[@]}" || die "functional M3 C1579 files differ from manifest central pin $central_pin"
[ "$standard_commit" = "f94c4c51b51fce22b533b7eeda08741970320913" ] || die "standard-new checkout is not the pinned M3 revision"
[ -z "$(git -C "$ROOT" status --porcelain --untracked-files=normal)" ] || die "central checkout is dirty"
[ -z "$(git -C "$standard" status --porcelain --untracked-files=normal)" ] || die "standard-new checkout is dirty"

"$ROOT/scripts/check_pins.sh" >"$run_dir/check-pins.log"
"$ROOT/scripts/check-contracts.sh" >"$run_dir/check-contracts.log"
"$ROOT/scripts/check-contracts.sh" --self-test >"$run_dir/check-contracts-self-test.log"
"$ROOT/scripts/fetch.sh" j3-24-007 >"$run_dir/fetch.log"
[ -f "$canonical_text" ] || die "missing pinned canonical source: $canonical_text"
[ -f "$standardir" ] || die "missing pinned StandardIR source: $standardir"
[ -f "$source_pdf" ] || die "missing fetched normative source: $source_pdf"

fo_path="$(command -v fo)"
fo_version="$(fo version | awk 'NR == 1 { print $2 }')"
fo_sha256="$(sha256sum "$fo_path" | awk '{print $1}')"
[ "$fo_version" = "0.3.2" ] || die "unexpected fo version: $fo_version"
[ "$fo_sha256" = "0e9ac6a20523f9919b75569e15e830011e8b69fa649e7a8c71b54ba18f131a68" ] || die "unexpected fo executable hash"

(cd "$standard" && fo clean) >"$run_dir/standard-fo-clean.log" 2>&1
[ ! -e "$standard/build" ] || die "standard-new build tree survived fo clean"
(cd "$standard" && fo) >"$run_dir/standard-fo.log" 2>&1
(cd "$standard" && fo exec --no-build sxsemantic "$semantic_input" "$run_dir/semantic-items.canonical.sx") >"$run_dir/sxsemantic.log" 2>&1
cmp "$run_dir/semantic-items.canonical.sx" "$golden"

python3 "$validator" --self-test >"$run_dir/oracle-self-test.log"
python3 "$validator" "$fixture" "$run_dir/semantic-items.canonical.sx" "$standardir" "$canonical_text" "$source_pdf" "$golden" "$run_dir/result.json" >"$run_dir/oracle.log"
[ -f "$ROOT/artifacts/traces/m3-c1579-source-backed-v0.json" ] || die "missing committed C1579 trace"
cmp "$run_dir/result.json" "$ROOT/artifacts/traces/m3-c1579-source-backed-v0.json"

python3 - "$run_dir/run-environment.json" "$central_pin" "$central_commit" "$standard" "$standard_commit" "$fo_path" "$fo_version" "$fo_sha256" "$validator" "$fixture" "$semantic_input" "$standardir" "$canonical_text" "$source_pdf" <<'PY'
import hashlib
import json
import platform
import shutil
import subprocess
import sys
from pathlib import Path

output, central_pin, central_commit, standard, standard_commit, fo_path, fo_version, fo_sha256, validator, fixture, semantic_input, standardir, canonical_text, source_pdf = sys.argv[1:]

def digest(path: str) -> str:
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def version(command: list[str]) -> str:
    result = subprocess.run(command, text=True, capture_output=True, check=False)
    return (result.stdout + result.stderr).splitlines()[0]

def identity(name: str, command: list[str]) -> dict[str, str]:
    path = shutil.which(name)
    if path is None:
        raise SystemExit(f"missing tool: {name}")
    resolved = str(Path(path).resolve())
    return {"path": resolved, "version": version(command), "sha256": digest(resolved)}

record = {
    "central": {"repository": "lazy-fortran-new", "revision_pin": central_pin, "worktree_commit": central_commit, "state": "clean", "functional_tree_matches_pin": True},
    "standard_new": {"repository": standard, "commit": standard_commit, "state": "clean", "build_tree_after": "absent"},
    "inputs": {"fixture": {"path": "tests/fixtures/m3-c1579-source-backed-v0.json", "sha256": digest(fixture)}, "semantic_items": {"path": "tests/fixtures/m3-c1579-semantic-items.sx", "sha256": digest(semantic_input)}, "standardir": {"path": ".cache/runs/E0171/R000433-provenance-replay/standardir.sx", "sha256": digest(standardir)}, "canonical_text": {"path": ".cache/runs/E0001/R000003/j3-24-007.canonical.txt", "sha256": digest(canonical_text)}, "normative_pdf": {"path": ".cache/j3-24-007.pdf", "sha256": digest(source_pdf)}},
    "toolchain": {"fo": {"path": str(Path(fo_path).resolve()), "version": fo_version, "sha256": fo_sha256}, "python": identity("python3", ["python3", "--version"]), "sha256sum": identity("sha256sum", ["sha256sum", "--version"]), "git": identity("git", ["git", "--version"]), "compiler": version(["gfortran", "--version"]), "poppler": version(["pdftotext", "-v"]), "oracle_sha256": digest(validator)},
    "environment": {"os": platform.system(), "os_release": platform.release(), "architecture": platform.machine(), "python_version": platform.python_version(), "python_path": sys.executable, "locale": {"LANG": "C", "LC_ALL": "C"}},
    "commands": ["scripts/check_pins.sh", "scripts/check-contracts.sh", "scripts/check-contracts.sh --self-test", "scripts/fetch.sh j3-24-007", "(cd standard-new && fo clean)", "(cd standard-new && fo)", "(cd standard-new && fo exec --no-build sxsemantic tests/fixtures/m3-c1579-semantic-items.sx <run-dir>/semantic-items.canonical.sx)", "python3 tests/e2e/validate_m3_c1579.py --self-test", "python3 tests/e2e/validate_m3_c1579.py ..."],
    "origin": "MECHANICAL",
}
Path(output).write_text(json.dumps(record, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

(cd "$standard" && fo clean) >"$run_dir/standard-fo-final-clean.log" 2>&1
[ ! -e "$standard/build" ] || die "standard-new build tree survived final fo clean"
[ -z "$(git -C "$standard" status --porcelain --untracked-files=normal)" ] || die "standard-new became dirty during the M3 C1579 gate"
[ -z "$(git -C "$ROOT" status --porcelain --untracked-files=normal)" ] || die "central checkout became dirty during the M3 C1579 gate"
printf 'M3 C1579 PASS: %s\n' "$run_dir"
