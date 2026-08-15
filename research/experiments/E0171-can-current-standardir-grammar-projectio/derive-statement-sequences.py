#!/usr/bin/env python3
"""Derive candidate statement-sequence boundaries from StandardIR topology.

This is a research witness, not a grammar rewriter.  It reads source-backed
syntax records plus the v2 lexical-layout fact that identifies statement
classes.  A candidate is a repeated reference whose transitive expression
closure reaches a statement class, or a first-item-plus-repeat sequence with
the same property.  The output keeps the source rule and expression path so a
later target projection can reject or adjudicate a candidate without guessing.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import re
import sys
from dataclasses import dataclass
from pathlib import Path


TOKEN = re.compile(r'"(?:\\.|[^"\\])*"|[^\s()]+|[()]')


class ParseError(ValueError):
    pass


def atom_value(token: str) -> str:
    if token.startswith('"') and token.endswith('"'):
        body = token[1:-1]
        return re.sub(r'\\(.)', r'\1', body)
    return token


def parse_one(text: str) -> list[object]:
    tokens = TOKEN.findall(text)
    if not tokens:
        raise ParseError("empty SX record")
    pos = 0

    def parse_expr() -> object:
        nonlocal pos
        if pos >= len(tokens) or tokens[pos] != '(':
            if pos >= len(tokens):
                raise ParseError("unexpected end of SX record")
            value = atom_value(tokens[pos])
            pos += 1
            return value
        pos += 1
        result: list[object] = []
        while pos < len(tokens) and tokens[pos] != ')':
            result.append(parse_expr())
        if pos >= len(tokens):
            raise ParseError("unclosed SX record")
        pos += 1
        return result

    result = parse_expr()
    if pos != len(tokens) or not isinstance(result, list):
        raise ParseError("record has trailing or non-list content")
    return result


def children(node: object, name: str) -> list[list[object]]:
    if not isinstance(node, list):
        return []
    return [item for item in node[1:] if isinstance(item, list) and item and item[0] == name]


def one_atom(node: object, name: str, default: str = "") -> str:
    values = children(node, name)
    if not values or len(values[0]) != 2 or not isinstance(values[0][1], str):
        return default
    return values[0][1]


def direct_refs(node: object) -> list[str]:
    if not isinstance(node, list):
        return []
    refs: list[str] = []
    if node and node[0] == "ref" and len(node) == 2 and isinstance(node[1], str):
        refs.append(node[1])
    for child in node[1:]:
        refs.extend(direct_refs(child))
    return refs


def path_nodes(node: object, prefix: str = "rhs") -> list[tuple[str, list[object]]]:
    if not isinstance(node, list):
        return []
    found = [(prefix, node)]
    for index, child in enumerate(node[1:], start=1):
        found.extend(path_nodes(child, f"{prefix}/{index}"))
    return found


def is_repeat(node: object) -> bool:
    return isinstance(node, list) and len(node) >= 2 and node[0] == "repeat"


def repeated_ref(node: object) -> str | None:
    if not is_repeat(node) or len(node) < 3:
        return None
    item = node[1]
    if isinstance(item, list) and len(item) == 2 and item[0] == "ref" and isinstance(item[1], str):
        return item[1]
    return None


def seq_items(node: object) -> list[object] | None:
    if not isinstance(node, list) or len(node) < 1 or node[0] != "seq":
        return None
    return node[1:]


def expression_nullable(node: object, nullable: set[str]) -> bool:
    if not isinstance(node, list) or not node:
        return False
    kind = node[0]
    if kind == "optional":
        return True
    if kind == "repeat":
        return len(node) >= 3 and str(node[2]) == "0"
    if kind == "alt":
        return any(expression_nullable(child, nullable) for child in node[1:])
    if kind == "seq":
        return all(expression_nullable(child, nullable) for child in node[1:])
    if kind == "ref" and len(node) == 2 and isinstance(node[1], str):
        return node[1] in nullable
    return False


def fixed_point_nullable(rules: list[Rule]) -> set[str]:
    nullable: set[str] = set()
    changed = True
    while changed:
        changed = False
        for rule in rules:
            if rule.lhs not in nullable and expression_nullable(rule.rhs, nullable):
                nullable.add(rule.lhs)
                changed = True
    return nullable


def direct_statement_ref(node: object, statement_classes: set[str]) -> str | None:
    if isinstance(node, list) and len(node) == 2 and node[0] == "ref" and isinstance(node[1], str):
        if node[1] in statement_classes:
            return node[1]
    return None


def compound_sequence(node: object, statement_classes: set[str], reachable: set[str], nullable: set[str]) -> tuple[list[tuple[int, str]], bool]:
    """Return direct statement positions and whether a seq is safe to retain.

    A compound repeated item is safe only when each non-statement component is
    either nullable or itself a statement-bearing sequence. This is a
    conservative structural relation; arbitrary semantic payload is rejected.
    """
    items = seq_items(node)
    if not items:
        return [], False
    direct: list[tuple[int, str]] = []
    for index, child in enumerate(items, start=1):
        statement = direct_statement_ref(child, statement_classes)
        if statement is not None:
            direct.append((index, statement))
            continue
        refs = direct_refs(child)
        if not refs:
            return [], False
        if not (expression_nullable(child, nullable) or any(ref in reachable for ref in refs)):
            return [], False
    return direct, bool(direct)


def sequence_internal_statements(node: object, statement_classes: set[str], reachable: set[str], nullable: set[str]) -> list[tuple[int, str]]:
    items = seq_items(node)
    if not items:
        return []
    result: list[tuple[int, str]] = []
    for index, child in enumerate(items):
        statement = direct_statement_ref(child, statement_classes)
        if statement is None or index == len(items) - 1:
            continue
        suffix = items[index + 1:]
        suffix_nullable = all(expression_nullable(item, nullable) for item in suffix)
        suffix_statement_bearing = any(
            ref in reachable for item in suffix for ref in direct_refs(item))
        if suffix_nullable or suffix_statement_bearing:
            result.append((index + 1, statement))
    return result


@dataclass(frozen=True)
class Rule:
    rule_id: str
    lhs: str
    rhs: object
    document: str
    clause: str
    page: str
    byte_start: str
    source_hash: str


def read_records(path: Path) -> list[Rule]:
    rules: list[Rule] = []
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        if not line.strip():
            continue
        try:
            record = parse_one(line)
        except ParseError as exc:
            raise ParseError(f"{path}:{line_number}: {exc}") from exc
        if not record or record[0] != "syntax":
            continue
        if len(record) < 3:
            raise ParseError(f"{path}:{line_number}: malformed syntax record")
        rule_id = str(record[1])
        lhs = one_atom(record, "lhs")
        rhs_nodes = children(record, "rhs")
        if not lhs or len(rhs_nodes) != 1:
            raise ParseError(f"{path}:{line_number}: syntax record lacks lhs/rhs")
        source_nodes = children(record, "source")
        source = source_nodes[0] if source_nodes else []
        rules.append(Rule(
            rule_id,
            lhs,
            rhs_nodes[0][1],
            one_atom(source, "document", ""),
            one_atom(source, "clause", ""),
            one_atom(source, "page", ""),
            one_atom(source, "byte-start", ""),
            one_atom(source, "source-sha256", ""),
        ))
    if not rules:
        raise ParseError(f"{path}: no syntax records")
    return rules


def read_suffix(path: Path) -> str:
    suffixes: set[str] = set()
    source_forms: set[str] = set()
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        if not line.strip():
            continue
        record = parse_one(line)
        if not record or record[0] != "statement-class-suffix":
            continue
        suffix_nodes = children(record, "suffix")
        if len(suffix_nodes) != 1 or len(suffix_nodes[0]) != 2:
            raise ParseError(f"{path}:{line_number}: malformed statement-class-suffix")
        suffixes.add(str(suffix_nodes[0][1]))
        form_nodes = children(record, "source-form")
        if len(form_nodes) != 1 or len(form_nodes[0]) != 2:
            raise ParseError(f"{path}:{line_number}: statement-class-suffix lacks source-form")
        source_forms.add(str(form_nodes[0][1]))
    if len(suffixes) != 1 or source_forms != {"all"}:
        raise ParseError(f"{path}: expected exactly one statement-class suffix")
    return next(iter(suffixes))


def fixed_point_statement_reachability(rules: list[Rule], suffix: str) -> set[str]:
    reachable = {rule.lhs for rule in rules if rule.lhs.endswith(suffix)}
    changed = True
    while changed:
        changed = False
        for rule in rules:
            if rule.lhs in reachable:
                continue
            if any(ref in reachable for ref in direct_refs(rule.rhs)):
                reachable.add(rule.lhs)
                changed = True
    return reachable


def derivation_refs(node: object, reachable: set[str]) -> list[str]:
    return sorted({ref for ref in direct_refs(node) if ref in reachable})


def derive_candidates(rules: list[Rule], suffix: str) -> tuple[list[dict[str, str]], set[str]]:
    reachable = fixed_point_statement_reachability(rules, suffix)
    statement_classes = {rule.lhs for rule in rules if rule.lhs.endswith(suffix)}
    nullable = fixed_point_nullable(rules)
    candidates: list[dict[str, str]] = []
    for rule in rules:
        for path, node in path_nodes(rule.rhs):
            for position, statement in sequence_internal_statements(
                    node, statement_classes, reachable, nullable):
                candidates.append({
                    "rule": rule.rule_id,
                    "container": rule.lhs,
                    "source_document": rule.document,
                    "source_clause": rule.clause,
                    "page": rule.page,
                    "byte_start": rule.byte_start,
                    "source_sha256": rule.source_hash,
                    "kind": "sequence-internal",
                    "path": f"{path}/{position}",
                    "item": statement,
                    "derivation": statement,
                    "status": "candidate",
                })
            item = repeated_ref(node)
            if is_repeat(node) and item is None:
                repeat_item = node[1] if len(node) > 1 else []
                nested = derivation_refs(repeat_item, reachable)
                direct, compound_ok = compound_sequence(
                    repeat_item, statement_classes, reachable, nullable)
                if compound_ok:
                    candidates.append({
                        "rule": rule.rule_id,
                        "container": rule.lhs,
                        "source_document": rule.document,
                        "source_clause": rule.clause,
                        "page": rule.page,
                        "byte_start": rule.byte_start,
                        "source_sha256": rule.source_hash,
                        "kind": "compound-repeat-item",
                        "path": path,
                        "item": "sequence",
                        "derivation": ",".join(nested),
                        "status": "candidate",
                    })
                    continue
                if nested:
                    candidates.append({
                        "rule": rule.rule_id,
                        "container": rule.lhs,
                        "source_document": rule.document,
                        "source_clause": rule.clause,
                        "page": rule.page,
                        "byte_start": rule.byte_start,
                        "source_sha256": rule.source_hash,
                        "kind": "unsupported-repeat-item",
                        "path": path,
                        "item": "expression",
                        "derivation": ",".join(nested),
                        "status": "unsupported",
                    })
                continue
            if item is not None and item in reachable:
                candidates.append({
                    "rule": rule.rule_id,
                    "container": rule.lhs,
                    "source_document": rule.document,
                    "source_clause": rule.clause,
                    "page": rule.page,
                    "byte_start": rule.byte_start,
                    "source_sha256": rule.source_hash,
                    "kind": "repeat-item",
                    "path": path,
                    "item": item,
                    "derivation": ",".join(derivation_refs(node, reachable)),
                    "status": "candidate",
                })
            items = seq_items(node)
            if not items:
                continue
            for index, child in enumerate(items):
                repeated = repeated_ref(child)
                repeat_item = child[1] if is_repeat(child) and len(child) > 1 else []
                direct, compound_ok = compound_sequence(
                    repeat_item, statement_classes, reachable, nullable)
                item_name = repeated if repeated is not None else ("sequence" if compound_ok else None)
                if item_name is None or (repeated is not None and repeated not in reachable):
                    continue
                prefix_refs = [ref for sibling in items[:index] for ref in direct_refs(sibling)]
                if not any(ref in reachable for ref in prefix_refs):
                    continue
                candidates.append({
                    "rule": rule.rule_id,
                    "container": rule.lhs,
                    "source_document": rule.document,
                    "source_clause": rule.clause,
                    "page": rule.page,
                    "byte_start": rule.byte_start,
                    "source_sha256": rule.source_hash,
                    "kind": "first-plus-repeat",
                    "path": f"{path}/{index + 1}",
                    "item": item_name,
                    "derivation": ",".join(derivation_refs(child, reachable)),
                    "status": "candidate",
                })
    candidates.sort(key=lambda row: (row["container"], row["rule"], row["byte_start"], row["path"], row["kind"]))
    return candidates, reachable


def write_tsv(path: Path, candidates: list[dict[str, str]], source: Path, layout: Path, suffix: str, reachable: set[str]) -> int:
    if path.exists():
        raise SystemExit(f"refusing to overwrite {path}")
    path.parent.mkdir(parents=True, exist_ok=True)
    fields = ["rule", "container", "source_document", "source_clause", "page", "byte_start", "source_sha256", "kind", "path", "item", "derivation", "status"]
    with path.open("x", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        writer.writerows(candidates)
    print(f"source_sha256={hashlib.sha256(source.read_bytes()).hexdigest()}")
    print(f"layout_sha256={hashlib.sha256(layout.read_bytes()).hexdigest()}")
    print(f"statement_suffix={suffix}")
    print(f"statement_reachable={len(reachable)}")
    print(f"candidates={len(candidates)}")
    unsupported = sum(row["status"] == "unsupported" for row in candidates)
    print(f"unsupported={unsupported}")
    return unsupported


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("standardir", type=Path)
    parser.add_argument("layout_sx", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    try:
        rules = read_records(args.standardir)
        suffix = read_suffix(args.layout_sx)
        candidates, reachable = derive_candidates(rules, suffix)
        unsupported = write_tsv(args.output, candidates, args.standardir, args.layout_sx, suffix, reachable)
    except (OSError, ParseError) as exc:
        print(f"derive-statement-sequences: {exc}", file=sys.stderr)
        return 2
    return 3 if unsupported else 0


if __name__ == "__main__":
    raise SystemExit(main())
