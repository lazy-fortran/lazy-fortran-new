# E0172: generic typed-predicate shape examples on the E0123 residual

E0172 is the controlled successor required by D0074. It changes the E0116
semantic proposal prompt only by making generic valid and invalid constructor
shapes explicit. It retries the same 53 residual row keys from E0123 and keeps
the other 234 E0117 rows as immutable predecessor controls.

The model remains a bounded proposer. Source spans, row identity, schema
acceptance, prior controls, witness execution and semantic promotion remain
deterministic gates. A lower structural-error count is useful evidence about
the prompt interface, not a semantic fact.

Run the preflight and candidate cell as follows:

```sh
research/experiments/E0172-can-generic-typed-predicate-shape-exampl/preflight.sh
research/experiments/E0172-can-generic-typed-predicate-shape-exampl/run.sh
```

After the model cell completes, run the deterministic verifier:

```sh
research/experiments/E0172-can-generic-typed-predicate-shape-exampl/analyse.sh
```

The analysis compares structural gate-error classes with E0123/R000254 while
requiring exact row replacement, source/schema/witness validity, mutation
failure, and zero semantic promotions.
