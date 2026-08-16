# L2 review v1 — oracle independence

Reviewed commit: `1c23fff`

Verdict: FAIL

Findings: the MIR golden matched FFC's own test literal, the ELF hash was
captured from implementation output rather than independently expected, and
QEMU only checked exit status zero. The frontend negative and deterministic
replay checks were valid.

Required correction: add an independently authored MIR semantic witness,
derive and check the bounded RV64 instruction sequence and ELF identity, and
retain QEMU as the independent executor. The runner must consume the committed
artifact manifest.

Disposition: corrected in the post-review oracle and runner update; this
report is retained as immutable review evidence.
