# D0182. Correct D0181 source-document provenance

Date: 2026-08-18
Status: amended by D0183
Amends: D0181

## Context

D0181 selected the bounded source-derived typed-name contract, but its prose
copied the J3-24-007 source-document SHA-256 with the final `e` omitted. The
contract witness, replay manifest and authoritative StandardIR use the full
hash `1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9e`.
R000691 also ran at the preceding central executable revision; R000692 is the
current no-bootstrap replay at central `1e112625cad8e2fe531a361a18e09ae064f4fbe1`.

## Decision

Amend D0181's source-document hash to the full 64-character value above. The
contract property, selected cases, source rules, scope refusals and
zero-promotion policy are unchanged. Treat R000692, not R000691, as the
authoritative technical replay for promotion because it consumes the committed
trace and runs from the current central revision.

## Rejected

Rewriting D0181's accepted body, changing the selected source cases, or
discarding R000691 is rejected. The earlier technical run remains retained
evidence; its lineage is superseded for promotion by the current replay.

## Reversal condition

Write a successor if the full pinned source hash fails against the source
manifest or StandardIR replay, or if a clean replay at the current central
revision contradicts R000692.
