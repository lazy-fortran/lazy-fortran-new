#!/usr/bin/env python3
"""Run E0115's bounded native-tool protocol against local llama.cpp only."""

import argparse
import csv
import hashlib
import importlib.util
import json
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
spec = importlib.util.spec_from_file_location("e0115_harness", HERE / "e0115_harness.py")
harness = importlib.util.module_from_spec(spec)
spec.loader.exec_module(harness)


def parser():
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument("--outdir", required=True)
    result.add_argument("--model", required=True)
    result.add_argument("--candidate", default="local")
    result.add_argument("--api-url", default="http://127.0.0.1:8080/v1/chat/completions")
    result.add_argument("--thinking", choices=("off", "on"), default="off")
    result.add_argument("--seed", type=int, default=1101)
    result.add_argument("--temperature", type=float, default=0.0)
    result.add_argument("--top-p", type=float, default=1.0)
    result.add_argument("--max-tokens", type=int, default=512)
    result.add_argument("--timeout", type=float, default=180.0)
    result.add_argument("--max-turns", type=int, default=12)
    result.add_argument("--limit", type=int, default=0)
    result.add_argument("--only-name", default="")
    result.add_argument("--quantization", default="unspecified")
    result.add_argument("--model-file", default="unspecified")
    result.add_argument("--model-sha256", default="unspecified")
    result.add_argument(
        "--residue",
        default=str(ROOT / ".cache/runs/E0106/R000001/residue-classifications.tsv"),
    )
    result.add_argument(
        "--canonical",
        default=str(ROOT / ".cache/runs/E0001/R000003/j3-24-007.canonical.txt"),
    )
    result.add_argument(
        "--pages",
        default=str(ROOT / ".cache/runs/E0001/R000003/j3-24-007.pages.index"),
    )
    result.add_argument(
        "--e0110",
        default=str(ROOT / ".cache/runs/E0110/R000001/classifications.tsv"),
    )
    result.add_argument("--source-sha256", default=harness.common.DEFAULT_SOURCE_SHA256)
    return result


