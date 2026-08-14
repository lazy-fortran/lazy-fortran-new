# D0083 — Reopen the StandardIR syntax-validity gate after independent audit

Date: 2026-08-14
Status: amended by D0084

## Context

The E0013/E0033 extraction gates established record counts, source
provenance, SX round-trip and projection reproducibility. They did not prove
that the extracted right-hand sides were faithful to the PDF grammar. An
independent review of
`.cache/runs/E0033/R000001/j3-24-007.standardir.sx` found defects that are
also directly observable in the pinned canonical text:

* page-footer handling drops continuation alternatives, including the
  continuations of R513, R741, R843 and R1307;
* whitespace-only tokenization attaches punctuation to names and the token
  classifier consequently misclassifies some punctuation and operator
  terminals;
* summary and detailed grammar occurrences can produce duplicate R-number
  records;
* some reported errors are not errors in the current artifact: R1416,
  R1417, R727, R754 and R836 are represented correctly, and an unresolved
  `ref` is not automatically a missing production because StandardIR also
  carries lexical, assumed-expansion and semantic-only names.

The evidence is reproducible from the canonical text, the E0033 artifact and
the `standard-new` sources at
`../standard-new/app/pdfproductions.f90` and
`../standard-new/src/standardir.f90`. The exact historical extraction gate is
`research/experiments/E0033-does-the-complete-core-extraction-report/analyse.sh`.

## Decision

Keep the historical E0013/E0033 results immutable as structural extraction
results, but reopen M1/M2's correctness claim. Before using the generated
grammars as a faithful Fortran parser input, `standard-new` must add a generic,
source-backed syntax-validity audit and then fix the generic causes:

1. preserve grammar continuation state across page headers and footers while
   still terminating it at the next actual rule or section boundary;
2. tokenize grammar notation with an explicit punctuation/operator policy,
   rather than attaching punctuation by whitespace or inferring terminal
   status from the first character;
3. represent repeated source occurrences separately from canonical emitted
   productions, retaining both provenance and deterministic deduplication;
4. classify every nonterminal-looking reference into production, lexical,
   assumed expansion, semantic-only, fixed erratum or unresolved, with an
   independent closure report; and
5. add source-span witnesses and negative controls so round-trip and
   projection agreement cannot pass on a self-consistent malformed record.

The fixes remain mechanical and Fortran-specific in `standard-new` for now,
as permitted by the project boundary. No LLM output may repair or silently
normalize a StandardIR production. A fixed source erratum is allowed only
under D0025 with an immutable source witness.

## Rejected

* Treating the independent model review as an authoritative patch list. It is
  a discovery aid; each finding must be checked against canonical bytes.
* Declaring every undefined `ref` a parser error. The StandardIR vocabulary
  intentionally includes names that are not numbered production LHS values.
* Fixing individual R-numbers with special cases. The observed truncation and
  punctuation defects are extractor/parser policy defects and require generic
  tests.
* Deleting or rewriting the earlier runs. Their structural claims and their
  limitations are evidence and remain in the denominator.

## Reversal condition

Close this validity gate again only when an independently authored audit over
the complete selected profile reports no dropped continuation, no malformed
punctuation attachment, no unexplained duplicate canonical production, and a
classified reference closure, with source-span negative controls passing.
The audit command and its pinned artifact must be recorded before M1 or M2 is
marked complete again.
