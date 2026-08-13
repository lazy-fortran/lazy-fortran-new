#!/usr/bin/env python3
"""Send prepared prompts to an already-running llama.cpp OpenAI API."""

import argparse
import json
import urllib.error
import urllib.request
from pathlib import Path

from e0111_common import InputError, jsonl_write


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


def call_api(url, payload, timeout):
    body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    request = urllib.request.Request(
        url,
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            return json.loads(response.read().decode("utf-8"))
    except (OSError, urllib.error.HTTPError, json.JSONDecodeError) as exc:
        raise InputError(f"llama.cpp API request failed: {exc}") from exc


def main():
    args = parser().parse_args()
    if args.context < 256 or args.max_tokens < 1:
        raise SystemExit("E0111 run-local: context/max-tokens is too small")
    if not 0.0 <= args.temperature <= 2.0 or not 0.0 < args.top_p <= 1.0:
        raise SystemExit("E0111 run-local: invalid temperature or top-p")
    try:
        prompts = load_prompts(args.prompts)
        responses = []
        errors = []
        for item in prompts:
            payload = {
                "model": args.model,
                "messages": [{"role": "user", "content": item["prompt"]}],
                "temperature": args.temperature,
                "top_p": args.top_p,
                "seed": args.seed,
                "max_tokens": args.max_tokens,
                "stream": False,
                "response_format": {"type": "json_object"},
            }
            try:
                result = call_api(args.api_url, payload, args.timeout)
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
                errors.append({"name": item["name"], "error": str(exc)})
                responses.append({"name": item["name"], "decision": "abstain"})
        jsonl_write(args.responses, responses)
        errors_path = Path(args.responses).with_name("model-errors.jsonl")
        jsonl_write(errors_path, errors)
        config = Path(args.responses).with_name("api-config.json")
        config.write_text(
            json.dumps(
                {
                    "provider": "llama.cpp-openai-compatible",
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
                    "requests": len(responses),
                    "model_errors": len(errors),
                },
                indent=2,
                sort_keys=True,
            )
            + "\n",
            encoding="utf-8",
        )
        print(f"wrote {len(responses)} llama.cpp responses to {args.responses}")
    except (InputError, OSError) as exc:
        raise SystemExit(f"E0111 run-local: {exc}") from exc


if __name__ == "__main__":
    main()