def write_jsonl(path, rows):
    with Path(path).open("w", encoding="utf-8", newline="\n") as stream:
        for row in rows:
            stream.write(json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n")


def load_residue(path):
    with Path(path).open(encoding="utf-8", newline="") as stream:
        return harness.common.load_residue(path)


def local_url(url):
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme != "http" or parsed.hostname not in {"127.0.0.1", "localhost", "::1"}:
        raise SystemExit("E0115 runner: --api-url must point to a local HTTP server")


def call_model(url, payload, timeout):
    request = urllib.request.Request(
        url,
        data=json.dumps(payload, ensure_ascii=False).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            data = json.loads(response.read().decode("utf-8"))
    except (OSError, urllib.error.URLError, json.JSONDecodeError) as exc:
        raise RuntimeError(str(exc)) from exc
    choices = data.get("choices") if isinstance(data, dict) else None
    if not isinstance(choices, list) or len(choices) != 1:
        raise RuntimeError("local server response does not contain exactly one choice")
    message = choices[0].get("message") if isinstance(choices[0], dict) else None
    if not isinstance(message, dict):
        raise RuntimeError("local server response has no message")
    return message, data


def system_prompt(name, rule_hints):
    indexed = (
        "The deterministic source index found these possible numbered rule IDs: "
        + ", ".join(rule_hints)
        + ". Read them before broad searching; the index supplies locations, not a decision."
        if rule_hints
        else "The deterministic source index found no numbered rule ID; use the search tools."
    )
    return (
        "You are a source-evidence assistant. Work only through the four "
        "declared tools. Find a normative source-backed definition or relation "
        f"for candidate `{name}`. Search and read evidence before submitting. "
        f"{harness.candidate_guidance(name)} Prefer a direct production or "
        "prose definition when one exists. The standard's assumed rules are "
        "valid source evidence; do not invent a target from them. "
        f"{indexed} "
        "The gate checks the evidence relation mechanically: the submission "
        "must describe the source text you actually read, not a guessed target. "
        "If the evidence is insufficient or ambiguous, call submit_pointer "
        "with decision abstain. Otherwise call submit_pointer with decision "
        "accept, the candidate name, a relation category, and evidence IDs. "
        "Never write a target, citation, source quotation, or explanation in "
        "the submission; the deterministic gate derives those from evidence."
    )


def user_prompt(name):
    return (
        f"Resolve exactly this residue candidate: {name}. Use the evidence tools "
        "and then submit one pointer or an explicit abstention."
    )


def tool_spec():
    return json.loads((HERE / "tool-schema.json").read_text(encoding="utf-8"))["tools"]


def tool_event(episode, tool_call):
    function = tool_call.get("function") if isinstance(tool_call, dict) else None
    if not isinstance(function, dict):
        raise RuntimeError("tool call has no function object")
    name = function.get("name")
    arguments = function.get("arguments", "{}")
    if not isinstance(name, str) or not isinstance(arguments, str):
        raise RuntimeError("malformed tool call")
    try:
        arguments = json.loads(arguments)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"tool arguments are not JSON: {exc}") from exc
    if not isinstance(arguments, dict):
        raise RuntimeError("tool arguments are not an object")
    try:
        result = episode.call(name, arguments)
    except (harness.ToolError, harness.common.InputError) as exc:
        result = {"status": "error", "code": "tool_rejected", "message": str(exc)}
    return name, arguments, result


def run_row(args, raw, ranges, residue, e0110, name, tools, trajectory_stream=None):
    episode = harness.Episode(raw, ranges, residue, e0110, name)
    messages = [
        {"role": "system", "content": system_prompt(name, episode.rule_hints())},
        {"role": "user", "content": user_prompt(name)},
    ]
    events = []
    def emit(event):
        if trajectory_stream is None:
            events.append(event)
        else:
            trajectory_stream.write(json.dumps({"name": name, **event}, ensure_ascii=False, sort_keys=True) + "\n")
            trajectory_stream.flush()

    model_errors = []
    gate_rejections = 0
    started = time.monotonic()
    for turn in range(1, args.max_turns + 1):
        payload = {
            "model": args.model,
            "messages": messages,
            "tools": tools,
            "tool_choice": "auto",
            "parallel_tool_calls": False,
            "temperature": args.temperature,
            "top_p": args.top_p,
            "seed": args.seed,
            "max_tokens": args.max_tokens,
            "stream": False,
        }
        call_started = time.monotonic()
        try:
            message, raw_response = call_model(args.api_url, payload, args.timeout)
        except RuntimeError as exc:
            model_errors.append({"turn": turn, "error": str(exc)})
            emit({"turn": turn, "kind": "model_error", "error": str(exc)})
            return {
                "name": name,
                "status": "hard_failure",
                "turns": turn,
                "wall_s": time.monotonic() - started,
                "evidence_calls": episode.evidence_calls,
                "submissions": episode.submissions,
                "source_bytes": episode.source_bytes,
                "gate_rejections": gate_rejections,
                "model_errors": model_errors,
                "oracle": "hard_failure" if e0110.get(name) is not None else None,
                "events": events,
            }
        emit(
            {
                "turn": turn,
                "kind": "model",
                "elapsed_s": time.monotonic() - call_started,
                "message": message,
                "usage": raw_response.get("usage"),
            }
        )
        calls = message.get("tool_calls", [])
        if not isinstance(calls, list) or len(calls) != 1:
            error = "model did not emit exactly one native tool call"
            model_errors.append({"turn": turn, "error": error})
            emit({"turn": turn, "kind": "model_error", "error": error})
            return {
                "name": name,
                "status": "hard_failure",
                "turns": turn,
                "wall_s": time.monotonic() - started,
                "evidence_calls": episode.evidence_calls,
                "submissions": episode.submissions,
                "source_bytes": episode.source_bytes,
                "gate_rejections": gate_rejections,
                "model_errors": model_errors,
                "oracle": "hard_failure" if e0110.get(name) is not None else None,
                "events": events,
            }
        call = calls[0]
        try:
            tool_name, arguments, result = tool_event(episode, call)
        except RuntimeError as exc:
            model_errors.append({"turn": turn, "error": str(exc)})
            emit({"turn": turn, "kind": "model_error", "error": str(exc)})
            return {
                "name": name,
                "status": "hard_failure",
                "turns": turn,
                "wall_s": time.monotonic() - started,
                "evidence_calls": episode.evidence_calls,
                "submissions": episode.submissions,
                "source_bytes": episode.source_bytes,
                "gate_rejections": gate_rejections,
                "model_errors": model_errors,
                "oracle": "hard_failure" if e0110.get(name) is not None else None,
                "events": events,
            }
        emit({"turn": turn, "kind": "tool", "tool": tool_name, "arguments": arguments, "result": result})
        messages.append(message)
        messages.append(
            {
                "role": "tool",
                "tool_call_id": call.get("id", f"call-{turn}"),
                "name": tool_name,
                "content": json.dumps(result, ensure_ascii=False, sort_keys=True),
            }
        )
        if result.get("status") == "accepted":
            status = "accepted"
        elif result.get("status") == "abstained":
            status = "abstained_after_budget"
        elif result.get("status") == "rejected":
            gate_rejections += 1
            continue
        elif result.get("status") == "error":
            continue
        else:
            continue
        expected = e0110.get(name)
        exact = bool(expected and episode.accepted and episode.accepted["byte_start"] == expected["byte_start"])
        oracle = None
        if expected is not None:
            oracle = "exact" if exact else "wrong-accepted" if status == "accepted" else status
        return {
            "name": name,
            "status": status,
            "turns": turn,
            "wall_s": time.monotonic() - started,
            "evidence_calls": episode.evidence_calls,
            "submissions": episode.submissions,
            "source_bytes": episode.source_bytes,
            "gate_rejections": gate_rejections,
            "model_errors": model_errors,
            "accepted": episode.accepted,
            "oracle": oracle,
            "events": events,
        }
    expected = e0110.get(name)
    return {
        "name": name,
        "status": "hard_failure",
        "turns": args.max_turns,
        "wall_s": time.monotonic() - started,
        "evidence_calls": episode.evidence_calls,
        "submissions": episode.submissions,
        "source_bytes": episode.source_bytes,
        "gate_rejections": gate_rejections,
        "model_errors": model_errors,
        "oracle": "hard_failure" if expected is not None else None,
        "events": events,
    }


def main():
    args = parser().parse_args()
    local_url(args.api_url)
    if args.max_turns < 1:
        raise SystemExit("E0115 runner: --max-turns must be positive")
    started = time.monotonic()
    raw = harness.common.load_canonical(args.canonical, args.source_sha256)
    source_hash = hashlib.sha256(raw).hexdigest()
    ranges = harness.common.load_page_index(args.pages, len(raw))
    residue = load_residue(args.residue)
    e0110 = harness.load_e0110(args.e0110, raw, ranges, source_hash)
    names = [row["name"].rstrip(",") for row in residue]
    if args.only_name:
        names = [name for name in names if name == args.only_name.rstrip(",")]
        if not names:
            raise SystemExit(f"E0115 runner: --only-name is not in residue: {args.only_name}")
    if args.limit:
        names = names[: args.limit]
    setup_wall = time.monotonic() - started
    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    tools = tool_spec()
    rows = []
    with (outdir / "trajectory.jsonl").open("w", encoding="utf-8", newline="\n") as trajectory, \
        (outdir / "rows.jsonl").open("w", encoding="utf-8", newline="\n") as row_file:
        for name in names:
            row = run_row(args, raw, ranges, residue, e0110, name, tools, trajectory)
            clean_row = {key: value for key, value in row.items() if key != "events"}
            rows.append(clean_row)
            row_file.write(json.dumps(clean_row, ensure_ascii=False, sort_keys=True) + "\n")
            row_file.flush()
            trajectory.write(
                json.dumps(
                    {"name": name, "kind": "row_result", "status": clean_row["status"]},
                    ensure_ascii=False,
                    sort_keys=True,
                )
                + "\n"
            )
            trajectory.flush()
    counts = {status: sum(row["status"] == status for row in rows) for status in ("accepted", "abstained_after_budget", "hard_failure")}
    wall_total = time.monotonic() - started
    summary = {
        "candidate": args.candidate,
        "model": args.model,
        "thinking": args.thinking,
        "residue_rows": len(rows),
        "accepted": counts["accepted"],
        "abstentions": counts["abstained_after_budget"],
        "hard_failures": counts["hard_failure"],
        "model_errors": sum(len(row["model_errors"]) for row in rows),
        "gate_rejections": sum(row["gate_rejections"] for row in rows),
        "total_model_calls": sum(row["turns"] for row in rows),
        "tool_calls": sum(row["evidence_calls"] for row in rows),
        "submissions": sum(row["submissions"] for row in rows),
        "source_bytes_returned": sum(row["source_bytes"] for row in rows),
        "oracle_rows": sum(row.get("oracle") is not None for row in rows),
        "oracle_exact_matches": sum(row.get("oracle") == "exact" for row in rows),
        "oracle_wrong_accepts": sum(row.get("oracle") == "wrong-accepted" for row in rows),
        "oracle_abstentions": sum(row.get("oracle") == "abstained_after_budget" for row in rows),
        "oracle_hard_failures": sum(row.get("oracle") == "hard_failure" for row in rows),
        "wall_s_total": wall_total,
        "setup_wall_s": setup_wall,
        "inference_wall_s": wall_total - setup_wall,
    }
    (outdir / "summary.json").write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    (outdir / "run-config.json").write_text(json.dumps(vars(args), indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(summary, sort_keys=True))


if __name__ == "__main__":
    main()
