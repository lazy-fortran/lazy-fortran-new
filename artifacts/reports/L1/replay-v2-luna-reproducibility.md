# L1 replay — corrected independent reproducibility review

Date: 2026-08-16
Corrected four-file diff SHA-256: `565ae83af5871d6aa527a88c7d1ef819027a66a42e997c0f17b15794161b25eb`
Reviewer: native GPT-5.6 Luna, reproducibility/determinism lane

## Verdict

PASS.

The runner checks the actual `HEAD` of both component checkouts against the
fixture pins before writing the trace. It also cleans ignored build trees,
checks the exact `fo` executable, repeats generation, and compares the fresh
trace byte-for-byte with the committed trace.

## Evidence checked

- `tests/e2e/run-l1.sh` passes.
- Actual component `HEAD`s equal the manifest commits.
- Component checkouts are clean in tracked state.
- Repeated outputs and the committed trace are deterministic.
- The exact `fo` version and executable hash match the manifest.
