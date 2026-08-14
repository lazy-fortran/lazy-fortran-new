#!/usr/bin/env python3
"""Send prepared prompts to an already-running llama.cpp OpenAI API."""

import argparse
import json
import os
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

from e0111_common import InputError, jsonl_append, jsonl_write, write_progress


DEFAULT_MODEL = "Qwen/Qwen3.5-2B"
DEFAULT_QUANTIZATION = "Q4_K_M"
DEFAULT_SEED = 1101
DEFAULT_TEMPERATURE = 0.0
DEFAULT_TOP_P = 1.0
DEFAULT_CONTEXT = 8192


def parser():
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument("prompts", help="prompts.jsonl produced by prepare-prompts.py")
    result.add_argument("responses", help="ignored-cache path for response JSONL")
    result.add_argument("--api-url", default="http://127.0.0.1:8080/v1/chat/completions")
    result.add_argument("--model", default=DEFAULT_MODEL)
    result.add_argument("--quantization", default=DEFAULT_QUANTIZATION)
    result.add_argument("--seed", type=int, default=DEFAULT_SEED)
    result.add_argument("--temperature", type=float, default=DEFAULT_TEMPERATURE)
    result.add_argument("--top-p", type=float, default=DEFAULT_TOP_P)
    result.add_argument("--context", type=int, default=DEFAULT_CONTEXT)
    result.add_argument("--max-tokens", type=int, default=768)
    result.add_argument("--timeout", type=float, default=120.0)
    result.add_argument("--thinking", choices=("off", "on"), default="off")
    result.add_argument("--candidate", default="unspecified")
    result.add_argument("--source-repo", default="unspecified")
    result.add_argument("--source-file", default="unspecified")
    result.add_argument("--model-sha256", default="unspecified")
    result.add_argument("--pointer-mode", action="store_true")
    result.add_argument("--pointer-only", action="store_true")
    result.add_argument(
        "--api-key-env",
        default="",
        help="read a bearer token from this environment variable; never record its value",
    )
    result.add_argument(
        "--deepseek-cloud",
        action="store_true",
        help="send DeepSeek cloud thinking-mode control and JSON-object output",
    )
    return result


def load_prompts(path):
    records = []
    try:
        with Path(path).open(encoding="utf-8") as stream:
            for line_number, line in enumerate(stream, 1):
                try:
                    item = json.loads(line)
                except json.JSONDecodeError as exc:
                    raise InputError(f"prompt line {line_number} is not JSON") from exc
                if (
                    not isinstance(item, dict)
                    or not isinstance(item.get("name"), str)
                    or not isinstance(item.get("prompt"), str)
                ):
                    raise InputError(f"prompt line {line_number} lacks name/prompt")
                records.append(item)
    except OSError as exc:
        raise InputError(f"cannot read prompts {path}: {exc}") from exc
    if len(records) != 127 or len({item["name"] for item in records}) != 127:
        raise InputError(f"expected 127 distinct prompts, got {len(records)}")
    return records


