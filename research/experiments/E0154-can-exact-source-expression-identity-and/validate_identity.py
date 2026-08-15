#!/usr/bin/env python3
"""Independently verify source-expression lineage in generated grammar exports."""

from __future__ import annotations

import argparse
import hashlib
import re
import tempfile
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Atom:
    value: str


Node = Atom | tuple["Node", ...]


def tokens(text: str) -> list[str]:
    result: list[str] = []
    i = 0
    while i < len(text):
        if text[i].isspace():
            i += 1
        elif text[i] in "()":
            result.append(text[i])
            i += 1
        elif text[i] == '"':
            start = i
            i += 1
            while i < len(text):
                if text[i] == "\\":
                    i += 2
                elif text[i] == '"':
                    i += 1
                    break
                else:
                    i += 1
            else:
                raise ValueError("unterminated SX string")
            result.append(text[start:i])
        else:
            start = i
            while i < len(text) and not text[i].isspace() and text[i] not in "()":
                i += 1
            result.append(text[start:i])
    return result


def parse(text: str) -> Node:
    stream = tokens(text)
    cursor = 0

    def form() -> Node:
        nonlocal cursor
        if cursor >= len(stream):
            raise ValueError("unexpected end of SX")
        token = stream[cursor]
        cursor += 1
        if token != "(":
            if token == ")":
                raise ValueError("unexpected SX close")
            if token.startswith('"'):
                value = token[1:-1].replace('\\"', '"').replace('\\\\', '\\')
            else:
                value = token
            return Atom(value)
        children: list[Node] = []
        while cursor < len(stream) and stream[cursor] != ")":
            children.append(form())
        if cursor >= len(stream):
            raise ValueError("unterminated SX list")
        cursor += 1
        return tuple(children)

    value = form()
    if cursor != len(stream):
        raise ValueError("trailing SX input")
    return value


def atom(node: Node) -> str:
    if not isinstance(node, Atom):
        raise ValueError("expected SX atom")
    return node.value


def canonical(node: Node) -> str:
    if isinstance(node, Atom):
        value = node.value
        quoted = not value or any(char.isspace() or char in '()"\\' for char in value)
        if not quoted:
            return value
        return '"' + value.replace('\\', '\\\\').replace('"', '\\"') + '"'
    return "(" + " ".join(canonical(child) for child in node) + ")"


def pair(node: Node, name: str) -> Node:
    if not isinstance(node, tuple) or len(node) != 2 or atom(node[0]) != name:
        raise ValueError(f"malformed SX {name} field")
    return node[1]


def field(node: Node, name: str) -> Node:
    if not isinstance(node, tuple):
        raise ValueError(f"malformed SX {name} container")
    for child in node:
        if isinstance(child, tuple) and len(child) == 2 and atom(child[0]) == name:
            return child[1]
    raise ValueError(f"missing SX {name} field")


SourceKey = tuple[str, int, int, int]
FORMAT_NAMES = ("grammar.ebnf", "Fortran2023.g4", "fortran2023.y", "grammar.js")


def source_expressions(path: Path) -> dict[SourceKey, str]:
    result: dict[SourceKey, str] = {}
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip() or not line.lstrip().startswith("(syntax "):
            continue
        node = parse(line)
        if not isinstance(node, tuple) or len(node) < 5 or atom(node[0]) != "syntax":
            raise ValueError(f"line {line_number}: malformed syntax record")
        rule = atom(node[1])
        rhs = pair(node[3], "rhs")
        if not isinstance(rhs, tuple) or not rhs:
            raise ValueError(f"line {line_number}: empty rhs")
        if atom(rhs[0]) == "alt":
            alternatives = rhs[1:]
        elif atom(rhs[0]) == "seq":
            alternatives = (rhs,)
        else:
            raise ValueError(f"line {line_number}: unsupported rhs root")
        source = node[4]
        byte_start = int(atom(field(source, "byte-start")))
        byte_length = int(atom(field(source, "byte-length")))
        for alternative, expression in enumerate(alternatives, 1):
            # fortsx's canonical writer terminates each serialized SX object
            # with one newline; include that byte in the independent oracle.
            digest = hashlib.sha256((canonical(expression) + "\n").encode("utf-8")).hexdigest()
            key = (rule, alternative, byte_start, byte_length)
            if key in result:
                raise ValueError(f"duplicate source alternative {rule}:{alternative}@{byte_start}+{byte_length}")
            result[key] = digest
    if not result:
        raise ValueError("source SX contains no syntax alternatives")
    return result


LINEAGE = re.compile(r"source-lineage=([^\s*/]+)")
EXPRESSION = re.compile(r"source-expression-sha256=([^\s*/]+)")
TARGET_EXPRESSION = re.compile(r"target-expression-sha256=([^\s*/]+)")
LINEAGE_ITEM = re.compile(r"([A-Za-z0-9_-]+):(\d+)(?:@(\d+)\+(\d+))?")


