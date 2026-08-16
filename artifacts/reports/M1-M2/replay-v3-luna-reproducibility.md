# M1-M2 focused Luna review — reproducibility

Snapshot: `668806716cc83814e128e38858c20d551b878933`

Origin: `LLM`

Verdict: `NEEDS FIX`

The exact clean replay was not represented by the durable environment record;
the trace comparator also excluded the entire environment block, so the stale
central commit could pass comparison.

Required correction: retain the exact-revision run identity and bind the
committed environment evidence to that immutable record.
