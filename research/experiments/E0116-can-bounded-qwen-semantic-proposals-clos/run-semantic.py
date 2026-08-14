#!/usr/bin/env python3
"""Run the bounded Qwen semantic-proposal protocol against local llama.cpp."""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import re
import subprocess
import time
import urllib.error
import urllib.parse
import urllib.request
from collections import Counter
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
    result.add_argument("--max-tokens", type=int, default=1536)
    result.add_argument("--timeout", type=float, default=180.0)
    result.add_argument("--http-retries", type=int, default=2,
                        help="bounded retries for transient model transport errors")
    result.add_argument("--max-turns", type=int, default=20)
    result.add_argument("--finalization-turns", type=int, default=2,
                        help="bounded submit-only turns after the normal turn budget")
    result.add_argument("--max-identical-submissions", type=int, default=3,
                        help="stop an episode after this many identical rejected proposals")
    result.add_argument("--escalate-thinking", action="store_true",
                        help="retry unresolved or failed rows once with thinking on")
    result.add_argument("--require-witnesses", action="store_true",
                        help="require accepted proposals to include fact assignments and expected outcomes")
    result.add_argument("--limit", type=int, default=0)
    result.add_argument("--only-constraint", default="")
    result.add_argument("--retry-from", default="",
                        help="retry unresolved/hard-failure row keys from a prior rows.jsonl")
    result.add_argument("--canonical", default=str(ROOT / ".cache/runs/E0001/R000003/j3-24-007.canonical.txt"))
    result.add_argument("--pages", default=str(ROOT / ".cache/runs/E0001/R000003/j3-24-007.pages.index"))
    result.add_argument("--source-sha256", default=harness.SOURCE_HASH)
    return result


def local_url(url):
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme != "http" or parsed.hostname not in {"127.0.0.1", "localhost", "::1", "10.77.0.10"}:
        raise SystemExit("E0116 runner: --api-url must point to the local model server")


def _retryable_http(status):
    return status in {429, 500, 502, 503, 504}


def _response_error(status, body):
    text = body.decode("utf-8", errors="replace").strip().replace("\n", " ")
    if len(text) > 400:
        text = text[:400] + "..."
    return f"local server HTTP {status}: {text or 'no response body'}"


