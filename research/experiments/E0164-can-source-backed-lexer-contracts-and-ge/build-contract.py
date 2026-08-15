#!/usr/bin/env python3
"""Expand StandardIR syntax records into the central grammar-v0 contract.

This is a laboratory conversion witness. It reads only source-backed
StandardIR SX and writes one normalized contract record per source
alternative; it does not add parser policy or Fortran-specific dispatch.
"""

from __future__ import annotations

import argparse
from pathlib import Path
import re


def lex(text: str) -> list[str]:
    tokens: list[str] = []
    position = 0
    while position < len(text):
        if text[position].isspace():
            position += 1
            continue
        if text[position] in "()":
            tokens.append(text[position])
            position += 1
            continue
        if text[position] == '"':
            position += 1
            value: list[str] = []
            while position < len(text):
                if text[position] == '\\' and position + 1 < len(text):
                    value.append(text[position + 1])
                    position += 2
                    continue
                if text[position] == '"':
                    position += 1
                    break
                value.append(text[position])
                position += 1
            else:
                raise ValueError("unclosed quoted SX atom")
            # Keep a quoted punctuation atom distinct from an SX list
            # delimiter while parsing; the marker is removed by node().
            tokens.append("\x00" + "".join(value))
            continue
        start = position
        while position < len(text) and not text[position].isspace() and text[position] not in "()":
            position += 1
        tokens.append(text[start:position])
    return tokens


def parse_one(text: str) -> list:
    tokens = lex(text)
    position = 0

    def node() -> list | str:
        nonlocal position
        if position >= len(tokens):
            raise ValueError("unexpected end of SX")
        token = tokens[position]
        position += 1
        if token.startswith("\x00"):
            return token[1:]
        if token != "(":
            if token == ")":
                raise ValueError("unexpected closing parenthesis")
            return token
        result: list = []
        while position < len(tokens) and tokens[position] != ")":
            result.append(node())
        if position >= len(tokens):
            raise ValueError("unclosed SX list")
        position += 1
        return result

    result = node()
    if position != len(tokens) or not isinstance(result, list):
        raise ValueError("expected one SX list")
    return result


def fields(record: list) -> dict[str, list]:
    result: dict[str, list] = {}
    for item in record[1:]:
        if isinstance(item, list) and len(item) >= 2 and isinstance(item[0], str):
            result[item[0]] = item[1:]
    return result


def atom(value: object, field: str) -> str:
    if not isinstance(value, str) or not value:
        raise ValueError(f"missing atom {field}")
    return value


def integer(value: object, field: str) -> int:
    try:
        return int(atom(value, field))
    except ValueError as error:
        raise ValueError(f"invalid integer {field}") from error


def sx_atom(value: object, field: str) -> str:
    """Render one atom without turning punctuation into SX structure."""
    text = atom(value, field)
    if any(character.isspace() or character in '()"\\' for character in text):
        return '"' + text.replace('\\', '\\\\').replace('"', '\\"') + '"'
    return text


def emit_nodes(
    expression: list | str,
    nodes: list[dict[str, object]],
    token_map: dict[str, str],
) -> int:
    if not isinstance(expression, list) or not expression:
        raise ValueError("empty RHS expression")
    kind = atom(expression[0], "node kind")
    if kind in {"ref", "token"}:
        if len(expression) != 2:
            raise ValueError(f"malformed {kind} node")
        nodes.append({"kind": {"ref": "reference", "token": "token"}[kind],
                      "name": (token_map.get(atom(expression[1], kind),
                                             atom(expression[1], kind))
                               if kind == "token" else atom(expression[1], kind)),
                      "minimum": 1, "unbounded": "false", "first": 0, "count": 0})
        return len(nodes)
    if kind not in {"seq", "alt", "optional", "repeat"}:
        raise ValueError(f"unsupported RHS node {kind}")
    group_index = len(nodes)
    nodes.append({"kind": {"seq": "sequence", "alt": "choice"}.get(kind, kind),
                  "name": "-", "minimum": 1,
                  "unbounded": "false", "first": 0, "count": 0})
    if kind in {"seq", "alt"}:
        children = expression[1:]
        if not children:
            raise ValueError(f"empty {kind} node")
        first = len(nodes) + 1
        for child in children:
            emit_nodes(child, nodes, token_map)
        nodes[group_index].update(first=first, count=len(children))
    elif kind == "optional":
        if len(expression) != 2:
            raise ValueError("malformed optional node")
        first = len(nodes) + 1
        emit_nodes(expression[1], nodes, token_map)
        nodes[group_index].update(minimum=0, first=first, count=1)
    else:
        if len(expression) != 4:
            raise ValueError("malformed repeat node")
        first = len(nodes) + 1
        emit_nodes(expression[1], nodes, token_map)
        maximum = atom(expression[3], "repeat maximum")
        if maximum != "unbounded":
            raise ValueError("repeat maximum is not unbounded")
        nodes[group_index].update(minimum=integer(expression[2], "repeat minimum"),
                                  unbounded="true",
                                  first=first, count=1)
    return group_index + 1


