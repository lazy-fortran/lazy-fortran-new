#!/usr/bin/env python3
"""Run pointer-only proposals with a deterministic, bounded repair loop."""

import argparse
import importlib.util
import json
import sys
import time
from datetime import datetime, timezone
from pathlib import Path


HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))


def load_module(filename, name):
    spec = importlib.util.spec_from_file_location(name, HERE / filename)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


runner = load_module("run-local.py", "e0111_run_local")
validator = load_module("validate-responses.py", "e0111_validator")


def parser():
    root = HERE.parents[2]
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument("prompts")
    result.add_argument("--outdir", required=True)
    result.add_argument("--api-url", default="http://127.0.0.1:8080/v1/chat/completions")
    result.add_argument("--model", required=True)
    result.add_argument("--quantization", default="unspecified")
    result.add_argument("--candidate", required=True)
    result.add_argument("--thinking", choices=("off", "on"), default="off")
    result.add_argument("--seed", type=int, default=1101)
    result.add_argument("--temperature", type=float, default=0.0)
    result.add_argument("--top-p", type=float, default=1.0)
    result.add_argument("--max-tokens", type=int, default=256)
    result.add_argument("--timeout", type=float, default=180.0)
    result.add_argument("--max-attempts", type=int, default=3)
    result.add_argument("--source-repo", default="unspecified")
    result.add_argument("--source-file", default="unspecified")
    result.add_argument("--model-sha256", default="unspecified")
    result.add_argument("--api-key-env", default="")
    result.add_argument("--deepseek-cloud", action="store_true")
    result.add_argument(
        "--residue",
        default=str(root / ".cache/runs/E0106/R000001/residue-classifications.tsv"),
    )
    result.add_argument(
        "--canonical",
        default=str(root / ".cache/runs/E0001/R000003/j3-24-007.canonical.txt"),
    )
    result.add_argument(
        "--pages",
        default=str(root / ".cache/runs/E0001/R000003/j3-24-007.pages.index"),
    )
    result.add_argument("--e0110", required=True)
    result.add_argument("--source-sha256", default=validator.DEFAULT_SOURCE_SHA256)
    return result


def json_from_content(content):
    if not isinstance(content, str):
        raise runner.InputError("response content is not text")
    stripped = content.strip()
    if stripped.startswith("```") and stripped.endswith("```"):
        stripped = stripped.split("\n", 1)[1].rsplit("\n", 1)[0].strip()
    value = json.loads(stripped)
    if not isinstance(value, dict):
        raise runner.InputError("response is not a JSON object")
    return value


def response_from_api(args, item):
    payload = {
        "model": args.model,
        "messages": [{"role": "user", "content": item["prompt"]}],
        "temperature": args.temperature,
        "top_p": args.top_p,
        "seed": args.seed,
        "max_tokens": args.max_tokens,
        "stream": False,
        "response_format": runner.response_format(
            item["name"], True, len(item.get("windows", [])), True
        ),
    }
    runner.apply_reasoning_control(payload, args.thinking, args.deepseek_cloud)
    if args.deepseek_cloud:
        payload["response_format"] = {"type": "json_object"}
    result = runner.call_api(args.api_url, payload, args.timeout, args.api_key_env)
    choices = result.get("choices") if isinstance(result, dict) else None
    if not isinstance(choices, list) or len(choices) != 1:
        raise runner.InputError("API response does not contain one choice")
    message = choices[0].get("message") if isinstance(choices[0], dict) else None
    content = message.get("content") if isinstance(message, dict) else None
    return json_from_content(content)


def repair_prompt(original, name, attempt, max_attempts, error):
    return (
        original
        + "\n\nDETERMINISTIC GATE FEEDBACK\n"
        + f"The previous response for {name} was rejected: {error}\n"
        + f"This is repair attempt {attempt} of {max_attempts}.\n"
        + "Return exactly one pointer-only JSON object. Correct the window or "
        + "relation, or return the exact abstention object. Never emit target, "
        + "citation text, or explanation."
    )


