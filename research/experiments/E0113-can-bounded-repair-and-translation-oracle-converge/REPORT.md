# E0113 report

The fixed full-document, pointer-only protocol ran on all 127 residue rows and
the six frozen E0110 translation-oracle rows for every declared text
candidate. The protocol is defined by the manifest and D0052/D0053. Raw
summaries and trajectories remain under `.cache/runs/E0113/` and are not
committed. The runtime correction is D0055.

| candidate | accepted | abstain | hard | model errors | oracle exact | calls | repairs | wall s |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Qwen 3.5 2B | 6 | 121 | 0 | 0 | 5/6 | 127 | 0 | 32.61 |
| Qwen 3.5 4B | 5 | 122 | 0 | 0 | 4/6 | 127 | 0 | 40.01 |
| Qwen 3.5 9B | 2 | 125 | 0 | 0 | 2/6 | 127 | 0 | 48.53 |
| Qwen 3.6 27B | 5 | 122 | 0 | 0 | 5/6 | 127 | 0 | 172.46 |
| Qwen 3.6 35B-A3B | 4 | 123 | 0 | 0 | 4/6 | 127 | 0 | 45.96 |
| Gemma 4 E2B | 5 | 122 | 0 | 0 | 4/6 | 127 | 0 | 24.52 |
| Gemma 4 E4B | 5 | 121 | 1 | 15 | 5/6 | 141 | 14 | 232.57 |
| Gemma 4 26B-A4B | 3 | 124 | 0 | 0 | 3/6 | 127 | 0 | 42.03 |
| Gemma 4 31B | 2 | 125 | 0 | 0 | 2/6 | 127 | 0 | 163.34 |
| DeepSeek V4 Flash | 5 | 122 | 0 | 0 | 5/6 | 127 | 0 | 115.11 |
| GPT-5.6 Luna | 2 | 125 | 0 | 0 | 2/6 | 128 | 1 | 651.86 |

The six oracle rows are included in `accepted`; the 121-row discovery
denominator is therefore `accepted - oracle_exact_matches` only as a
translation-quality decomposition, not as a second run denominator. The
highest discovery result was one novel accepted row, reached by Qwen 3.5 2B,
Qwen 3.5 4B and Gemma 4 E2B. No candidate produced a reliable broad
resolution of the residue. The large checkpoints did not improve the oracle
or discovery result under this protocol.

The E4B model's 15 malformed-response errors occurred after the new runtime
loaded it successfully; one row remained a hard failure after the repair
budget. The earlier old-runtime scheduler assertion is retained as a separate
toolchain-control run and is not counted as model quality. Luna had one gate
rejection followed by a bounded repair. No semantic relation was promoted into
StandardIR.

Regenerate the tables and figures with:

```sh
python3 research/experiments/E0113-can-bounded-repair-and-translation-oracle-converge/record-results.py
python3 research/experiments/E0113-can-bounded-repair-and-translation-oracle-converge/plot-results.py \
  --text .cache/runs/E0113/R000001/analysis/text.tsv \
  --visual .cache/runs/E0113/R000001/analysis/visual.tsv \
  --outdir .cache/runs/E0113/R000001/plot
```
