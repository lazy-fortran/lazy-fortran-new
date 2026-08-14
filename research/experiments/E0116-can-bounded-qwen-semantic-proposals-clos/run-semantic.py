#!/usr/bin/env python3
"""Run the bounded Qwen semantic-proposal protocol against local llama.cpp."""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

import semantic_harness as harness


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
E0081 = ROOT / "research/experiments/E0081-can-deterministic-source-patterns-invent/analyse.sh"


def parser():
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument("--outdir", required=True)
    result.add_argument("--model", default="qwen36-35b-a3b")
    result.add_argument("--api-url", default="http://127.0.0.1:18080/v1/chat/completions")
    result.add_argument("--thinking", choices=("off", "on"), default="off")
    result.add_argument("--seed", type=int, default=11601)
    result.add_argument("--temperature", type=float, default=0.0)
    result.add_argument("--top-p", type=float, default=1.0)
    result.add_argument("--max-tokens", type=int, default=768)
    result.add_argument("--timeout", type=float, default=180.0)
    result.add_argument("--max-turns", type=int, default=20)
    result.add_argument("--limit", type=int, default=0)
    result.add_argument("--only-constraint", default="")
    result.add_argument("--canonical", default=str(ROOT / ".cache/runs/E0001/R000003/j3-24-007.canonical.txt"))
    result.add_argument("--pages", default=str(ROOT / ".cache/runs/E0001/R000003/j3-24-007.pages.index"))
    result.add_argument("--source-sha256", default=harness.SOURCE_HASH)
    return result


def local_url(url):
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme != "http" or parsed.hostname not in {"127.0.0.1", "localhost", "::1"}:
        raise SystemExit("E0116 runner: --api-url must point to a local HTTP tunnel")


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


def tool_spec():
    return json.loads((HERE / "tool-schema.json").read_text(encoding="utf-8"))["tools"]


def system_prompt(row):
    rules = ", ".join(row["associated_rules"])
    return f"""You are a semantic formalization assistant for the Fortran standard.
Work only through the declared tools. The current source-backed constraint is
{row['constraint_id']} associated with {rules}.

The source clause as initially indexed is:
{row['source_text']}

First call read_constraint. Read associated rules when their grammar context is
needed, and use search_standard/read_span only for bounded source evidence. Then
call submit_semantic exactly once with either decision accept or abstain.

For accept, return a small typed predicate object with exactly {{"op": OP,
"args": [...]}}. Allowed OP values are: and, or, not, implies, eq, ne, lt, le,
gt, ge, in, not-in, present, absent, has, type-is, rank-is, scalar, constant,
unique, same-as, named, accessible, derived, processor-supports, count-le and
count-ge. Do not use code, prose, eval, an unlisted operator, or a parser rule.
Facts are lowercase kebab-case identifiers. Use only facts needed by this one
constraint. Evidence IDs must be IDs returned by the tools. The deterministic
gate owns source hash, byte span, page, rule association, schema acceptance and
promotion; you only propose the local predicate fragment. If the clause cannot
be represented faithfully by this schema after reading the source, abstain so
the row is retained for a later schema extension."""


def user_prompt(row):
    return f"Formalize {row['constraint_id']} as one source-backed typed predicate, or abstain explicitly."


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
    except (harness.GateError, TypeError, KeyError) as exc:
        result = {"status": "error", "code": "tool_rejected", "message": str(exc)}
    return name, arguments, result


