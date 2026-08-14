# E0122: generic finite materialization of normative predicate forms

E0122 extends the E0118 finite-case materializer with generic support for
string-length and count terms, existential predicates, containment facts and
their typed finite domains. It consumes the E0120 source oracle without
adding C-number or model-specific branches.

Run it with:

```sh
E0118_ORACLE=research/experiments/E0120-can-deterministic-normative-constraint-f/source-oracle.tsv \
E0118_OUTDIR=.cache/runs/E0122/R000001 \
research/experiments/E0118-can-independently-generated-source-deriv/analyse.sh
```

The source AST still owns expected outcomes. Model predicates are evaluated
only as candidates; missing candidate fact names are `candidate_unavailable`,
not silently aliased. Rows without a model/oracle overlap remain explicit and
no compiler or semantic promotion is attempted.
