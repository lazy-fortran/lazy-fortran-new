# Roadmap

## Aim

Lazy Fortran tests whether a useful compiler can be derived from language and
target specifications with less material to maintain. Generation is a means,
not the product.

The optimization target is useful, verified compiler behavior per total
surface. Total surface includes handwritten code, generator code, declarative
input, generated output, tests, fixtures, documentation, and coordination
records, including the material a reviewer must inspect. Fewer reviewable lines
are the default preference, but line count is not a reason to compress clear,
testable code. A change should add a meaningful capability, improve correctness
or performance, or reduce that surface while preserving behavior.

## Architecture to keep

```text
Fortran standard -> compact StandardIR -> generic language engines
ISA, ABI, and object specifications -> compact TargetIR -> generic target engines
unresolved prose -> bounded LLM proposal -> checked typed fact
measured hot path -> optional deterministic specialization
```

The specification-derived compiler thesis survives in this form:

- Deterministic extraction handles structure that can be recovered reliably.
- StandardIR and TargetIR hold compact, cited facts rather than generated
  implementations for individual examples.
- Generic parsers, semantic passes, lowerers, and encoders consume those facts.
- An LLM proposes only facts that deterministic extraction cannot recover
  economically from prose.
- Accepted LLM output becomes ordinary typed data after independent checks.
- Specialization is optional and justified by measurement. The generic path
  remains the reference behavior.
- Provenance, source citations, and licence boundaries remain part of every
  derived fact.

Production runtime code remains modern Fortran. A build-time tool may use
another language when that gives a materially smaller and more reliable
implementation.

## Working defaults

These are defaults, not doctrine. A concrete failure, benchmark, or maintenance
cost may justify another route. Keep the explanation with the change instead
of creating a new process to authorize the exception.

- Define a goal as one finite user-visible capability, its corpus or fixture,
  its observable result, and an independent verifier.
- Close a goal when that capability passes. Do not reuse a passed goal as an
  open umbrella for unrelated work.
- Prefer the smallest complete vertical change across the components it needs.
- For ordinary implementation, edit, test, commit, and push. Add research
  records only for an explicit experiment, audit, release, or milestone
  promotion.
- Keep short-lived task detail in an issue, commit, or working note. Do not
  copy it into several permanent ledgers.
- Let one central fixture establish cross-component behavior. Component tests
  establish component behavior.
- Preserve failures that are part of a declared experiment. Ordinary failed
  development attempts need no permanent record beyond useful tests or commit
  history.

## Minimum-surface rule

The fastest route is the route that leaves the fewest lines for the next person
to understand, verify, regenerate, and maintain. This is the primary design
criterion for the active goal.

For every proposed change, compare the complete result, including handwritten
code, generator code, declarative input, generated output, tests, fixtures,
documentation, schemas, coordination records, and review steps. Choose the
change with the smaller total review surface when behavior and evidence are
equivalent. Keep a larger local implementation only when it buys a measured
capability, correctness property, performance result, or reusable mechanism.

The default implementation unit is one existing capability, one smallest
vertical change, one independent behavioral check, and one central replay.
Ordinary work creates no new ledger, report, schema, generator, fixture family,
or coordination procedure unless the existing interface cannot express the
capability or the new artifact is required for an independent check. A goal is
finished when its stated capability passes. It does not expand merely because
adjacent improvements remain available.

The specification-to-code pipeline remains justified only when its compact
facts and generic consumers reduce this total surface. Deterministic
extraction, checked LLM proposals, and optional specialization are means to
that reduction. If a generator, compatibility layer, or generated table adds
more review surface than the behavior it removes, keep the simpler explicit
representation and record the boundary in the roadmap.

## Fast execution rule

For two behavior-preserving designs, choose the one with the lower total
review surface. Count source, generator code, declarative input, generated
output, tests, fixtures, documentation, schemas, task records, reports, and
review material.

The execution loop is one existing capability, one smallest vertical change,
one independent behavioral check, and one central replay. Parallelize only
disjoint production files that already have a specified interface. Integrate
the verified commit immediately, push it, and continue from the next failing
boundary. Ordinary implementation adds only the code, tests, and central pin
or status line required to make the result reproducible.

Do not add a task record, decision, run, report, fixture, script, schema, or
generated table when the existing interface can express the change. Add one
only when it is required for a distinct capability, an independent oracle, or
reproducibility, and remove the superseded artifact in the same change when
possible.

## Surface discipline

- Prefer one general algorithm to branches generated for names, values, list
  lengths, source spellings, or test cases.
- Use compact tables, bytecode, tries, or automata when data drives behavior.
  Do not emit source ladders merely because source generation is convenient.
- Generated size should track distinct specification facts, not corpus size or
  the number of sampled witnesses.
