# D0137. Correct C1579 printed-page binding

Date: 2026-08-17
Status: accepted
Supersedes: D0136
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

D0136 selected the bounded C1579 RESULT entry-name exclusion property, but its
page citation used 356. The pinned canonical page index places canonical lines
15386--15387 on page 357: page 356 spans byte offsets 1012039--1015374 and
page 357 starts at byte 1015376. The StandardIR R1544 production remains on
page 356; that is a separate source occurrence and is not the C1579 page.

## Decision

Correct the C1579 source binding to printed/PDF page 357. Retain the existing
canonical lines, source hash, PDF hash and StandardIR R1532/R1544 metadata. The
independent validator must consume the pinned page index and reject a page or
boundary mutation. The bounded oracle, typed states, witnesses and nonclaims
from D0136 remain unchanged.

The exact page-index evidence is:

```text
.cache/runs/E0001/R000003/j3-24-007.pages.index
page 356 start 1012039 length 3336
page 357 start 1015376 length 4588
```

The replay command remains:

```text
tests/e2e/run-m3-c1579.sh --fresh
```

## Rejected

* Keeping page 356 for C1579: it identifies the preceding R1544 production,
  not the page containing the C1579 constraint.
* Broadening the C1579 property or restarting E0172.

## Reversal condition

Write a successor if the pinned page index, PDF extraction or canonical source
contradicts page 357, or if the corrected replay cannot preserve exact source
and StandardIR identity.

## Evidence

* `.cache/runs/E0001/R000003/j3-24-007.pages.index`, SHA-256
  `49406a5aecf423555662643f07f6c2bdf72dd3df3954862231afa31505e18929`.
* `.cache/runs/E0001/R000003/j3-24-007.canonical.txt` lines 15386--15387,
  SHA-256 `1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9`.
* `.cache/j3-24-007.pdf`, SHA-256
  `7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2`.
* `.cache/runs/E0171/R000433-provenance-replay/standardir.sx` rows R1532 and
  R1544, SHA-256 `106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2`.
