# E0170 findings

E0170 remains open. Its command is the `analysis` command in `manifest.yaml`;
each attempt retains its generated corpus, command log, per-root runtime log,
timing file and independent recognizer report under `.cache/runs/E0170/`.

The prerequisite E0168 PDF-fidelity gate and E0169 parser-control
adjudication are green. E0170 is the first gate to exercise the selected
source-backed contract through the production runtime over a bounded complete
corpus. No StandardIR or grammar source has been changed.

## Retained intermediate failures

- R000374 is a harness failure. The first replay asked the E0161 recognizer to
  discover role-family roots from the baseline grammar, although those witness
  comments exist only in the opt-in candidate. It produced only two roots and
  failed closed before runtime execution.
- R000375 is a harness-bound failure. The chosen high depth/token bounds
  truncated recursive derivations, and the current recognizer correctly
  rejected an incomplete corpus instead of treating it as complete.
- R000376 is a harness setup failure. The root timing directory was not
  created before `/usr/bin/time` was invoked. The complete corpus itself was
  generated successfully; no runtime result was claimed.
- R000377 is a production-runtime timeout. With the corrected complete bounds,
  the first seven `allocate-object` cases completed, while the eighth case
  (`letter digit % letter`) consumed a CPU core without producing an outcome
  for the bounded timeout. The child was terminated after its timing record
  was retained. This is the current blocking defect.
- R000378 is a rejected Luna production attempt. A generic reachability,
  duplicate-rule and dependency-worklist patch was tested against the exact
  witness but did not meet the bounded termination requirement. It remains
  uncommitted and is preserved as a patch artifact; no production change was
  merged.

The complete corpus parameters are depth 8, four terminal tokens, 256 words,
64 negative mutations and repeat limit 1. The exact command and the resulting
case counts are emitted by `run-broad-runtime-gate.sh`; no case is removed
because it is inconvenient. The next accepted run requires a generic runtime
termination fix, an independent regression test, a clean production commit,
and a complete replay over the same generated corpus.
