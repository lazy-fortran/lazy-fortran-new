# E0158 plan

This gate is deliberately before the next grammar generation. It checks the
source evidence, not the already generated grammar outputs. The five witnesses
cover a continuation-free declaration (`R741`), a multi-line production
(`R843`), punctuation and list references (`R1103`), a production crossing a
PDF page break (`R1307`), and mixed terminal/nonterminal spelling (`R1315`).
The same checker also validates all source byte spans and all duplicate rule
occurrences, so the focus list is not a collection of special cases.

The intended command is:

```text
research/experiments/E0158-authoritative-pdf-fidelity-gate/check.sh \
  .cache/runs/E0154/R000314/input/standardir.sx \
  .cache/runs/E0001/R000003/j3-24-007.canonical.txt \
  .cache/j3-24-007.pdf \
  .cache/runs/E0158/R000320-pdf-fidelity.tsv
```

No target grammar, parser generator, LLM or semantic extractor is involved in
this gate. A passing report authorizes a fresh four-format regeneration; the
existing R000320 all-root replay remains historical pre-gate evidence.

## R000321: fidelity gate passes

The report passes with 522 source records, 522 unique byte spans and 522
canonical grammar-definition occurrences. All 20 duplicate rule families retain
40 distinct source occurrences. R741, R843, R1103, R1307 and R1315 each pass
both normalized RHS comparison and independent token/ref leaf classification.
R1307 crosses a PDF page break and removes two layout-header lines without
losing grammar content. The pinned PDF hash and the negative mutation both
pass.

The source extractor therefore needs no rule-specific repair for this pinned
document and witness set. The gate now authorizes a fresh all-root regeneration
using the already generic four-format pipeline. That regeneration must remain
separate from the pre-gate R000320 output.
