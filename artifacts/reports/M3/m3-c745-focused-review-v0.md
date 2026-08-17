# M3 C745 focused review v0

Status: `NEEDS FIX`; no bounded C745 or full M3 promotion is authorized by
these retained review findings.

The first focused review used central revision
`e89dcce3644c20f7407fa98564ee0408ffc562a7` and replay `E0208/R000002`.
The semantic-scope lane passed. The reproducibility lane found that the E0208
manifest still pinned `95acf3d94cf51775656be7424a39f3ed00fe68ff`, so the
replay revision was not the exact manifest revision.

After that pin was corrected, the second focused review used `07f57dabc8896694d067220ef0c5a5840b47df97` and `E0208/R000003`.
The semantic-scope lane passed. The reproducibility lane found that the
validator's `oracle()` and the fixture's expected values were self-consistent,
not independent. The correction added the separately authored,
hash-pinned expected-outcome table
`tests/fixtures/m3-c745-expected-outcomes-v0.json`.

The corrected replay then passed at `ed172bad35dc758cd5490c7440a9039a93f115d5`
as `E0208/R000005`. A third focused review found that this passing replay had
not yet been written to the durable run ledger or linked by a committed C745
replay report. That evidence-handoff defect is retained in the run ledger; the
replay itself remains a valid bounded result.

No review in this report promotes a semantic fact, a Fortran parser, or full
M3. The required correction is to commit the R000005 run record and bounded
replay report, then repeat focused review from that durable packet.
