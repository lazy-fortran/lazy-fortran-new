#!/usr/bin/env bash
# Run the compact E0120 source-linked normative-form analyzer.

set -euo pipefail
export LC_ALL=C

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
here="$root/research/experiments/E0120-can-deterministic-normative-constraint-f"
canonical="${CANONICAL_TEXT:-$root/.cache/runs/E0001/R000003/j3-24-007.canonical.txt}"
pages="${PAGE_INDEX:-$root/.cache/runs/E0001/R000003/j3-24-007.pages.index}"
constraints="${CONSTRAINT_INVENTORY:-$root/.cache/runs/E0081/R000001/constraint-spans.tsv}"
structure="${STRUCTURE_ARTIFACT:-$root/.cache/runs/E0106/R000001/structure.jsonl}"
residue="${RESIDUE_ARTIFACT:-$root/.cache/runs/E0106/R000001/residue-classifications.tsv}"
baseline="${E0083_ORACLE:-$root/research/experiments/E0083-can-deterministic-predicate-patterns-for/independent-oracle.tsv}"
outdir="${1:-$root/.cache/runs/E0120/R000001}"
oracle_output="${E0120_SOURCE_ORACLE:-$here/source-oracle.tsv}"

python3 "$here/analyze.py" \
    --canonical "$canonical" \
    --pages "$pages" \
    --constraints "$constraints" \
    --structure "$structure" \
    --residue "$residue" \
    --baseline "$baseline" \
    --source-oracle "$oracle_output" \
    --outdir "$outdir"
