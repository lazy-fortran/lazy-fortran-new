#!/usr/bin/env python3
"""Validate the M1-M2 StandardIR projections against the pinned contracts."""

from __future__ import annotations

import hashlib
import json
import re
import sys
import tomllib
from pathlib import Path


class ContractError(Exception):
    pass


def fail(message: str) -> None:
    raise SystemExit(f"M1-M2 contract failure: {message}")


def parse(text: str) -> object:
    tokens: list[str] = []
    index = 0
    while index < len(text):
        char = text[index]
        if char.isspace():
            index += 1
            continue
        if char in "()":
            tokens.append(char)
            index += 1
            continue
        if char == '"':
            index += 1
            value: list[str] = []
            while index < len(text):
                char = text[index]
                index += 1
                if char == '"':
                    break
                if char == "\\":
                    if index >= len(text):
                        raise ContractError("unterminated SX escape")
                    value.append(text[index])
                    index += 1
                else:
                    value.append(char)
            else:
                raise ContractError("unterminated SX string")
            tokens.append("\x00" + "".join(value))
            continue
        start = index
        while index < len(text) and not text[index].isspace() and text[index] not in "()":
            index += 1
        tokens.append(text[start:index])

    def expression(position: int) -> tuple[object, int]:
        if position >= len(tokens) or tokens[position] != "(":
            if position >= len(tokens):
                raise ContractError("unexpected end of SX")
            token = tokens[position]
            return (token[1:] if token.startswith("\x00") else token), position + 1
        values: list[object] = []
        position += 1
        while position < len(tokens) and tokens[position] != ")":
            value, position = expression(position)
            values.append(value)
        if position >= len(tokens):
            raise ContractError("unclosed SX list")
        return values, position + 1

    value, end = expression(0)
    if end != len(tokens):
        raise ContractError("multiple SX expressions")
    return value


def atom(value: object, context: str) -> str:
    if not isinstance(value, str):
        raise ContractError(f"{context} is not an atom")
    return value


def list_node(value: object, context: str) -> list[object]:
    if not isinstance(value, list):
        raise ContractError(f"{context} is not a list")
    return value


def label(value: object, context: str) -> str:
    node = list_node(value, context)
    if not node:
        raise ContractError(f"{context} is empty")
    return atom(node[0], f"{context} label")


def pairs(node: object, context: str) -> dict[str, object]:
    values = list_node(node, context)
    result: dict[str, object] = {}
    for child in values[1:]:
        if not isinstance(child, list):
            continue
        child_values = list_node(child, context)
        if len(child_values) < 2:
            continue
        name = atom(child_values[0], f"{context} field")
        if name in result:
            raise ContractError(f"duplicate {context} field {name}")
        result[name] = child_values[1] if len(child_values) == 2 else child
    return result


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def schema_info(path: Path) -> tuple[str, dict[str, list[tuple[str, str]]], dict[str, set[str]]]:
    root = list_node(parse(path.read_text(encoding="utf-8")), str(path))
    if len(root) < 2 or atom(root[0], str(path)) != "schema":
        raise ContractError(f"{path} has no schema root")
    name = atom(root[1], f"{path} schema name")
    records: dict[str, list[tuple[str, str]]] = {}
    enums: dict[str, set[str]] = {}
    for declaration in root[2:]:
        values = list_node(declaration, f"{path} declaration")
        if not values:
            continue
        kind = atom(values[0], f"{path} declaration label")
        if kind == "record":
            record_name = atom(values[1], f"{path} record name")
            records[record_name] = [
                (atom(field[0], "record field name"), atom(field[1], "record field type"))
                for field in (list_node(item, "record field") for item in values[2:])
            ]
        elif kind == "enum":
            enum_name = atom(values[1], f"{path} enum name")
            enums[enum_name] = {atom(item, "enum value") for item in values[2:]}
    return name, records, enums


def integer(value: object, context: str) -> int:
    text = atom(value, context)
    if not re.fullmatch(r"[0-9]+", text):
        raise ContractError(f"{context} is not a non-negative integer")
    return int(text)


def bool_atom(value: object, context: str) -> str:
    text = atom(value, context)
    if text not in {"true", "false"}:
        raise ContractError(f"{context} is not a boolean")
    return text


