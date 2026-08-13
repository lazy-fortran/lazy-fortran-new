#!/usr/bin/env python3
"""Prepare one bounded, source-window prompt for every E0106 residue row."""

import argparse
import json
from pathlib import Path

from e0111_common import (
    DEFAULT_SOURCE_SHA256,
    InputError,
    containing_page,
    jsonl_write,
    load_canonical,
    load_page_index,
    load_residue,
    utf8_window,
)


DEFAULT_MODEL = "Qwen/Qwen3.5-2B"
DEFAULT_QUANTIZATION = "Q4_K_M"
DEFAULT_SEED = 1101
DEFAULT_TEMPERATURE = 0.0
DEFAULT_TOP_P = 1.0
DEFAULT_CONTEXT = 8192
DEFAULT_WINDOW_BYTES = 384


def parser():
    root = Path(__file__).resolve().parents[3]
    result = argparse.ArgumentParser(description=__doc__)
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
    result.add_argument(
        "--outdir", default=str(root / ".cache/runs/E0111/R000001")
    )
    result.add_argument("--source-sha256", default=DEFAULT_SOURCE_SHA256)
    result.add_argument("--model", default=DEFAULT_MODEL)
    result.add_argument("--quantization", default=DEFAULT_QUANTIZATION)
    result.add_argument("--seed", type=int, default=DEFAULT_SEED)
    result.add_argument("--temperature", type=float, default=DEFAULT_TEMPERATURE)
    result.add_argument("--top-p", type=float, default=DEFAULT_TOP_P)
    result.add_argument("--context", type=int, default=DEFAULT_CONTEXT)
    result.add_argument("--window-bytes", type=int, default=DEFAULT_WINDOW_BYTES)
    return result


def prompt_for(row, windows, settings):
    source = []
    for window in windows:
        source.append(
            "WINDOW page={page} byte_start={byte_start} byte_length={byte_length}\n"
            "{text}\nEND WINDOW".format(**window)
        )
    source_text = "\n\n".join(source) if source else "NO SOURCE WINDOW WAS FOUND."
    return f"""You are the bounded local-model subject of experiment E0111.
Reason only over the source windows supplied below. Do not use model memory,
comparison grammars, or unstated source text.

Emit exactly one JSON object and no Markdown. The object must have either the
form {{"name":"...","decision":"abstain"}} or the form
{{"name":"...","decision":"proposal","relation":"...","target":"...",
"citation":{{"page":N,"byte_start":N,"byte_length":N,
"source_sha256":"...","text":"..."}}}}. Do not emit any other keys.
The name must be copied exactly as supplied. Use one of the exact relation
tokens `is`, `is-one-of`, `means`, or `consists-of`, and a concise target. A
proposal is allowed only when the supplied source text contains the candidate
as the subject of that exact definition form; otherwise abstain.

The citation must copy an exact UTF-8 byte span from one supplied window. Its
page, byte_start, byte_length, source_sha256, and text are checked against the
canonical source and page index. Never invent a citation. This is a proposal
inventory only: it does not promote a semantic fact.

Residue row: {row["name"]}
E0106 classification: {row["new_class"]}
E0106 matching records: {row["matching_records"]}
Pinned source SHA-256: {settings["source_sha256"]}

{source_text}
"""


def main():
    args = parser().parse_args()
    try:
        raw = load_canonical(args.canonical, args.source_sha256)
        ranges = load_page_index(args.pages, len(raw))
        residue = load_residue(args.residue)
        if args.context < 256 or args.window_bytes < 32:
            raise InputError("context or window size is too small")
        if not 0.0 <= args.temperature <= 2.0:
            raise InputError("temperature must be between 0 and 2")
        if not 0.0 < args.top_p <= 1.0:
            raise InputError("top-p must be greater than 0 and at most 1")
        windows_by_name = {}
        for row in residue:
            windows = []
            for anchor in row["matching"]:
                page = containing_page(ranges, anchor["byte_start"], 1)
                if page != anchor["page"]:
                    raise InputError(
                        f"matching record page mismatch for {row['name']}: "
                        f"{anchor['page']} versus {page}"
                    )
                windows.append(
                    utf8_window(raw, page, anchor["byte_start"], ranges, args.window_bytes)
                )
            unique = {
                (item["page"], item["byte_start"], item["byte_length"]): item
                for item in windows
            }
            windows_by_name[row["name"]] = [
                unique[key] for key in sorted(unique)
            ]
        outdir = Path(args.outdir)
        outdir.mkdir(parents=True, exist_ok=True)
        settings = {
            "experiment": "E0111",
            "provider": "llama.cpp-openai-compatible",
            "model": args.model,
            "quantization": args.quantization,
            "seed": args.seed,
            "temperature": args.temperature,
            "top_p": args.top_p,
            "context": args.context,
            "attempts_per_candidate": 1,
            "repair_attempts": 0,
            "source_sha256": args.source_sha256,
            "window_bytes": args.window_bytes,
        }
        prompts = []
        for row_number, row in enumerate(residue, 1):
            prompts.append(
                {
                    "row": row_number,
                    "name": row["name"],
                    "classification": row["new_class"],
                    "matching_records": row["matching_records"],
                    "source_sha256": args.source_sha256,
                    "windows": windows_by_name[row["name"]],
                    "prompt": prompt_for(row, windows_by_name[row["name"]], settings),
                }
            )
        jsonl_write(outdir / "prompts.jsonl", prompts)
        (outdir / "run-config.json").write_text(
            json.dumps(settings, indent=2, sort_keys=True) + "\n", encoding="utf-8"
        )
        print(f"prepared {len(prompts)} bounded prompts in {outdir}")
    except (InputError, OSError, ValueError) as exc:
        raise SystemExit(f"E0111 prepare-prompts: {exc}") from exc


if __name__ == "__main__":
    main()
