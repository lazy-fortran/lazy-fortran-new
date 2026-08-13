#!/usr/bin/env python3
"""Run bounded visual translation against the E0110 source oracle."""

import argparse
import base64
import csv
import importlib.util
import json
import re
import time
from pathlib import Path


HERE = Path(__file__).resolve().parent
E0111 = (HERE.parent / "E0111-can-qwen3-5-2b-propose-source-cited-loca").resolve()
import sys
sys.path.insert(0, str(E0111))
spec = importlib.util.spec_from_file_location("e0111_run_local", E0111 / "run-local.py")
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)


def compact(value):
    return " ".join(str(value).split())


def oracle_rows(path, canonical):
    raw = Path(canonical).read_bytes()
    result = {}
    with Path(path).open(encoding="utf-8", newline="") as stream:
        for row in csv.DictReader(stream, delimiter="\t"):
            if row.get("classification") != "strict-definition":
                continue
            text = raw[int(row["byte_start"]) : int(row["byte_start"]) + int(row["byte_length"])].decode("utf-8")
            marker = re.search(
                rf"\b{re.escape(row['normalized'])}\s+{re.escape(row['form']) if row['form'] != 'is-one-of' else r'is\s+one\s+of'}\b",
                text,
                re.IGNORECASE,
            )
            if marker is None:
                raise SystemExit(f"E0114: cannot derive oracle target for {row['name']}")
            result[row["name"]] = {
                "relation": row["form"],
                "target": compact(text[marker.end() :]),
                "page": int(row["page"]),
            }
    if len(result) != 6:
        raise SystemExit(f"E0114: expected six oracle rows, got {len(result)}")
    return result


def schema(name):
    return {
        "type": "json_schema",
        "json_schema": {
            "name": "e0114_visual_translation",
            "strict": True,
            "schema": {
                "type": "object",
                "additionalProperties": False,
                "properties": {
                    "name": {"type": "string", "enum": [name]},
                    "decision": {"type": "string", "enum": ["proposal", "abstain"]},
                    "relation": {"type": "string"},
                    "target": {"type": "string", "maxLength": 512},
                },
                "required": ["name", "decision"],
            },
        },
    }


def call(args, task, prompt):
    data = base64.b64encode(Path(task["image"]).read_bytes()).decode("ascii")
    payload = {
        "model": args.model,
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": prompt},
                    {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{data}"}},
                ],
            }
        ],
        "temperature": 0.0,
        "top_p": 1.0,
        "seed": 1114,
        "max_tokens": 256,
        "stream": False,
        "response_format": schema(task["name"]),
    }
    result = runner.call_api(args.api_url, payload, args.timeout, "")
    choices = result.get("choices") if isinstance(result, dict) else None
    if not isinstance(choices, list) or len(choices) != 1:
        raise runner.InputError("visual API response lacks one choice")
    content = choices[0].get("message", {}).get("content")
    response = json.loads(content)
    if not isinstance(response, dict):
        raise runner.InputError("visual response is not an object")
    return response


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("tasks")
    parser.add_argument("--e0110", required=True)
    parser.add_argument("--canonical", required=True)
    parser.add_argument("--outdir", required=True)
    parser.add_argument("--api-url", default="http://127.0.0.1:8080/v1/chat/completions")
    parser.add_argument("--model", required=True)
    parser.add_argument("--candidate", required=True)
    parser.add_argument("--max-attempts", type=int, default=3)
    parser.add_argument("--timeout", type=float, default=240.0)
    args = parser.parse_args()
    if args.max_attempts < 1:
        raise SystemExit("E0114: max-attempts is too small")
    tasks = [json.loads(line) for line in Path(args.tasks).read_text(encoding="utf-8").splitlines()]
    oracle = oracle_rows(args.e0110, args.canonical)
    started = time.monotonic()
    attempts = []
    results = []
    for task in tasks:
        prompt = (
            f"Inspect only the attached rendered PDF page. Candidate name: {task['name']}. "
            "Locate the candidate's normative definition on the page and translate "
            "it into the JSON object below. Do not use OCR text supplied elsewhere, "
            "outside knowledge, or any other page. Return abstain if unreadable. "
            f"Return exactly one object with name {task['name']}, decision proposal or "
            "abstain, and for proposal the relation and target text."
        )
        terminal = None
        final = None
        row_started = time.monotonic()
        for attempt in range(1, args.max_attempts + 1):
            call_started = time.monotonic()
            try:
                response = call(args, task, prompt)
                final = response
                expected = oracle[task["name"]]
                if response.get("name") != task["name"]:
                    status = "gate_rejection"
                    error = "name does not match the task"
                elif response.get("decision") == "abstain":
                    status = "abstain"
                    error = ""
                elif response.get("decision") != "proposal":
                    status = "gate_rejection"
                    error = "invalid decision"
                elif response.get("relation") != expected["relation"]:
                    status = "gate_rejection"
                    error = "relation does not match the frozen oracle"
                elif compact(response.get("target", "")) != expected["target"]:
                    status = "gate_rejection"
                    error = "target does not match the frozen oracle"
                else:
                    status = "accepted"
                    error = ""
                attempts.append(
                    {
                        "name": task["name"],
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
                    prompt += "\nThe deterministic gate rejected the previous object. Correct it or abstain; do not explain."
            except (runner.InputError, json.JSONDecodeError, TypeError, OSError) as exc:
                error = str(exc)
                attempts.append(
                    {
                        "name": task["name"],
                        "attempt": attempt,
                        "status": "model_error",
                        "response": None,
                        "error": error,
                        "elapsed_s": time.monotonic() - call_started,
                    }
                )
                if attempt < args.max_attempts:
                    prompt += "\nThe previous response was unusable. Return only the required JSON object or abstain."
        if terminal is None:
            terminal = "hard_failure"
        results.append(
            {
                "name": task["name"],
                "status": terminal,
                "attempts": sum(row["name"] == task["name"] for row in attempts),
                "wall_s": time.monotonic() - row_started,
                "final_response": final,
            }
        )
    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    for filename, rows in (("attempts.jsonl", attempts), ("results.jsonl", results)):
        with (outdir / filename).open("w", encoding="utf-8", newline="\n") as stream:
            for row in rows:
                stream.write(json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n")
    exact = sum(row["status"] == "accepted" for row in results)
    normalized = 0
    relation_matches = 0
    for row in results:
        response = row.get("final_response") or {}
        expected = oracle[row["name"]]
        if response.get("relation") == expected["relation"]:
            relation_matches += 1
        if compact(response.get("target", "")).casefold() == expected["target"].casefold():
            normalized += 1
    abstentions = sum(row["status"] == "abstain" for row in results)
    errors = sum(row["status"] == "model_error" for row in attempts)
    summary = {
        "candidate": args.candidate,
        "model": args.model,
        "oracle_rows": len(results),
        "exact_target_matches": exact,
        "normalized_target_matches": normalized,
        "relation_matches": relation_matches,
        "abstentions": abstentions,
        "hard_failures": sum(row["status"] == "hard_failure" for row in results),
        "model_errors": errors,
        "total_model_calls": len(attempts),
        "repair_iterations": sum(max(0, row["attempts"] - 1) for row in results),
        "inference_wall_s": time.monotonic() - started,
        "wall_s_total": time.monotonic() - started,
    }
    (outdir / "summary.json").write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(summary, sort_keys=True))


if __name__ == "__main__":
    main()
