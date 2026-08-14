# D0077 — Keep TargetIR encoding SX private until a consumer requires it

Date: 2026-08-14
Status: accepted

## Context

The first generic TargetIR encoding codec now has an internal SX
read/write boundary in `fortback-new`. It preserves target identity,
operation identity, fixed bits, ordered variable fields and both source
provenance records. No sibling repository currently consumes that serialized
form; the backend uses it only to exercise a canonical representation of its
normalized records.

## Decision

Keep the TargetIR encoding SX representation private to `fortback-new` for
now. Treat `targetir-v0.sxs` and the normalized typed record as the
cross-repository authority. A central serialized TargetIR contract is added
only when an identified producer/consumer boundary needs it; that change
requires a new contract revision, fixture, independent consumer test and
provenance record.

The private serializer must remain generic over normalized records and retain
source identity. It must not become a second ISA-specific table, a hidden
backend dispatch mechanism or an undocumented dependency of another
production repository.

## Rejected

- Promoting the internal SX text immediately: this would create a central
  contract without a consumer, increasing compatibility surface and requiring
  migration work before the backend needs it.
- Leaving serialization implicit in ad hoc tests: this would lose the useful
  canonical round-trip boundary and make later extraction harder to verify.
- Storing ISA source payloads in the serialized form: the laboratory manifest
  and provenance chain remain authoritative, and production repositories do
  not vendor external specifications.

## Reversal condition

Write a successor if a second production component must exchange normalized
TargetIR encoding records, or if differential generation requires a stable
cross-repository serialized witness. The successor must identify that
consumer, version the contract, define compatibility and migration gates, and
show that the shared boundary removes more duplication than it adds.
