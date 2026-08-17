# C1586 semantic/source focused review

Verdict: `PASS`

The reviewer checked the bounded claim at central revision
`fe83c8c8bfea69aee99a57de2dcdc48871713b3e`: only the C1586 statement-function
self-name prohibition is represented. The review checked the pinned canonical
source span, StandardIR R1547 binding, typed absent/present and
same/different/unknown states, the ACCEPTED/REJECTED/UNRESOLVED truth table,
negative neighbours, and the explicit exclusions of parsing, name resolution,
definition ordering, broad C1586 and model promotion.

The independent replay command was:

```text
tests/e2e/run-m3-c1586-self-reference.sh --fresh
```

The review supports bounded promotion only. Full M3 remains open.
