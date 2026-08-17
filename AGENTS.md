# lazy-fortran-new

The laboratory for the specification-generated Lazy Fortran compiler program.
It holds the architecture, the historical evidence, the experiments, the runs,
the decisions and the papers. The compiler itself is built in separate
production repositories, which this one coordinates but does not contain.

General Fortran, git, and agent rules live in `~/code/prompts/AGENTS.md` and
`~/code/prompts/rules/fortran.md` and always apply. This file records only what
is specific to this repository.

**The forbidden direction.** This repository must not grow a compiler, a
database, or an orchestration framework. Research state is Markdown, TOML, JSON
and JSONL in git. If `git grep`, GitHub search, or a generated static index can
answer a question, that is the answer. Do not add a system. When some future
pain proves a tool necessary, write a decision record first. The accepted
successor D0082 permits one disposable, read-only, loopback research-library
view in `scripts/browse/`; it may not write state, trigger work, expose
arbitrary paths, or become a production service.

## Layout

- `WHITEPAPER.md`: the program's thesis and method. The central document.
- `DESIGN.md`: repository hierarchy, StandardIR, ImplIR, contracts.
- `LESSONS.md`: what the existing toolchain's history demonstrates, with
  commit-level evidence and counter-evidence.
- `ROADMAP.md`: phases, current position, what blocks what.
- `STATUS.md`: mutable central delivery state.
- `MILESTONES.md`: central cross-repository definitions of done.
- `RESEARCH.md`: how experiments, runs and decisions are recorded.
- `repos.toml`: production repositories and oracle repositories.
- `scripts/`: clone, status, update, fetch, experiment and index helpers, plus
  `browse.sh`, the disposable read-only viewer for cached run artifacts (D0039).
- `research/experiments/`: one directory per experiment, `E<NNNN>-<slug>`.
- `research/runs/`: append-only JSONL, one file per month.
- `research/decisions/`: one file per decision, `D<NNNN>-<slug>.md`.
- `research/corpora/`: corpus manifests, never corpus contents.
- `artifacts/`: small manifests, trace indexes and reviewed reports only;
  payloads remain in the ignored cache. See the provenance gate below.
- `papers/`: one directory per paper, each pinning the runs it reports.
- `docs/self-hosting.md`: the two IRs, their serialization, and the bootstrap.
- `docs/text-representation.md`: how text is held, and why not as strings.
- `docs/literature.md`: prior art, with what each reference is used for.
- `docs/provenance.md`: licence classes, the consultation log, artifact pins.
- `docs/glossary.md`: terms as this project uses them.
- `docs/goal-mode.md`, `docs/cross-repo-protocol.md` and
  `docs/oracle-policy.md`: central delivery-control rules.

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
licence, retrieval date, and what it is used for. Small central integration
trace manifests and reviewed reports may also be committed under
`artifacts/manifests/`, `artifacts/traces/` and `artifacts/reports/`; large
payloads remain in the gitignored cache. `scripts/fetch.sh` downloads into a
gitignored cache and verifies the hash. A hash mismatch is a hard failure,
never a warning. `git status` must be clean after any fetch.

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
2. Reference large payloads by path under `artifacts/`. Never inline them.
3. Never edit a line that is already written.

### Add a decision

1. `research/decisions/D<NNNN>-<slug>.md`, from `TEMPLATE.md`.
2. Record what was decided, what was rejected, and what evidence would reverse
   it. A decision with no reversal condition is a preference.
3. Create a `proposed` record with a `## Decision needed` section when the
   choice is not determined by an accepted decision or D0028. Under D0028,
   accept the record yourself when the evidence and the default principles
   determine the choice. Do not leave it open merely as a handoff.
4. Link it from `ROADMAP.md` or the document whose plan it changes, then run
   `scripts/index.sh` and `scripts/check-decisions.sh`.
5. Keep implementation commits separate from accepted decision commits when
   practical, so the planning handoff can review the choice independently.

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

