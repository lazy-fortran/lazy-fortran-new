# StandardIR lane

Owner: `standard-new`. Contract: `contracts/standardir-v0.sxs`. Primary source
and artifact provenance remain in the laboratory. Production code consumes
source paths supplied by the laboratory fetch contract and emits StandardIR.

## Current gate

The immediate gate is M2 in `ROADMAP.md`: the complete selected syntax profile
must be source-backed, closed and sane in all required projections. E0098 is
the current measurement. Regenerate it with
`research/experiments/E0098-can-the-current-complete-standardir-proj/analyse.sh`.

## Independent slices

- carry the accepted lexical and composite projection into the production
  StandardIR API.
- close the remaining target-specific export boundary without inventing
  parser semantics.
- complete the StandardIR schema and generated visitor contract.
- expose stable provenance-bearing records to the frontend lane.

The first slice may proceed independently of backend source ingestion. Semantic
formalization remains a separate lane within the laboratory's Phase 1 gate and
must not be smuggled into syntax aliases.

## Exit and handoff

The lane hands off only a versioned `standardir-v0` record set with source
references, origin labels and resolution states. A committed production slice
is not integrated until its generated output, independent oracle and normal
`standard-new` gates are checked by the coordinator.