def source_ref(
    raw_source: object,
    source_fields: list[tuple[str, str]],
    expected_document: str,
    expected_hash: str,
) -> list[object]:
    raw = pairs(raw_source, "source")
    aliases = {"source-hash": "source-sha256"}
    values: list[object] = ["source-ref"]
    for field, field_type in source_fields:
        raw_name = aliases.get(field, field)
        if raw_name not in raw:
            raise ContractError(f"source is missing contract field {field}")
        value = raw[raw_name]
        if field_type == "int":
            integer(value, f"source {field}")
        else:
            atom(value, f"source {field}")
        if field == "page" and integer(value, "source page") < 1:
            raise ContractError("source page is not positive")
        if field == "document" and atom(value, "source document") != expected_document:
            raise ContractError("source document differs from the pinned manifest")
        if field == "source-hash" and atom(value, "source hash") != expected_hash:
            raise ContractError("source hash differs from the pinned source")
        values.extend([[field, value]])
    return values


def check_record_fields(node: object, record_name: str, fields: list[tuple[str, str]]) -> dict[str, object]:
    if label(node, record_name) != record_name:
        raise ContractError(f"expected {record_name} record")
    actual = pairs(node, record_name)
    expected = {name for name, _ in fields}
    if set(actual) != expected:
        raise ContractError(
            f"{record_name} fields differ: expected {sorted(expected)}, got {sorted(actual)}"
        )
    return actual


def render(value: object) -> str:
    if isinstance(value, list):
        return "(" + " ".join(render(item) for item in value) + ")"
    text = atom(value, "SX value")
    if re.fullmatch(r"[^\s()\"]+", text):
        return text
    return json.dumps(text, ensure_ascii=False)


def normalize_expression(
    expression: object, node_kinds: set[str]
) -> tuple[list[list[object]], int]:
    nodes: list[list[object]] = []
    aliases = {
        "ref": "reference",
        "token": "token",
        "seq": "sequence",
        "alt": "choice",
        "optional": "optional",
        "repeat": "repeat",
    }

    def visit(value: object) -> int:
        current = list_node(value, "grammar expression")
        if not current:
            raise ContractError("grammar expression is empty")
        source_kind = atom(current[0], "grammar expression kind")
        kind = aliases.get(source_kind)
        if kind is None or kind not in node_kinds:
            raise ContractError(f"grammar expression kind {source_kind} is not in the contract")
        index = len(nodes) + 1
        nodes.append([])
        if source_kind in {"ref", "token"}:
            if len(current) != 2:
                raise ContractError(f"{source_kind} expression has the wrong arity")
            name = atom(current[1], f"{source_kind} name")
            nodes[index - 1] = ["grammar-node", kind, name, "1", "false", "0", "0"]
        elif source_kind in {"seq", "alt"}:
            if len(current) < 2:
                raise ContractError(f"{source_kind} expression has no children")
            first_child = len(nodes) + 1
            for child in current[1:]:
                visit(child)
            nodes[index - 1] = [
                "grammar-node", kind, "-", "1", "false", str(first_child), str(len(current) - 1)
            ]
        elif source_kind == "optional":
            if len(current) != 2:
                raise ContractError("optional expression has the wrong arity")
            first_child = len(nodes) + 1
            visit(current[1])
            nodes[index - 1] = ["grammar-node", kind, "-", "0", "false", str(first_child), "1"]
        else:
            if len(current) != 4 or atom(current[3], "repeat bound") != "unbounded":
                raise ContractError("repeat expression has the wrong shape")
            minimum = integer(current[2], "repeat minimum")
            first_child = len(nodes) + 1
            visit(current[1])
            nodes[index - 1] = [
                "grammar-node", kind, "-", str(minimum), "true", str(first_child), "1"
            ]
        return index

    return nodes, visit(expression)