### Decision trigger

Before implementing a nontrivial choice about architecture, representation,
scope, profile membership, external format, oracle policy, performance target,
model use or repository boundary, search the decision ledger. If no accepted
decision covers it, write a proposed decision before coding, then accept it
yourself when D0028 and the evidence determine the choice. Stop for the
planning model or user only when requirements conflict, evidence is materially
insufficient, the change is irreversible beyond scope, or new authority is
needed. A later implementation must link the accepted decision in its commit
or experiment record.

## Parallel production slices

The laboratory is the planning and evidence authority. Production agents work
in the assigned sibling checkout, not here, and never edit laboratory metadata.
The central roadmap supplies one bounded slice per agent. Slices must have
non-overlapping files and an exact base commit. Before launch, the coordinator
checks that the assigned checkout or worktree is clean, on the expected branch,
and at the recorded base. Two agents never share a mutable worktree.

Use native Codex subagents with GPT-5.6 Luna for parallel production slices.
Use reasoning effort `medium` by default. Low effort is not permitted for
semantic fixture generation or review. A higher effort requires a task-specific
blocker recorded by the coordinator.
Give each subagent the absolute assigned checkout path, branch, exact base
commit, file scope and test command; for example, `/home/ert/code/standard-new`
or `/home/ert/code/fortback-new`.

Launch independent subagents in parallel only when their repository, branch and
file scope do not overlap. The prompt must require a concise report of base
commit, branch/worktree, allowed paths, commit, changed files, commands run,
independent-oracle results, warnings, decisions encountered, experiment needed
and blockers. Agents may commit only within their assigned production
repository. Agents do not push: after a verified component or central commit,
the coordinator pushes it in the same cycle and verifies that the configured
remote contains the revision before reporting it integrated or synchronized.
A durable commit left only in a local clone is `BLOCKED`, not complete. Let
native Codex manage the subagent lifetime and result collection; use its
managed wait/result mechanism when a result is needed. Do not background or
self-poll processes.

After reports arrive, the central agent checks the commits, runs the relevant
gates, writes or updates decisions and experiments, appends runs, updates the
roadmap, and records exact production commit pins. A committed result is not
called integrated until its base, diff and gates have been checked. Do not
create a task runner or shared service for this workflow.

### Coordinator work during agent waves

While production subagents are active, the coordinator must immediately take
an independent laboratory task when one is ready: run the next experiment,
prepare its manifest and analysis, verify source pins, update decisions or
roadmap metadata, or perform another non-overlapping evidence task. Do not sit
idle waiting for agent reports. The laboratory task must not edit an agent's
checkout, assigned production paths, or an unverified result, and it must not
become an automatic polling loop. If no safe laboratory task exists, record
that reason and return control rather than inventing parallel work.

Every wave launch therefore has two explicit scopes: the production slices
assigned to native Luna agents and the coordinator's independent laboratory
slice. The coordinator integrates production results only after their reports
arrive and the normal review gates pass.

### Fast fixture harvest waves

For a fixture harvest, freeze the source ledger, StandardIR inputs, contract
schema and batch output schema before dispatch. Partition source rows across
disjoint worktrees or report scopes. Workers return provisional JSONL batches
with semantic packet origin `LLM`. They do not edit central metadata, commit,
push or promote semantic facts.

The controller performs one batch intake pass for shape, duplicate keys,
source identity and hashes. It may mechanically rebind source envelopes to the
pinned ledger, but it does not rewrite semantic packet fields. Malformed
packets remain retained failures. The controller records one ready/review/
rejected result for the wave.

Implementation begins after the current harvest batch passes structural intake.
Independent ready candidates may then be implemented in parallel while later
harvest continues. Each selected candidate still requires its own contract,
independent oracle, mutation controls and clean replay. Central metadata is
updated once per wave. Provisional packets do not receive per-case decision
records or review reports until selected for implementation or promotion.

