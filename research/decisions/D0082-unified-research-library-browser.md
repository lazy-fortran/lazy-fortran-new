# D0082. Unified read-only research library browser

Date: 2026-08-14
Status: accepted
Supersedes: D0039

## Context

The disposable browser from D0039 now exposes the run cache well, but the
project's evidence is broader than run files. A reader needs to move from the
standard PDF and source-backed rule register to generated grammar projections,
semantic prompts and responses, MIR, TargetIR, ISA/ABI/microarchitecture
manifests, production source, and the flow that connects them. A second
dashboard would duplicate navigation and create two incompatible histories.

## Decision

Extend `scripts/browse/` into one loopback-only, read-only research library.
The Markdown, TOML, JSONL, manifests, production checkouts and ignored cache
remain authoritative. The browser rebuilds projections in memory on request and
provides:

* lane-level progress percentages with an explicit evidence basis;
* searchable rule/register views for StandardIR, semantic rows, MIR and
  TargetIR artifacts;
* on-demand case inspection with prompts, responses, attempts and gate results;
* clickable pipeline views for syntax, semantic, MIR and backend generations;
* allowlisted, syntax-highlighted production source and verified ISA artifact
  metadata/files; and
* the existing run artifact tree, SX tree and provenance views.

The UI is a single plain Node/TypeScript HTTP reader with no database,
framework, package dependency, write path, experiment trigger or persistent
index. It binds to loopback only. External artifacts continue to be manifests
plus ignored, hash-verified cache files; they are never copied into the
repository. Production source is exposed only from the four named sibling
repositories and an explicit allowlist.

## Rejected

An independent E0142 dashboard is rejected because it duplicates the existing
browser and would split the user's view of the evidence. A persistent database,
generated static index, general-purpose web service, framework and model
control endpoint are rejected because they add state and lifecycle without
improving the evidence. A progress percentage based on code volume is rejected
as misleading; only named gates in `research/progress.toml` count.

## Reversal condition

If rebuilding the projections on request becomes measurably unusable at the
repository's actual scale, or if the browser must be used outside the local
research workstation, write a successor decision with measurements and a new
security boundary before adding persistence or a service.
