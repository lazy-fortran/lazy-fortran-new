# E0112 report

Status: no reliable configuration found.

The reproducible summary table is generated with:

```text
python3 research/experiments/E0112-can-model-ladder-converge-source-cited-residue/record-attempts.py \
  --out .cache/runs/E0112/R000001/attempts.tsv
```

The figure is generated with:

```text
python3 research/experiments/E0112-can-model-ladder-converge-source-cited-residue/plot-convergence.py \
  .cache/runs/E0112/R000001/attempts.tsv \
  --outdir .cache/runs/E0112/R000001/plot
```

## Result

The corrected pointer protocol produced no novel, validator-accepted fact.
Every accepted model proposal was one of the deterministic E0110 overlap
rows. The 27B model made fewer invalid proposals than the 4B and 35B-A3B
models. The Gemma 26B-A4B run was fastest among the timed corrected runs.
None passed the reliability gate: all had at least one strict rejection, and
the two-attempt requirement was not satisfied for the single-attempt models.

The timed corrected runs were:

| configuration | accepted | rejected | errors | overlap agreements | seconds/row |
| --- | ---: | ---: | ---: | ---: | ---: |
| Qwen 3.6 35B-A3B, attempt 1 | 5 | 29 | 0 | 5 | 1.18 |
| Qwen 3.6 35B-A3B, attempt 2 | 5 | 28 | 0 | 5 | 1.20 |
| Qwen 3.6 27B | 5 | 5 | 0 | 5 | 1.54 |
| Gemma 4 26B-A4B | 4 | 10 | 0 | 4 | 0.65 |
| DeepSeek V4 Flash cloud | 5 | 38 | 0 | 5 | 1.02 |

The earlier raw-citation Qwen runs remain in the table as protocol controls.
They are not capability results: they copied exact source bytes in the model
response and consequently mixed model failures with citation-format failures.
The corrected pointer runs reconstruct citations deterministically and are the
relevant comparison.

The attempted Qwen 3.6 35B-A3B thinking-on load was interrupted before a
127-row result existed and is not represented as a completed configuration.

DeepSeek V4 Flash was tested separately through the official cloud
OpenAI-compatible endpoint with `DEEPSEEK_API_KEY` supplied at runtime. The
credential is not recorded in the lab or brain; its source is the encrypted
chezmoi-managed `~/.config/slopshell/deepseek.env`. The cloud run is a control
for model capability, not a replacement for the local-model ladder.

## What the protocol does and does not test

The denominator is the complete 127-row E0106 residue. The model does not,
however, receive the complete PDF for each row. It receives one mechanically
selected 384-byte canonical-text window. The experiment therefore tests safe
local classification of supplied evidence, not full-document discovery.

Most residue names occur in the supplied window as the right-hand side of a
different production, or as an ordinary use. A safe model should abstain.
Invalid proposals were cases where a model nevertheless reversed a grammar
relation or treated a right-hand-side occurrence as a definition.

The next experiment should add a deterministic retrieval stage: search the
whole canonical source for candidate subject-position definitions, then give
the model the bounded candidate windows. The current pointer validator and
source reconstruction should remain unchanged.

## Prompt audit

The instructions are narrow enough to make the oracle meaningful but are not
tuned to individual Fortran rules. The generic parts are candidate identity,
source-window isolation, an explicit abstention option, a finite relation
vocabulary, and a deterministic evidence pointer. The Fortran-specific parts
are the current residue names, the normative grammar relation forms, and the
E0106/E0110 source artifacts.

The relation vocabulary is intentionally incomplete for the current bounded
experiment. It must not be mistaken for a general StandardIR definition
language: prose definitions, tables, `shall` constraints and cross-clause
relations require separate retrieval and recognizers.

A native `gpt-5.6-luna` control independently judged the supplied windows, but
it did not emit a validator input artifact. Its result is retained in the
conversation as a qualitative control and is not mixed into the quantitative
plot.
