# papers

One directory per paper. Each pins exactly what it reports:

```
papers/<slug>/
├── runs.txt        one run ID per line
├── pins.toml       repository commits and corpus hashes
├── analyse.sh      regenerates every table and figure from those runs
└── ...             the manuscript
```

A paper never contains a transcribed number that could have been generated. If
a figure cannot be produced by `analyse.sh` from the runs in `runs.txt`, either
the run records are incomplete or the number should not be in the paper.

This is not extra work imposed for virtue. The run records exist anyway, and
building the tables from them is less effort than copying numbers and then
checking them again after the next re-run.

Planned, in the order the roadmap produces them:

| Slug | From | Question |
|---|---|---|
| `standard-to-grammar` | E1 | How much of a real language standard converts to formal structure without a model? |
| `prose-to-standardir` | E2 | How much semantic formalization is mechanical? |
| `implir-small-models` | E3, E4 | Does a restricted output language reduce the model scale required? |
| `generated-frontend` | E5, E6 | Can generated frontends match hand-written ones on speed? |
| `generated-backend` | E11 | How does the cost of a generated backend vary with ISA specification quality? |
| `language-comparison` | E8 | The same compiler algorithms in Fortran, C and Rust |

None started.
