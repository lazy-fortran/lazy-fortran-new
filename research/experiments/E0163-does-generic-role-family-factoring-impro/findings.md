# E0163 findings

E0159 already supplied the independent conflict-state inventory and exact
LFortran policy comparison. For the selected `program` profile the baseline is
427 shift/reduce and 2,266 reduce/reduce conflicts; the pinned LFortran
grammar declares and observes 238 and 180. The state categories show that
role/name families dominate selected reduce/reduce conflicts, while expression
and precedence families are the main shift/reduce category. These categories
are diagnostic labels, not semantic correspondences.

E0160's generic `data-ref` role-family projection was then checked in both
modes. The selected candidate passes all four parser generators and improves
the Bison inventory to 425/2,135. E0161 independently checks that it preserves
the complete bounded corpus: 359 positive cases, 636 negative mutations, no
truncation, no positive misses and no negative candidate acceptances.

The same generic mechanism is not promoted to the all-roots default. Its
all-roots result is 760/3,894 versus the baseline 758/3,885. The transformation
is therefore justified as an opt-in selected-parser projection, but not as a
global conflict reduction. No precedence rewrite is justified by this result;
the expression family remains a separate successor experiment requiring its
own generic language-preservation witness.

The reproducible adjudication command is:

```text
research/experiments/E0163-does-generic-role-family-factoring-impro/analyse.py \
  .cache/runs/E0159/R000329/summary.json \
  .cache/runs/E0160/R000336/grammar-oracles.tsv \
  .cache/runs/E0160/R000337/grammar-oracles.tsv \
  .cache/runs/E0160/R000337/role-family-witnesses.tsv \
  .cache/runs/E0161/R000340/language-report.json \
  .cache/runs/E0163/R000347/report.tsv
```

R000347 closes conflict classification and the first generic factoring
decision. The selected projection remains opt-in. The next deterministic gate
is lexer/runtime behavior plus a broader positive/negative parser corpus;
semantic extraction, LLM experiments, plots and backend work remain blocked.
