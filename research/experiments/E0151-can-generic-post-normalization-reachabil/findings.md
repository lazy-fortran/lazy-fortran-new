# E0151 current baseline

Run the baseline with:

```text
research/experiments/E0151-can-generic-post-normalization-reachabil/analyse.sh
```

The baseline is the selected E0147/R000022 Bison projection. It is expected to
show the same four unreachable normalized nonterminals and seven useless rules
reported by Bison. The independent graph calculation is a target diagnostic;
it does not authorize deleting source-backed StandardIR records. The candidate
production replay must add a source-lineage witness for every pruned target
rule and pass the mutation control before this experiment can report success.
