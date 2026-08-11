# runs

One JSONL file per month, `YYYY-MM.jsonl`. One run per line, not
pretty-printed, so the files stay greppable and safe to append to from parallel
jobs. `.gitattributes` sets `merge=union` here so a concurrent append is
resolved by keeping both sides rather than by someone choosing which data to
discard.

Append-only. A run is never edited after it is written. A correction is a new
run carrying `"supersedes"`. Failures are kept. Deleting them destroys the
denominator of every rate this project reports.

`RESEARCH.md` gives the schema and the status vocabulary.

```sh
# runs belonging to one experiment
scripts/experiment.sh runs E0003

# regenerate the aggregate tables
scripts/index.sh
```

No runs recorded yet.
