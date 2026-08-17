# C1586 reproducibility/control-plane review correction 2

Verdict: `NEEDS FIX`

After the ledger append, the checkout was dirty. The two run records were
committed and pushed before the next review.
