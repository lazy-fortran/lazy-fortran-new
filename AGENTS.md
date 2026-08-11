# lazy-fortran-new

The laboratory for the specification-generated Lazy Fortran compiler program.
It holds the architecture, the historical evidence, the experiments, the runs,
the decisions and the papers. The compiler itself is built in separate
production repositories, which this one coordinates but does not contain.

General Fortran, git, and agent rules live in `~/code/prompts/AGENTS.md` and
`~/code/prompts/rules/fortran.md` and always apply. This file records only what
is specific to this repository.

**The forbidden direction.** This repository must not grow a compiler, a
service, a database, a dashboard, or an orchestration framework. Research state
is Markdown, TOML, JSON and JSONL in git. If `git grep`, GitHub search, or a
generated static index can answer a question, that is the answer. Do not add a system. When some future pain proves a tool necessary, write a
decision record first.

## Layout

- `WHITEPAPER.md`: the program's thesis and method. The central document.
- `DESIGN.md`: repository hierarchy, StandardIR, ImplIR, contracts.
- `LESSONS.md`: what the existing toolchain's history demonstrates, with
  commit-level evidence and counter-evidence.
- `ROADMAP.md`: phases, current position, what blocks what.
- `RESEARCH.md`: how experiments, runs and decisions are recorded.
- `repos.toml`: production repositories and oracle repositories.
- `scripts/`: clone, status, update, fetch, experiment and index helpers.
- `research/experiments/`: one directory per experiment, `E<NNNN>-<slug>`.
- `research/runs/`: append-only JSONL, one file per month.
- `research/decisions/`: one file per decision, `D<NNNN>-<slug>.md`.
- `research/corpora/`: corpus manifests, never corpus contents.
- `artifacts/`: manifests only. See the provenance gate below.
- `papers/`: one directory per paper, each pinning the runs it reports.
- `docs/self-hosting.md`: the two IRs, their serialization, and the bootstrap.
- `docs/text-representation.md`: how text is held, and why not as strings.
- `docs/literature.md`: prior art, with what each reference is used for.
- `docs/provenance.md`: licence classes, the consultation log, artifact pins.
- `docs/glossary.md`: terms as this project uses them.

`docs/` deliberately does not restate the architecture. `DESIGN.md` is the
overview and the production repositories own their own detailed specifications.
Duplicated documentation is what `19a3537` deleted seven thousand lines of.

## The boundary

This repository is the laboratory. `standard-new`, `fortfront-new`, `ffc-new`
and `fortback-new` are production components. The split is not stylistic.

What belongs here: research questions, experiment manifests, run records,
model transcripts, benchmark histories, abandoned approaches, cross-repository
wiring, historical analysis, papers, and the reasoning behind any decision that
touches more than one repository.

What belongs there: the code that produces the compiler, its specifications,
its generated output, and the tests that establish it is correct.

Consequences in both directions. A production repository that accumulates
research notes becomes unreadable as a software component, and its history
stops being a record of the software. This is what happened to the old
`standard` repository, where `19a3537` eventually deleted about seven thousand
lines of audit documentation in one commit. A laboratory that accumulates
production code stops being a record of the science, because the code starts
being maintained for its own sake rather than kept as evidence of what was
tried. Neither drift announces itself. Both are noticed only once the repository
is unpleasant to work in.

The practical test when you are unsure where something goes: if it would still
matter after the component it describes was rewritten from scratch, it belongs
here.

**Nothing is inherited from the old repositories, and nothing is deliberately
unlearned.** No API contract, module boundary, naming scheme, data structure,
error convention or test harness from `standard`, `fortfront`, `ffc`, `fortad`
or `fluff` constrains this work. There is no compatibility requirement in either
direction, and a new design is free to differ completely. At the same time, the
good parts are imported deliberately rather than rediscovered. `LESSONS.md`
ends with the list of practices to take directly. Read the old repositories
freely. Copy their proven gates. Do not copy their shapes by default.

## Provenance gate

These are the rules this repository exists to enforce. A change that violates
one of them is wrong even if everything else about it is right.

**Nothing external is vendored.** Not standards documents, not grammars, not
ISA specifications, not corpora, not compiler sources. Each external artifact
gets a manifest under `artifacts/` recording its URL, SHA-256, byte size,
licence, retrieval date, and what it is used for. `scripts/fetch.sh` downloads
into a gitignored cache and verifies the hash. A hash mismatch is a hard
failure, never a warning. `git status` must be clean after any fetch.

**Every generated artifact carries an origin label**, one of `MECHANICAL`,
`SEARCH`, `SMT`, `LLM`, `LLM_REPAIR`, `HUMAN`, `IMPORTED`, `DIFFERENTIAL`.
Without this the program cannot answer the question it exists to ask.

**Every StandardIR entry cites its source**: document, clause, rule number,
page, and the source document's hash. An entry that cannot cite the document is
not a formalization of it.

**Runs are append-only.** A run record is never edited after it is written. A
correction is a new run that supersedes the old one by ID. Rewriting history
here is falsifying data, not tidying.

