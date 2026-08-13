# StandardIR lane

Owner: `standard-new`. Contract: `contracts/standardir-v0.sxs`. Primary source
and artifact provenance remain in the laboratory. Production code consumes
source paths supplied by the laboratory fetch contract and emits StandardIR.

## Current gate

M2 is complete for the selected production parser profile under D0029. The
source-side syntax profile is closed; tree-sitter remains a non-gating derived
differential export whose conflict inventory is retained as evidence. E0098 is
the current measurement. Regenerate it with
`research/experiments/E0098-can-the-current-complete-standardir-proj/analyse.sh`.

## Independent slices

- carry the accepted lexical and composite projection into the production
  StandardIR API.
- close the remaining target-specific export boundary without inventing
  parser semantics.
- complete the StandardIR schema and generated visitor contract.
- expose stable provenance-bearing records to the frontend lane.

The source-backed production API, PDF/JSONL projection mode, caller-backed
semantic-item adapter, and bounded semantic-item table are integrated. The
legacy interchange format remains unchanged. Semantic formalization remains a
separate lane within the laboratory's Phase 1 gate and must not be smuggled
into syntax aliases; unresolved and disputed states remain representable.

## Exit and handoff

The lane hands off only a versioned `standardir-v0` record set with source
references, origin labels and resolution states. A committed production slice
is not integrated until its generated output, independent oracle and normal
`standard-new` gates are checked by the coordinator.
