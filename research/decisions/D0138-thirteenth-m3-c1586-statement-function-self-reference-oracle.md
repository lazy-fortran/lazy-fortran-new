# D0138. Thirteenth M3 slice uses C1586 statement-function self-name exclusion

Date: 2026-08-17
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

The exact E0181 residual-selection verifier reproduced the retained 287-row
ledger. Its negative control failed as expected; four hard failures and two
unresolved rows remain, with 94 disputed rows, 69 unwitnessed rows and zero
semantic promotions. C1579 is now a promoted bounded slice, so the remaining
unresolved residual is C1586.

C1586 is a large rule. It covers the allowed primary forms in a statement
function scalar expression, intrinsic operations, function-reference interface
and result restrictions, array arguments, and statement-function definition
ordering. The whole rule is not a small executable contract.

## Decision

Define the next bounded M3 delivery contract as the C1586 statement-function
self-name exclusion. It evaluates only this source-backed projection:

```text
if a statement-function reference is absent                         ACCEPTED
if it is present and its name differs from the name being defined      ACCEPTED
if it is present and its name equals the name being defined            REJECTED
if the reference presence or relevant name relation is unknown       UNRESOLVED
```

The typed candidate has these fields:

```text
reference_presence: absent | present | unknown
name_relation:      not-applicable | same | different | unknown
```

`not-applicable` is valid only with `reference_presence=absent`; a present
reference requires `same` or `different`, and an unknown relevant fact closes
the oracle to `UNRESOLVED`. Candidate facts are human-authored. No model
output can promote a semantic fact.

The source binding is J3-24-007 C1586 (R1547), canonical-text lines
15468--15469 on PDF/page-index page 358. Those lines state that a referenced
statement function must have been defined earlier and must not be the name of
the statement function being defined. This slice checks only the latter
self-name condition. The already represented StandardIR `R1547`
`stmt-function-stmt` production supplies the syntax shape.

The exact pinned source evidence is:

```text
canonical text: .cache/runs/E0001/R000003/j3-24-007.canonical.txt
canonical SHA-256: 1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e
PDF SHA-256: 7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2
page index: .cache/runs/E0001/R000003/j3-24-007.pages.index
page-index SHA-256: 49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929
page 358: start 1019965 length 3429
C1586 lines: 15468--15469, byte-start 1023125, byte-length 254
full C1586 span: lines 15464--15469, byte-start 1022608, byte-length 771
StandardIR: .cache/runs/E0171/R000433-provenance-replay/standardir.sx
StandardIR SHA-256: 106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2
R1547: page 358, byte-start 1022521, byte-length 86, occurrence 522
standard-new: f94c4c51b51fce22b533b7eeda08741970320913
```

The implementation gate is the exact central command
`tests/e2e/run-m3-c1586-self-reference.sh --fresh`. It must independently
check the source/page/StandardIR identities, the typed witnesses and
fail-closed unknowns, source/rule mutation controls, exact trace comparison,
zero model calls and zero semantic promotions.

This contract does not parse scalar expressions or Fortran statements, infer
statement-function references, resolve names, decide definition ordering,
perform type checking, or claim the remainder of C1586.

## Rejected

* Implementing all of C1586: its combined expression, procedure, array and
  ordering conditions exceed one small deterministic vertical slice.
* Selecting a new model experiment or reviving E0172.
* Promoting the unresolved E0123 proposal row as semantic evidence.
* Choosing C1587, C1588 or C1589: their retained rows are not the unresolved
  residual selected by this verifier, and each requires a different fact
  vocabulary or association/type decision.

## Reversal condition

Write a successor if the pinned canonical span cannot be shown to contain the
self-name prohibition, if `R1547` is absent or has different source metadata,
or if an independent replay cannot distinguish same-name, different-name,
absent-reference and unknown states without parsing or name resolution.

## Evidence

* E0181 exact verifier output and analysis report, recorded as
  `research/runs/2026-08.jsonl#R000065`.
* `.cache/runs/E0181/R000001/analysis/merged/selected-rows.jsonl`, `C1586@1`.
* `.cache/runs/E0001/R000003/j3-24-007.canonical.txt`, lines 15464--15469.
* `.cache/runs/E0171/R000433-provenance-replay/standardir.sx`, row R1547.
* `research/decisions/D0136-twelfth-m3-c1579-result-entry-name-oracle.md`,
  which rejected the unbounded C1586 rule before this narrower projection was
  defined.