def source_fields(source: list) -> dict[str, list]:
    if not source or not all(isinstance(item, list) for item in source):
        raise ValueError("record has no source record")
    result: dict[str, list] = {}
    for item in source:
        if len(item) >= 2 and isinstance(item[0], str):
            result[item[0]] = item[1:]
    return result


def record_source(record: list) -> list:
    values = fields(record)
    source = values.get("source", [])
    nested = source_fields(source)
    if "rule" not in nested and values.get("rule"):
        source = list(source) + [["rule", atom(values["rule"][0], "rule")]]
    return source


def references(expression: list | str) -> set[str]:
    result: set[str] = set()
    if isinstance(expression, list):
        if len(expression) == 2 and expression[0] == "ref":
            result.add(atom(expression[1], "reference"))
        for child in expression:
            result.update(references(child))
    return result


def contract_line(
    identity: str,
    alternative: int,
    lhs: str,
    expression: list | str,
    source: list,
    token_map: dict[str, str],
) -> str:
    source_values = source_fields(source)
    source_ref = "(source (source-ref (document {document}) (clause {clause}) " \
        "(rule {source_rule}) (page {page}) (source-hash {source_hash})))".format(
            document=atom(source_values.get("document", [None])[0], "document"),
            clause=atom(source_values.get("clause", [None])[0], "clause"),
            source_rule=atom(source_values.get("rule", [None])[0], "rule"),
            page=atom(source_values.get("page", [None])[0], "page"),
            source_hash=atom(
                source_values.get("source-sha256",
                                  source_values.get("source-hash", [None]))[0],
                "source-hash"),
        )
    nodes: list[dict[str, object]] = []
    root = emit_nodes(expression, nodes, token_map)
    rendered = " ".join(
        f"(grammar-node {n['kind']} {sx_atom(n['name'], 'node name')} {n['minimum']} "
        f"{n['unbounded']} {n['first']} {n['count']})" for n in nodes
    )
    return (
        f"(syntax-rule (id {sx_atom(identity, 'rule')}) (alternative {alternative}) "
        f"(lhs {sx_atom(lhs, 'lhs')}) (root {root}) "
        f"(nodes (grammar-nodes {rendered})) {source_ref} "
        "(origin mechanical) (resolution resolved))"
    )


def read_records(path: Path, kind: str) -> list[list]:
    records: list[list] = []
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.startswith(f"({kind} "):
            continue
        record = parse_one(line)
        if not record or record[0] != kind:
            raise ValueError(f"{path}:{line_number}: not a {kind} record")
        records.append(record)
    return records


def identifier(value: object, field: str) -> str:
    result = atom(value, field)
    if not re.fullmatch(r"[A-Za-z][A-Za-z0-9_-]*", result):
        raise ValueError(f"{field} is not an identifier: {result!r}")
    return result


def closure_expression(record: list) -> tuple[str, str, list | str]:
    values = fields(record)
    name = identifier(values.get("name", [None])[0], "classification name")
    kind = atom(values.get("kind", [None])[0], "classification kind")
    if kind in {"alias", "scalar"}:
        target = identifier(values.get("target", [None])[0], "alias target")
        return name, name, ["seq", ["ref", target]]
    if kind == "list":
        target = identifier(values.get("target", [None])[0], "list target")
        separator = atom(values.get("separator", [None])[0], "list separator")
        return name, name, ["seq", ["ref", target],
                            ["repeat", ["seq", ["token", separator], ["ref", target]],
                             "0", "unbounded"]]
    raise ValueError(f"unsupported classification kind {kind!r} for {name}")


