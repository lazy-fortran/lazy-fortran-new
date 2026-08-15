#!/usr/bin/env python3
"""Build a reproducible structural inventory of Bison conflicts."""

from __future__ import annotations

import argparse
import hashlib
import re
import subprocess
from pathlib import Path


EXPECTED_LFORTRAN_SHA256 = (
    "112ef0ce5078ccec630a893bc51b92232348c37742b1451c833928a422907936"
)


def run(command: list[str], *, cwd: Path | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(command, cwd=cwd, text=True, capture_output=True, check=False)


def write(path: Path, text: str) -> None:
    path.write_text(text, encoding="utf-8")


def conflict_counts(text: str) -> tuple[int, int]:
    shift = reduce = 0
    for match in re.finditer(
        r"^State (\d+) conflicts:((?: \d+ (?:shift/reduce|reduce/reduce),?)+)$",
        text,
        re.MULTILINE,
    ):
        for count, kind in re.findall(r"(\d+) (shift/reduce|reduce/reduce)", match.group(2)):
            if kind == "shift/reduce":
                shift += int(count)
            else:
                reduce += int(count)
    return shift, reduce


def parse_state_blocks(text: str) -> list[dict[str, object]]:
    summaries = {
        int(state): (int(sr), int(rr))
        for state, rest in re.findall(
            r"^State (\d+) conflicts:((?: \d+ (?:shift/reduce|reduce/reduce),?)+)$",
            text,
            re.MULTILINE,
        )
        for sr, rr in [(
            sum(int(count) for count in re.findall(r"(\d+) shift/reduce", rest)),
            sum(int(count) for count in re.findall(r"(\d+) reduce/reduce", rest)),
        )]
    }
    starts = list(re.finditer(r"^State (\d+)\n", text, re.MULTILINE))
    rows: list[dict[str, object]] = []
    for index, match in enumerate(starts):
        end = starts[index + 1].start() if index + 1 < len(starts) else len(text)
        block = text[match.end():end]
        counts = summaries.get(int(match.group(1)))
        if counts is None:
            continue
        sr, rr = counts
        symbols = sorted(
            set(re.findall(r"\b(?:r|h_r|standardir_start)_[A-Za-z0-9_x]+|\bstandardir_start\b", block))
        )
        nullable = block.count("ε •")
        rows.append({
            "state": int(match.group(1)),
            "shift_reduce": sr,
            "reduce_reduce": rr,
            "symbols": symbols,
            "nullable": nullable,
        })
    return rows


def category(row: dict[str, object]) -> str:
    symbols = row["symbols"]
    assert isinstance(symbols, list)
    joined = " ".join(symbols)
    state = int(row["state"])
    if state == 0 and ("standardir_start" in symbols or "$accept" in joined):
        return "broad-start-entry"
    if any(token in joined for token in ("r_expr", "_x2D_expr", "r_level_x2D_", "r_primary")):
        return "expression-or-precedence"
    if any(token in joined for token in ("r_name", "_x2D_name", "r_data_x2D_ref", "r_designator", "r_variable")):
        return "role-or-name-family"
    if any(token in joined for token in ("r_letter", "r_digit", "literal_x2D_constant", "r_sign", "r_char_x2D")):
        return "lexical-or-literal"
    if any(token in joined for token in ("_x2D_list", "h_r_")) and int(row["nullable"]) > 0:
        return "nullable-or-list-boundary"
    return "other-grammar-structure"


def inventory(path: Path, profile: str) -> tuple[list[dict[str, object]], tuple[int, int]]:
    rows = parse_state_blocks(path.read_text(encoding="utf-8", errors="replace"))
    for row in rows:
        row["profile"] = profile
        row["category"] = category(row)
    return rows, conflict_counts(path.read_text(encoding="utf-8", errors="replace"))


def run_bison(source: Path, output_dir: Path, name: str) -> tuple[Path, str]:
    report = output_dir / f"{name}.output"
    generated = output_dir / f"{name}.c"
    result = run([
        "bison", "--warnings=all,counterexamples",
        "--report=state,solved,counterexamples",
        f"--report-file={report}", "-o", generated, source,
    ])
    write(output_dir / f"{name}.stderr", result.stderr)
    write(output_dir / f"{name}.stdout", result.stdout)
    if result.returncode != 0 or not report.is_file():
        raise SystemExit(f"bison failed for {name}: {result.stderr}")
    return report, result.stderr


def expected_policy(source: Path) -> tuple[int, int]:
    text = source.read_text(encoding="utf-8")
    match_sr = re.search(r"^%expect\s+(\d+)", text, re.MULTILINE)
    match_rr = re.search(r"^%expect-rr\s+(\d+)", text, re.MULTILINE)
    if match_sr is None or match_rr is None:
        raise SystemExit("LFortran conflict policy declarations are missing")
    return int(match_sr.group(1)), int(match_rr.group(1))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--generated-grammar", type=Path, required=True)
    parser.add_argument("--all-root-report", type=Path, required=True)
    parser.add_argument("--lfortran-parser", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    source = args.generated_grammar.resolve()
    all_report = args.all_root_report.resolve()
    lfortran = args.lfortran_parser.resolve()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)

    if not source.is_file():
        raise SystemExit(f"missing generated Bison grammar: {source}")
    if not all_report.is_file():
        raise SystemExit(f"missing retained all-root Bison report: {all_report}")
    if not lfortran.is_file():
        raise SystemExit(f"missing pinned LFortran grammar: {lfortran}")
    lfortran_hash = hashlib.sha256(lfortran.read_bytes()).hexdigest()
    if lfortran_hash != EXPECTED_LFORTRAN_SHA256:
        raise SystemExit(f"LFortran hash mismatch: {lfortran_hash}")
    write(output / "lfortran-parser.yy.sha256", f"{lfortran_hash}  {lfortran}\n")

    selected_text = source.read_text(encoding="utf-8")
    if not any(
        "target=selected-root root=program" in line
        for line in selected_text.splitlines()[:4]
    ):
        raise SystemExit(
            "--generated-grammar must be the producer-emitted selected program "
            "profile; the analyzer will not rewrite %start"
        )
    selected_report, _ = run_bison(source, output, "standardir-program")
    lfortran_report, _ = run_bison(lfortran, output, "lfortran")
    profiles = [
        ("all-roots", all_report),
        ("selected-program", selected_report),
        ("lfortran", lfortran_report),
    ]

    all_rows: list[dict[str, object]] = []
    profile_totals: dict[str, tuple[int, int]] = {}
    for profile, report in profiles:
        rows, totals = inventory(report, profile)
        all_rows.extend(rows)
        profile_totals[profile] = totals
        observed = (
            sum(int(row["shift_reduce"]) for row in rows),
            sum(int(row["reduce_reduce"]) for row in rows),
        )
        if observed != totals:
            raise SystemExit(f"state/header total mismatch for {profile}: {observed} != {totals}")

    expected = expected_policy(lfortran)
    if profile_totals["lfortran"] != expected:
        raise SystemExit(
            f"LFortran policy mismatch: observed {profile_totals['lfortran']} != declared {expected}"
        )

    with (output / "conflict-states.tsv").open("w", encoding="utf-8") as handle:
        handle.write("profile\tstate\tshift_reduce\treduce_reduce\tcategory\tnullable_items\tevidence_symbols\n")
        for row in all_rows:
            handle.write("\t".join([
                str(row["profile"]), str(row["state"]), str(row["shift_reduce"]),
                str(row["reduce_reduce"]), str(row["category"]), str(row["nullable"]),
                ",".join(row["symbols"]),
            ]) + "\n")

    with (output / "summary.tsv").open("w", encoding="utf-8") as handle:
        handle.write("profile\tcategory\tconflict_states\tshift_reduce\treduce_reduce\n")
        for profile, _ in profiles:
            rows = [row for row in all_rows if row["profile"] == profile]
            by_category: dict[str, list[dict[str, object]]] = {}
            for row in rows:
                by_category.setdefault(str(row["category"]), []).append(row)
            for name, group in sorted(by_category.items()):
                handle.write("\t".join([
                    profile, name, str(len(group)),
                    str(sum(int(row["shift_reduce"]) for row in group)),
                    str(sum(int(row["reduce_reduce"]) for row in group)),
                ]) + "\n")

    with (output / "policy.tsv").open("w", encoding="utf-8") as handle:
        handle.write("profile\tdeclared_shift_reduce\tdeclared_reduce_reduce\tobserved_shift_reduce\tobserved_reduce_reduce\tstatus\n")
        handle.write("lfortran\t%d\t%d\t%d\t%d\tPASS\n" % (*expected, *profile_totals["lfortran"]))
        for profile in ("all-roots", "selected-program"):
            observed = profile_totals[profile]
            handle.write("%s\t-\t-\t%d\t%d\tINVENTORY_ONLY\n" % (profile, *observed))

    all_total = profile_totals["all-roots"]
    selected_total = profile_totals["selected-program"]
    write(output / "summary.json", "{\n" +
          f'  "all_roots": {{"shift_reduce": {all_total[0]}, "reduce_reduce": {all_total[1]}}},\n' +
          f'  "selected_program": {{"shift_reduce": {selected_total[0]}, "reduce_reduce": {selected_total[1]}}},\n' +
          f'  "lfortran_declared": {{"shift_reduce": {expected[0]}, "reduce_reduce": {expected[1]}}},\n' +
          f'  "lfortran_observed": {{"shift_reduce": {profile_totals["lfortran"][0]}, "reduce_reduce": {profile_totals["lfortran"][1]}}},\n' +
          '  "status": "PASS",\n'
          '  "resolution": "INVENTORY_ONLY"\n}\n')
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
