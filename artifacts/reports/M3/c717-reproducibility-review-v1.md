# C717 focused reproducibility review v1

Verdict: NEEDS FIX
Origin: LLM
Packet: corrected E0189 replay `R000478`, `.cache/runs/E0189/R000003`.

First fatal issue: the replay's `central_revision_pin` is
`fe6790d488b825216d072d3e3b2c685078e1a2c1`, but that revision predates the
`R000478` run record and the corrected E0189 handoff references. A clean
checkout at the pinned revision therefore cannot independently recover the
replay record or its unambiguous task wiring.

Evidence:

- `git show fe6790d4:research/runs/2026-08.jsonl` has no `R000478` record.
- The historical `research/runs/2026-08.jsonl` lines for `R000077` remain
  assigned to E0068 and the first E0189 replay, so that ID cannot be reused.
- The corrected result, trace, fixture, environment and oracle hashes match
  the R000478 record; the defect is the durable revision boundary, not the
  bounded oracle result.

Required correction: append this review failure without editing prior run
records, then commit the corrected replay record and all E0189/task/status/
roadmap handoff references in a central revision that predates the next clean
replay. Preserve `R000077`, `R000477` and `R000478` unchanged.
