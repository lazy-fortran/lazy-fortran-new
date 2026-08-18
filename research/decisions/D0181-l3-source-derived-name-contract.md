# D0181. Freeze the source-derived typed-name boundary

Date: 2026-08-18
Status: amended by D0182

## Context

D0180 stops the exact-name ladder after the bounded `x`, `y`, `z` and `alpha`
witnesses. The existing `frontend-ast-v1` schema already has a typed
`variable-declaration.name` and `source-span`; the next useful question is
whether that field can be derived from source spelling rather than selected by
an exact whole-source dispatch.

## Decision

Freeze one pre-implementation contract over the existing v1 shape:

```text
raw source declaration spelling
  → variable-declaration.name
  → declaration source-span
```

The positive and two changed-name controls keep the program and declaration
form fixed while selecting `beta`, `q7` and `theta_2`. They exercise the
letter, digit and underscore alternatives represented by J3-24-007 R601--R603
and R903. Each expected name must equal the bytes after `integer :: `, and its
expected declaration span must be byte range 10 through the end of that
declaration line. The existing malformed `integer ::` source remains a
`REJECTED` negative neighbour.

The exact source-backed evidence is the pinned J3-24-007 PDF
`7371e889f231cfb0316d30365d5083fb5af34cbb6d5f7cb1e01855c73021bfa2`, the
source document hash
`1cf538329c57e4f617adb36f2c7cd91a5a5561c78bcce16ec96f7ff1a9979f9`, and the
StandardIR replay
`.cache/runs/E0171/R000433-provenance-replay/standardir.sx` with hash
`106389186689ae819783ab6742ba4a469f8d1a84ce3bbf25e9baf98a32cf25c2`. The
bound rules are R501, R1401, R504, R507, R508, R601, R602, R603, R704, R705,
R801 and R903.

The contract and its expected table are marked `LLM`: Luna generated the
fixture proposal. The independent contract oracle is `MECHANICAL`; it checks
the pinned bytes, hashes, source-derived spans, mutation isolation, negative
neighbour and zero-promotion guards. No model output can promote a semantic
fact. This task freezes expectations only; it does not claim that fortfront
already accepts these names.

## Rejected

More exact-name goldens, multiple declarations, attributes, kind selectors,
case folding, implicit typing, symbol resolution, general parser work and
semantic promotion are outside this contract. The producer must not broaden
the schema or downstream MIR path to satisfy it.

## Reversal condition

Reverse or split this contract if the independent oracle cannot establish the
three source-derived cases, if the pinned R601--R603/R903 evidence does not
support the selected names, or if the existing v1 span/name fields cannot
express the boundary without a schema revision.
