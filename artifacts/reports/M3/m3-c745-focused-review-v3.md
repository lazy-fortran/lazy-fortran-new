# M3 C745 focused review v3

Status: `PASS`; bounded C745 promotion is authorized as a bounded oracle leaf
only. Full M3 remains `OPEN`.

The semantic-scope lane passes: the contract and validator cover 27 typed
states, 4 `ACCEPTED`, 1 `REJECTED`, 22 `UNRESOLVED`, 12 rejected mutation
controls, an independent human-authored expected-outcome table, zero model
calls, zero semantic promotions and explicit non-claims.

The reproducibility/control-plane lane passes: the E0208 manifest, source
report, milestone command, task evidence, current status, run `R000556`
(`E0208/R000010`) and active verifier agree on the pinned packet. The full
canonical run ledger parses as 610 JSON records. The malformed historical
selection bytes are preserved in
`research/runs/archive/2026-08.jsonl.raw`; correction runs `R000558` and
`R000559` record the serialization repair and its zero-promotion result.

The bounded promotion is limited to this C745 typed oracle. It does not
promote a general semantic fact, add a parser, restart E0172 or close M3.
