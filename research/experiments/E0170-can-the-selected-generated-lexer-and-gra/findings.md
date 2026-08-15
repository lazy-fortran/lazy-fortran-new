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
- R000379 is a second rejected Luna production attempt. A chart/worklist
  implementation was started from the clean runtime base, but it was not
  completed or independently verified and was restored without a commit.
  No production change was merged.

The complete corpus parameters are depth 8, four terminal tokens, 256 words,
64 negative mutations and repeat limit 1. The exact command and the resulting
case counts are emitted by `run-broad-runtime-gate.sh`; no case is removed
because it is inconvenient. The next accepted run requires a generic runtime
termination fix, an independent regression test, a clean production commit,
and a complete replay over the same generated corpus.

## Algorithm boundary from the literature

The accepted runtime decision is D0101. The replacement must be a finite
chart/worklist evaluator with explicit predictor, scanner and completer
transitions and deduplicated state identity. This is the standard shape of
Earley-style chart parsing, with GLL as the reference for descriptor/worklist
handling under ambiguity and left recursion. The outer timeout remains only a
safety bound for a failing run; it is not an implementation termination rule.

The production agent must first pass a focused independent suite covering the
exact timeout witness, epsilon, direct and indirect left recursion, ambiguity,
unknown references and malformed inputs. Only then may the unchanged broad
995-case corpus be rerun. The script named in `manifest.yaml` regenerates the
counts and reports every case; no case is removed.

## R000380: exact witness fixed, broad scalability still open

The accepted Luna commit `41908855` replaces the old global rescanning with a
finite chart/worklist evaluator. Independent `fo` passes with zero warnings,
the focused frontier suite passes, and the former `allocate-object` timeout
witness completes. The complete corpus still fails the gate: 9 of 11 root
batches completed with zero mismatches, but the `program` root exceeded the
60-second per-root safety guard after 90 outcomes. Its timing file is empty and
the retained runtime log ends in `command-timeout`; the `variable` root was not
started. Peak RSS of completed roots was 1,556,480 KB and their summed elapsed
time was 327.5 seconds. These values are regenerated from the R000380 timing
files by the E0170 runner; they are not a success-rate denominator.

This is now classified as generic chart-state explosion or insufficient
indexing, not as a missing Fortran rule. The next slice must preserve the
finite-state correctness invariant while reducing work generically. It must
first reproduce the `program` root with a bounded diagnostic (state counts by
rule/dot/uncertainty, queue growth and completion counts), then optimize using
exact grammar reachability/productivity and packed or indexed chart operations
where they preserve the existing outcome contract. The first literature-backed
special case to investigate is the practical-Earley treatment of empty and
nullable productions (Aycock and Horspool, 2002), because it changes the
finite chart automaton rather than adding a source-language exception. It may
not add a root, rule-number or input-specific exception, and it must rerun the
focused suite before the unchanged 995-case corpus.
