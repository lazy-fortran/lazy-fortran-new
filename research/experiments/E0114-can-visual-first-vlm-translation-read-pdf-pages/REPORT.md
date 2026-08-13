# E0114 report

The visual-first control ran on six rendered PDF pages, using only the page
image and candidate name. The rendered pages and model outputs remain in
`.cache/runs/E0114/`; the PDF and oracle are pinned laboratory inputs and are
not copied into the repository. Results are not pooled with E0113.

| candidate | exact target | abstain | hard | calls | repairs | wall s | relation matches |
|---|---:|---:|---:|---:|---:|---:|---:|
| Qwen 3.5 9B | 4/6 | 0 | 2 | 10 | 4 | 30.49 | 5/6 |
| Qwen 3.6 27B | 5/6 | 1 | 0 | 6 | 0 | 35.85 | 5/6 |
| Qwen 3.6 35B-A3B | 4/6 | 0 | 2 | 12 | 6 | 36.48 | 5/6 |
| Gemma 4 E2B | 0/6 | 6 | 0 | 6 | 0 | 2.65 | 0/6 |
| Gemma 4 E4B | 0/6 | 4 | 2 | 12 | 6 | 12.91 | 2/6 |
| Gemma 4 26B-A4B | 1/6 | 3 | 2 | 10 | 4 | 8.82 | 3/6 |
| Gemma 4 31B | 3/6 | 1 | 2 | 10 | 4 | 30.62 | 5/6 |

Visual abstention is a false negative, not a successful terminal result. The
visual protocol therefore reports exact matches, abstentions and hard
failures separately. Qwen 3.6 27B was strongest on this six-page control;
Gemma's visual performance was inconsistent despite the corrected runtime.
The experiment does not establish that a model can resolve the full residue,
and it promotes no StandardIR fact.

Regenerate the shared tables and figures with:

```sh
python3 research/experiments/E0113-can-bounded-repair-and-translation-oracle-converge/record-results.py
python3 research/experiments/E0113-can-bounded-repair-and-translation-oracle-converge/plot-results.py \
  --text .cache/runs/E0113/R000001/analysis/text.tsv \
  --visual .cache/runs/E0113/R000001/analysis/visual.tsv \
  --outdir .cache/runs/E0113/R000001/plot
```