def main() -> None:
    if len(sys.argv) != 5:
        raise SystemExit(
            "usage: validate_m1m2_contracts.py FIXTURE STANDARDIR STANDARDIR-VIEW GRAMMAR-VIEW"
        )
    fixture_path, standardir_path, standardir_view_path, grammar_view_path = map(Path, sys.argv[1:])
    fixture = tomllib.loads(fixture_path.read_text(encoding="utf-8"))
    root = fixture_path.resolve().parents[2]
    names = fixture["central_contracts"]
    paths = fixture["central_contract_paths"]
    hashes = fixture["central_contract_sha256"]
    if names != ["standardir-v0", "standardir-grammar-v0"]:
        fail("M1-M2 contract set is not the declared pair")
    schemas = []
    for name, relative_path, expected_hash in zip(names, paths, hashes):
        path = root / relative_path
        if digest(path) != expected_hash:
            fail(f"contract hash differs: {relative_path}")
        schema_name, records, enums = schema_info(path)
        if schema_name != name:
            fail(f"contract root differs: {relative_path}")
        schemas.append((records, enums))

    standard_records, standard_enums = schemas[0]
    grammar_records, grammar_enums = schemas[1]
    required_standard = {"source-ref", "syntax-item"}
    required_grammar = {"source-ref", "grammar-node", "syntax-rule"}
    if not required_standard <= standard_records.keys() or not required_grammar <= grammar_records.keys():
        fail("pinned contracts do not declare the required records")
    for enum_name in ("origin", "resolution"):
        if enum_name not in standard_enums or enum_name not in grammar_enums:
            fail(f"pinned contracts do not declare {enum_name}")
    node_kinds = grammar_enums.get("node-kind", set())
    if not node_kinds:
        fail("grammar contract has no node-kind enum")

    source_manifest = tomllib.loads((root / fixture["source_manifest"]).read_text(encoding="utf-8"))
    expected_document = source_manifest["name"].upper()
    expected_hash = source_manifest["sha256"]
    contract_origin = fixture.get("contract_origin", "mechanical")
    contract_resolution = fixture.get("contract_resolution", "resolved")
    if contract_origin not in standard_enums["origin"] or contract_resolution not in standard_enums["resolution"]:
        fail("fixture contract metadata is outside the pinned enums")

    lines = [line for line in standardir_path.read_text(encoding="utf-8").splitlines() if line.strip()]
    if not lines:
        fail("StandardIR output is empty")
    header = list_node(parse(lines[0]), "StandardIR header")
    header_fields = pairs(header, "standardir header")
    if label(header, "StandardIR header") != "standardir":
        fail("StandardIR header label differs")
    if atom(header_fields.get("origin"), "StandardIR origin").lower() != contract_origin:
        fail("StandardIR header origin differs from the contract projection")

    standard_view: list[str] = [
        render(["standardir-contract", ["contract", "standardir-v0"], ["version", "0"]])
    ]
    grammar_view: list[str] = [
        render(["grammar-contract", ["contract", "standardir-grammar-v0"], ["version", "0"]])
    ]
    grammar_rows = 0
    for line_number, line in enumerate(lines[1:], start=2):
        syntax = list_node(parse(line), f"StandardIR line {line_number}")
        if label(syntax, f"StandardIR line {line_number}") != "syntax":
            fail(f"StandardIR line {line_number} is not a syntax record")
        fields = pairs(syntax, f"StandardIR line {line_number}")
        if len(syntax) < 2:
            fail(f"StandardIR line {line_number} has no id")
        fields["id"] = syntax[1]
        for required in ("id", "lhs", "rhs", "source"):
            if required not in fields:
                fail(f"StandardIR line {line_number} is missing {required}")
        source = source_ref(
            fields["source"], standard_records["source-ref"], expected_document, expected_hash
        )
        syntax_id = atom(fields["id"], f"StandardIR line {line_number} id")
        lhs = atom(fields["lhs"], f"StandardIR line {line_number} lhs")
        standard_item = [
            "syntax-item",
            ["id", syntax_id],
            ["lhs", lhs],
            ["source", source],
            ["origin", contract_origin],
            ["resolution", contract_resolution],
        ]
        check_record_fields(standard_item, "syntax-item", standard_records["syntax-item"])
        standard_view.append(render(standard_item))

        rhs = list_node(fields["rhs"], f"StandardIR line {line_number} rhs")
        alternatives = rhs[1:] if label(rhs, "rhs") == "alt" else [rhs]
        for alternative, expression in enumerate(alternatives, start=1):
            nodes, root_index = normalize_expression(expression, node_kinds)
            node_list = ["nodes", ["grammar-nodes", *nodes]]
            rule = [
                "syntax-rule",
                ["id", syntax_id],
                ["alternative", str(alternative)],
                ["lhs", lhs],
                ["root", str(root_index)],
                node_list,
                ["source", source],
                ["origin", contract_origin],
                ["resolution", contract_resolution],
            ]
            check_record_fields(rule, "syntax-rule", grammar_records["syntax-rule"])
            for node in nodes:
                if len(node) != 7:
                    raise ContractError("grammar node has the wrong arity")
                if node[1] not in node_kinds:
                    raise ContractError(f"grammar node kind {node[1]} is not in the contract")
                integer(node[3], "grammar node minimum")
                bool_atom(node[4], "grammar node unbounded")
                integer(node[5], "grammar node first child")
                integer(node[6], "grammar node child count")
            grammar_view.append(render(rule))
            grammar_rows += 1

    standardir_view_path.write_text("\n".join(standard_view) + "\n", encoding="utf-8")
    grammar_view_path.write_text("\n".join(grammar_view) + "\n", encoding="utf-8")
    print(
        f"M1-M2 contracts: PASS standardir_records={len(standard_view) - 1} "
        f"grammar_rules={grammar_rows}"
    )


if __name__ == "__main__":
    try:
        main()
    except (ContractError, OSError, KeyError, ValueError) as error:
        fail(str(error))
