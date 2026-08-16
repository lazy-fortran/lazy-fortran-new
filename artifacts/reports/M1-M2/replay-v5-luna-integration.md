# M1-M2 focused Luna review — integration and reproducibility command

Verifier revision: `668806716cc83814e128e38858c20d551b878933`

Evidence commit: `d4236b02eae040db4921eccbcc69e36f86e00f9b`

Origin: `LLM`

Verdict: `NEEDS FIX`

The trace recorded a negative-control command with `cwd: standard-new` but a
relative laboratory path, so the documented command could not be executed as
written. The exact replay, binding, control-plane metadata and bounded claim
otherwise passed.

Required correction: emit the negative command as exact argv/cwd data using
resolved component and fixture paths, then regenerate the trace.
