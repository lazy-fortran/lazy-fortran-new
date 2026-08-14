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
  dense_primary:
    - Qwen/Qwen3-0.6B
    - Qwen/Qwen3-1.7B
    - Qwen/Qwen3-4B
    - Qwen/Qwen3-8B
    - Qwen/Qwen3-14B
  gemma_controls:
    - google/gemma-4-E2B-it
    - google/gemma-4-E4B-it
    - google/gemma-4-12B-it
    - google/gemma-4-26B-A4B-it
    - google/gemma-4-31B-it
  qwen_controls:
    - Qwen/Qwen3.5-27B
    - Qwen/Qwen3.5-35B-A3B

metrics: [accepted, attempts, input_tokens, output_tokens, wall_s, cost_usd]

analysis: research/experiments/E0003-implir-small-models/analyse.sh

denominator: >
  The complete predeclared set of eligible rules. Report exclusions and
  skipped rules separately from failures and accepted results.

independent_oracle: >
  The fixed behavioral or structural oracle used to accept a result. A
  round-trip between two implementations of the same algorithm is not enough.

toolchain:
  record_in_run: true
  fields: [compiler, fo, poppler, oracle_versions]
```

Two rules about the question field. State it so it can come out either way, an
experiment whose manifest cannot describe a disappointing result is not an
experiment. And name the metrics before running anything, so that the choice of
metric is not made after seeing the data.

`scripts/experiment.sh new "<question>"` allocates the next ID and writes the
manifest from the template.

Repository experiment IDs are zero-padded, such as `E0001`. The shorthand E1
may appear in prose and paper titles, but manifests, run records and links use
the full ID.

---

## Runs

Every attempt is a run. One JSON object per line, appended to
`research/runs/<YYYY-MM>.jsonl`. One line, not pretty-printed, so the file stays
greppable and safe to append to concurrently.

```json
{"run":"R000341","experiment":"E0003","rule":"C851","method":"LLM","model":"Qwen/Qwen3-4B","family":"qwen3-dense","representation":"implir","standard_commit":"abc1234","generator_commit":"def5678","oracle_commits":{"gfortran":"...","lfortran":"..."},"toolchain":{"compiler":"...","fo":"...","poppler":"..."},"origin":"LLM","status":"accepted","attempts":2,"input_tokens":1834,"output_tokens":194,"wall_s":1.43,"cost_usd":0.0004,"verification":{"parse":true,"typecheck":true,"tests":true,"mutation":true},"prompt":"artifacts/model/E0003/R000341.prompt.txt","response":"artifacts/model/E0003/R000341.response.txt"}
```

For a deterministic production slice, the record additionally names `kind` as
`production-slice`, the repository, exact `base_commit` and resulting
`commit`, the task branch/worktree state, and the independent-oracle result.
The `verification` object must include the repository's full `fo` result and
the introduced warning count. A production commit is not an accepted run
merely because its own tests pass; the coordinator must verify the base, diff,
scope, oracle and cleanup independently.

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

### Agent episodes

Experiments that let a model call tools retain one append-only JSONL episode
trace per row. The trace records the validated tool name and arguments,
source-result IDs and byte counts, call and tool duration, token counts when
available, finish reason, gate state and terminal result. The experiment
manifest fixes tool names, output limits, call/submission budgets, checkpoint
rules and the complete model/protocol matrix before execution. A tool result
must be replayable from the pinned source and must not contain a hidden answer.
Missing, unavailable and inapplicable cells are recorded explicitly; they are
not removed from the denominator. A model-produced abstention is a measured
false negative unless the experiment's manifest explicitly defines a different
endpoint.

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

`research/decisions/D<NNNN>-<slug>.md`, from `TEMPLATE.md`. Four sections:
Context, Decision, Rejected, Reversal condition.

**The body is immutable once accepted.** Context, Decision, Rejected and
Reversal condition are never rewritten. This is the same rule that governs
runs, for the same reason: a reversal condition can only be checked against
what was actually believed at the time, and an edited record silently becomes
a description of what we believe now.

To change a decision, write a new record. The Status line of the old file is
the only part that may then be edited, and only to point at the successor.

### Status vocabulary

| Status | Meaning |
|---|---|
| `proposed` | Written, not yet in force. Body may still change. |
| `accepted` | In force. Body frozen. |
| `superseded by D####` | Replaced wholesale. The successor makes the choice. |
| `amended by D####` | Still in force, with the successor narrowing or extending it. |
| `retracted` | Withdrawn without replacement. The successor explains why nothing replaces it. |

The successor carries the matching header: `Supersedes:`, `Amends:` or
`Retracts:`. Both directions are recorded so the chain reads forwards and
backwards, and `scripts/index.sh` generates the live table from the headers
rather than from a hand-maintained list.

### Writing a successor

Say what the earlier reasoning got wrong, not merely what is now preferred. A
successor that only states the new choice loses the most useful thing in the
record: the failure mode that was not anticipated. If the earlier decision was
right on the evidence available and wrong on evidence that arrived later, say
that too, because it is the difference between a mistake and a discovery.

Decisions that change the plan are linked from `ROADMAP.md`.

### Decision handoff and implementation gate

