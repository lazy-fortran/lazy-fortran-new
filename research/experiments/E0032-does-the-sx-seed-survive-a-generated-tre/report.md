# E0032. Generated SX tree and malformed-input corpus

## Question

Does the SX seed survive a generated-tree and malformed-input corpus?

## Method

The implementation and test are pinned to `standard-new` commit `803f46f`.
The complete check is regenerated with:

```text
research/experiments/E0032-does-the-sx-seed-survive-a-generated-tre/analyse.sh
```

The focused test generates 64 deterministic SX trees with maximum recursion
depth 4, writes them to a line corpus, parses each line again, and compares the
tree structure and atom content. It also checks 10 fixed malformed inputs and
their expected rejection messages.

One expected malformed message was changed in a controlled mutation. The
focused test failed with `malformed SX corpus message differs`; the fixture was
restored before the accepted run. This is the independent-oracle failure
control.

## Result

Accepted. The generated corpus contains 64 lines and 939 bytes, with SHA-256
`50968a919e33031d74e58abc9eddec94d4f779ef302caf1ed861b797989013af`.
The focused corpus test, text-policy self-test, normal text-policy scan,
changed-file formatting check and full `fo` pipeline all passed. The run uses
no model calls and has origin `MECHANICAL`.

This closes the SX generated-tree and malformed-input corpus item. The corpus
is a generated test artifact and remains in the ignored build directory; only
its reproducibility metrics are recorded here.
