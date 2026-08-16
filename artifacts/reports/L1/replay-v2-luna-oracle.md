# L1 replay — corrected independent oracle review

Date: 2026-08-16
Corrected four-file diff SHA-256: `565ae83af5871d6aa527a88c7d1ef819027a66a42e997c0f17b15794161b25eb`
Reviewer: native GPT-5.6 Luna, oracle-independence lane

## Verdict

PASS.

The independent standard-library-only oracle checks the source, canonical
artifact, provenance, positive and negative frontend observations, the case
manifest, and the malformed fixture's reviewed hash and single-missing-close
shape. The runtime rejection and diagnostic are therefore not the oracle's
only evidence for malformed input.

## Evidence checked

- `tests/e2e/run-l1.sh` passes.
- Positive and negative output hashes match the reviewed manifest.
- The malformed fixture is independently validated before its runtime result
  is accepted.
- No component parser or runtime is imported by `tests/e2e/oracle_l1.py`.
