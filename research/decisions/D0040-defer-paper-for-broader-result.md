# D0040. Defer the paper until the broader generated-infrastructure result

Date: 2026-08-13
Status: accepted
Supersedes: D0038
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

D0038 accepted a venue-neutral paper around the syntax-extraction boundary.
That package is reproducible, but it presents the first laboratory slice as a
finished publication unit. The project now has a broader question worth
testing: how much of a production scientific programming language is already
determined by its normative specification, and how much implementation remains
search, synthesis, or language-specific engineering.

The current evidence is sufficient to support that question, but not to answer
it. Syntax extraction and projection are measured. The semantic ledger still
contains a large unresolved residue. The generated frontend repository has not
started. The research records, failed runs, source pins, and decisions already
preserve the evidence needed for a later manuscript.

## Decision

1. Do not submit the current syntax-only paper. Remove its manuscript and
   submission package from the repository. Keep all experiments, run records,
   artifact manifests, decisions, source pins, and generated outputs in the
   ignored cache.
2. The planned paper has one author: Christopher Albert.
3. Continue the research without waiting for publication. Start
   `fortfront-new` when the StandardIR and semantic boundaries provide a
   meaningful generated frontend slice.
4. Build the next manuscript around a broader measured result. The intended
   evidence is:
   - mechanical syntax recovery and projection;
   - deterministic recovery of definitions and relations where the normative
     text supports it;
   - a measured mechanical, solver, model-assisted, and handwritten residue
     for static semantics;
   - a generated frontend validated on a substantial real Fortran corpus;
   - correctness and performance comparisons against established frontends;
   - provenance for every accepted generated component and every unresolved
     boundary.
5. Treat *Nature Computational Science* as the aspirational first target for
   that broader result. Its scope includes fundamental and applied tools and
   frameworks for computational science, and its Article and Resource formats
   require a substantial, broadly significant result. Reassess the fit against
   the current author guidelines when the evidence exists. See the journal's
   [aims and scope](https://www.nature.com/natcomputsci/natcomputsci/natcomputsci/about/aims)
   and [content types](https://www.nature.com/natcomputsci/content). Top
   programming languages venues remain fallback targets if the result stops at
   a parser or compiler-construction contribution.

The current research question is therefore:

> How much of the implementation of a production scientific programming
> language is already determined by its normative specification?

The repository records the answer as measurements rather than as a paper
draft. A future paper is generated only after the evidence and its stopping
boundary are clear.

## Rejected

Submitting the current syntax-only package is rejected because it would force
the first publication to crystallize before the semantic and frontend
measurements that motivate the broader project exist.

Waiting for publication before starting `fortfront-new` is rejected because
publication is not a phase gate for the research program.

Deleting the experiments with the paper is rejected because the runs and
failures are the evidence from which the later paper must be derived.

Treating the Nature target as a commitment is rejected. It is a target whose
fit depends on breadth, significance, and validation still to be measured.

## Reversal condition

Write a successor if the next frontend and semantic measurements show that the
broader claim is not supportable, or if a completed result is better served by
a different venue or by separate papers. Reopen the paper decision earlier if
an external priority or collaboration need makes a documented intermediate
preprint materially valuable.
