# C729 reproducibility/control-plane review v0

Status: `NEEDS FIX`
Origin: `LLM`
Functional snapshot: `24798c2c18e6e3d751e571d7be2afc23d4fa2c9b`
Control-plane snapshot: `7ed9ca9a64b43bc562bb1b234aade268f6aebaa1`
Replay: `tests/e2e/run-m3-c729.sh .cache/runs/E0184/R000001`

The functional C729 replay, source binding, mutation controls, committed
trace, zero model calls and zero semantic promotions passed. The review found
that the recorded contract-schema hash in the R000039/R000040 ledger chain
was mistyped, and the original fixed-output command was not suitable for a
second exact replay. Promotion was not authorized.

The repair was to retain the append-only correction history, record the exact
64-character schema hash, add deterministic `--fresh` run-directory
allocation, repin the experiment to the functional snapshot, and replay it
twice. The later R000041/R000042 records and v1 review supersede this failed
review for promotion purposes; this report remains as failure evidence.