def call_api(url, payload, timeout, api_key_env):
    body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    headers = {"Content-Type": "application/json"}
    if api_key_env:
        api_key = os.environ.get(api_key_env, "").strip()
        if not api_key:
            raise InputError(f"environment variable {api_key_env} is empty or unset")
        headers["Authorization"] = f"Bearer {api_key}"
    request = urllib.request.Request(
        url,
        data=body,
        headers=headers,
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            return json.loads(response.read().decode("utf-8"))
    except (OSError, urllib.error.HTTPError, json.JSONDecodeError) as exc:
        raise InputError(f"llama.cpp API request failed: {exc}") from exc


def apply_reasoning_control(payload, thinking, deepseek_cloud=False):
    """Apply the provider-specific per-request reasoning control."""
    if deepseek_cloud:
        payload["thinking"] = {"type": "disabled" if thinking == "off" else "enabled"}
    else:
        payload["chat_template_kwargs"] = {"enable_thinking": thinking == "on"}
    return payload


def response_format(name, pointer_mode, window_count, pointer_only=False):
    if not pointer_mode and not pointer_only:
        return {"type": "json_object"}
    allowed_windows = list(range(1, window_count + 1)) or [0]
    schema = {
        "type": "object",
        "additionalProperties": False,
        "properties": {
            "name": {"type": "string", "enum": [name]},
            "decision": {"type": "string", "enum": ["abstain", "proposal"]},
            "relation": {
                "type": "string",
                "enum": ["is", "is-one-of", "means", "consists-of"],
            },
            "window": {"type": "integer", "enum": allowed_windows},
        },
        "required": ["name", "decision"],
    }
    if not pointer_only:
        schema["properties"]["target"] = {"type": "string", "maxLength": 512}
    return {
        "type": "json_schema",
        "json_schema": {"name": "e0111_proposal", "strict": True, "schema": schema},
    }


def infer_pointer_contract(prompts, requested_mode, requested_only):
    """Make the prompt manifest and API response schema agree."""
    prompt_only = bool(prompts) and all(
        item.get("pointer_only") is True for item in prompts
    )
    if requested_only and not prompt_only:
        raise InputError("--pointer-only requires prompts generated with --pointer-only")
    effective_only = requested_only or prompt_only
    return requested_mode or effective_only, effective_only


def main():
    args = parser().parse_args()
    if args.context < 256 or args.max_tokens < 1:
        raise SystemExit("E0111 run-local: context/max-tokens is too small")
    if args.pointer_only and not args.pointer_mode:
        raise SystemExit("E0111 run-local: --pointer-only requires --pointer-mode")
    if not 0.0 <= args.temperature <= 2.0 or not 0.0 < args.top_p <= 1.0:
        raise SystemExit("E0111 run-local: invalid temperature or top-p")
    try:
        prompts = load_prompts(args.prompts)
        # The prompt manifest is part of the request contract.  Infer the
        # strict schema from it when the caller omitted the redundant flag;
        # this prevents a pointer-only cell from silently sending a weaker
        # response schema to the model.
        pointer_mode, pointer_only = infer_pointer_contract(
            prompts, args.pointer_mode, args.pointer_only
        )
        responses = []
        errors = []
        progress_path = Path(args.responses).with_name("progress.json")
        errors_path = Path(args.responses).with_name("model-errors.jsonl")
        Path(args.responses).write_text("", encoding="utf-8")
        errors_path.write_text("", encoding="utf-8")
        started_monotonic = time.monotonic()
        started_at = datetime.now(timezone.utc).isoformat()
        write_progress(
            progress_path,
            total=len(prompts),
            completed=0,
            started_monotonic=started_monotonic,
            started_at=started_at,
        )
        for item in prompts:
            payload = {
                "model": args.model,
                "messages": [{"role": "user", "content": item["prompt"]}],
                "temperature": args.temperature,
                "top_p": args.top_p,
                "seed": args.seed,
                "max_tokens": args.max_tokens,
                "stream": False,
                "response_format": response_format(
                    item["name"],
                    pointer_mode,
                    len(item.get("windows", [])),
                    pointer_only,
                ),
            }
            if args.deepseek_cloud:
                apply_reasoning_control(payload, args.thinking, deepseek_cloud=True)
                payload["response_format"] = {"type": "json_object"}
            else:
                apply_reasoning_control(payload, args.thinking)
            try:
                result = call_api(args.api_url, payload, args.timeout, args.api_key_env)
                choices = result.get("choices") if isinstance(result, dict) else None
                if not isinstance(choices, list) or len(choices) != 1:
                    raise InputError(f"API response for {item['name']} lacks one choice")
                message = choices[0].get("message") if isinstance(choices[0], dict) else None
                content = message.get("content") if isinstance(message, dict) else None
                if not isinstance(content, str):
                    raise InputError(f"API response for {item['name']} lacks text content")
                proposal = json.loads(content)
                if not isinstance(proposal, dict):
                    raise InputError(f"model response for {item['name']} is not an object")
                if proposal.get("name") != item["name"]:
                    raise InputError(f"model response name mismatch for {item['name']}")
                responses.append(proposal)
            except (InputError, json.JSONDecodeError, TypeError) as exc:
                error = {"name": item["name"], "error": str(exc)}
                errors.append(error)
                jsonl_append(errors_path, error)
                response = {"name": item["name"], "decision": "abstain"}
                responses.append(response)
                jsonl_append(args.responses, response)
            else:
                jsonl_append(args.responses, responses[-1])
            write_progress(
                progress_path,
                total=len(prompts),
                completed=len(responses),
                started_monotonic=started_monotonic,
                started_at=started_at,
                current=(
                    prompts[len(responses)]["name"]
                    if len(responses) < len(prompts)
                    else None
                ),
                model_errors=len(errors),
            )
        config = Path(args.responses).with_name("api-config.json")
        provider = "deepseek-api" if args.deepseek_cloud else "llama.cpp-openai-compatible"
        config.write_text(
            json.dumps(
                {
                    "provider": provider,
                    "api_url": args.api_url,
                    "model": args.model,
                    "quantization": args.quantization,
                    "seed": args.seed,
                    "temperature": args.temperature,
                    "top_p": args.top_p,
                    "context": args.context,
                    "max_tokens": args.max_tokens,
                    "thinking": args.thinking,
                    "candidate": args.candidate,
                    "source_repo": args.source_repo,
                    "source_file": args.source_file,
                    "model_sha256": args.model_sha256,
                    "pointer_mode": pointer_mode,
                    "pointer_only": pointer_only,
                    "api_key_env": args.api_key_env,
                    "deepseek_cloud": args.deepseek_cloud,
                    "requests": len(responses),
                    "model_errors": len(errors),
                },
                indent=2,
                sort_keys=True,
            )
            + "\n",
            encoding="utf-8",
        )
        write_progress(
            progress_path,
            total=len(prompts),
            completed=len(responses),
            started_monotonic=started_monotonic,
            started_at=started_at,
            model_errors=len(errors),
            status="completed",
        )
        print(f"wrote {len(responses)} llama.cpp responses to {args.responses}")
    except (InputError, OSError) as exc:
        raise SystemExit(f"E0111 run-local: {exc}") from exc


if __name__ == "__main__":
    main()