The decision ledger is the planning interface. When work encounters a choice
that can change architecture, representation, scope, profile membership,
external format, oracle policy, performance target, model use or repository
boundary, search the ledger before writing code. If no accepted record covers
the choice, create a proposed record with a `## Decision needed` section and
list the concrete alternatives, the evidence available, and the consequence of
each choice. Under D0028, the agent accepts the record itself when the
evidence and the default principles determine the choice. A planning model or
the user is asked only when the principles do not determine it, requirements
conflict, or new authority is required.

Implementation may proceed under an accepted record. A local reversible default
may be recorded in the work update without a new decision only when it does not
change the roadmap or an interface. Otherwise the agent decides and accepts
the proposed record under D0028 when possible. It stops at the proposed record
only for an unresolved boundary. `scripts/check-decisions.sh` validates IDs, statuses, section
headers and successor links. `scripts/new-decision.sh "title" [slug]` allocates
the next ID from `TEMPLATE.md`.

Every commit that implements a nontrivial decision names its decision ID in the
commit body, changed-document link or experiment manifest. `scripts/index.sh`
publishes all proposed decisions in a handoff table.

---

## Parallel production work

`lazy-fortran-new` is the sole planning and evidence repository. A production
slice is delegated to one native Codex subagent with one exact sibling
checkout, branch, base commit, file scope and test command. The coordinator
first checks status and branch divergence. The checkout/worktree must be clean
and exclusive to that task. The subagent uses GPT-5.6 Luna and writes no
laboratory files. `~/code/prompts/scripts/gpt-delegate.sh` is reserved for
bounded reproducible `codex exec` experiments and transcripts.

The subagent report contains:

```text
repository, branch/worktree, base commit, resulting commit
allowed paths and forbidden paths
changed files
commands and tests, including independent-oracle results and warnings
decisions encountered
experiment or run record needed
blockers and suggested next slice
```

After a completion report has arrived and its commit has been recorded, the
coordinator closes that completed agent before launching another wave. This is
resource cleanup, not status polling: leaving completed agent threads open can
exhaust the native concurrency limit while no productive work is running.
Active agents are never closed or inspected without a completion event or an
explicit user request.

Independent slices may run concurrently only when their repositories and file
scopes do not overlap. The central agent is the only one that turns reports
into accepted decisions, experiment manifests, append-only runs, provenance
entries, roadmap changes or cross-repository commit pins. Production commits
contain production code, specifications, generated source and tests. Research
metadata stays here.

The coordinator records the model, prompt/log paths or hashes, production commit
and dependency pins in the append-only run record. A commit is reported as
`committed` until its base, diff and gates are independently checked. Only then
is it `integrated`.

## Contracts and integration lifecycle

`contracts/` is the sole central authority for cross-repository interface
revisions. `.sxs` schemas are authoritative. Fixtures are canonical witnesses.
The coordinator records the contract revision, source pins and production
commit together in the run record. Contract revisions are additive by default.
breaking changes require a new revision, a decision and a migration slice.

Integration is intentionally frequent. Once a committed slice has passed its
base, scope, diff, independent-oracle and repository gates, the coordinator
merges it into the target main integration line and records the merged commit.
The clean task worktree and local branch are then removed. A remote task branch,
if one was published, is deleted after the merge. An abandoned slice is
recorded with its last commit and failure state before the same cleanup. No
force deletion is used for dirty or unmerged state without explicit authority.

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

`scripts/index.sh` regenerates `research/index.md` from manifests and run files.
It lists experiments with their questions, run counts and status, and rules
with their formalization, implementation, tests and verification state. The index is
generated, never edited. If a number is wrong, the fix is in the data or the
script.

### Reading a run's artifacts

The payloads themselves live in the gitignored cache, so nothing above shows
them. `scripts/browse.sh` prints the file index of one run directory, and serves
a read-only local viewer for the SX, EBNF, ANTLR4, Bison, tree-sitter and
generated Fortran in it, with the manifest and ledger run beside each file:

```sh
scripts/browse.sh index --run E0074/R000001    # or --run R000083, the ledger ID
scripts/browse.sh serve --run E0074/R000001    # http://127.0.0.1:7373/
scripts/browse.sh selftest
```

It is a viewer and nothing else: read-only, loopback only, no stored state, no
dependencies, and no gate depends on it. `research/decisions/D0039-disposable-local-artifact-browser.md`
states the bounds and what would mean deleting it, and `scripts/browse/README.md`
documents the commands.

### Grammar export oracle gate

An exporter completing successfully is not evidence that its grammar is a
usable parser input. For every source-valid StandardIR grammar run, execute the
E0147 validator procedure against the same run directory:

```sh
research/experiments/E0147-can-source-backed-standardir-validity-close/validate-grammar-exports.sh \
    .cache/runs/E0147/R000001
```

The procedure runs ANTLR4, Bison and tree-sitter independently, records their
versions, exit codes and complete logs, and records EBNF as a projection-only
format with no external parser validator. Undefined symbols, dropped source
mapping and fatal validator errors are failures. Warnings remain in the run
record and must be explained; they are never converted to success by deleting
rules or editing generated files. A source-validity subgate may therefore be
accepted before this downstream gate, but it cannot close the experiment or
unlock semantic/model work.

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

**Name the independent oracle.** Generated code is accepted against fixed
expected bytes, a seed implementation, a behavioral oracle, or an independently
constructed witness set. Agreement between two generated consumers alone does
not establish correctness.

**Every number names its command.** A figure in any document is accompanied by
the command that regenerates it, or it is not written down.

**Gates have negative controls.** Any check the project relies on has a test
proving it can fail. A gate never observed failing is not evidence.
