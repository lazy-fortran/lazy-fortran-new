# E0034. Flat SX arena-reader corpus differential

## Question

Does the flat SX arena reader agree with the recursive seed over the generated
corpus?

## Method

The implementation and tests are pinned to `standard-new` commit `5e3def5`.
The complete check is regenerated with:

```text
research/experiments/E0034-does-the-flat-sx-arena-reader-agree-with/analyse.sh
```

The focused corpus test generates 64 deterministic SX trees with maximum
recursion depth 4. It serializes each tree, parses the canonical line with the
recursive seed and the flat arena reader, and compares every byte emitted by
their writer paths. It also checks the fixed four-node arena fixture and 10
malformed inputs with expected messages.

One expected malformed message was changed in a controlled mutation. The
focused test failed with `recursive seed malformed message differs`; the
fixture was restored before the accepted run.

## Result

Accepted. The fixed fixture and all 64 generated-tree differentials passed.
All 10 malformed inputs were rejected with the expected messages. Text policy,
formatting, the full `fo` pipeline and the mutation control passed. The run
uses no model calls and has origin `DIFFERENTIAL`.

This extends the arena-reader differential from one fixed nested fixture to a
deterministic generated corpus. The recursive seed remains the comparison
oracle until a generated SX reader replaces it.
