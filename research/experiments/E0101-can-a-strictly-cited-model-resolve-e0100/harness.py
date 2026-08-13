#!/usr/bin/env python3
"""Package E0100 residue and validate an explicitly supplied model response."""
import csv
import json
import os
import shlex
import subprocess
import sys
from pathlib import Path

EXPECTED = {"ambiguous candidate", "no candidate"}
SPAN_FIELDS = ("name", "normalized", "kind", "line", "page", "reference",
               "source_hash", "origin", "span")


def fail(message):
    raise SystemExit(f"E0101: {message}")


def read_tsv(path):
    try:
        with open(path, newline="", encoding="utf-8") as handle:
            return list(csv.DictReader(handle, delimiter="\t"))
    except OSError as exc:
        fail(f"cannot read {path}: {exc}")


def load(classifications, spans):
    rows = read_tsv(classifications)
    required = {"name", "classification", "candidate_spans", "source_hash", "origin"}
    if not rows or not required <= set(rows[0]):
        fail("E0100 classifications lack the required provenance columns")
    # E0100's candidate-spans.tsv is intentionally headerless.
    with open(spans, encoding="utf-8", newline="") as handle:
        raw = list(csv.reader(handle, delimiter="\t"))
    span_rows = [dict(zip(SPAN_FIELDS, row)) for row in raw]
    residue = [row for row in rows if row["classification"] in EXPECTED]
    if len(residue) != 127 or len({row["name"] for row in residue}) != 127:
        fail(f"E0100 residue is not 127 distinct rows (got {len(residue)})")
    by_name = {row["name"]: [] for row in residue}
    for span in span_rows:
        if span.get("name") in by_name:
            item = {key: span.get(key, "") for key in SPAN_FIELDS}
            item["line"], item["page"] = int(item["line"]), int(item["page"])
            by_name[span["name"]].append(item)
    for row in residue:
        if row["origin"] != "MECHANICAL" or not row["source_hash"]:
            fail(f"missing provenance for {row['name']}")
        expected = int(row["candidate_spans"])
        if expected != len(by_name[row["name"]]):
            fail(f"retained span count mismatch for {row['name']}")
        if any(span["source_hash"] != row["source_hash"] or span["origin"] != row["origin"]
               for span in by_name[row["name"]]):
            fail(f"span provenance mismatch for {row['name']}")
    return residue, by_name


def write_package(outdir, residue, by_name):
    outdir.mkdir(parents=True, exist_ok=True)
    package = outdir / "residue.jsonl"
    with package.open("w", encoding="utf-8") as handle:
        for row in sorted(residue, key=lambda item: item["name"]):
            record = {"name": row["name"], "classification": row["classification"],
                      "audit_occurrences": int(row["audit_ref_occurrences"]),
                      "audit_referring_rules": int(row["audit_referring_rules"]),
                      "source_hash": row["source_hash"], "origin": row["origin"],
                      "spans": by_name[row["name"]]}
            handle.write(json.dumps(record, ensure_ascii=False, sort_keys=True) + "\n")
    return package


def validate(package, response, by_name):
    expected = {json.loads(line)["name"] for line in package.open(encoding="utf-8")}
    seen = set()
    accepted = unresolved = rejected = aliases = 0
    try:
        lines = response.read_text(encoding="utf-8").splitlines()
    except OSError as exc:
        fail(f"cannot read model output: {exc}")
    for number, line in enumerate(lines, 1):
        try:
            item = json.loads(line)
        except json.JSONDecodeError as exc:
            fail(f"model output line {number} is not JSON: {exc.msg}")
        if not isinstance(item, dict) or set(item) - {"name", "decision", "relation", "target", "citation"}:
            fail(f"model output line {number} has unsupported fields")
        name, decision = item.get("name"), item.get("decision")
        if name not in expected or name in seen:
            fail(f"model output line {number} has unknown or duplicate name")
        seen.add(name)
        if decision in {"unresolved", "abstain"}:
            if "citation" in item or "relation" in item or "target" in item:
                fail(f"{name}: unresolved/abstain cannot carry a relation or citation")
            unresolved += 1
            continue
        if decision != "relation" or not item.get("relation") or not item.get("target"):
            fail(f"{name}: decision must be cited relation or unresolved/abstain")
        citation = item.get("citation")
        if not isinstance(citation, dict) or set(citation) != {"line", "page", "source_hash", "span"}:
            fail(f"{name}: relation lacks an exact citation")
        if not any(all(citation[key] == span[key] for key in citation) for span in by_name[name]):
            fail(f"{name}: citation is not a retained normative span")
        accepted += 1
        if item["relation"] == "alias":
            aliases += 1
    if seen != expected:
        fail(f"model output omits {len(expected - seen)} residue rows")
    return accepted, unresolved, rejected, aliases


def main():
    if len(sys.argv) != 4:
        fail("usage: harness.py CLASSIFICATIONS.tsv SPANS.tsv OUTDIR")
    residue, by_name = load(sys.argv[1], sys.argv[2])
    outdir = Path(sys.argv[3])
    package = write_package(outdir, residue, by_name)
    runner = os.environ.get("MODEL_RUNNER", "").strip()
    if not runner:
        (outdir / "execution-blocker.txt").write_text(
            "MODEL_RUNNER is unset; no model call was made.\n", encoding="utf-8")
        print("E0101 package gate passed; execution blocked: MODEL_RUNNER is unset")
        return 0
    response = outdir / "model-output.jsonl"
    command = shlex.split(runner)
    if not command:
        fail("MODEL_RUNNER is empty after parsing")
    try:
        subprocess.run(command + [str(package), str(response)], check=True)
    except (OSError, subprocess.CalledProcessError) as exc:
        fail(f"explicit MODEL_RUNNER failed: {exc}")
    accepted, unresolved, rejected, aliases = validate(package, response, by_name)
    (outdir / "summary.tsv").write_text(
        "metric\tvalue\n" + f"residue_rows\t{len(residue)}\nretained_normative_spans\t{sum(map(len, by_name.values()))}\n"
        + f"model_calls\t1\naccepted_relations\t{accepted}\nunresolved_or_abstained\t{unresolved}\n"
        + f"rejected_outputs\t{rejected}\nalias_promotions\t{aliases}\n", encoding="utf-8")
    print("E0101 strict model-output gate passed")


if __name__ == "__main__":
    main()
