#!/usr/bin/env python3
"""Run the same bounded pointer protocol through one-shot Codex CLI calls."""

import argparse
import importlib.util
import json
import subprocess
import sys
import time
from pathlib import Path


HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
spec = importlib.util.spec_from_file_location("e0113_iterative", HERE / "run-iterative.py")
protocol = importlib.util.module_from_spec(spec)
spec.loader.exec_module(protocol)
runner = protocol.runner
validator = protocol.validator


def parser():
    root = HERE.parents[2]
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument("prompts")
    result.add_argument("--outdir", required=True)
    result.add_argument("--codex", default="codex")
    result.add_argument("--model", default="gpt-5.6-luna")
    result.add_argument("--candidate", default="gpt56-luna-codex-cli")
    result.add_argument("--max-attempts", type=int, default=3)
    result.add_argument("--timeout", type=float, default=300.0)
    result.add_argument("--residue", default=str(root / ".cache/runs/E0106/R000001/residue-classifications.tsv"))
    result.add_argument("--canonical", default=str(root / ".cache/runs/E0001/R000003/j3-24-007.canonical.txt"))
    result.add_argument("--pages", default=str(root / ".cache/runs/E0001/R000003/j3-24-007.pages.index"))
    result.add_argument("--e0110", required=True)
    result.add_argument("--source-sha256", default=validator.DEFAULT_SOURCE_SHA256)
    return result


def one_shot(args, prompt, output_path):
    command = [
        args.codex,
        "exec",
        "--model",
        args.model,
        "--ephemeral",
        "--sandbox",
        "read-only",
        "--skip-git-repo-check",
        "--ignore-user-config",
        "--ignore-rules",
        "--cd",
        "/tmp",
        "-o",
        str(output_path),
        "-",
    ]
    completed = subprocess.run(
        command,
        input=prompt,
        text=True,
        capture_output=True,
        timeout=args.timeout,
        check=False,
    )
    if completed.returncode != 0:
        raise runner.InputError(
            f"codex exec exited {completed.returncode}: {completed.stderr[-1000:]}"
        )
    content = output_path.read_text(encoding="utf-8") if output_path.exists() else completed.stdout
    return protocol.json_from_content(content)


