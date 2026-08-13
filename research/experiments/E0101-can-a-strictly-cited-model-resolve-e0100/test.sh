#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

python3 - "$tmp" <<'PY'
import csv, pathlib, sys
root = pathlib.Path(sys.argv[1])
with (root / "classifications.tsv").open("w", newline="") as f:
    fields = ["name", "classification", "candidate_spans", "audit_ref_occurrences",
              "audit_referring_rules", "audit_canonical_lines", "source_hash", "origin"]
    w = csv.DictWriter(f, fields, delimiter="\t"); w.writeheader()
    for i in range(46):
        w.writerow(dict(name=f"ambiguous-{i}", classification="ambiguous candidate",
                        candidate_spans=int(i == 0), audit_ref_occurrences=1, audit_referring_rules=1,
                        audit_canonical_lines=1, source_hash="hash", origin="MECHANICAL"))
    for i in range(81):
        w.writerow(dict(name=f"none-{i}", classification="no candidate",
                        candidate_spans=0, audit_ref_occurrences=1, audit_referring_rules=1,
                        audit_canonical_lines=1, source_hash="hash", origin="MECHANICAL"))
with (root / "spans.tsv").open("w") as f:
    f.write("ambiguous-0\tambiguous-0\tdefinition\t7\t2\tR1\thash\tMECHANICAL\tambiguous-0 is a test term\n")
PY

out="$tmp/no-runner"
env -u MODEL_RUNNER python3 "$here/harness.py" "$tmp/classifications.tsv" "$tmp/spans.tsv" "$out" >"$tmp/no-runner.log"
test -s "$out/residue.jsonl"
test -s "$out/execution-blocker.txt"
! test -e "$out/model-output.jsonl"
grep -q 'no model call was made' "$out/execution-blocker.txt"

runner="$tmp/runner.sh"
cat >"$runner" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' '{"name":"ambiguous-0","decision":"relation","relation":"definition","target":"x","citation":{"line":999,"page":2,"source_hash":"hash","span":"forged"}}' >"$2"
for i in $(seq 1 45); do printf '{"name":"ambiguous-%s","decision":"abstain"}\n' "$i" >>"$2"; done
for i in $(seq 0 80); do printf '{"name":"none-%s","decision":"abstain"}\n' "$i" >>"$2"; done
SH
chmod +x "$runner"
cat >"$runner" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
python3 - "$1" "$2" <<'PY'
import json, pathlib, sys
rows = []
for record in pathlib.Path(sys.argv[1]).read_text().splitlines():
    item = json.loads(record)
    name = item["name"]
    if name == "ambiguous-0":
        item = {"name": name, "decision": "relation", "relation": "definition", "target": "x",
                "citation": {"line": 7, "page": 2, "source_hash": "hash",
                              "span": "ambiguous-0 is a test term"}}
    else:
        item = {"name": name, "decision": "abstain"}
    rows.append(item)
pathlib.Path(sys.argv[2]).write_text("\n".join(json.dumps(row) for row in rows) + "\n")
PY
SH
chmod +x "$runner"
MODEL_RUNNER="$runner" python3 "$here/harness.py" "$tmp/classifications.tsv" "$tmp/spans.tsv" "$tmp/accepted" >"$tmp/accepted.log"
test "$(awk -F '\t' '$1 == "accepted_relations" {print $2}' "$tmp/accepted/summary.tsv")" -eq 1
cat >"$runner" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' '{"name":"ambiguous-0","decision":"relation","relation":"definition","target":"x","citation":{"line":999,"page":2,"source_hash":"hash","span":"forged"}}' >"$2"
for i in $(seq 1 45); do printf '{"name":"ambiguous-%s","decision":"abstain"}\n' "$i" >>"$2"; done
for i in $(seq 0 80); do printf '{"name":"none-%s","decision":"abstain"}\n' "$i" >>"$2"; done
SH
chmod +x "$runner"
if MODEL_RUNNER="$runner" python3 "$here/harness.py" "$tmp/classifications.tsv" "$tmp/spans.tsv" "$tmp/unsupported" >"$tmp/unsupported.log" 2>&1; then
  echo 'unsupported citation was accepted' >&2; exit 1
fi
grep -q 'not a retained normative span' "$tmp/unsupported.log"

cat >"$runner" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' '{"name":"ambiguous-0","decision":"relation","relation":"alias","target":"x"}' >"$2"
for i in $(seq 1 45); do printf '{"name":"ambiguous-%s","decision":"abstain"}\n' "$i" >>"$2"; done
for i in $(seq 0 80); do printf '{"name":"none-%s","decision":"abstain"}\n' "$i" >>"$2"; done
SH
if MODEL_RUNNER="$runner" python3 "$here/harness.py" "$tmp/classifications.tsv" "$tmp/spans.tsv" "$tmp/uncited" >"$tmp/uncited.log" 2>&1; then
  echo 'uncited alias was accepted' >&2; exit 1
fi
grep -q 'lacks an exact citation' "$tmp/uncited.log"
printf '%s\n' 'E0101 negative and no-runner gates passed'
