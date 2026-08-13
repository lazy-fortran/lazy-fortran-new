#!/usr/bin/env python3
"""Record the fixed E0113 text and E0114 visual summaries in ignored data files."""

import csv
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
RUN_ROOT = ROOT / ".cache/runs"
OUT = RUN_ROOT / "E0113/R000001/analysis"

TEXT = [
    ("Qwen", "qwen35-2b", "Qwen/Qwen3.5-2B", "Q4_K_M", "old-19e92c3", "off", "E0113", "qwen35-2b-q4"),
    ("Qwen", "qwen35-4b", "Qwen/Qwen3.5-4B", "Q4_K_M", "old-19e92c3", "off", "E0113", "qwen35-4b-q4"),
    ("Qwen", "qwen35-9b", "Qwen/Qwen3.5-9B", "Q4_K_M", "old-19e92c3", "off", "E0113", "qwen35-9b-q4"),
    ("Qwen", "qwen36-27b", "Qwen/Qwen3.6-27B", "UD-Q4_K_XL", "old-19e92c3", "off", "E0113", "qwen36-27b"),
    ("Qwen", "qwen36-35b-a3b", "Qwen/Qwen3.6-35B-A3B", "UD-Q4_K_XL", "old-19e92c3", "off", "E0113", "qwen36-35b-a3b"),
    ("Gemma", "gemma4-e2b", "google/gemma-4-E2B-it", "Q4_0", "old-19e92c3", "off", "E0113", "gemma4-e2b-q4"),
    ("Gemma", "gemma4-e4b", "google/gemma-4-E4B-it", "Q4_0", "b10405-e79e4bf", "off", "E0113", "gemma4-e4b-q4-b10405"),
    ("Gemma", "gemma4-26b-a4b", "google/gemma-4-26B-A4B-it", "UD-Q4_K_XL", "b10405-e79e4bf", "off", "E0113", "gemma4-26b-a4b-b10405"),
    ("Gemma", "gemma4-31b", "google/gemma-4-31B-it", "UD-Q4_K_XL", "b10405-e79e4bf", "off", "E0113", "gemma4-31b-b10405"),
    ("DeepSeek", "deepseek-v4-flash", "deepseek-v4-flash", "cloud-api", "official-cloud", "off", "E0113", "deepseek-v4-flash-b10405"),
    ("Codex", "gpt56-luna-codex-cli", "gpt-5.6-luna", "codex-cli", "codex-cli", "off", "E0113", "gpt56-luna-codex-cli"),
]

VISUAL = [
    ("Qwen", "qwen35-9b", "Qwen/Qwen3.5-9B", "Q4_K_M", "b10405-e79e4bf", "E0114", "qwen35-9b-q4-b10405"),
    ("Qwen", "qwen36-27b", "Qwen/Qwen3.6-27B", "UD-Q4_K_XL", "b10405-e79e4bf", "E0114", "qwen36-27b-b10405"),
    ("Qwen", "qwen36-35b-a3b", "Qwen/Qwen3.6-35B-A3B", "UD-Q4_K_XL", "b10405-e79e4bf", "E0114", "qwen36-35b-b10405"),
    ("Gemma", "gemma4-e2b", "google/gemma-4-E2B-it", "Q4_0", "b10405-e79e4bf", "E0114", "gemma4-e2b-b10405"),
    ("Gemma", "gemma4-e4b", "google/gemma-4-E4B-it", "Q4_0", "b10405-e79e4bf", "E0114", "gemma4-e4b-b10405"),
    ("Gemma", "gemma4-26b-a4b", "google/gemma-4-26B-A4B-it", "UD-Q4_K_XL", "b10405-e79e4bf", "E0114", "gemma4-26b-a4b-b10405"),
    ("Gemma", "gemma4-31b", "google/gemma-4-31B-it", "UD-Q4_K_XL", "b10405-e79e4bf", "E0114", "gemma4-31b-b10405"),
]


def read(path):
    with path.open(encoding="utf-8") as stream:
        return json.load(stream)


def text_row(item):
    family, candidate, model, quantization, runtime, thinking, experiment, directory = item
    data = read(RUN_ROOT / "E0113/R000001" / directory / "summary.json")
    residue = data["residue_rows"]
    oracle = data["oracle_rows"]
    return {
        "experiment": experiment,
        "modality": "text",
        "family": family,
        "candidate": candidate,
        "model": model,
        "quantization": quantization,
        "runtime": runtime,
        "thinking": thinking,
        "residue_rows": residue,
        "accepted": data["accepted"],
        "abstentions": data["abstentions"],
        "hard_failures": data["hard_failures"],
        "model_errors": data["model_errors"],
        "oracle_rows": oracle,
        "oracle_exact_matches": data["oracle_exact_matches"],
        "oracle_wrong_accepts": data["oracle_wrong_accepts"],
        "oracle_abstentions": data["oracle_abstentions"],
        "oracle_hard_failures": data["oracle_hard_failures"],
        "wall_s_total": data["wall_s_total"],
        "inference_wall_s": data["inference_wall_s"],
        "setup_wall_s": data["setup_wall_s"],
        "total_model_calls": data["total_model_calls"],
        "repair_iterations": data["repair_iterations"],
        "gate_rejections": data["gate_rejections"],
        "novel_accepted": data["novel_accepted"],
        "resolution_rate": data["accepted"] / residue,
        "oracle_accuracy": data["oracle_exact_matches"] / oracle,
    }


def visual_row(item):
    family, candidate, model, quantization, runtime, experiment, directory = item
    data = read(RUN_ROOT / "E0114/R000001" / directory / "summary.json")
    oracle = data["oracle_rows"]
    return {
        "experiment": experiment,
        "modality": "visual",
        "family": family,
        "candidate": candidate,
        "model": model,
        "quantization": quantization,
        "runtime": runtime,
        "thinking": "off",
        "residue_rows": "",
        "accepted": "",
        "abstentions": data["abstentions"],
        "hard_failures": data["hard_failures"],
        "model_errors": data["model_errors"],
        "oracle_rows": oracle,
        "oracle_exact_matches": data["exact_target_matches"],
        "oracle_wrong_accepts": "",
        "oracle_abstentions": data["abstentions"],
        "oracle_hard_failures": data["hard_failures"],
        "wall_s_total": data["wall_s_total"],
        "inference_wall_s": data["inference_wall_s"],
        "setup_wall_s": "",
        "total_model_calls": data["total_model_calls"],
        "repair_iterations": data["repair_iterations"],
        "gate_rejections": "",
        "novel_accepted": "",
        "resolution_rate": "",
        "oracle_accuracy": data["exact_target_matches"] / oracle,
    }


def write(path, rows):
    fields = list(rows[0])
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def main():
    text = [text_row(item) for item in TEXT]
    visual = [visual_row(item) for item in VISUAL]
    write(OUT / "text.tsv", text)
    write(OUT / "visual.tsv", visual)
    print(f"recorded {len(text)} text and {len(visual)} visual configurations")


if __name__ == "__main__":
    main()