def main():
    args = parser().parse_args()
    if args.max_attempts < 1:
        raise SystemExit("E0113 Codex: max-attempts is too small")
    started = time.monotonic()
    prompts = runner.load_prompts(args.prompts)
    raw = validator.load_canonical(args.canonical, args.source_sha256)
    ranges = validator.load_page_index(args.pages, len(raw))
    residue = validator.load_residue(args.residue)
    expected_names = {row["name"] for row in residue}
    prompt_windows = validator.read_prompt_windows(args.prompts)
    e0110 = validator.read_e0110(args.e0110, raw, ranges, args.source_sha256)
    expected_by_name = {row["name"]: row for row in e0110}
    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    attempts = []
    results = []
    accepted = []
    model_errors = []
    for item in prompts:
        current_prompt = item["prompt"]
        row_started = time.monotonic()
        terminal = None
        final = None
        for attempt in range(1, args.max_attempts + 1):
            call_started = time.monotonic()
            output_path = outdir / f"codex-{item['row']:03d}-attempt-{attempt}.txt"
            try:
                response = one_shot(args, current_prompt, output_path)
                final = response
                try:
                    proposal = validator.validate_pointer_response(
                        response,
                        expected_names,
                        prompt_windows,
                        raw,
                        ranges,
                        args.source_sha256,
                        pointer_only=True,
                    )
                except validator.InputError as exc:
                    status, error, proposal = "gate_rejection", str(exc), None
                else:
                    status, error = (
                        ("abstain", "")
                        if response.get("decision") == "abstain"
                        else ("accepted", "")
                    )
                    if proposal is not None:
                        accepted.append(proposal)
                attempts.append(
                    {
                        "name": item["name"],
                        "attempt": attempt,
                        "status": status,
                        "response": response,
                        "error": error,
                        "elapsed_s": time.monotonic() - call_started,
                    }
                )
                if status in {"accepted", "abstain"}:
                    terminal = status
                    break
                if attempt < args.max_attempts:
                    current_prompt = protocol.repair_prompt(
                        item["prompt"], item["name"], attempt + 1, args.max_attempts, error
                    )
            except (runner.InputError, json.JSONDecodeError, OSError, subprocess.TimeoutExpired) as exc:
                error = str(exc)
                model_errors.append({"name": item["name"], "attempt": attempt, "error": error})
                attempts.append(
                    {
                        "name": item["name"],
                        "attempt": attempt,
                        "status": "model_error",
                        "response": None,
                        "error": error,
                        "elapsed_s": time.monotonic() - call_started,
                    }
                )
                if attempt < args.max_attempts:
                    current_prompt = protocol.repair_prompt(
                        item["prompt"], item["name"], attempt + 1, args.max_attempts, error
                    )
        if terminal is None:
            terminal = "hard_failure"
        oracle = None
        if item["name"] in expected_by_name:
            oracle = {
                "expected_key": validator.key(expected_by_name[item["name"]]),
                "status": (
                    "exact"
                    if terminal == "accepted"
                    and validator.key(accepted[-1]) == validator.key(expected_by_name[item["name"]])
                    else "wrong-accepted"
                    if terminal == "accepted"
                    else terminal
                ),
            }
        results.append(
            {
                "name": item["name"],
                "status": terminal,
                "attempts": sum(row["name"] == item["name"] for row in attempts),
                "wall_s": time.monotonic() - row_started,
                "final_response": final,
                "oracle": oracle,
            }
        )
    oracle_results = [row for row in results if row["oracle"] is not None]
    oracle_exact = sum(row["oracle"]["status"] == "exact" for row in oracle_results)
    summary = {
        "candidate": args.candidate,
        "model": args.model,
        "residue_rows": len(residue),
        "accepted": sum(row["status"] == "accepted" for row in results),
        "abstentions": sum(row["status"] == "abstain" for row in results),
        "hard_failures": sum(row["status"] == "hard_failure" for row in results),
        "gate_green": sum(row["status"] in {"accepted", "abstain"} for row in results),
        "gate_rejections": sum(row["status"] == "gate_rejection" for row in attempts),
        "model_errors": len(model_errors),
        "total_model_calls": len(attempts),
        "repair_iterations": sum(max(0, row["attempts"] - 1) for row in results),
        "overlap_agreements": sum(
            item["name"] in expected_by_name and validator.key(item) == validator.key(expected_by_name[item["name"]])
            for item in accepted
        ),
        "overlap_disagreements": sum(
            item["name"] in expected_by_name and validator.key(item) != validator.key(expected_by_name[item["name"]])
            for item in accepted
        ),
        "novel_accepted": sum(item["name"] not in expected_by_name for item in accepted),
        "oracle_rows": len(oracle_results),
        "oracle_exact_matches": oracle_exact,
        "oracle_wrong_accepts": sum(row["oracle"]["status"] == "wrong-accepted" for row in oracle_results),
        "oracle_abstentions": sum(row["oracle"]["status"] == "abstain" for row in oracle_results),
        "oracle_hard_failures": sum(row["oracle"]["status"] == "hard_failure" for row in oracle_results),
        "oracle_translation_accuracy": oracle_exact / len(oracle_results) if oracle_results else 0.0,
        "setup_wall_s": 0.0,
        "inference_wall_s": time.monotonic() - started,
        "wall_s_total": time.monotonic() - started,
    }
    protocol.write_jsonl(outdir / "attempts.jsonl", attempts)
    protocol.write_jsonl(outdir / "gate-results.jsonl", results)
    protocol.write_jsonl(outdir / "accepted-proposals.jsonl", accepted)
    protocol.write_jsonl(outdir / "model-errors.jsonl", model_errors)
    (outdir / "summary.json").write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(summary, sort_keys=True))


if __name__ == "__main__":
    main()
