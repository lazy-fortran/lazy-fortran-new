# E0033. Complete-core extraction denominator audit

## Question

Does the complete core extraction report every page and failure category?

## Method

The extraction implementation is pinned to `standard-new` commit `65b0549`.
The complete check is regenerated with:

```text
research/experiments/E0033-does-the-complete-core-extraction-report/analyse.sh
```

The audit reruns the E0013 complete-core extraction, counts the 688-page
document and 536-page selected span from the page index, independently counts
production starts in the full and selected JSONL outputs, validates every JSON
record, checks source-hash coverage in StandardIR, and compares the full and
selected production-ID sets.

The expected eligible-production count was changed from 522 to 521 in a
controlled mutation. The metric comparison failed; the expected values were
restored before the accepted run.

## Result

Accepted. The audit reports 688 indexed pages, 536 selected pages, zero skipped
selected pages, 522 eligible and 522 extracted production starts, zero parse or
JSON failures, zero provenance failures, and zero full-versus-selected scope
difference. Formatting and the full `fo` pipeline passed. The run uses no
model calls and has origin `MECHANICAL`.

This closes the roadmap item requiring completeness, parse-failure,
provenance-failure and skipped-page counts. It does not decide BOM, ligature,
hyphenation or column-order policy; those remain separate extraction questions.
