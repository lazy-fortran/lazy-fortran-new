# C1579 semantic/source review v1

Status: `NEEDS_FIX`

Snapshot: central commit `fb2136891ac0a237cbb592b911219050ae9c73cf`.

The complete nine-state witness table, seven mutation controls, fail-closed
unknown handling, exact C1579 text, hashes and StandardIR R1532/R1544 identity
passed. The validator performed no parsing, inference, scope resolution, model
call or semantic promotion. The pinned canonical page index was then checked
against the PDF and exposed the remaining source defect: canonical lines
15386--15387 begin at byte 1015407, after page 356 ends at byte 1015375, and
appear on PDF page 357. The fixture and contract still cited page 356.

Correct the citation and make the page boundary an independently checked input,
then regenerate the trace and run:

```text
tests/e2e/run-m3-c1579.sh --fresh
```
