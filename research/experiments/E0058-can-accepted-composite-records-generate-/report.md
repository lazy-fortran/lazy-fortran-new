# E0058: Source-linked parser diagnostic lookup

Status: accepted

## Question

Can the accepted composite StandardIR records generate a source-linked
diagnostic lookup without losing source identity or exact spans?

## Result

Yes, for the tested diagnostic data path. The E0055 composite input contains
519 syntax records. The mechanical traversal emitted 519 diagnostic rows, and
all 519 retain the source rule, page, byte start, byte length, and the pinned
source-document SHA-256.

The generated `parser_source_ref_t` table and lookup routine compiled with
GNU Fortran 16.1.1 using `-ffree-line-length-none -Wall -Wextra -Werror`.
The runtime check found the known `program`/`R501` source at page 53 and byte
span 138571..138623, rejected an unknown `unknown`/`R999` lookup, and passed
the source-hash check. Mutating the first byte start changed the independent
diagnostic witness.

The result is therefore an accepted verification of source-linked diagnostic
lookup. It does not establish parser acceptance, semantic checking, or a
complete direct parser. The generated lookup table is a deterministic
structural artifact. Local parser operations remain the next implementation
holes.

## Reproduction

```text
research/experiments/E0058-can-accepted-composite-records-generate-/analyse.sh
```

The run summary is `artifacts/runs/E0058/R000001-summary.toml`. Generated
payloads remain in the ignored cache and are not repository sources.

## Decision boundary

Proceed to fill the local parser operations and exercise the generated direct
parser against a pinned real-source corpus. Keep parser-wide dispatch,
registration, and source-linked diagnostic wiring mechanically generated.
Escalate only when a local constructive operation cannot be expressed as a
small typed implementation fragment under the existing schemas. Do not hand
wire architecture to resolve such a case.