- Keep one canonical representation of each fact. Derive other forms during
  the build or cache them when regeneration is cheap.
- Commit generated output only when consumers require a stable artifact or
  regeneration would be an unreasonable burden.
- Add a generator only when it lowers total surface, prevents a demonstrated
  class of defects, or produces a measured performance benefit.
- Treat schemas, task records, fixtures, review reports, and coordination
  steps as surface too. Before adding one, try the existing interface. Add the
  smallest new artifact only when the capability cannot be expressed there,
  and delete the superseded path in the same change when possible.
- Before an external consumer exists, change contracts in place when that is
  cheaper than maintaining compatibility machinery.
- Delete superseded generator code, generated policy, fixtures, and prose in
  the same change that makes them unnecessary.
- Prefer data-driven corpus tests and shared runners to one script per witness.

## Current baseline

The pinned components provide a bounded path from raw Fortran source through
StandardIR, frontend AST, MIR, RISC-V ELF output, and qemu execution. The
accepted slice includes a named main program, intrinsic scalar integer
declarations, bounded assignment and arithmetic forms, `STOP`, and
list-directed `PRINT`.

The baseline is verified by:

```sh
scripts/check_pins.sh
scripts/check-contracts.sh
tests/e2e/run-l3.sh --fresh
bash tests/e2e/check-generated-chain.sh
```

This proves the bounded path, not a general Fortran compiler. The current
implementation still contains fixture-specific source policies, sampled value
and cardinality bounds, repeated route scripts, and coordination text that
outgrows the capability it describes. Those artifacts are evidence of what
worked. They are not architectural commitments.

The first scalar-pipeline simplification is now in place. The
frontend now allocates one `output-items` list for pure integer PRINT values.
It now derives stored-variable PRINT lists from the existing initializer
parser. FFC lowers both representations through one generic item traversal,
with the fixed three-item `17, 18, 19` route removed. Fortback validates and
encodes pure-literal and stored-variable lists through generic paths, with one
count-driven validator replacing the fixed two-through-six item validators, and
its common initialized-expression checks now share one parameterized path.
The clean
bounded PRINT expression items now use one typed parser and the AST-v2
two-assignment expression reuses the generic expression parser. Fortfront's
initialized update parser now uses one operator/policy path and its variable
PRINT batch dispatch derives metadata from the parsed count instead of one
branch per historical item count, and its bounded assignment-sequence assembly
reuses one typed repeated-assignment path with generic span calculation. FFC's
initialized variable arithmetic uses
one parameterized MIR path without operator-specific wrappers, its legacy PRINT
route matcher uses one count-driven check for consecutive literal routes, its
variable PRINT counts 2 through 10 use one parameterized emitter and validator,
and its literal-list emitters share one constructor, and its AST-v2 literal-list
validators share one parameterized shape check. Its four initialized
literal-binary lowering branches now share one parameterized path. The central
replay routes for assignment counts 3 through 6 now share the existing runner,
count 2 retains its stricter negative control. Pure literal PRINT routes for
counts 2 through 10 also share one replay helper, while the standalone and
generic-item routes remain explicit. Stored-variable PRINT routes for counts
2 through 100 now use one count-driven replay loop, preserving the historical
oracle mode names for counts 2 through 6. That replay discovers fixture keys
and item counts from the source files instead of carrying a number-to-name
dispatch. The central gate
`bash tests/e2e/check-generated-chain.sh` passes 146 routes. General
Pure-literal PRINT routes use the same fixture-driven discovery and derive
their oracle mode from the source item count.
Assignment-sequence routes likewise derive their count and matching negative
controls from the fixture files.
binary-expression parsing now shares one parameterized token walk. General
variable-binary lowering now shares one opcode/name selection and validation
branch. General expression parsing, assignment sequences, and broader language
coverage remain open. FFC now uses generic AST-v1 assignment-sequence lowering
as the primary path for legal identifiers and integer literals. Fortback now derives the repeated
generated PRINT route-operation pattern from a compact rule with boundary
controls while retaining explicit exceptional route facts. Fortfront's generated PRINT policy
now validates legal variable names and the declared scalar value range.
Raw-source program-unit assembly remains open.
The raw-source program-unit envelope and legacy PRINT compatibility fields
remain explicit. Genericizing either is deferred until it reduces total review
surface without changing the public SX shape.

## Current goal: generic scalar pipeline

Replace the bounded scalar path with a compact generic implementation while
preserving its accepted behavior.

This is the only active implementation goal until it closes. The target path
is:

```text
Fortran source -> StandardIR and TargetIR facts -> generic frontend AST
-> generic MIR -> table-driven RISC-V backend -> qemu
```

Use one dependency chain at a time. Keep the current central replay green
through each boundary. Parallel work is useful only for already specified,
non-overlapping files that do not create another coordination layer.

