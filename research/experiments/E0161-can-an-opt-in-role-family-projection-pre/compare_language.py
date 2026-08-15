#!/usr/bin/env python3
"""Compare two generated EBNF grammars with a bounded CFG language oracle.

The parser and recognizer are deliberately independent of standard-new's
StandardIR transformer.  The oracle only consumes the emitted EBNF files.  It
reports a bounded corpus, not a claim about the complete Fortran language.
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass
from pathlib import Path


class GrammarError(ValueError):
    pass


@dataclass(frozen=True)
class Literal:
    value: str


@dataclass(frozen=True)
class Reference:
    name: str


@dataclass(frozen=True)
class Sequence:
    items: tuple["Expression", ...]


@dataclass(frozen=True)
class Choice:
    items: tuple["Expression", ...]


@dataclass(frozen=True)
class Optional:
    item: "Expression"


@dataclass(frozen=True)
class Repeat:
    item: "Expression"


@dataclass(frozen=True)
class Empty:
    pass


Expression = Literal | Reference | Sequence | Choice | Optional | Repeat | Empty
Word = tuple[str, ...]


def remove_comments(text: str) -> str:
    result: list[str] = []
    quoted = False
    escaped = False
    comment = False
    index = 0
    while index < len(text):
        char = text[index]
        next_char = text[index + 1] if index + 1 < len(text) else ""
        if comment:
            if char == "*" and next_char == ")":
                comment = False
                index += 2
            else:
                result.append("\n" if char == "\n" else " ")
                index += 1
            continue
        if quoted:
            result.append(char)
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                quoted = False
            index += 1
            continue
        if char == '"':
            quoted = True
            result.append(char)
            index += 1
        elif char == "(" and next_char == "*":
            comment = True
            result.extend((" ", " "))
            index += 2
        else:
            result.append(char)
            index += 1
    if comment:
        raise GrammarError("unterminated EBNF comment")
    if quoted:
        raise GrammarError("unterminated EBNF literal")
    return "".join(result)


def find_semicolon(text: str) -> int:
    quoted = False
    escaped = False
    for index, char in enumerate(text):
        if quoted:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                quoted = False
        elif char == '"':
            quoted = True
        elif char == ";":
            return index
    return -1


def tokenize(text: str) -> list[str]:
    tokens: list[str] = []
    index = 0
    symbols = set("|()[]{}")
    while index < len(text):
        char = text[index]
        if char.isspace():
            index += 1
        elif char in symbols:
            tokens.append(char)
            index += 1
        elif char == '"':
            start = index
            index += 1
            escaped = False
            while index < len(text):
                current = text[index]
                index += 1
                if escaped:
                    escaped = False
                elif current == "\\":
                    escaped = True
                elif current == '"':
                    break
            else:
                raise GrammarError("unterminated EBNF literal")
            tokens.append(text[start:index])
        else:
            start = index
            while index < len(text) and not text[index].isspace() and text[index] not in symbols:
                index += 1
            tokens.append(text[start:index])
    return tokens


class BodyParser:
    def __init__(self, tokens: list[str]):
        self.tokens = tokens
        self.index = 0

    def parse(self) -> Expression:
        expression = self.choice(stop=None)
        if self.index != len(self.tokens):
            raise GrammarError(f"unexpected EBNF token {self.tokens[self.index]!r}")
        return expression

    def choice(self, stop: str | None) -> Expression:
        alternatives = [self.sequence(stop)]
        while self.peek() == "|":
            self.index += 1
            alternatives.append(self.sequence(stop))
        if len(alternatives) == 1:
            return alternatives[0]
        return Choice(tuple(alternatives))

    def sequence(self, stop: str | None) -> Expression:
        items: list[Expression] = []
        while self.peek() is not None and self.peek() != "|" and self.peek() != stop:
            items.append(self.primary())
        return Sequence(tuple(items)) if items else Empty()

    def primary(self) -> Expression:
        token = self.peek()
        if token is None:
            raise GrammarError("unexpected end of EBNF expression")
        self.index += 1
        if token == "(":
            value = self.choice(")")
            self.expect(")")
            return value
        if token == "[":
            value = self.choice("]")
            self.expect("]")
            return Optional(value)
        if token == "{":
            value = self.choice("}")
            self.expect("}")
            return Repeat(value)
        if token in {")", "]", "}", "|",
        }:
            raise GrammarError(f"unexpected EBNF delimiter {token!r}")
        if token.startswith('"'):
            return Literal(decode_literal(token))
        return Reference(token)

    def peek(self) -> str | None:
        return self.tokens[self.index] if self.index < len(self.tokens) else None

    def expect(self, expected: str) -> None:
        actual = self.peek()
        if actual != expected:
            raise GrammarError(f"expected {expected!r}, got {actual!r}")
        self.index += 1


def decode_literal(token: str) -> str:
    try:
        value = json.loads(token)
    except json.JSONDecodeError as error:
        raise GrammarError(f"invalid EBNF literal {token!r}: {error}") from error
    if not isinstance(value, str):
        raise GrammarError(f"EBNF literal is not a string: {token!r}")
    return value


def load_grammar(path: Path) -> dict[str, Expression]:
    text = remove_comments(path.read_text(encoding="utf-8"))
    productions: dict[str, list[Expression]] = {}
    current_name: str | None = None
    current_body: list[str] = []
    for line_number, line in enumerate(text.splitlines(), 1):
        remaining = line.strip()
        while remaining:
            if current_name is None:
                match = re.match(r"^([A-Za-z_][A-Za-z0-9_-]*)\s*::=\s*(.*)$", remaining)
                if match is None:
                    raise GrammarError(f"line {line_number}: expected production head")
                current_name = match.group(1)
                remaining = match.group(2).strip()
            semicolon = find_semicolon(remaining)
            if semicolon < 0:
                current_body.append(remaining)
                break
            current_body.append(remaining[:semicolon])
            body = " ".join(current_body).strip()
            productions.setdefault(current_name, []).append(BodyParser(tokenize(body)).parse())
            current_name = None
            current_body = []
            remaining = remaining[semicolon + 1 :].strip()
    if current_name is not None:
        raise GrammarError(f"unterminated production {current_name}")
    if not productions:
        raise GrammarError(f"{path}: no productions")
    return {
        name: Choice(tuple(bodies)) if len(bodies) > 1 else bodies[0]
        for name, bodies in productions.items()
    }


def bounded_words(
    grammar: dict[str, Expression],
    root: str,
    max_depth: int,
    max_tokens: int,
    max_words: int,
    repeat_limit: int,
) -> tuple[Word, ...]:
    if root not in grammar:
        raise GrammarError(f"root {root!r} is not defined")
    truncated = False

    def trim(values: set[Word]) -> set[Word]:
        nonlocal truncated
        result = {value for value in values if len(value) <= max_tokens}
        if len(result) > max_words:
            truncated = True
            return set(sorted(result, key=lambda word: (len(word), word))[:max_words])
        return result

    def concat(left: set[Word], right: set[Word]) -> set[Word]:
        return trim({a + b for a in left for b in right})

    def derive(expression: Expression, depth: int, stack: tuple[str, ...]) -> set[Word]:
        if depth > max_depth:
            return set()
        if isinstance(expression, Empty):
            return {()}
        if isinstance(expression, Literal):
            return {(expression.value,)} if max_tokens >= 1 else set()
        if isinstance(expression, Reference):
            if expression.name not in grammar:
                return {(expression.name,)} if max_tokens >= 1 else set()
            if expression.name in stack:
                return set()
            return derive(grammar[expression.name], depth + 1, stack + (expression.name,))
        if isinstance(expression, Sequence):
            result = {()}
            for item in expression.items:
                result = concat(result, derive(item, depth, stack))
            return result
        if isinstance(expression, Choice):
            result: set[Word] = set()
            for item in expression.items:
                result.update(derive(item, depth, stack))
            return trim(result)
        if isinstance(expression, Optional):
            return trim({()} | derive(expression.item, depth + 1, stack))
        if isinstance(expression, Repeat):
            result = {()}
            layer = {()}
            for _ in range(repeat_limit):
                layer = concat(layer, derive(expression.item, depth + 1, stack))
                result.update(layer)
                if not layer:
                    break
            return trim(result)
        raise TypeError(expression)

    words = derive(Reference(root), 0, ())
    return tuple(sorted(words, key=lambda word: (len(word), word))), truncated


def recognizes(grammar: dict[str, Expression], root: str, word: Word, max_repeat: int) -> bool:
    if root not in grammar:
        raise GrammarError(f"root {root!r} is not defined")
    memo: dict[tuple[Expression, int, tuple[str, ...]], frozenset[int]] = {}

    def match(expression: Expression, position: int, stack: tuple[str, ...]) -> frozenset[int]:
        key = (expression, position, stack)
        if key in memo:
            return memo[key]
        if isinstance(expression, Empty):
            result = frozenset({position})
        elif isinstance(expression, Literal):
            result = frozenset({position + 1}) if position < len(word) and word[position] == expression.value else frozenset()
        elif isinstance(expression, Reference):
            if expression.name not in grammar:
                result = frozenset({position + 1}) if position < len(word) and word[position] == expression.name else frozenset()
            elif expression.name in stack:
                result = frozenset()
            else:
                result = match(grammar[expression.name], position, stack + (expression.name,))
        elif isinstance(expression, Sequence):
            positions = {position}
            for item in expression.items:
                positions = {end for start in positions for end in match(item, start, stack)}
                if not positions:
                    break
            result = frozenset(positions)
        elif isinstance(expression, Choice):
            result = frozenset(end for item in expression.items for end in match(item, position, stack))
        elif isinstance(expression, Optional):
            result = frozenset({position} | set(match(expression.item, position, stack)))
        elif isinstance(expression, Repeat):
            positions = {position}
            for _ in range(max_repeat):
                next_positions = {
                    end for start in positions for end in match(expression.item, start, stack)
                    if end != start
                }
                combined = positions | next_positions
                if combined == positions:
                    break
                positions = combined
            result = frozenset(positions)
        else:
            raise TypeError(expression)
        memo[key] = result
        return result

    return len(word) in match(Reference(root), 0, ())


def mutate(words: tuple[Word, ...], max_cases: int) -> tuple[Word, ...]:
    candidates: set[Word] = set()
    for word in words:
        candidates.add(word + ("__INVALID__",))
        for index in range(len(word)):
            candidates.add(word[:index] + word[index + 1 :])
            candidates.add(word[:index] + (word[index], word[index]) + word[index + 1 :])
            candidates.add(word[:index] + ("__INVALID__",) + word[index + 1 :])
    return tuple(sorted(candidates, key=lambda value: (len(value), value))[:max_cases])


def write_corpus(path: Path, rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as output:
        for row in rows:
            output.write(json.dumps(row, sort_keys=True) + "\n")


def contains_reference(expression: Expression, names: set[str]) -> bool:
    if isinstance(expression, Reference):
        return expression.name in names
    if isinstance(expression, (Sequence, Choice)):
        return any(contains_reference(item, names) for item in expression.items)
    if isinstance(expression, (Optional, Repeat)):
        return contains_reference(expression.item, names)
    return False


def role_family_names(path: Path) -> set[str]:
    names: set[str] = set()
    for line in path.read_text(encoding="utf-8").splitlines():
        match = re.search(r"target-role-family[^\n]*source-roles=([^\s*)]+)", line)
        if match:
            names.update(name for name in match.group(1).split(",") if name)
    return names


def compare_root(
    baseline: dict[str, Expression],
    candidate: dict[str, Expression],
    root: str,
    args: argparse.Namespace,
) -> tuple[dict[str, object], list[dict[str, object]]]:
    baseline_words, baseline_truncated = bounded_words(
        baseline, root, args.max_depth, args.max_tokens, args.max_words, args.repeat_limit
    )
    candidate_words, candidate_truncated = bounded_words(
        candidate, root, args.max_depth, args.max_tokens, args.max_words, args.repeat_limit
    )
    positive_baseline = [
        word for word in baseline_words
        if recognizes(candidate, root, word, args.max_tokens + 1)
    ]
    positive_candidate = [
        word for word in candidate_words
        if recognizes(baseline, root, word, args.max_tokens + 1)
    ]
    baseline_positive_misses = [word for word in baseline_words if word not in positive_baseline]
    candidate_positive_misses = [word for word in candidate_words if word not in positive_candidate]

    negative_candidates = mutate(baseline_words, args.max_negative * 4)
    negative_rows: list[dict[str, object]] = []
    for word in negative_candidates:
        baseline_accepts = recognizes(baseline, root, word, args.max_tokens + 1)
        candidate_accepts = recognizes(candidate, root, word, args.max_tokens + 1)
        if not baseline_accepts:
            negative_rows.append({
                "root": root,
                "kind": "negative",
                "tokens": list(word),
                "baseline_accepts": baseline_accepts,
                "candidate_accepts": candidate_accepts,
            })
        if len(negative_rows) >= args.max_negative:
            break

    rows: list[dict[str, object]] = []
    rows.extend(
        {
            "root": root,
            "kind": "positive",
            "tokens": list(word),
            "baseline_accepts": True,
            "candidate_accepts": recognizes(candidate, root, word, args.max_tokens + 1),
        }
        for word in baseline_words
    )
    rows.extend(negative_rows)
    failures = [row for row in negative_rows if row["candidate_accepts"]]
    result = {
        "root": root,
        "baseline_generated_positive": len(baseline_words),
        "candidate_generated_positive": len(candidate_words),
        "baseline_generation_truncated": baseline_truncated,
        "candidate_generation_truncated": candidate_truncated,
        "baseline_positive_misses": len(baseline_positive_misses),
        "candidate_positive_misses": len(candidate_positive_misses),
        "negative_cases": len(negative_rows),
        "negative_candidate_acceptances": len(failures),
        "bounded_corpus_complete": not baseline_truncated and not candidate_truncated,
        "status": "PASS" if (
            not baseline_positive_misses
            and not candidate_positive_misses
            and not failures
            and not baseline_truncated
            and not candidate_truncated
        ) else "FAIL",
    }
    return result, rows


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("baseline", type=Path)
    parser.add_argument("candidate", type=Path)
    parser.add_argument("--root", action="append")
    parser.add_argument("--role-family-file", type=Path)
    parser.add_argument("--corpus", type=Path, required=True)
    parser.add_argument("--report", type=Path, required=True)
    parser.add_argument("--max-depth", type=int, default=8)
    parser.add_argument("--max-tokens", type=int, default=4)
    parser.add_argument("--max-words", type=int, default=512)
    parser.add_argument("--max-negative", type=int, default=64)
    parser.add_argument("--repeat-limit", type=int, default=1)
    args = parser.parse_args()

    baseline = load_grammar(args.baseline)
    candidate = load_grammar(args.candidate)
    roots = list(args.root or [])
    family_names = role_family_names(args.role_family_file) if args.role_family_file else set()
    if family_names:
        roots.extend(
            name for name, expression in baseline.items()
            if name in candidate and contains_reference(expression, family_names)
        )
    roots = list(dict.fromkeys(roots or ["program"]))
    per_root: list[dict[str, object]] = []
    rows: list[dict[str, object]] = []
    for root in roots:
        result, root_rows = compare_root(baseline, candidate, root, args)
        per_root.append(result)
        rows.extend(root_rows)
    write_corpus(args.corpus, rows)

    negative_failures = [row for row in rows if row["kind"] == "negative" and row["candidate_accepts"]]
    report = {
        "roots": roots,
        "baseline_productions": len(baseline),
        "candidate_productions": len(candidate),
        "baseline_lexical_terminals": sorted(find_undefined(baseline)),
        "candidate_lexical_terminals": sorted(find_undefined(candidate)),
        "role_family_names": sorted(family_names),
        "positive_cases": sum(int(item["baseline_generated_positive"]) for item in per_root),
        "negative_cases": sum(int(item["negative_cases"]) for item in per_root),
        "negative_candidate_acceptances": len(negative_failures),
        "per_root": per_root,
        "status": "PASS" if all(item["status"] == "PASS" for item in per_root) else "FAIL",
        "bounds": {
            "max_depth": args.max_depth,
            "max_tokens": args.max_tokens,
            "max_words": args.max_words,
            "max_negative": args.max_negative,
            "repeat_limit": args.repeat_limit,
        },
    }
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0 if report["status"] == "PASS" else 1


def find_undefined(grammar: dict[str, Expression]) -> set[str]:
    result: set[str] = set()

    def visit(expression: Expression) -> None:
        if isinstance(expression, Reference):
            if expression.name not in grammar:
                result.add(expression.name)
        elif isinstance(expression, (Sequence, Choice)):
            for item in expression.items:
                visit(item)
        elif isinstance(expression, (Optional, Repeat)):
            visit(expression.item)

    for expression in grammar.values():
        visit(expression)
    return result


if __name__ == "__main__":
    raise SystemExit(main())
