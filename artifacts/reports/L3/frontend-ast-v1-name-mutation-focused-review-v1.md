# Focused review: typed AST v1 exact `z` witness

The corrected E0237 replay is promotable only under D0178's bounded
changed-name boundary. The evidence packet is central revision
`1eaa143eb91831734eb6753c97274731de79c37c`; its frozen executable revision is
`e95a811c764a7d7d5792d89b4840c5d2c677d20e`, and the producer is fortfront
`a657f367251e0d8e4b638d0ff5362565c4d73685`.

R000678 is the corrected no-bootstrap replay. It executes the exact `z`
source, executes the promoted `y` source through the same producer and
compares that output with the established y golden, rejects the malformed
`integer ::` neighbour, repeats the z output identically, passes the
schema-linked independent oracle and records zero model calls and semantic
promotions. The executable command is:

```text
AST_EXPECTED_CENTRAL_COMMIT=e95a811c764a7d7d5792d89b4840c5d2c677d20e \
tests/e2e/run-frontend-ast-v1-name-mutation.sh --fresh
```

The final independent focused reviews R000681 and R000682 both pass packet
lineage, source and schema pins, behavioral z/y controls, malformed rejection,
repeat and trace reproducibility, oracle independence and promotion safety.

Failures are retained rather than overwritten: R000676/R000677 caught that
the first replay only hashed the y control; R000679/R000680 caught that the
review packet did not distinguish the executable revision from the later
evidence revision. Those corrections are now reflected in the runner,
validator, task command and evidence packet.

This promotes only the exact z witness. It does not establish arbitrary
identifier parsing, declaration parsing, semantic analysis, MIR or full M3.
The contract witness remains labelled `origin llm`; deterministic replay and
independent review, not model output, authorize the bounded promotion.
