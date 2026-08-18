# Focused review: typed AST v1 exact `y` witness

The E0236 replay is promotable only under D0177's narrowed boundary. The
central verifier accepts the pinned source
`program p / integer :: y / end program p`, emits the typed AST v1 variable
name `y`, rejects the exact malformed `integer ::` neighbour, repeats the
positive output identically, and records zero model calls and zero semantic
promotions. The schema/output structure is checked by an independent
validator that does not import fortfront implementation code.

The final independent reviews are R000671 and R000672. Both pass the exact
witness, negative control, oracle independence, reproducibility, scope and
promotion-safety checks. The post-narrowing mechanical regression is R000670.

The retained R000668 failure is material: it rejected the earlier stronger
wording that implied general source-derived name handling. The current
producer recognizes a bounded exact witness set, so this result does not
promote arbitrary identifiers, declaration parsing, symbol resolution,
semantics, MIR or full M3. A future name-derivation claim requires an
independent changed-name or third-name control and a separate contract.

## Reproduction

The frozen technical replay is:

```text
AST_EXPECTED_CENTRAL_COMMIT=eaca690504abc1a2c218d86e38fdc188b199540d \
tests/e2e/run-frontend-ast-v1-name.sh --fresh
```

The post-narrowing regression is:

```text
AST_EXPECTED_CENTRAL_COMMIT=b5910ac46432f411edb7f436d119ca68b39acf1e \
tests/e2e/run-frontend-ast-v1-name.sh --fresh
```

Both use the pinned schema, witness, golden output, negative neighbour,
validator and path-independent trace recorded by E0236. The promotion is
bounded-only; full M3 remains open.
