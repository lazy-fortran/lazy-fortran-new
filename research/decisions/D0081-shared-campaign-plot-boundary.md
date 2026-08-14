# D0081 — Use one declarative campaign and shared plot collector

Date: 2026-08-14
Status: accepted

## Context

The seven prior model/protocol experiments already have independent runners and
validators, but their analysis tables use different layouts. Repeating a model
across them must not create seven copies of model-specific plotting logic or
silently omit historical cells. PNGs are generated run artifacts, not research
source.

## Decision

E0142 owns one declarative campaign manifest listing the seven protocol
families, the active model profile, comparison controls and one plot entry per
experiment. A shared collector normalizes the existing append-only summaries
into a common in-memory table; seven tiny experiment entry points select the
experiment and call the same renderer. The collector discovers newly completed
model rows from the declared run-summary locations, so adding a model profile
does not require copying plotting code.

The existing experiment runners, validators and witness gates remain the
execution authority. The shared layer does not start services, make model
calls, alter denominators, or replace a protocol's independent oracle. It
only reads terminal artifacts and emits ignored PNG/PDF/SVG files. Each
completed experiment publishes its current PNG separately through the
slopbox handoff; no generated image is committed.

## Rejected

- A new general-purpose orchestration service in the laboratory repository.
- Seven independent model lists or duplicated plotting implementations.
- Replacing protocol-specific validators with a common aggregate score.
- Checking generated figures into git.

## Reversal condition

Split an adapter or revise the boundary if a protocol-specific data shape
cannot be normalized without losing a declared metric or provenance, or if the
shared collector becomes larger than the protocol-specific analysis it
replaces.
