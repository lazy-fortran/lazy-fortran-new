# E0028. Text package cross-component properties

## Question

Do the text primitives satisfy cross-component byte and boundary properties?

## Method

The implementation and property test are pinned to `standard-new` commit
`2a05139`. The complete check is regenerated with:

```text
research/experiments/E0028-do-the-text-primitives-satisfy-cross-com/analyse.sh
```

The test generates a deterministic 96-byte reference sequence, appends it at
varying chunk sizes, checks the complete buffer and 672 short span subranges,
then checks builder and memory-writer output and counting-writer size. It also
checks case-insensitive interner identity and a fixed U+1F600 UTF-8 scalar.

The first byte is compared with a separately declared literal oracle. Changing
that literal from 48 to 49 made the focused test fail with
`independent property oracle differs`; the fixture was restored before the
accepted run. This is the independent-oracle failure control.

## Result

Accepted. The focused property test, text-policy self-test, normal text-policy
scan, changed-file formatting check and full `fo` pipeline all passed. The run
uses no model calls and has origin `MECHANICAL`.

This closes the text-package property/fixture gate in ROADMAP.md. Fuzzed trees,
malformed SX input and later schema-level properties remain separate work.
