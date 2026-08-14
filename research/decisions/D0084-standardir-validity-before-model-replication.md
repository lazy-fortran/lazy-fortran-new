# D0084. Establish StandardIR validity before semantic model replication

Date: 2026-08-14
Status: accepted
Supersedes: D0080
Amends: D0083

## Context

The E0013/E0033 gates measured extraction structure, provenance, SX
round-tripping and reproducible exports. They did not establish that the
right-hand side of each production matches the normative source. The
independent review found the following defects, and direct inspection of the
current artifacts confirms them:

* R513, R741, R843 and R1307 end at a page-local continuation even though the
  production continues on the next page;
* `pdfproductions.f90` decides whether a line is grammar by a small prefix and
  first-character heuristic, so page furniture and grammar continuation are
  confused at the same boundary;
* `standardir.f90` splits notation at whitespace and classifies a token from
  its first character. This produces `(token ENUM,)`, `(token "(C")`,
  `(token "(association-list")`, `(ref scalar-int-expr,)`, and `(token Tn)`;
* punctuation and Unicode operator glyphs can become references, as in the
  current R1010, R915, R916 and R1040 records;
* the source contains repeated R-number occurrences, while the current record
  identity is too close to the R-number to distinguish occurrence, canonical
  production and conflicting duplicate;
* E0055 applies accepted aliases, expansions and errata to the extracted
  stream. It does not repair lost continuation text or malformed notation, so
  its composite input is a better parser experiment input than E0013 but is
  not a faithful normative grammar;
* the old Qwen replication matrix consumes this research layer. Continuing
  model comparisons before the source validity gate would measure a moving or
  malformed task rather than model capability.

The defects are generic extraction and notation-policy failures. They are not
evidence that individual R-numbers need hand-written repairs. Some findings in
the review were false positives: R727, R754, R836, R1416 and R1417 are correct
in the current artifact, and an unresolved reference is not automatically a
missing production.

## Decision

1. Stop the E0142 model-replication matrix. Retain the completed historical
   cells and the interrupted E0115 cell as append-only evidence. Do not start
   E0116, E0117 or E0123 under the old input and protocol. D0079 remains the
   default local model choice for later work, but it is activated only after a
   source-valid task exists.

2. Make E0147, the source-backed StandardIR validity audit, the only immediate
   syntax experiment. It uses no model calls. It must establish these stages:

   * preserve the raw canonical source lines and page rectangles;
   * identify production occurrences with a source span that can cross page
     headers, footers and page breaks without absorbing the next rule or prose;
   * lex grammar notation losslessly with explicit classes for identifiers,
     punctuation, operators, delimiters, ellipsis, quoted terminals and
     unclassified glyphs;
   * parse that notation into a grammar expression before assigning `ref` or
     `token` meaning;
   * normalize only through declared generic transformations for alternatives,
     optional groups, repetition, literal terminals and source-defined list
     forms;
   * retain raw lexemes, normalized nodes, source spans and occurrence identity
     together;
   * classify every reference as numbered production, lexical fact, assumed
     syntax, fixed erratum, semantic-only name or unresolved; and
   * export grammars only from records that pass the source-validity gate.

3. Require independent evidence for the audit. SX round-trip and producer-
   consumer agreement are necessary checks, not oracles. The audit must have
   independently authored positive witnesses for each failure class and
   negative controls that mutate a continuation, punctuation boundary,
   duplicate identity, reference class or source span and must fail. It must
   compare every accepted production with the canonical source span and record
   an explicit outcome for every rejected or unsupported shape.

4. Keep the following boundaries separate:

   * `extracted`: source text was located;
   * `parsed`: notation was tokenized and structurally parsed;
   * `source-valid`: the normalized expression agrees with the source witness;
   * `closed`: every reference has an accepted classification;
   * `exportable`: the selected profile passes target validators and warning
     policy.

   A record cannot reach `exportable` by passing an earlier structural stage.
   Historical E0013, E0033 and E0055 outputs keep their original status and
   are labeled structural or composite evidence, not source-valid grammar.

5. After E0147 closes, use Qwen 3.8 27B only on the measured residual that
   survives the generic audit. The model may inspect bounded source evidence
   and return a typed local proposal or an explicit unresolved result. It may
   not repair productions by R-number, choose grammar wiring, change a
   denominator, invent a token/reference classification or promote a fact.
   Every proposal requires a source-span witness and an independent replay
   gate. This is a later residual-resolution lane, not part of E0147.

6. Treat J3/24-007 as the pinned public baseline. ISO/IEC 1539-1:2023 and
   Technical Corrigendum 1:2026 are separate source and errata inputs. A claim
   about the current corrected standard requires an explicit overlay experiment
   after the baseline validity gate; the corrigendum must not be silently mixed
   into the baseline extraction.

## Rejected

* Continuing the E0142 matrix to obtain more plots. Its inputs are not yet
  source-valid, so the additional model rows would not answer a stable
  capability question.
* Repairing R741, R843, R1307 or other cited numbers with special cases. The
  generic continuation and notation policies must explain them together.
* Treating a successful SX round-trip, a grammar export, or agreement with an
  existing compiler grammar as an independent source oracle.
* Asking Qwen to rewrite the complete grammar. Model assistance is reserved
  for a bounded, source-presented residual after the mechanical gate.
* Declaring every non-production reference an error. StandardIR has explicit
  lexical, assumed-syntax, erratum and semantic-only vocabularies.

## Reversal condition

Write a successor if a complete E0147 audit shows that the declared generic
pipeline cannot represent a source construct without source-rule-specific
branches, or if the baseline and corrigendum require a different source
identity model. The successor must identify the lost construct, retain the
failed witness and state whether the residual should be handled by a compact
erratum record or the bounded Qwen residual lane.