def call_model(url, payload, timeout, http_retries=0):
    encoded = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    transport_retries = 0
    last_error = None
    for attempt in range(max(0, http_retries) + 1):
        request = urllib.request.Request(
            url,
            data=encoded,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        retryable = False
        try:
            with urllib.request.urlopen(request, timeout=timeout) as response:
                data = json.loads(response.read().decode("utf-8"))
        except urllib.error.HTTPError as exc:
            body = exc.read(4096)
            last_error = RuntimeError(_response_error(exc.code, body))
            retryable = _retryable_http(exc.code)
        except (OSError, urllib.error.URLError) as exc:
            last_error = RuntimeError(str(exc))
            retryable = True
        except json.JSONDecodeError as exc:
            last_error = RuntimeError(f"local server returned invalid JSON: {exc}")
            retryable = True
        else:
            choices = data.get("choices") if isinstance(data, dict) else None
            if not isinstance(choices, list) or len(choices) != 1:
                last_error = RuntimeError("local server response does not contain exactly one choice")
            else:
                message = choices[0].get("message") if isinstance(choices[0], dict) else None
                if not isinstance(message, dict):
                    last_error = RuntimeError("local server response has no message")
                else:
                    choice = choices[0]
                    telemetry = {
                        "transport_retries": transport_retries,
                        "response_id": data.get("id"),
                        "finish_reason": choice.get("finish_reason"),
                        "timings": data.get("timings"),
                    }
                    return message, data, telemetry
        if not retryable or attempt >= max(0, http_retries):
            break
        transport_retries += 1
        time.sleep(min(2.0, 0.25 * (2 ** attempt)))
    assert last_error is not None
    raise last_error


def tool_spec(require_witnesses=False):
    tools = json.loads((HERE / "tool-schema.json").read_text(encoding="utf-8"))["tools"]
    if require_witnesses:
        tools = copy.deepcopy(tools)
        submit = next(tool for tool in tools
                      if tool["function"]["name"] == "submit_semantic")
        submit["function"]["parameters"]["required"].append("witnesses")
    return tools


def content_tool_call(content, turn):
    """Adapt one Qwen XML tool call when the server leaves it in content."""
    if not isinstance(content, str):
        return None
    matches = re.findall(
        r"<tool_call>\s*<function=([A-Za-z_][A-Za-z0-9_]*)>(.*?)</function>\s*</tool_call>",
        content,
        flags=re.DOTALL,
    )
    if len(matches) != 1:
        return None
    name, body = matches[0]
    arguments = {}
    for parameter, value in re.findall(
        r"<parameter=([A-Za-z_][A-Za-z0-9_]*)>\s*(.*?)\s*</parameter>",
        body,
        flags=re.DOTALL,
    ):
        value = value.strip()
        try:
            arguments[parameter] = json.loads(value)
        except json.JSONDecodeError:
            arguments[parameter] = value
    return {
        "id": f"content-call-{turn}",
        "type": "function",
        "function": {"name": name, "arguments": json.dumps(arguments)},
    }


def system_prompt(row, prior, require_witnesses=False):
    rules = ", ".join(row["associated_rules"])
    control = prior.get(row["constraint_id"])
    control_hint = ""
    if control is not None:
        control_hint = f"""
This row is an independent accepted-control replay. Reproduce this canonical
control exactly; it is not a new interpretation:
required_facts={json.dumps(control['required_facts'], sort_keys=True)}
provided_facts={json.dumps(control['provided_facts'], sort_keys=True)}
predicate={json.dumps(harness._parse_sx(control['predicate']), sort_keys=True)}
"""
    witness_hint = ""
    if require_witnesses:
        witness_hint = """
For every accept proposal, witnesses is required and must contain one to eight
objects of the form {\"label\":\"short-case-name\",\"expect\":true or false,
\"facts\":{\"fact-name\": value}}. Facts are concrete assignments for the
predicate's lowercase facts; use only JSON booleans, strings, integers, or
arrays. Choose cases that exercise the constraint, including positive and
negative cases when the predicate distinguishes them. The deterministic
harness checks predicate evaluation for each case; these cases are evidence
for a later independent witness and do not themselves promote the proposal.
"""
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
count-ge, value, name-length, exists, named-constant, has-kind-param,
contains-deferred-binding, inherits-deferred-binding, resolved,
has-deferred-type-parameter, unlimited-polymorphic, abstract-type, derived-type,
intrinsic-module, nonintrinsic-module, intrinsic-type-name,
intrinsic-procedure, abstract-interface, explicit-interface-procedure,
procedure-declaration, declared-earlier, use-accessible, declared-in-specification, has-attribute,
bind-type, sequence-type, in-table-16-2, generic-name, procedure-name and
relation. Use relation only for a source-backed semantic relation, aggregate,
quantified condition or referenced interface that the primitive constructors
cannot express. Its first argument is a lowercase relation name and the
remaining arguments are lowercase fact names or nested predicates; do not use
it to hide an ordinary equality, implication or attribute test.
Do not use code, prose, eval, an unlisted operator, or a parser rule.
Facts are lowercase kebab-case identifiers. Use only facts needed by this one
constraint. Evidence IDs must be IDs returned by the tools. The deterministic
gate owns source hash, byte span, page, rule association, schema acceptance and
promotion; you only propose the local predicate fragment. If the clause cannot
be represented faithfully by this schema after reading the source, abstain so
the row is retained for a later schema extension.

For eq, ne, lt, le, gt and ge, put the value field first and a literal second,
for example {{"op":"eq","args":["exponent-letter","E"]}} or
{{"op":"eq","args":["type-param-value",":"]}}. Never compare two lowercase
fact-like names; use same-as for field-to-field identity. Use JSON arrays for
finite domains, not an invented predicate or executable expression. For a
clause of the generic form “X shall not be Y except in context Z”, use the
canonical shape implies(forbidden-condition, allowed-context), rather than a
negated conjunction.
Shape examples: valid nested Boolean forms are
{{"op":"not","args":[{{"op":"present","args":["x"]}}]}} and
{{"op":"implies","args":[{{"op":"has","args":["x"]}},
{{"op":"not","args":[{{"op":"has","args":["y"]}}]}}]}};
field identity is {{"op":"same-as","args":["x","y"]}}; a value
comparison is {{"op":"eq","args":["x","literal"]}}; and a generic
source-backed relation is {{"op":"relation","args":["relation-name",
"x"]}}. Invalid shapes include {{"op":"and","args":["x","y"]}},
{{"op":"implies","args":["x","y"]}} and eq/ne with two fact names.
{witness_hint}
{control_hint}"""


def user_prompt(row):
    return f"Formalize {row['constraint_id']} as one source-backed typed predicate, or abstain explicitly."


def proposal_fingerprint(arguments):
    return json.dumps(arguments, ensure_ascii=False, sort_keys=True, separators=(",", ":"))


def submission_repair_message(result, repeats):
    message = result.get("message", result.get("code", "unknown"))
    if repeats < 2:
        return (
            "The deterministic gate rejected that proposal: "
            f"{message}. Submit a concise replacement; do not repeat the rejected "
            "predicate. If the primitive constructors cannot express the "
            "source-backed relation, use the generic relation constructor."
        )
    return (
        "LOOP RECOVERY: this exact semantic proposal has now been rejected "
        f"{repeats} times. The gate message is: {message}. You must change the "
        "predicate structure, not merely resend the same JSON. Never compare two "
        "fact identifiers with eq/ne/lt/le/gt/ge; use a literal on the right, "
        "same-as for field identity, or relation for a source-backed relation. "
        "Do not encode a Boolean fact as the string 'true'. If the clause cannot "
        "be represented faithfully, submit decision abstain exactly once."
    )


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
    except (harness.GateError, harness.common.InputError, TypeError, KeyError) as exc:
        result = {"status": "error", "code": "tool_rejected", "message": str(exc)}
    return name, arguments, result


def run_row_attempt(args, raw, ranges, rows, prior, row, tools, trajectory, thinking, attempt):
    """Run one fresh bounded episode for one primary constraint row."""
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
            "transport_retries": 0,
            "loop_recoveries": 0,
            "finalization_turns": 0,
            "prompt_tokens": 0,
            "completion_tokens": 0,
            "total_tokens": 0,
            "proposal": None,
        }
        trajectory.write(json.dumps({
            "row_key": row["row_key"], "constraint_id": row["constraint_id"],
            "attempt": attempt, "kind": "attempt_result", "status": "reference-only",
        }, sort_keys=True) + "\n")
        trajectory.flush()
        return result
    episode = harness.ConstraintEpisode(
        raw, ranges, rows, row, prior, require_witnesses=args.require_witnesses
    )
    messages = [
        {"role": "system", "content": system_prompt(row, prior, args.require_witnesses)},
        {"role": "user", "content": user_prompt(row)},
    ]
    events = []
    model_errors = []
    gate_rejections = 0
    transport_retries = 0
    loop_recoveries = 0
    finalization_turns = 0
    token_totals = Counter()
    force_submit = False
    last_evidence_call = None
    repeated_evidence_calls = 0
    submission_counts = Counter()
    started = time.monotonic()

    def emit(event):
        event = {
            "row_key": row["row_key"], "constraint_id": row["constraint_id"],
            "attempt": attempt, **event,
        }
        events.append(event)
        trajectory.write(json.dumps(event, ensure_ascii=False, sort_keys=True) + "\n")
        trajectory.flush()

    status = None
    finalization_prompt_sent = False
    total_turns = args.max_turns + args.finalization_turns
    for turn in range(1, total_turns + 1):
        finalizing = turn > args.max_turns
        if finalizing:
            finalization_turns += 1
            if not finalization_prompt_sent:
                messages.append({
                    "role": "user",
                    "content": (
                        "FINALIZATION: the normal dialogue budget is exhausted. "
                        "Use this submit-only phase now. Call submit_semantic with "
                        "one concise source-backed proposal, or decision abstain if "
                        "the clause cannot be represented faithfully. Do not call "
                        "an evidence tool and do not repeat a rejected proposal."
                    ),
                })
                finalization_prompt_sent = True
        force_now = force_submit or finalizing
        # A forced tool choice is consumed by this one request. The next request
        # returns to auto, matching the loop-prevention behavior of mature agent
        # runners.
        force_submit = False
        payload = {
            "model": args.model,
            "messages": messages,
            "tools": tools,
            "tool_choice": (
                {"type": "tool", "name": "submit_semantic"}
                if force_now else "auto"
            ),
            "parallel_tool_calls": False,
            "temperature": args.temperature,
            "top_p": args.top_p,
            "seed": args.seed,
            "max_tokens": args.max_tokens,
            "stream": False,
            "chat_template_kwargs": {"enable_thinking": thinking == "on"},
        }
        call_started = time.monotonic()
        try:
            message, response, telemetry = call_model(
                args.api_url, payload, args.timeout, args.http_retries
            )
        except RuntimeError as exc:
            model_errors.append({"turn": turn, "error": str(exc)})
            emit({"turn": turn, "kind": "model_error", "error": str(exc)})
            if finalizing:
                break
            messages.append({
                "role": "user",
                "content": (
                    "The model transport failed after bounded retries: "
                    f"{exc}. Continue with exactly one valid declared tool call."
                ),
            })
            continue
        usage = response.get("usage") or {}
        for key in ("prompt_tokens", "completion_tokens", "total_tokens"):
            if isinstance(usage.get(key), int):
                token_totals[key] += usage[key]
        transport_retries += telemetry["transport_retries"]
        emit({
            "turn": turn,
            "kind": "model",
            "elapsed_s": time.monotonic() - call_started,
            "message": message,
            "usage": usage,
            "response_id": telemetry["response_id"],
            "finish_reason": telemetry["finish_reason"],
            "timings": telemetry["timings"],
            "transport_retries": telemetry["transport_retries"],
        })
        calls = message.get("tool_calls", [])
        if not calls:
            adapted = content_tool_call(message.get("content"), turn)
            if adapted is not None:
                calls = [adapted]
                emit({
                    "turn": turn,
                    "kind": "content_tool_adapter",
                    "tool": adapted["function"]["name"],
                })
        if not isinstance(calls, list) or len(calls) != 1:
            error = "model did not emit exactly one native tool call"
            model_errors.append({"turn": turn, "error": error})
            emit({"turn": turn, "kind": "model_error", "error": error})
            messages.append(message)
            messages.append({
                "role": "user",
                "content": (
                    "Call exactly one declared tool now. In finalization, that tool "
                    "must be submit_semantic."
                ),
            })
            continue
        call = calls[0]
        try:
            tool_name, arguments, result = tool_event(episode, call)
        except RuntimeError as exc:
            model_errors.append({"turn": turn, "error": str(exc)})
            emit({"turn": turn, "kind": "model_error", "error": str(exc)})
            messages.append({
                "role": "user",
                "content": f"The last native tool call was malformed: {exc}. "
                           "The malformed assistant call is not retained in the "
                           "conversation. Call exactly one declared tool again "
                           "with valid JSON and concise arguments.",
            })
            continue
        emit({"turn": turn, "kind": "tool", "tool": tool_name, "arguments": arguments, "result": result})
        messages.append(message)
        messages.append({
            "role": "tool",
            "tool_call_id": call.get("id", f"call-{turn}"),
            "name": tool_name,
            "content": json.dumps(result, ensure_ascii=False, sort_keys=True),
        })
        if tool_name in {"read_constraint", "read_rule", "search_standard", "read_span"}:
            fingerprint = json.dumps([tool_name, arguments], sort_keys=True)
            if fingerprint == last_evidence_call:
                repeated_evidence_calls += 1
            else:
                repeated_evidence_calls = 0
            last_evidence_call = fingerprint
            message_text = str(result.get("message", ""))
            if repeated_evidence_calls >= 2 or "evidence-call budget exhausted" in message_text:
                force_submit = True
                messages.append({
                    "role": "user",
                    "content": "Evidence retrieval is now closed for this episode. "
                               "Submit exactly one semantic proposal or abstain; do not "
                               "request another evidence tool.",
                })
        if finalizing and tool_name != "submit_semantic":
            messages.append({
                "role": "user",
                "content": "Finalization is submit-only. Call submit_semantic now, or abstain.",
            })
            continue
        if result.get("status") == "accepted":
            status = "accepted"
            break
        if result.get("status") == "unresolved":
            status = "unresolved"
            break
        if result.get("status") in {"rejected", "error"}:
            gate_rejections += int(result.get("status") == "rejected")
            if tool_name == "submit_semantic":
                fingerprint = proposal_fingerprint(arguments)
                submission_counts[fingerprint] += 1
                repeats = submission_counts[fingerprint]
                if repeats >= 2:
                    loop_recoveries += 1
                    emit({
                        "turn": turn,
                        "kind": "loop_recovery",
                        "repeats": repeats,
                        "fingerprint": fingerprint,
                    })
                messages.append({
                    "role": "user",
                    "content": submission_repair_message(result, repeats),
                })
                if repeats >= args.max_identical_submissions:
                    status = "hard_failure"
                    emit({
                        "turn": turn,
                        "kind": "attempt_stop",
                        "reason": "repeated-identical-submission",
                    })
                    break
            continue
    if status is None:
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
        "transport_retries": transport_retries,
        "loop_recoveries": loop_recoveries,
        "finalization_turns": finalization_turns,
        "prompt_tokens": token_totals["prompt_tokens"],
        "completion_tokens": token_totals["completion_tokens"],
        "total_tokens": token_totals["total_tokens"],
        "thinking": thinking,
        "proposal": proposal,
    }


def run_row(args, raw, ranges, rows, prior, row, tools, trajectory):
    """Run a row, optionally escalating one failed no-thinking attempt."""
    if not row["primary"]:
        return run_row_attempt(args, raw, ranges, rows, prior, row, tools, trajectory,
                               args.thinking, 1)
    modes = [args.thinking]
    if args.escalate_thinking and args.thinking == "off":
        modes.append("on")
    attempts = []
    for attempt, thinking in enumerate(modes, start=1):
        result = run_row_attempt(args, raw, ranges, rows, prior, row, tools, trajectory,
                                 thinking, attempt)
        attempts.append(result)
        trajectory.write(json.dumps({
            "row_key": row["row_key"], "constraint_id": row["constraint_id"],
            "attempt": attempt, "kind": "attempt_result", "status": result["status"],
            "thinking": thinking,
        }, sort_keys=True) + "\n")
        trajectory.flush()
        if result["status"] in {"accepted", "reference-only"}:
            break
    final = dict(attempts[-1])
    summed = {
        key: sum(item.get(key, 0) for item in attempts)
        for key in (
            "turns", "wall_s", "evidence_calls", "submissions", "source_bytes",
            "gate_rejections", "transport_retries", "loop_recoveries",
            "finalization_turns", "prompt_tokens", "completion_tokens", "total_tokens",
        )
    }
    final.update(summed)
    final["attempts"] = len(attempts)
    final["thinking_modes"] = [item.get("thinking") for item in attempts]
    final["attempt_history"] = [
        {"status": item["status"], "thinking": item.get("thinking"),
         "turns": item["turns"], "wall_s": item["wall_s"]}
        for item in attempts
    ]
    final["model_errors"] = [error for item in attempts for error in item["model_errors"]]
    return final


def main():
    args = parser().parse_args()
    local_url(args.api_url)
    if args.max_turns < 1:
        raise SystemExit("E0116 runner: --max-turns must be positive")
    if args.finalization_turns < 0:
        raise SystemExit("E0116 runner: --finalization-turns cannot be negative")
    if args.http_retries < 0:
        raise SystemExit("E0116 runner: --http-retries cannot be negative")
    if args.max_identical_submissions < 2:
        raise SystemExit("E0116 runner: --max-identical-submissions must be at least 2")
    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    predecessor = outdir / "e0081"
    predecessor.mkdir(exist_ok=True)
    constraint_file = predecessor / "constraint-spans.tsv"
    if not constraint_file.exists():
        subprocess.run([str(E0081), str(predecessor)], check=True)
    raw = harness.common.load_canonical(args.canonical, args.source_sha256)
    source_hash = hashlib.sha256(raw).hexdigest()
    if source_hash != args.source_sha256:
        raise SystemExit("E0116 runner: canonical source hash differs")
    ranges = harness.common.load_page_index(args.pages, len(raw))
    rows = harness.load_constraints(constraint_file)
    prior = harness.load_prior(ROOT / ".cache/runs/E0087/R000001/formalizations.tsv")
    if args.only_constraint:
        rows = [row for row in rows if row["constraint_id"] == args.only_constraint]
        if not rows:
            raise SystemExit(f"E0116 runner: unknown constraint: {args.only_constraint}")
    if args.limit:
        rows = rows[: args.limit]
    if args.retry_from:
        prior_rows = [
            json.loads(line)
            for line in Path(args.retry_from).read_text(encoding="utf-8").splitlines()
            if line
        ]
        retry_keys = {
            item["row_key"] for item in prior_rows
            if item.get("status") in {"unresolved", "hard_failure"}
        }
        rows = [row for row in rows if row["row_key"] in retry_keys]
    started = time.monotonic()
    results = []
    tools = tool_spec(args.require_witnesses)
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
        "require_witnesses": args.require_witnesses,
        "eligible_constraints": len(results),
        "proposal_rows": sum(row["proposal"] is not None for row in results),
        "schema_accepted_rows": sum(row["status"] == "accepted" for row in results),
        "unresolved_rows": sum(row["status"] == "unresolved" for row in results),
        "hard_failures": sum(row["status"] == "hard_failure" for row in results),
        "reference_only_rows": sum(row["status"] == "reference-only" for row in results),
        "repair_attempts": sum(row["gate_rejections"] for row in results),
        "evidence_calls": sum(row["evidence_calls"] for row in results),
        "submission_calls": sum(row["submissions"] for row in results),
        "tool_calls": sum(row["evidence_calls"] + row["submissions"] for row in results),
        "model_calls": sum(row["turns"] for row in results),
        "transport_retries": sum(row["transport_retries"] for row in results),
        "loop_recoveries": sum(row["loop_recoveries"] for row in results),
        "finalization_turns": sum(row["finalization_turns"] for row in results),
        "prompt_tokens": sum(row["prompt_tokens"] for row in results),
        "completion_tokens": sum(row["completion_tokens"] for row in results),
        "total_tokens": sum(row["total_tokens"] for row in results),
        "thinking_escalations": sum(max(row.get("attempts", 1) - 1, 0) for row in results),
        "source_hash": source_hash,
        "wall_s_total": time.monotonic() - started,
    }
    (outdir / "summary.json").write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    (outdir / "run-config.json").write_text(json.dumps(vars(args), indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(summary, sort_keys=True))


if __name__ == "__main__":
    main()
