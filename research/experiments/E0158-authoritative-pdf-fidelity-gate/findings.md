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