**Failures are kept.** `parse_failure`, `verification_failure`,
`performance_rejected`, `timeout`, `model_error` are results. Deleting a failed
run because it did not become production code destroys the denominator of every
rate this program reports.

**Grammar productions are not copied.** Anything that derives grammar or
semantics from the standard derives it from the standard. Do not lift
productions out of the existing `.g4` corpus in `lazy-fortran/standard`, or out
of LFortran or Flang, into StandardIR. Those grammars are comparisons, and they
may be wrong.

This is a rule about how one artifact is derived, not a blindfold. Reading those
grammars to understand the problem, to decide what to build, or to adjudicate a
disagreement afterwards is expected and is recorded. The project's goal is to
demonstrate that a specification-generated compiler works, not to prove it was
built in isolation, and any model used here was trained on Fortran compilers
anyway, so a claim of information isolation would be a fiction. The separate
restriction on GPL sources below is legal, and that one is absolute.

## Licence and clean-room boundary

New work here is MIT. The oracle compilers are not, and the distinction matters
legally, not just tidily.

- **GPL sources (gfortran, and the GCC tree).** Behavioral comparison
  only. Run the binary, diff accept and reject decisions, diagnostics, and
  runtime output. Do not read `gcc/fortran/*.cc` or any other GPL
  implementation source while authoring the corresponding component of this
  project. This restriction is absolute and has no research exception.
- **Permissive sources: LFortran (BSD), Flang (Apache-2.0), the kaby76
  grammar corpus, Intel XED, Zydis, riscv-opcodes, Sail, the ARM machine
  readable architecture.** Source may be read. Every instance is logged in
  `docs/provenance.md` with what was read, when, and which artifact it
  informed.
- Downloading and hash-pinning solves redistribution. It does not solve
  contamination. Keep the two separate in your reasoning.

## Recipes

### Add a source document

1. Add a manifest to `artifacts/standards/` or `artifacts/isa/` with URL,
   SHA-256, size, licence, retrieval date, purpose.
2. Add its pin to `scripts/fetch.sh`.
3. Run `scripts/fetch.sh <name>`, then run it again. The second run must
   verify against the cache without re-downloading.
4. Confirm `git status` is clean.

### Add an experiment

1. `scripts/experiment.sh new "<question>"` allocates the next `E<NNNN>` and
   writes `research/experiments/E<NNNN>-<slug>/manifest.yaml` from the template.
2. State the question as something that can come out either way. An experiment
   whose manifest cannot describe a result that would disappoint you is not an
   experiment.
3. Pin every repository commit the experiment depends on.
4. Name the metrics before running anything.

### Add a run

1. Append one JSON object to `research/runs/<YYYY-MM>.jsonl`. One line, no
   pretty-printing, so the file stays greppable and append-safe.
2. Reference large payloads by path under `artifacts/`; never inline them.
3. Never edit a line that is already written.

### Add a decision

1. `research/decisions/D<NNNN>-<slug>.md`, from `TEMPLATE.md`.
2. Record what was decided, what was rejected, and what evidence would reverse
   it. A decision with no reversal condition is a preference.
3. Link it from `ROADMAP.md` if it changes the plan, then run
   `scripts/index.sh`.

### Change a decision

The body of an accepted decision is immutable, for the same reason runs are:
a reversal condition can only be checked against what was actually believed at
the time.

1. Write a new record carrying `Supersedes:`, `Amends:` or `Retracts:` with the
   old ID.
2. Say what the earlier reasoning got wrong, not only what is now preferred.
3. Edit the old file's `Status:` line, and nothing else, to point at the
   successor.
4. Run `scripts/index.sh`. The decision table is generated from the headers.

Statuses: `proposed`, `accepted`, `superseded by D####`, `amended by D####`,
`retracted`. `RESEARCH.md` defines them.

## Documentation rules

No marketing language. No emoji, and no severity shouting. Terse, specific, and
falsifiable. The existing repositories in this house contain both the good and
the bad versions of this; `fortplot/AGENTS.md` and `fo/CLAUDE.md` are the models,
`fortfront/CLAUDE.md` is not.

**Any number in a document must name the command that regenerates it.** Counts
of tests, rules, coverage or performance rot silently, and they rot in both
directions. `fluff/README.md` currently understates its own test health
because a cleanup landed and the README did not. A figure without a command
beside it is a claim about the past presented as a claim about the present.

State what is not done as plainly as what is. Bounded claims with named
refusals, in the style of `fortad/ROADMAP.md`, are the target.

## Quality gates before claiming done

1. Every commit hash cited in any document resolves in the repository it names:
   `git -C <repo> cat-file -t <hash>`.
2. Every file path cited in any document exists.
3. `bash -n` passes on every script; `scripts/fetch.sh` fails loudly when given
   a corrupted expected hash. A verifier that cannot be made to fail is not
   evidence that anything was verified.
4. Prose has been through the `deslop` skill and `fo` is green wherever Fortran
   exists.
