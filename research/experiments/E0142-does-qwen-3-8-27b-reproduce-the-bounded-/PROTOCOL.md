# E0142 protocol

E0142 is wired but intentionally unstarted. It repeats the existing semantic
experiments with the logical model profile `qwen38-27b` and the currently active
local llama.cpp service at:

```text
http://127.0.0.1:8080/v1/chat/completions
```

The harness must not start, stop, reload or reconfigure that service.

## Preflight

Before any model call, record the server-reported model identifier, model hash,
llama.cpp commit/build, quantization, context size, KV-cache type, flash
attention, sampler settings, reasoning configuration and endpoint. If the
server does not advertise image input, the E0114 visual cell is terminal
`not_applicable`.

The logical profile is `qwen38-27b`; the current server advertises request ID
`qwen`. Runs record both values and never infer the profile from a model name
alone. The current preflight reports multimodal capability, so E0114 is
applicable unless a later preflight says otherwise.

## Matrix

Run the existing protocols without changing their gates:

```text
E0112/E0113/E0115  fixed-window | full-retrieval | bounded-tools
E0114              visual-first page control when image-capable
E0116              typed predicates over 287 constraints
E0117              required witnesses over 287 constraints
E0123              exact 53-row retry plus 234 immutable controls
```

Each applicable cell begins with reasoning off. A failed cell receives at most
one fresh reasoning-on episode under its existing finite budget. The trace is
append-only and records every model turn, native tool call, source byte range,
submission, rejection, retry, token count, wall time and terminal status.

The deterministic side performs source segmentation, citation and hash checks,
cross-reference resolution, predicate/schema validation, witness construction,
replay and exact row-key merging. The model sees one local task plus bounded
source tools; it never owns fact vocabulary, dependency wiring, promotion or
compiler architecture.

The declarative campaign index and shared collector are in `campaign.toml` and
`plot_campaign.py`. The seven `plots/plot-E*.py` entry points select a protocol
but share all collection and rendering code. They scan terminal summaries under
`.cache/runs`, so a new model row appears automatically when its existing
protocol postprocessor writes the declared summary format. They write PNG/PDF/
SVG only below the ignored run area; each PNG is uploaded separately after its
experiment becomes terminal.

For the semantic cells, deterministic extraction first supplies the numbered
constraint, definitions, cross-references, source spans, known fact vocabulary
and dependency candidates. Repeated source forms are compiled mechanically.
The model may only return a schema-valid local fragment; schema validity is not
acceptance. Source provenance, independent replay and an independent witness
gate decide whether a proposal becomes an accepted ledger entry. The terminal
states remain `candidate`, `schema_valid`, `source_valid`, `witnessed`,
`accepted`, `unresolved` and `disputed`; no repair step may invent facts,
citations, dependencies or wiring.

When reproducing an older Qwen 3.6 run, pass its pinned model and endpoint
explicitly. The new default profile is for new runs only. Historical manifests
and append-only run records are not rewritten.

The unified evidence browser is `scripts/browse.sh serve`. It is a read-only
loopback view of the library, not an experiment runner. While a cell is active,
open its case browser and run-progress card to inspect prompts, responses, gate
records and the heartbeat/ETA. The rule register, pipeline flows and source
library connect those cases to StandardIR, MIR, TargetIR, ISA, ABI and
microarchitecture material without copying it into this experiment.

No later cell is started by creating this file. E0112 is the first active cell;
its terminal validation must complete before the next protocol is launched.
Before each cell, pin the preflight values in the run manifest. Adding another
model requires a model profile and a run cell, not a copied plot
implementation.
