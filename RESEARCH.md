# Research conventions

How experiments, runs, decisions and artifacts are recorded. The rules exist so
that every number this project publishes can be regenerated from data nobody
edited afterwards.

The infrastructure is git, Markdown, TOML, JSON and JSONL. If `git grep`, GitHub
search or a generated static index can answer a question, that is the answer.
Adding a database or a service requires a decision record arguing that the pain
is real.

---

## Experiments

One directory per experiment: `research/experiments/E<NNNN>-<slug>/`, containing
`manifest.yaml`, and after completion `report.md`.

```yaml
id: E0003
title: ImplIR and minimum model size
question: >
  Does expressing semantic-rule implementations in ImplIR rather than Fortran
  reduce the smallest model that can produce an accepted implementation?
status: draft            # draft | running | reported | abandoned
opened: 2026-08-11

repos:                   # pinned, exact
  lazy-fortran-new: a15bfe2
  standard-new: 81c2ac4

inputs:
  standard: j3-24-007
  profile: core0-v1
  rules: research/experiments/E0003-implir-model-scaling/rules.txt

variables:
  representation: [fortran, implir]
  model: ["0.5b", "1.5b", "3b", "7b", "14b"]

metrics: [accepted, attempts, input_tokens, output_tokens, wall_s, cost_usd]

analysis: research/experiments/E0003-implir-model-scaling/analyse.sh
```

Two rules about the question field. State it so it can come out either way, an
experiment whose manifest cannot describe a disappointing result is not an
experiment. And name the metrics before running anything, so that the choice of
metric is not made after seeing the data.

`scripts/experiment.sh new "<question>"` allocates the next ID and writes the
manifest from the template.

---

## Runs

Every attempt is a run. One JSON object per line, appended to
`research/runs/<YYYY-MM>.jsonl`. One line, not pretty-printed, so the file stays
greppable and safe to append to concurrently.

```json
{"run":"R000341","experiment":"E0003","rule":"C851","method":"LLM","model":"qwen-1.5b","representation":"implir","standard_commit":"abc1234","generator_commit":"def5678","origin":"LLM","status":"accepted","attempts":2,"input_tokens":1834,"output_tokens":194,"wall_s":1.43,"cost_usd":0.0004,"verification":{"parse":true,"typecheck":true,"tests":true,"mutation":true},"prompt":"artifacts/model/E0003/R000341.prompt.txt","response":"artifacts/model/E0003/R000341.response.txt"}
```

**Runs are append-only.** A run record is never edited after it is written. A
correction is a new run that supersedes the old one by ID, with
`"supersedes":"R000341"`. Editing history here is falsifying data.

**Failures are kept.** Deleting a failed run because it did not become
production code destroys the denominator of every rate this project reports.

Statuses: `accepted`, `parse_failure`, `type_failure`, `semantic_failure`,
`verification_failure`, `mutation_failure`, `performance_rejected`, `timeout`,
`compiler_crash`, `model_error`, `abandoned`.

Large payloads, prompts, responses, benchmark dumps, traces, are referenced by
path, never inlined. See "Artifacts" below for where they live.

---

## Origin labels

Every generated artifact carries exactly one:

| Label | Meaning |
|---|---|
| `MECHANICAL` | Deterministic generation from a specification |
| `SEARCH` | Enumeration or autotuning over a defined space |
| `SMT` | Solver-produced, including CEGIS |
| `LLM` | Model-produced, accepted on the first attempt |
| `LLM_REPAIR` | Model-produced after one or more repair cycles |
| `HUMAN` | Written by a person |
| `IMPORTED` | Taken from an external source, with provenance |
| `DIFFERENTIAL` | Derived from disagreement between oracles |

These labels are what eventually make statements like "96.8% mechanically
derived" possible. An artifact without one cannot be counted, which means it
cannot be published about.

---

## Decisions

`research/decisions/D<NNNN>-<slug>.md`:

```markdown
# D0003, No git submodules

Date: 2026-08-11
Status: accepted        # proposed | accepted | superseded by D#### 

## Context
What situation forced a choice.

## Decision
What was chosen.

## Rejected
What else was considered, and why not. Be specific; "too complex" is not a
reason.

## Reversal condition
What evidence would make this wrong. A decision with no reversal condition is a
preference, and should be written as one.
```

Decisions that change the plan are linked from `ROADMAP.md`.

---

## Artifacts

`artifacts/` contains **manifests only**. No payloads: no PDFs, corpora or
tarballs, and therefore no Git LFS.

```toml
# artifacts/standards/j3-24-007.toml
name        = "j3-24-007"
title       = "Fortran 2023 working draft"
url         = "https://j3-fortran.org/doc/year/24/24-007.pdf"
sha256      = "7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2"
bytes       = 9970124
pages       = 688
licence     = "J3/ISO, not redistributable"
retrieved   = "2026-08-11"
purpose     = "Primary normative source for StandardIR extraction (E1, E2)"
```

`scripts/fetch.sh` downloads into `.cache/`, gitignored, and verifies the
hash. A mismatch is a hard failure, never a warning. `git status` must be clean
after any fetch.

Run payloads follow the same rule: `artifacts/model/E0003/R000341.prompt.txt` is
a *path recorded in a manifest*, not a committed file, unless it is small,
textual and worth diffing. When in doubt, keep it out of git and record its
hash.

The searchable metadata stays small deliberately, so that GitHub search remains
a usable interface into the whole record.

---

## Indexes

`scripts/index.sh` regenerates `research/index.md` from manifests and run files:
experiments with their questions, run counts and status; rules with their
formalization, implementation, tests and verification state. The index is
generated, never edited. If a number is wrong, the fix is in the data or the
script.

---

## Papers

`papers/<slug>/` pins the runs it reports in `runs.txt`, one ID per line, plus
the repository commits and corpus hashes. Tables and plots are regenerated from
those runs by a script in the same directory. A paper never contains a
transcribed number that could have been generated.

A publication snapshot can be exported to an archival format later. That is not
allowed to complicate daily work.

---

## Reporting rules

Three, and they exist because `LESSONS.md` §6 and §7 document what happens
without them.

**Name the denominator.** A pass rate states what was skipped. A rate computed
over total-minus-skipped is reported alongside the strict rate, never instead of
it.

**Every number names its command.** A figure in any document is accompanied by
the command that regenerates it, or it is not written down.

**Gates have negative controls.** Any check the project relies on has a test
proving it can fail. A gate never observed failing is not evidence.
