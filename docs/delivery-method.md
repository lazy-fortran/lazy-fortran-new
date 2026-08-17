# Delivery method

This project is currently optimizing for a working specification-generated
compiler path, not for an unbounded research-frontier inventory.

## One milestone, one observable

The laboratory owns the cross-repository milestone. A production repository
owns the implementation slice assigned to it. Every active slice names:

```text
input fixture
→ declared contract(s)
→ deterministic producer(s)
→ final observable
→ independent oracle
```

The next slice is not complete because a trace exists, generated code
compiles, or provenance was added. It is complete only when a clean checkout
reproduces the observable and the oracle agrees.

`standard-new` is currently assigned S0: a small lexical normative-source to
StandardIR slice. After its artifact and hash are stable, the laboratory is
assigned L0: one minimal source fixture through the existing contract chain.
The full M1/M2 grammar gate remains the eventual source-validity requirement;
the S0/L0 path is the fastest way to expose a real blocker without extending
the current audit loop.

## Oracle rule

Define the oracle before writing the implementation. Use one or more of:

* a cited normative source span;
* a reviewed, immutable golden artifact;
* an independent parser, compiler or extractor;
* a semantics-preserving metamorphic transformation;
* an invalid near-neighbor with a stable diagnostic class and span policy.

The implementation under test must not generate its own expected result. A
trace or round-trip is evidence only when a separate check consumes it.

## Stop rule

Do not add provenance, correspondence, schema variants, model experiments,
semantic promotion or backend work unless the active S0/L0 acceptance test
requires it. Preserve failed and paused audit work in the laboratory record;
do not delete it or let it control the next slice merely because it is
interesting.

## Repository ownership

`ROADMAP.md`, lane views, decisions, experiments and runs remain central. The
production repositories carry only their permanent rules, delivery status,
milestone definitions, reproducibility/oracle instructions and implementation
tests. They do not acquire research ledgers or independent roadmaps.

## M3 evidence lane

M3 is now an evidence reservoir, not the default delivery frontier. Existing
bounded slices and residual CXXX packets remain available for later executable
features; no new packet is selected merely to advance a count. A bounded wave
may still freeze its source ledger, StandardIR inputs, contract schema and
output schema before dispatch. Luna workers split frozen rows across disjoint
worktrees and return batch JSONL. Their semantic packets carry origin `LLM`.
Source envelopes are checked and, when needed, mechanically rebound by the
controller against the pinned ledger.

The controller records one intake result for the wave. It separates ready,
review and rejected packets and retains malformed output as a failure. A ready
packet is still a candidate, not a semantic fact.

After intake, implementation workers may process independent ready candidates
in parallel only when an executable feature consumes them. Each candidate must
cross the same source-backed contract, independent oracle, mutation and
clean-replay gates. The controller integrates central state in one wave commit
and pushes it once. The active throughput unit is now a concrete source-to-
observable vertical slice; per-packet decision records and review reports are
created only when a candidate is selected for implementation or reaches a
promotion boundary.

## Current executable path

The active path is L3, beginning with one raw free-form named main program and
ending in a process exit status. Its first positive input is `program p` /
`end program p`; its negative neighbour mismatches the two names. The existing
frontend-v0, MIR-v0 and backend contracts are reused where they already cover
the path. This boundary deliberately excludes declarations, expressions, I/O,
modules, procedures and fixed-form source until the first raw-source replay
passes.
