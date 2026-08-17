# D0154. C747 uses the canonical page-index containment record

Date: 2026-08-17
Status: accepted
Amends: D0153
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

D0153 correctly selected C747 and recorded its printed source page as 77, but
its evidence line also called page-index record 77 without distinguishing the
printed page from the canonical byte-page index. The C747 source span is
`237572:183`. In the pinned
`.cache/runs/E0001/R000003/j3-24-007.pages.index`, record 77 covers
`195782:198301`, while record 91 covers `235554:237768` and contains the C747
span.

The first C747 replay accepted this conflation because the validator checked
the hard-coded page record but did not check span containment. Focused review
R000571 found the defect. The correction is independently replayed by
R000572/R000573 and the validator now requires unique containment by record 91.

## Decision

Amend D0153's provenance wording as follows:

* Printed normative page: 77.
* Canonical page-index record: page 91, start 235554, length 2214.
* C747 source span: byte start 237572, byte length 183, with containment
  asserted against that canonical record.

The C747 semantic property, typed fields, oracle outcomes, scope exclusions
and no-promotion rule from D0153 are unchanged.

## Rejected

* Treating the printed page number as the canonical byte-page index. They are
  different coordinate systems and must be recorded separately.
* Accepting a page-index identity without checking that the source span lies
  within the recorded byte range.
* Reopening C747 selection or broadening the semantic property. The correction
  is provenance-only.

## Reversal condition

Write a successor if the pinned page index, canonical source span, or an
independent containment check gives a different unique record, or if a clean
replay cannot preserve the corrected source binding without semantic
promotion.

## Evidence

* `research/runs/2026-08.jsonl#R000571` records the failed focused review;
  `#R000572` and `#R000573` record the corrected replays.
* `artifacts/reports/M3/m3-c747-focused-review-v0.md` records the finding.
* `artifacts/reports/M3/m3-c747-source-backed-v0.md` records the corrected
  contract and replay.
* `.cache/runs/E0001/R000003/j3-24-007.canonical.txt`, lines 3766--3767, and
  `.cache/runs/E0001/R000003/j3-24-007.pages.index`, record 91.
* Pinned canonical text SHA-256
  `1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e`, page
  index SHA-256 `49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929`,
  StandardIR SHA-256
  `106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2` and
  normative PDF SHA-256
  `7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2`.

<!--
This body is immutable once the status is `accepted`. To change a decision,
write a new record that names this one in its Supersedes, Amends or Retracts
header and says what the old reasoning got wrong. Only the Status line of this
file may then be edited, to point at the successor.
-->
