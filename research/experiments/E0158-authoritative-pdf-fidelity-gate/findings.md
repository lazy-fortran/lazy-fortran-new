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

## R000325: historical narrow current-source recheck

The same independent checker was rerun against the E0154/R000318 StandardIR
input used by the corrected E0157 audit. It again passes all 522 records and
522 unique PDF byte spans, all 20 duplicate rule families, and the five
representative continuation/token-ref witnesses. R1307 removes two page-layout
headers while preserving the complete production. The pinned PDF hash and the
negative mutation pass.

This narrow recheck is retained as the first current-source result. Its
checker did not yet verify all-record token/reference leaves or the
canonical-text-to-PDF manifest lineage; it is superseded by R000336.

## R000336: full current-source fidelity gate (preliminary record)

The checker was strengthened generically before accepting the gate. It now
verifies every record's canonical-text source hash, every source span's
token/reference leaf sequence, the canonical text byte hash and size from its
artifact manifest, the page-index hash, the manifest's PDF source hash and the
standard-new generator pin. The canonical text was independently regenerated
from the pinned PDF with:

```text
(cd ../standard-new && fo exec pdfcanonical \
  ../lazy-fortran-new/.cache/j3-24-007.pdf \
  /tmp/e0158-current.canonical.txt /tmp/e0158-current.pages.index)
```

Both regenerated hashes equal the pinned canonical artifact and page index.
R000352 passes all 522 records and 522 unique spans, all 20 duplicate rule
families, all-record token/reference leaves, the five representative witnesses,
the PDF/manifest lineage checks and the negative mutation. It reports 46
surface-normalization differences caused by the standard's optional-plus-
ellipsis repetition shorthand; the corresponding leaf content is identical
and the five full structural witnesses pass. No rule-number-specific extractor
repair was needed.

R000335 is retained as the underlying report attempt with a metadata hash typo;
R000336 is retained as a collided preliminary record. R000352 is the
authoritative append-only run record for this gate and supersedes both metadata
attempts without changing the underlying report.

## R000364: current-source replay before the selected runtime

The same deterministic checker was rerun against the exact E0154/R000353
source evidence and retained as `.cache/runs/E0164/R000364-pdf-fidelity.tsv`.
It again passes all 522 source spans, all 20 duplicate rule families, every
source hash and token/ref leaf, the PDF/canonical/page-index lineage checks,
and R741, R843, R1103, R1307 and R1315. The negative mutation fails as
required. This is the current gate used by R000365; no extractor repair or
rule-number-specific exception was made.
