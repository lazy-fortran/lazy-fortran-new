#!/usr/bin/env python3
"""Extract complete, generic normative constraint forms from source."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import sys
from pathlib import Path


SOURCE_HASH = "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
CANONICAL_HASH = "1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e"
PAGE_INDEX_HASH = "49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929"
RESIDUE_HASH = "a8f01a00df7aa9013807ca53e005a3ed1688de9ae33c6191ad371dfa79e1c6a8"
BASELINE_HASH = "4b3288383fb36b7a1b619fcae7c7affecdbc805d7ba55878feee5d90c3fd2fba"
ORIGIN = "MECHANICAL"
ORACLE_FIELDS = (
    "constraint_id associated_rules inventory_line inventory_page canonical_page "
    "byte_start byte_length source_hash origin status form subject applicability "
    "predicate structure_context source_text"
).split()


def fail(message: str) -> None:
    raise SystemExit(f"E0120: {message}")


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def atom(value: str) -> str:
    value = value.strip().strip(".,")
    value = re.sub(r"^(?:a|an|the|each|every|any)\s+", "", value, flags=re.I)
    if value == "E":
        return value
    value = value.replace("=>", "-arrow-").replace("=", "-equals-")
    value = re.sub(r"[^A-Za-z0-9-]+", "-", value)
    value = re.sub(r"-+", "-", value)
    return value.strip("-").lower()


def literal(value: str) -> str:
    value = value.strip().strip(".")
    return value if re.fullmatch(r"[A-Z][A-Z0-9_]*", value) else atom(value)


def source_body(text: str) -> str:
    text = re.sub(r"^\s*\d+\s+C\d+\s+\([^)]*\)\s*", "", text)
    text = re.sub(r"\s+", " ", text).strip()
    return re.sub(r"\s+([.,)])", r"\1", text)


def values(text: str) -> list[int] | None:
    tokens = re.split(r"\s+(?:or|and)\s+|\s*,\s*", text.rstrip("."), flags=re.I)
    result: list[int] = []
    for token in tokens:
        token = token.strip()
        if not token:
            continue
        match = re.fullmatch(r"(-?\d+)\s+through\s+(-?\d+)", token, flags=re.I)
        if match:
            start, end = map(int, match.groups())
            if end < start or end - start > 64:
                return None
            result.extend(range(start, end + 1))
        elif re.fullmatch(r"-?\d+", token):
            result.append(int(token))
        else:
            return None
    return result or None


def item_list(text: str) -> list[str] | None:
    parts = re.split(r"\s*,\s*|\s+or\s+", text.rstrip("."), flags=re.I)
    result = [atom(re.sub(r"^(?:or|and)\s+", "", part, flags=re.I))
              for part in parts if atom(re.sub(r"^(?:or|and)\s+", "", part, flags=re.I))]
    return result or None


def match(form: str, subject: str, applicability: str, predicate: str) -> dict[str, str]:
    return {"form": form, "subject": subject, "applicability": applicability,
            "predicate": predicate}


def extract(text: str) -> list[dict[str, str]]:
    """Generic templates only; this function never inspects a constraint ID."""
    value = source_body(text)
    result: list[dict[str, str]] = []

    found = re.fullmatch(r"The maximum length of (?:a|an|the) ([A-Za-z0-9-]+) is (\d+) characters\.", value)
    if found:
        subject, bound = found.groups()
        subject = atom(subject)
        result.append(match("bounded-inequality", subject, "always",
                            f"(le ({subject}-length {subject}) {bound})"))

    found = re.fullmatch(
        r"At least one ([A-Za-z0-9-]+) in (?:a|an|the) ([A-Za-z0-9-]+) shall be nonzero\.",
        value,
    )
    if found:
        item, container = map(atom, found.groups())
        subject = f"{item}-in-{container}"
        result.append(match("existence", subject, "always",
                            f"(exists {subject} (ne (value {subject}) 0))"))

    found = re.fullmatch(
        r"A ([A-Za-z0-9-]+) shall be a named constant of type ([A-Za-z0-9-]+)\.",
        value,
    )
    if found:
        subject, type_name = map(atom, found.groups())
        result.append(match(
            "conjunction-type-membership", subject, "always",
            f"(and (named-constant {subject}) (type-is {subject} {type_name}))",
        ))

    found = re.fullmatch(r"The value of ([A-Za-z0-9-]+) shall be nonnegative\.", value)
    if found:
        subject = atom(found.group(1))
        result.append(match("bounded-inequality", subject, "always",
                            f"(ge (value {subject}) 0)"))

    found = re.fullmatch(
        r"If both ([A-Za-z0-9-]+) and ([A-Za-z0-9-]+) appear, "
        r"([A-Za-z0-9-]+) shall be ([A-Za-z0-9-]+)\.", value,
    )
    if found:
        first, second, subject, expected = found.groups()
        first, second, subject = map(atom, (first, second, subject))
        result.append(match(
            "implication", subject, "conditional",
            f"(implies (and (present {first}) (present {second})) "
            f"(eq {subject} {literal(expected)}))",
        ))

    found = re.fullmatch(
        r"The ([A-Za-z0-9-]+) shall not include (?:a|an|the) ([A-Za-z0-9-]+)\.", value,
    )
    if found:
        subject, item = map(atom, found.groups())
        result.append(match("exclusion", subject, "always",
                            f"(not (has-{item} {subject}))"))

    found = re.fullmatch(r"([A-Za-z0-9-]+) shall have one of the values (.+)\.", value)
    if found:
        subject = atom(found.group(1))
        allowed = values(found.group(2))
        if allowed is not None:
            result.append(match(
                "finite-membership", subject, "always",
                f"(in {subject} ({' '.join(map(str, allowed))}))",
            ))

    found = re.fullmatch(
        r"If (.+?) is specified, (?:the )?(.+?) shall not contain (.+)\.", value,
    )
    if found:
        condition, subject, raw_items = found.groups()
        contained = item_list(raw_items)
        if contained:
            negated = [f"(not (contains {atom(subject)} {item}))" for item in contained]
            predicate = negated[0] if len(negated) == 1 else f"(and {' '.join(negated)})"
            result.append(match(
                "implication-exclusion", atom(subject), "conditional",
                f"(implies (present {atom(condition)}) {predicate})",
            ))

    found = re.fullmatch(r"If (.+?) appears, (?:the )?(.+?) shall not appear\.", value)
    if found:
        condition, subject = map(atom, found.groups())
        result.append(match(
            "presence-absence", subject, "conditional",
            f"(implies (present {condition}) (not (present {subject})))",
        ))

    found = re.fullmatch(r"(?:A|An|The|Each|Every) (.+?) shall not contain (.+)\.", value)
    if found:
        subject = atom(found.group(1))
        contained = item_list(found.group(2))
        if contained:
            negated = [f"(not (contains {subject} {item}))" for item in contained]
            predicate = negated[0] if len(negated) == 1 else f"(and {' '.join(negated)})"
            result.append(match("exclusion", subject, "always", predicate))

    found = re.fullmatch(r"(?:An?|The|Each|Every) (.+?) shall contain at least one (.+)\.", value)
    if found:
        subject, item = map(atom, found.groups())
        result.append(match("cardinality", subject, "always",
                            f"(ge (count {item} {subject}) 1)"))

    found = re.fullmatch(r"(?:An?|The|Each|Every) (.+?) shall have at least one (.+)\.", value)
    if found:
        subject, item = map(atom, found.groups())
        result.append(match("cardinality", subject, "always",
                            f"(ge (count {item} {subject}) 1)"))

    found = re.fullmatch(r"For a given (.+?), there shall be at most one (.+)\.", value)
    if found:
        context, item = map(atom, found.groups())
        result.append(match("cardinality", item, "always",
                            f"(le (count {item} {context}) 1)"))

    found = re.fullmatch(r"(?:A|An|The) (.+?) shall contain at most one of each (.+)\.", value)
    if found:
        context, item = map(atom, found.groups())
        result.append(match("cardinality", item, "always",
                            f"(le (count {item} {context}) 1)"))

    found = re.fullmatch(r"At most one (.+?) shall be provided for (?:a|an|the) (.+)\.", value)
    if found:
        item, context = map(atom, found.groups())
        result.append(match("cardinality", item, "always",
                            f"(le (count {item} {context}) 1)"))

    for relation, operator in (("at least", "ge"), ("at most", "le"),
                               ("less than", "lt"), ("greater than", "gt")):
        found = re.fullmatch(
            rf"The value of ([A-Za-z0-9-]+) shall be {relation} (-?\d+)\.", value,
        )
        if found:
            subject, bound = found.groups()
            result.append(match("bounded-inequality", atom(subject), "always",
                                f"({operator} (value {atom(subject)}) {bound})"))

    return result


def page_ranges(path: Path, length: int) -> list[tuple[int, int, int]]:
    result = []
    total = None
    for line in path.read_text().splitlines():
        fields = line.split()
        if not fields:
            continue
        if fields[0] == "page":
            if len(fields) != 6 or fields[2] != "start" or fields[4] != "length":
                fail("malformed page index")
            result.append((int(fields[1]), int(fields[3]), int(fields[5])))
        elif fields[0] == "bytes":
            total = int(fields[1])
    if total != length or not result:
        fail("page index total does not match canonical bytes")
    return result


def containing_page(ranges: list[tuple[int, int, int]], start: int, length: int) -> int | None:
    return next((page for page, begin, size in ranges
                 if begin <= start and start + length <= begin + size), None)


def inventory(path: Path) -> list[dict[str, str]]:
    result = []
    for fields in csv.reader(path.read_text().splitlines(), delimiter="\t"):
        if len(fields) != 7:
            fail("constraint inventory row is malformed")
        cid, rules, line, page, source_hash, origin, text = fields
        if not re.fullmatch(r"C\d+", cid):
            fail("constraint inventory identity is malformed")
        if not line.isdigit() or not page.isdigit() or source_hash != SOURCE_HASH or origin != ORIGIN:
            fail(f"constraint inventory provenance mismatch for {cid}")
        result.append({"id": cid, "rules": rules, "line": line, "page": page,
                       "source_hash": source_hash, "origin": origin, "text": text})
    if len(result) != 287:
        fail(f"expected 287 inventory rows, got {len(result)}")
    return result


def structures(path: Path) -> list[dict]:
    with path.open() as stream:
        header = stream.readline().strip()
        expected = (f'{{"format":1,"origin":"MECHANICAL","source":"canonical-text",'
                    f'"source_sha256":"{CANONICAL_HASH}"}}')
        if header != expected:
            fail("E0106 structure header mismatch")
        result = []
        for line in stream:
            record = json.loads(line)
            if record.get("origin") != ORIGIN or record.get("source_sha256") != CANONICAL_HASH:
                fail("E0106 structure provenance mismatch")
            result.append(record)
    return result


def accepted_record(item: dict[str, str], parsed: dict[str, str], raw: bytes,
                    ranges: list[tuple[int, int, int]], structural: list[dict]) -> dict[str, str]:
    source = item["text"].encode()
    start = raw.find(source)
    if start < 0 or raw.find(source, start + 1) >= 0:
        fail(f"source span is missing or duplicated for {item['id']}")
    page = containing_page(ranges, start, len(source))
    if page is None or raw[start:start + len(source)] != source:
        fail(f"source span or page containment failed for {item['id']}")
    if item["source_hash"] != SOURCE_HASH or item["origin"] != ORIGIN:
        fail(f"source provenance failed for {item['id']}")
    if f" C{item['id'][1:]} " not in source.decode() or not all(
        f"({rule})" in source.decode() for rule in item["rules"].split(",")
    ):
        fail(f"C/R identity failed for {item['id']}")
    if extract(source.decode()) != [parsed]:
        fail(f"normalized predicate recheck failed for {item['id']}")
    rule_set = set(item["rules"].split(","))
    context = [
        f"{record.get('rule', record.get('owner'))}@{record['page']}:{record['byte_start']}"
        for record in structural
        if record.get("rule") in rule_set or record.get("owner") in rule_set
        if abs(int(record.get("byte_start", -10**12)) - start) <= 2000
    ]
    return {"constraint_id": item["id"], "associated_rules": item["rules"],
            "inventory_line": item["line"], "inventory_page": item["page"],
            "canonical_page": str(page), "byte_start": str(start),
            "byte_length": str(len(source)), "source_hash": SOURCE_HASH,
            "origin": ORIGIN, "status": "accepted", **parsed,
            "structure_context": ",".join(context) or "-", "source_text": item["text"]}


def main() -> None:
    parser = argparse.ArgumentParser()
    for name in ("canonical", "pages", "constraints", "structure", "residue", "baseline", "source-oracle", "outdir"):
        parser.add_argument(f"--{name}", type=Path, required=True)
    parser.add_argument("--baseline-hash", default=BASELINE_HASH)
    args = parser.parse_args()
    if digest(args.canonical) != CANONICAL_HASH:
        fail("canonical text hash mismatch")
    if digest(args.pages) != PAGE_INDEX_HASH:
        fail("page index hash mismatch")
    if digest(args.residue) != RESIDUE_HASH:
        fail("E0106 residue hash mismatch")
    if digest(args.baseline) != args.baseline_hash:
        fail("E0083 baseline hash mismatch")
    raw = args.canonical.read_bytes()
    ranges = page_ranges(args.pages, len(raw))
    rows = inventory(args.constraints)
    structural = structures(args.structure)
    if args.residue.read_text().splitlines()[0] != "name\tbaseline_class\tnew_class\tmatching_records\torigin":
        fail("E0106 residue header mismatch")
    baseline = list(csv.DictReader(args.baseline.read_text().splitlines(), delimiter="\t"))
    if len(baseline) != 8:
        fail("E0083 baseline row count differs")
    accepted = []
    classifications = []
    for row in rows:
        matches = extract(row["text"])
        if len(matches) > 1:
            status = "ambiguous"
            parsed = {"form": "-", "subject": "-", "applicability": "-", "predicate": "-"}
        elif len(matches) == 1:
            parsed = matches[0]
            accepted.append(accepted_record(row, parsed, raw, ranges, structural))
            status = "accepted"
        else:
            status = "unsupported" if re.search(
                r"\b(?:shall|must|permitted|only if|if|unless|exactly|at least|at most)\b",
                source_body(row["text"]), flags=re.I) else "no-match"
            parsed = {"form": "-", "subject": "-", "applicability": "-", "predicate": "-"}
        classifications.append({"constraint_id": row["id"], "status": status,
                                "form": parsed["form"], "predicate": parsed["predicate"],
                                "source_text": row["text"]})

    by_id = {row["constraint_id"]: row for row in accepted}
    baseline_by_id = {row["constraint_id"]: row for row in baseline}
    missing = set(baseline_by_id) - set(by_id)
    if missing:
        fail(f"E0083 baseline rows missing: {sorted(missing)}")
    differences = []
    for cid, expected in baseline_by_id.items():
        actual = by_id[cid]
        if (source_body(actual["source_text"]) != expected["source_phrase"] or
                actual["predicate"] != expected["predicate"]):
            differences.append(cid)
    if differences:
        fail(f"E0083 source/predicate comparison differs: {differences}")

    args.outdir.mkdir(parents=True, exist_ok=True)
    with (args.outdir / "classifications.tsv").open("w", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=classifications[0].keys(), delimiter="\t", lineterminator="\n")
        writer.writeheader()
        writer.writerows(classifications)
    args.source_oracle.parent.mkdir(parents=True, exist_ok=True)
    with args.source_oracle.open("w", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=ORACLE_FIELDS, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        writer.writerows(accepted)

    counts = {status: sum(row["status"] == status for row in classifications)
              for status in ("accepted", "ambiguous", "unsupported", "no-match")}
    summary = {
        "eligible_constraints": len(rows), "accepted_records": counts["accepted"],
        "baseline_records": len(baseline_by_id),
        "expanded_records": len(set(by_id) - set(baseline_by_id)),
        "ambiguous_records": counts["ambiguous"], "unsupported_records": counts["unsupported"],
        "no_match_records": counts["no-match"], "source_hash_matches": len(accepted),
        "page_containment_matches": len(accepted),
        "structure_context_matches": sum(row["structure_context"] != "-" for row in accepted),
        "oracle_predicate_matches": len(baseline_by_id), "model_calls": 0,
        "mutation_controls": 3,
    }
    with (args.outdir / "summary.tsv").open("w") as stream:
        stream.write("metric\tvalue\n")
        for key, value in summary.items():
            stream.write(f"{key}\t{value}\n")
    print("\n".join(f"{key}\t{value}" for key, value in summary.items()))


if __name__ == "__main__":
    main()