### Contracts, waves and cleanup

The lane views under `roadmaps/` and the versioned SX schemas under
`contracts/` are central coordination metadata. A production task consumes the
exact contract revisions named in its assignment. Contract changes are
additive by default. A breaking change gets a new central revision, decision
record and migration slice. Production repositories do not copy the research
ledger or add local roadmaps.

Use dependency-ready waves. One vertical slice is the default unit: one
exclusive worktree, one short-lived branch, one exact base and one verifiable
commit. Merge verified slices frequently into the target repository's main
integration line rather than accumulating a long-lived lane branch.

After merge and the relevant CI gate, record the merged commit and remove the
clean task worktree and local branch. If a task branch was published, delete
the remote task branch after the merge. For an abandoned task, record its last
commit and failure first, then perform the same cleanup. Never force-delete a
dirty worktree or an unmerged branch without explicit authorization. The
coordinator owns these lifecycle actions. Agents do not delete shared state.

## Documentation rules

No marketing language. No emoji, and no severity shouting. Terse, specific, and
falsifiable. The existing repositories in this house contain both the good and
the bad versions of this. `fortplot/AGENTS.md` and `fo/CLAUDE.md` are the models,
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
3. `bash -n` passes on every script. `scripts/fetch.sh` fails loudly when given
   a corrupted expected hash. A verifier that cannot be made to fail is not
   evidence that anything was verified. `scripts/check-contracts.sh` validates
   every central contract schema and witness, including its negative control.
4. Prose has been through the `deslop` skill and `fo` is green wherever Fortran
   exists.

## Cross-repository control-plane rule

This repository is the sole coordination and Goal Mode control plane for the
Lazy Fortran generated compiler program.

All cross-repository state belongs here: the active milestone, component pins,
contracts, end-to-end fixtures, oracles, reproducibility commands, integration
traces and accepted or rejected decisions. `standard-new`, `fortfront-new`,
`ffc-new` and `fortback-new` are implementation repositories. Do not create
independent project-management loops, milestone ledgers or research ledgers in
them.

For cross-repository work:

1. Read `repos.toml`, `STATUS.md`, `MILESTONES.md` and the active contracts.
2. Pin every consumed component revision and relevant artifact hash.
3. Make code changes in the correct component repository and commit them there.
4. Update the central pin and integration evidence here.
5. Run the central end-to-end verification command from this repository.
6. Commit central evidence only after the complete slice passes.

A component-local build or test is necessary but never sufficient for a
cross-repository milestone.

## Persistent Goal Mode operating system

`TASK_POOL.yaml`, `STATUS.md`, `MILESTONES.md` and
`docs/operating-loop.md` are the local control-plane entry points. At fast-cycle
entry read `AGENTS.md`, `STATUS.md`, `TASK_POOL.yaml`, the active task and its
named verifier/evidence. Load the roadmap, contracts, component records and
review protocols only when the active task names them or an integration cycle
requires them; reconcile the full map at integration.

Use one active task and one verifier per fast cycle. Central status changes
only from that verifier and its independent oracle. Component-local success,
provenance, generated code, hashes, traces and architecture prose are not
delivery evidence unless the central fixture consumes them. Historical runs
whose clean-checkout conditions are not verified for this checkout are
`NEEDS REPLAY` and cannot promote a milestone.

Use installed skills by trigger rather than copying their protocols here:
`program-loop` and the relevant domain skill are the baseline;
`evidence-gate`, `parallel-luna`, `bounded-exploration` and
`expert-escalation` activate only at their stated boundaries. `fortran` owns
the local Fortran workflow; `referee` is for manuscript review only.

For cross-repository work, pin consumed revisions, commit component changes
first, then update the central pin and run the central end-to-end verifier.
Do not start L2 or a second fixture family while the preceding replay gate is
open. Durable state changes are pushed and remotely verified; scratch work is
not.