The result should:

- accept unseen legal identifiers and integer values without regenerating
  branches for them
- parse scalar declarations, assignment expressions, `STOP`, and
  list-directed output through shared grammar and AST structures
- lower AST sequences and expressions through one generic MIR traversal
- validate and encode the required RISC-V instructions through compact target
  facts and a generic backend
- reject malformed neighboring sources and corrupted intermediate artifacts
- match an independent compiler or explicit behavioral oracle at the program
  boundary
- reduce total implementation, generated, test, and documentation surface, or
  document a measured reason where a local increase is necessary

The goal is complete when existing accepted scalar programs still pass, novel
unsampled programs pass, invalid neighbors fail, component `fo` gates pass,
and one clean central replay verifies the complete path.

## Simplification sequence

This is the implementation order for the active goal:

- First, stop extending fixture-specific policy ranges. A new source example
  must exercise a general mechanism or expose what that mechanism lacks.
- Next, change `fortback-new`. Replace the generated backend policy with
  compact instruction and encoding facts consumed by one validator and
  encoder. Preserve the current central replay before changing the language
  front end.
- Then, change `ffc-new`. Replace route-specific lowering with generic AST
  traversal and MIR sequence construction.
- Then, change `fortfront-new`. Replace exact source envelopes and
  list-cardinality ladders with a tokenizer, grammar tables, generic
  expression parsing, and AST lists.
- Then, change `standard-new` only where its facts need consolidation for the
  generic frontend. Keep one compact source-backed table per distinct language
  rule.
- Then, collapse repeated fixtures and shell routes into corpus records
  consumed by shared runners. Keep mutation controls and independent output
  checks.
- Reconcile `STATUS.md`, `MILESTONES.md`, and `TASK_POOL.yaml` after the
  generic slice lands. Keep one concise statement of current capability and
  blockers. Leave historical detail in git and the research tree.
- Reassess the production repository split after measuring the simplified
  workflow. If ordinary features still require synchronized changes
  everywhere, merge components or reserve cross-repository pin updates for
  experiments, audits, and releases.

Do not open another witness wave for a new name, value, operator, list length,
or source spelling. A source-specific branch, generated module, route script,
or policy row is a stop signal. Add a table row only when it represents a
distinct standard or target fact. Otherwise generalize the consumer first.

Each slice closes against the same gate: the accepted corpus still passes, an
unseen source passes, malformed neighbors and intermediate mutations fail, an
independent behavioral oracle agrees, and the total implementation, generated,
test, documentation, and review surface is lower. A local increase needs a
measured reason recorded with the change.

## Later capability goals

Each later goal remains finite and behavioral. Detailed task decomposition is
created only when work starts.

### Procedures and modules

Compile calls, procedure bodies, module interfaces, and separate compilation
through the same generic language pipeline.

### Arrays and storage

Add array syntax, shape and storage semantics, descriptors where required, and
observable execution tests.

### Source-backed semantics

Expand StandardIR coverage from grammar facts into typed semantic rules. Each
rule keeps its source citation and has positive and negative witnesses.

### Additional targets

Demonstrate that TargetIR and the generic backend can support another ISA
without copying the compiler pipeline.

### Self-hosting and performance

Pursue self-hosting, optimization search, and specialized fast paths only after
the generic compiler is small enough to serve as a stable oracle.

## LLM use

Use an LLM where the source standard expresses a local rule in prose and a
deterministic translator would cost more than the residual work.

An LLM proposal must name its source, fit a typed schema, and come with checks
that can disprove it. Grammar witnesses, counterexamples, consistency checks,
and differential compiler behavior are suitable checks. Review the proposal,
not a large generated implementation derived from it.

Store an accepted fact once as data. If the same reasoning pattern recurs,
replace repeated model calls with a deterministic translator. Model call count
and generated volume are observations, not success metrics.

For the generic scalar pipeline, use existing source-backed facts first. Invoke
an LLM only when a missing standard or target fact blocks deterministic work.
The model produces a typed fact or a bounded proposal. It does not produce a
fixture-specific compiler route.

## Progress criterion

Progress is one of:

- a newly supported class of programs with an independent behavioral oracle
- a correctness defect exposed and fixed by a reproducing case
- a measured performance improvement
- a net deletion that preserves verified behavior

New metadata, a larger generated file, more sampled values, or another
horizontal helper layer is not progress by itself.

## Research and review triggers

Run an experiment when the answer is uncertain and could change the design.
Write a durable decision when a lasting architecture, format, licence, or
cross-repository boundary changes. Request independent review for a release or
promotion claim whose risk warrants it. Ordinary implementation needs none of
these merely because it changed the compiler.

The prior roadmap, completed waves, run records, and decisions remain available
in git history and under `research/`. This document states the current route
and does not duplicate that history.
