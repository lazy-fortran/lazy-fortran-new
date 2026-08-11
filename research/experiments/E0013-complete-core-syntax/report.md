# E0013 report

The gate is reproduced by
`research/experiments/E0013-complete-core-syntax/check-core-syntax.sh`.
It passed with the pinned J3/24-007 PDF, `standard-new` at `7abd7b1`, and no
model calls or manual extraction edits.

| Projection | Result |
|---|---|
| Full-document scope audit, pages 1--688 | 522 production starts; selected pages 45--580 contain the same 522; set difference 0 |
| Production JSONL, pages 45--580 | 1,185 records including the header; 1,184 production lines; 522 starts; 662 continuations |
| StandardIR SX | 523 records including the header; 522 syntax objects; source hash on every record |
| SX round-trip | 523 records; byte-identical to the input |
| Normalized production JSONL | 523 records including the header; 522 normalized productions; no empty notation |

Fixed witnesses cover the assumed-syntax prelude (`R401`--`R403`), the first
core rule (`R501`), the continuation gap (`R516`), lexical rules (`R601` and
`R603`) and the final extracted rule (`R1547`). Their expected values are
checked by the same command above.

This closes lossless PDF-to-machine-readable syntax extraction for the chosen
core span. It does not yet select Core 0 rules, compute dependency closure,
formalize semantic constraints, generate a parser or generate compiler code.
