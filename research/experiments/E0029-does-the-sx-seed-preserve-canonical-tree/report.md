# E0029. SX canonical and malformed-input boundary

## Question

Does the SX seed preserve canonical trees and reject malformed inputs?

## Method

The implementation and test are pinned to `standard-new` commit `f19c2ca`.
The complete check is regenerated with:

```text
research/experiments/E0029-does-the-sx-seed-preserve-canonical-tree/analyse.sh
```

The focused test compares canonical writer bytes with an independent fixture,
checks structural parse/write/parse equality, and checks exact failure messages
for empty input, unmatched delimiters, unclosed lists and quoted atoms,
unsupported escapes, trailing forms, an overlong atom and an overfull list.

The canonical expected output was changed from `a b` to `a c` in a controlled
mutation. The focused test failed with `canonical SX bytes differ from oracle`;
the fixture was restored before the accepted run. This is the
independent-oracle failure control.

## Result

Accepted. The focused robustness test, text-policy self-test, normal text-policy
scan, changed-file formatting check and full `fo` pipeline all passed. The run
uses no model calls and has origin `MECHANICAL`.

This closes only the independent canonical-fixture and malformed-input
expectations slice. The seed is still recursive rather than the required
Bootstrap-Core arena reader; fuzzed trees, the malformed corpus and SX content
hashing remain open.
