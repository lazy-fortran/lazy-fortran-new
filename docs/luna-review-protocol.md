# Independent Luna review protocol

Luna reviews are independent evidence checks, not a planning committee.
Use native GPT-5.6 Luna agents with the same immutable milestone snapshot,
fixture, pins, verifier output and artifact paths. Do not give any reviewer
another reviewer's prompt, draft, verdict or conclusions before that reviewer
issues its own verdict.

## Review lanes

Run one scoped reviewer for each lane:

1. **Milestone truth and scope** — Does the evidence satisfy exactly the
   active definition of done, without silently claiming a larger result?
2. **Contract and interface** — Are component revisions, schemas, stage
   boundaries, adapters and ownership explicit and mutually compatible?
3. **Oracle independence** — Does the expected behavior come from a genuinely
   independent normative, golden, differential, metamorphic or negative oracle?
4. **Reproducibility and determinism** — Can a clean checkout reproduce the
   result with the recorded commands, versions, hashes and no local state?

## Verdict format

Each reviewer writes one report at the central evidence path, for example:

```text
artifacts/reports/<milestone>/<cycle>-luna-scope.md
artifacts/reports/<milestone>/<cycle>-luna-contract.md
artifacts/reports/<milestone>/<cycle>-luna-oracle.md
artifacts/reports/<milestone>/<cycle>-luna-reproducibility.md
```

The report contains:

- snapshot commit and component pins;
- assigned lane and excluded questions;
- verdict: `PASS`, `FAIL` or `OPEN`;
- concrete evidence paths and commands inspected;
- the smallest blocking defect, if any;
- whether the verdict is sufficient for milestone promotion.

The coordinator compares reports only after all four independent verdicts
exist. Any `FAIL`, `OPEN` or material disagreement blocks promotion and is
recorded without averaging. A later adjudication must cite new evidence or a
bounded GPT-Sol consultation; it must not rewrite a review.

Luna reviews do not replace the central verifier, component tests, or the
independent oracle. They review whether those gates mean what the milestone
claims.