def write_jsonl(path, rows):
    with path.open("w", encoding="utf-8", newline="\n") as stream:
        for row in rows:
            stream.write(json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n")


def main():
    args = parser().parse_args()
    total_started = time.monotonic()
    if args.max_attempts < 1 or args.max_tokens < 1:
        raise SystemExit("E0113 iterative runner: max-attempts/max-tokens is too small")
    if not 0.0 <= args.temperature <= 2.0 or not 0.0 < args.top_p <= 1.0:
        raise SystemExit("E0113 iterative runner: invalid temperature or top-p")
    try:
        prompts = runner.load_prompts(args.prompts)
        progress_path = Path(args.outdir) / "progress.json"
        started_at = datetime.now(timezone.utc).isoformat()
        runner.write_progress(
            progress_path,
            total=len(prompts),
            completed=0,
            started_monotonic=total_started,
            started_at=started_at,
        )
        raw = validator.load_canonical(args.canonical, args.source_sha256)
        ranges = validator.load_page_index(args.pages, len(raw))
        residue = validator.load_residue(args.residue)
        expected_names = {row["name"] for row in residue}
        prompt_windows = validator.read_prompt_windows(args.prompts)
        if set(prompt_windows) != expected_names:
            raise runner.InputError("prompt names differ from residue denominator")
        e0110 = validator.read_e0110(args.e0110, raw, ranges, args.source_sha256)
        inference_started = time.monotonic()
        attempts = []
        results = []
        accepted = []
        model_errors = []
        for item in prompts:
            row_started = time.monotonic()
            current_prompt = item["prompt"]
            terminal = None
            final_response = None
            for attempt in range(1, args.max_attempts + 1):
                request_item = dict(item, prompt=current_prompt)
                call_started = time.monotonic()
                try:
                    response = response_from_api(args, request_item)
                    final_response = response
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
                        status = "gate_rejection"
                        error = str(exc)
                        proposal = None
                    else:
                        if response.get("decision") == "abstain":
                            status = "abstain"
                            error = ""
                        else:
                            status = "accepted"
                            error = ""
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
                        final_response = response
                        break
                    if attempt < args.max_attempts:
                        current_prompt = repair_prompt(
                            item["prompt"], item["name"], attempt + 1, args.max_attempts, error
                        )
                except (runner.InputError, json.JSONDecodeError, TypeError, OSError) as exc:
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
                        current_prompt = repair_prompt(
                            item["prompt"], item["name"], attempt + 1, args.max_attempts, error
                        )
            if terminal is None:
                terminal = "hard_failure"
            oracle = None
            expected = next((row for row in e0110 if row["name"] == item["name"]), None)
            if expected is not None:
                oracle = {
                    "expected_key": validator.key(expected),
                    "status": (
                        "exact"
                        if terminal == "accepted"
                        and validator.key(accepted[-1]) == validator.key(expected)
                        and accepted[-1]["name"] == item["name"]
                        else "wrong-accepted"
                        if terminal == "accepted"
                        else terminal
                    ),
                }
            results.append(
                {
                    "name": item["name"],
                    "status": terminal,
                    "attempts": sum(1 for row in attempts if row["name"] == item["name"]),
                    "wall_s": time.monotonic() - row_started,
                    "final_response": final_response,
                    "oracle": oracle,
                }
            )
            runner.write_progress(
                progress_path,
                total=len(prompts),
                completed=len(results),
                started_monotonic=total_started,
                started_at=started_at,
                current=(
                    prompts[len(results)]["name"] if len(results) < len(prompts) else None
                ),
                model_errors=len(model_errors),
            )
        inference_wall = time.monotonic() - inference_started
        expected_by_name = {item["name"]: item for item in e0110}
        overlap_agreements = sum(
            item["name"] in expected_by_name and validator.key(item) == validator.key(expected_by_name[item["name"]])
            for item in accepted
        )
        overlap_disagreements = sum(
            item["name"] in expected_by_name and validator.key(item) != validator.key(expected_by_name[item["name"]])
            for item in accepted
        )
        oracle_rows = [row for row in results if row["oracle"] is not None]
        oracle_counts = {
            status: sum(row["oracle"]["status"] == status for row in oracle_rows)
            for status in ("exact", "wrong-accepted", "abstain", "hard_failure")
        }
        novel_accepted = sum(item["name"] not in expected_by_name for item in accepted)
        outdir = Path(args.outdir)
        outdir.mkdir(parents=True, exist_ok=True)
        write_jsonl(outdir / "attempts.jsonl", attempts)
        write_jsonl(outdir / "gate-results.jsonl", results)
        write_jsonl(outdir / "accepted-proposals.jsonl", accepted)
        write_jsonl(outdir / "model-errors.jsonl", model_errors)
        write_jsonl(
            outdir / "responses.jsonl",
            [
                result["final_response"]
                if result["final_response"] is not None
                else {"name": result["name"], "decision": "hard_failure"}
                for result in results
            ],
        )
        counts = {status: sum(row["status"] == status for row in results) for status in ("accepted", "abstain", "hard_failure")}
        gate_rejections = sum(row["status"] == "gate_rejection" for row in attempts)
        total_calls = len(attempts)
        repair_iterations = sum(max(0, row["attempts"] - 1) for row in results)
        summary = {
            "candidate": args.candidate,
            "model": args.model,
            "quantization": args.quantization,
            "thinking": args.thinking,
            "residue_rows": len(residue),
            "accepted": counts["accepted"],
            "abstentions": counts["abstain"],
            "hard_failures": counts["hard_failure"],
            "gate_green": counts["accepted"] + counts["abstain"],
            "gate_rejections": gate_rejections,
            "model_errors": len(model_errors),
            "total_model_calls": total_calls,
            "repair_iterations": repair_iterations,
            "max_attempts": args.max_attempts,
            "overlap_agreements": overlap_agreements,
            "overlap_disagreements": overlap_disagreements,
            "novel_accepted": novel_accepted,
            "oracle_rows": len(oracle_rows),
            "oracle_exact_matches": oracle_counts["exact"],
            "oracle_wrong_accepts": oracle_counts["wrong-accepted"],
            "oracle_abstentions": oracle_counts["abstain"],
            "oracle_hard_failures": oracle_counts["hard_failure"],
            "oracle_translation_accuracy": (
                oracle_counts["exact"] / len(oracle_rows) if oracle_rows else 0.0
            ),
            "inference_wall_s": inference_wall,
            "setup_wall_s": inference_started - total_started,
            "wall_s_total": time.monotonic() - total_started,
            "wall_s": time.monotonic() - total_started,
        }
        (outdir / "summary.json").write_text(
            json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8"
        )
        with (outdir / "summary.tsv").open("w", encoding="utf-8", newline="") as stream:
            stream.write("metric\tvalue\n")
            for key, value in summary.items():
                stream.write(f"{key}\t{value}\n")
        (outdir / "run-config.json").write_text(
            json.dumps(vars(args), indent=2, sort_keys=True) + "\n", encoding="utf-8"
        )
        runner.write_progress(
            progress_path,
            total=len(prompts),
            completed=len(results),
            started_monotonic=total_started,
            started_at=started_at,
            model_errors=len(model_errors),
            status="completed",
        )
        print(json.dumps(summary, sort_keys=True))
    except (runner.InputError, validator.InputError, OSError, ValueError) as exc:
        raise SystemExit(f"E0113 iterative runner: {exc}") from exc


if __name__ == "__main__":
    main()