def identity_rows(path: Path, expected: dict[SourceKey, str]) -> tuple[list[str], set[SourceKey]]:
    errors: list[str] = []
    covered: set[SourceKey] = set()
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        lineage_match = LINEAGE.search(line)
        if not lineage_match:
            continue
        lineage_text = lineage_match.group(1)
        if lineage_text == "none":
            items = []
        else:
            items = [match.groups() for match in LINEAGE_ITEM.finditer(lineage_text)]
        if not items:
            if lineage_text != "none":
                errors.append(f"{path.name}:{line_number}: malformed source lineage")
            source_expression = EXPRESSION.search(line)
            if source_expression and source_expression.group(1) != "none":
                errors.append(f"{path.name}:{line_number}: source-less lineage has a source hash")
            target_expression = TARGET_EXPRESSION.search(line)
            if not target_expression:
                errors.append(f"{path.name}:{line_number}: missing target-expression-sha256")
            elif not re.fullmatch(r"[0-9a-f]{64}", target_expression.group(1)):
                errors.append(f"{path.name}:{line_number}: malformed target expression hash")
            continue
        expression_match = EXPRESSION.search(line)
        if not expression_match:
            errors.append(f"{path.name}:{line_number}: missing source-expression-sha256")
            continue
        hashes = expression_match.group(1).split(",")
        if len(hashes) != len(items):
            errors.append(f"{path.name}:{line_number}: lineage/hash cardinality differs")
            continue
        target_expression = TARGET_EXPRESSION.search(line)
        if not target_expression:
            errors.append(f"{path.name}:{line_number}: missing target-expression-sha256")
        elif not re.fullmatch(r"[0-9a-f]{64}", target_expression.group(1)):
            errors.append(f"{path.name}:{line_number}: malformed target expression hash")
        for (rule, alternative, start, length), digest in zip(items, hashes, strict=True):
            if digest == "none":
                continue
            candidates = [
                (key, value) for key, value in expected.items()
                if key[0] == rule and key[1] == int(alternative)
            ]
            if start is not None:
                candidates = [
                    (key, value) for key, value in candidates
                    if key[2] == int(start) and key[3] == int(length)
                ]
            if not candidates:
                errors.append(f"{path.name}:{line_number}: unknown source alternative {rule}:{alternative}")
            elif digest not in {value for _, value in candidates}:
                errors.append(f"{path.name}:{line_number}: wrong expression hash for {rule}:{alternative}")
            else:
                covered.update(key for key, value in candidates if value == digest)
            if not re.fullmatch(r"[0-9a-f]{64}", digest):
                errors.append(f"{path.name}:{line_number}: malformed expression hash")
    return errors, covered


def validate(
    run_dir: Path, expected: dict[SourceKey, str]
) -> tuple[list[str], dict[str, set[SourceKey]]]:
    errors: list[str] = []
    per_format: dict[str, set[SourceKey]] = {}
    for filename in FORMAT_NAMES:
        path = run_dir / filename
        if not path.is_file():
            errors.append(f"missing export {filename}")
            per_format[filename] = set()
            continue
        rows, file_covered = identity_rows(path, expected)
        errors.extend(rows)
        per_format[filename] = file_covered
        missing = set(expected) - file_covered
        errors.extend(
            f"{filename}: missing source alternative {rule}:{alternative}@{start}+{length}"
            for rule, alternative, start, length in sorted(missing)
        )
    return errors, per_format


def mutation_control(run_dir: Path, expected: dict[SourceKey, str]) -> str:
    source = next((run_dir / name for name in ("grammar.ebnf", "Fortran2023.g4", "fortran2023.y", "grammar.js")
                   if (run_dir / name).is_file()), None)
    if source is None:
        return "FAIL"
    with tempfile.TemporaryDirectory(prefix="e0154-identity-") as temporary:
        mutated = Path(temporary) / source.name
        text = source.read_text(encoding="utf-8")
        # Role-family witnesses may precede source-preservation witnesses and
        # carry source-expression hashes for merged lineage.  The identity
        # table below validates source-preservation rows, so mutate one of
        # those first; otherwise the negative control can change an unrelated
        # witness field without exercising the checker.
        match = re.search(
            r"(?m)^\(\* target-source-preservation[^\n]*source-expression-sha256=([0-9a-f]{64})",
            text,
        )
        if match is None:
            match = re.search(r"source-expression-sha256=([0-9a-f]{64})", text)
        if not match:
            return "PASS" if validate(run_dir, expected)[0] else "FAIL"
        replacement = "0" * 64
        mutated.write_text(text[:match.start(1)] + replacement + text[match.end(1):], encoding="utf-8")
        rows, _ = identity_rows(mutated, expected)
        return "PASS" if rows else "FAIL"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--run", type=Path, required=True)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()
    expected = source_expressions(args.source)
    errors, per_format = validate(args.run, expected)
    covered = set().union(*per_format.values()) if per_format else set()
    mutation = mutation_control(args.run, expected)
    args.report.parent.mkdir(parents=True, exist_ok=True)
    with args.report.open("w", encoding="utf-8") as output:
        output.write("metric\tvalue\n")
        output.write(f"source_alternatives\t{len(expected)}\n")
        output.write(f"covered_source_alternatives\t{len(covered)}\n")
        output.write(f"missing_or_wrong_rows\t{len(errors)}\n")
        output.write(f"positive_identity\t{'PASS' if not errors else 'FAIL'}\n")
        output.write(f"negative_mutation\t{mutation}\n")
        for filename in FORMAT_NAMES:
            output.write(f"format_present_{filename}\t{'yes' if (args.run / filename).is_file() else 'no'}\n")
            output.write(f"format_covered_{filename}\t{len(per_format.get(filename, set()))}\n")
            output.write(
                f"format_identity_{filename}\t{'PASS' if len(per_format.get(filename, set())) == len(expected) else 'FAIL'}\n"
            )
        for error in errors:
            output.write(f"error\t{error}\n")
    print(args.report.read_text(encoding="utf-8"), end="")
    return 0 if not errors and mutation == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