def run_row(args, raw, ranges, rows, prior, row, tools, trajectory):
    if not row["primary"]:
        result = {
            "row_key": row["row_key"],
            "constraint_id": row["constraint_id"],
            "status": "reference-only",
            "turns": 0,
            "wall_s": 0.0,
            "evidence_calls": 0,
            "submissions": 0,
            "source_bytes": 0,
            "gate_rejections": 0,
            "model_errors": [],
            "proposal": None,
        }
        trajectory.write(json.dumps({"row_key": row["row_key"], "constraint_id": row["constraint_id"], "kind": "row_result", "status": "reference-only"}, sort_keys=True) + "\n")
        trajectory.flush()
        return result
    episode = harness.ConstraintEpisode(raw, ranges, rows, row, prior)
    messages = [
        {"role": "system", "content": system_prompt(row)},
        {"role": "user", "content": user_prompt(row)},
    ]
    events = []
    model_errors = []
    gate_rejections = 0
    started = time.monotonic()

    def emit(event):
        event = {"row_key": row["row_key"], "constraint_id": row["constraint_id"], **event}
        events.append(event)
        trajectory.write(json.dumps(event, ensure_ascii=False, sort_keys=True) + "\n")
        trajectory.flush()

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
            message, response = call_model(args.api_url, payload, args.timeout)
        except RuntimeError as exc:
            model_errors.append({"turn": turn, "error": str(exc)})
            emit({"turn": turn, "kind": "model_error", "error": str(exc)})
            break
        emit({
            "turn": turn,
            "kind": "model",
            "elapsed_s": time.monotonic() - call_started,
            "message": message,
            "usage": response.get("usage"),
        })
        calls = message.get("tool_calls", [])
        if not isinstance(calls, list) or len(calls) != 1:
            error = "model did not emit exactly one native tool call"
            model_errors.append({"turn": turn, "error": error})
            emit({"turn": turn, "kind": "model_error", "error": error})
            messages.append(message)
            messages.append({"role": "user", "content": "Call exactly one declared tool now."})
            continue
        call = calls[0]
        try:
            tool_name, arguments, result = tool_event(episode, call)
        except RuntimeError as exc:
            model_errors.append({"turn": turn, "error": str(exc)})
            emit({"turn": turn, "kind": "model_error", "error": str(exc)})
            break
        emit({"turn": turn, "kind": "tool", "tool": tool_name, "arguments": arguments, "result": result})
        messages.append(message)
        messages.append({
            "role": "tool",
            "tool_call_id": call.get("id", f"call-{turn}"),
            "name": tool_name,
            "content": json.dumps(result, ensure_ascii=False, sort_keys=True),
        })
        if result.get("status") == "accepted":
            status = "accepted"
            break
        if result.get("status") == "unresolved":
            status = "unresolved"
            break
        if result.get("status") in {"rejected", "error"}:
            gate_rejections += int(result.get("status") == "rejected")
            continue
    else:
        status = "hard_failure"

    if episode.terminal == "accepted":
        status = "accepted"
    elif episode.terminal == "unresolved":
        status = "unresolved"
    elif "status" not in locals():
        status = "hard_failure"
    proposal = episode.accepted
    return {
        "constraint_id": row["constraint_id"],
        "row_key": row["row_key"],
        "status": status,
        "turns": len([event for event in events if event["kind"] == "model"]),
        "wall_s": time.monotonic() - started,
        "evidence_calls": episode.evidence_calls,
        "submissions": episode.submissions,
        "source_bytes": episode.source_bytes,
        "gate_rejections": gate_rejections,
        "model_errors": model_errors,
        "proposal": proposal,
    }


def main():
    args = parser().parse_args()
    local_url(args.api_url)
    if args.max_turns < 1:
        raise SystemExit("E0116 runner: --max-turns must be positive")
    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    predecessor = outdir / "e0081"
    predecessor.mkdir(exist_ok=True)
    constraint_file = predecessor / "constraint-spans.tsv"
    if not constraint_file.exists():
        subprocess.run([str(E0081), str(predecessor)], check=True)
    raw = common.load_canonical(args.canonical, args.source_sha256)
    source_hash = hashlib.sha256(raw).hexdigest()
    if source_hash != args.source_sha256:
        raise SystemExit("E0116 runner: canonical source hash differs")
    ranges = common.load_page_index(args.pages, len(raw))
    rows = harness.load_constraints(constraint_file)
    prior = harness.load_prior(ROOT / ".cache/runs/E0087/R000001/formalizations.tsv")
    if args.only_constraint:
        rows = [row for row in rows if row["constraint_id"] == args.only_constraint]
        if not rows:
            raise SystemExit(f"E0116 runner: unknown constraint: {args.only_constraint}")
    if args.limit:
        rows = rows[: args.limit]
    started = time.monotonic()
    results = []
    tools = tool_spec()
    with (outdir / "trajectory.jsonl").open("w", encoding="utf-8") as trajectory, (outdir / "rows.jsonl").open("w", encoding="utf-8") as row_file:
        for row in rows:
            result = run_row(args, raw, ranges, harness.load_constraints(constraint_file), prior, row, tools, trajectory)
            clean = {key: value for key, value in result.items()}
            results.append(clean)
            row_file.write(json.dumps(clean, ensure_ascii=False, sort_keys=True) + "\n")
            row_file.flush()
            trajectory.write(json.dumps({"row_key": row["row_key"], "constraint_id": row["constraint_id"], "kind": "row_result", "status": clean["status"]}, sort_keys=True) + "\n")
            trajectory.flush()
    summary = {
        "model": args.model,
        "thinking": args.thinking,
        "eligible_constraints": len(results),
        "proposal_rows": sum(row["proposal"] is not None for row in results),
        "schema_accepted_rows": sum(row["status"] == "accepted" for row in results),
        "unresolved_rows": sum(row["status"] == "unresolved" for row in results),
        "hard_failures": sum(row["status"] == "hard_failure" for row in results),
        "reference_only_rows": sum(row["status"] == "reference-only" for row in results),
        "repair_attempts": sum(row["gate_rejections"] for row in results),
        "tool_calls": sum(row["evidence_calls"] for row in results),
        "model_calls": sum(row["turns"] for row in results),
        "source_hash": source_hash,
        "wall_s_total": time.monotonic() - started,
    }
    (outdir / "summary.json").write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    (outdir / "run-config.json").write_text(json.dumps(vars(args), indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(summary, sort_keys=True))


if __name__ == "__main__":
    main()