def reachable_entries(entries: list[dict[str, object]], root: str) -> list[dict[str, object]]:
    by_lhs: dict[str, list[dict[str, object]]] = {}
    for entry in entries:
        by_lhs.setdefault(str(entry["lhs"]), []).append(entry)
    reachable = {root}
    changed = True
    while changed:
        changed = False
        for lhs in tuple(reachable):
            for entry in by_lhs.get(lhs, []):
                for name in entry["references"]:
                    if name in by_lhs and name not in reachable:
                        reachable.add(name)
                        changed = True
    return [entry for entry in entries if entry["lhs"] in reachable]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--classifications", type=Path)
    parser.add_argument("--lexical", type=Path)
    parser.add_argument("--selected-root")
    args = parser.parse_args()

    lexical_records_data = read_records(args.lexical, "lexical-fact") if args.lexical else []
    token_map: dict[str, str] = {}
    for record in lexical_records_data:
        values = fields(record)
        source_term = atom(values.get("source-term", [None])[0], "source-term")
        canonical = values.get("canonical-spelling")
        if canonical:
            token_map[source_term] = atom(canonical[0], "canonical-spelling")

    entries: list[dict[str, object]] = []
    syntax_records = 0
    for line_number, line in enumerate(args.source.read_text(encoding="utf-8").splitlines(), 1):
        if not line.startswith("(syntax "):
            continue
        record = parse_one(line)
        if len(record) < 2 or record[0] != "syntax":
            raise SystemExit(f"line {line_number}: not a syntax record")
        values = fields(record)
        rhs = values.get("rhs", [])
        if len(rhs) != 1:
            raise SystemExit(f"line {line_number}: syntax record has no RHS")
        expression = rhs[0]
        alternatives = expression[1:] if isinstance(expression, list) and expression and expression[0] == "alt" else [expression]
        for alternative, child in enumerate(alternatives, 1):
            entries.append({
                "lhs": atom(values.get("lhs", [None])[0], "lhs"),
                "references": references(child),
                "text": contract_line(atom(record[1], "rule"), alternative,
                                       atom(values.get("lhs", [None])[0], "lhs"),
                                       child, values.get("source", []), token_map),
            })
        syntax_records += 1
    if not entries:
        raise SystemExit("no syntax records")

    classification_records = 0
    closure_rules = 0
    if args.classifications:
        for record in read_records(args.classifications, "classification"):
            values = fields(record)
            kind = atom(values.get("kind", [None])[0], "classification kind")
            classification_records += 1
            if kind in {"semantic-only", "lexical"}:
                continue
            name, lhs, expression = closure_expression(record)
            entries.append({
                "lhs": lhs,
                "references": references(expression),
                "text": contract_line(f"CLOSURE-{name}", 1, lhs, expression,
                                       values.get("source", []), token_map),
            })
            closure_rules += 1

    lexical_rules = 0
    for record in lexical_records_data:
        values = fields(record)
        source_term = atom(values.get("source-term", [None])[0], "source-term")
        if values.get("canonical-spelling"):
            continue
        if not re.fullmatch(r"[A-Za-z][A-Za-z0-9_-]*", source_term):
            continue
        target = identifier(values.get("target", [None])[0], "lexical target")
        expression = ["seq", ["token", target]]
        entries.append({
            "lhs": source_term,
            "references": set(),
            "text": contract_line(f"LEXICAL-{source_term}", 1, source_term,
                                   expression, record_source(record), token_map),
        })
        lexical_rules += 1

    lexical_records = len(lexical_records_data)

    if args.selected_root:
        entries = reachable_entries(entries, args.selected_root)
    output = [str(entry["text"]) for entry in entries]
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("\n".join(output) + "\n", encoding="utf-8")
    print(f"syntax_records={syntax_records}")
    print(f"classification_records={classification_records}")
    print(f"closure_rules={closure_rules}")
    print(f"lexical_records={lexical_records}")
    print(f"lexical_rules={lexical_rules}")
    if args.selected_root:
        print(f"selected_root={args.selected_root}")
    print(f"contract_rules={len(output)}")
    print(f"max_line_bytes={max(len(line.encode()) for line in output)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
