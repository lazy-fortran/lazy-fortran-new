# D0041. Fortran-first adapter and mechanical syntax closure

Date: 2026-08-13
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

The laboratory is currently formalizing J3/24-007 for Fortran. The reusable
parts are already the SX representation, StandardIR records, provenance,
typed resolution facts, exporters and deterministic wiring. The ingestion
layer is necessarily specific to this document: its PDF layout, R/C notation,
assumed syntax notation, lexical tables and fixed errata.

D0024 and D0026 already selected deterministic representations for R401--R403
and their overlaps. E0055 generated a deterministic projection of 80 R401 and
20 R403 family records. E0074 later tested a deliberately narrower integration
that applied only the three E0072 aliases, omitting D0024 and D0026 from its
inputs. The subsequent residue measurements therefore reopened expansion
names that had already been handled by an earlier projection.

## Decision

Finish the current Fortran/J3 adapter before generalizing the tooling. Keep the
generic boundary clean, but do not introduce a multi-standard framework or
abstract the adapter prematurely.

The immediate gate is mechanical closure of the complete syntax input:

1. Reintegrate D0024, D0026, D0027 and the accepted fixed errata into the
   current complete projection.
2. Apply R401, R402 and R403 as source-provenanced assumed-expansion facts,
   preserving repetition, separators, aliases and scalar constraints.
3. Classify every remaining reference as an explicit production,
   assumed-expansion, lexical fact, erratum/token operation, semantic-only
   fact, disputed fact or explicit unresolved residue. No reference may be
   silently dropped or guessed.
4. Require the generated composite parser inputs and direct wiring to contain
   no unclassified parser names. Semantic-only facts remain outside parser
   aliases but must themselves be source-linked.
5. Only after this gate is measured may new model-assisted semantic work,
   frontend construction or a generalized second-standard adapter proceed.

The generic implementation consumes expansion algebra and typed facts. It must
not grow hardcoded knowledge of J3 terms in the generic generator. J3/Fortran
specific PDF extraction, wording patterns, errata and lexical data remain in
the current adapter and its experiment records.

If an unclassified residue remains after the mechanical closure, it
is measured separately. A small model may propose local typed records only for
that residue. It does not discover R401--R403 and does not own composition or
wiring.

## Rejected

Generalizing the ingestion layer before the Fortran result is closed is
rejected because it adds abstraction without a second source standard to test
against. Sending the current residue to a model before reapplying E0055's
accepted expansion projection is rejected because it would confuse an
integration regression with missing normative information. Adding more
Fortran-specific branches to the generic generator is rejected. Such behavior
belongs in the adapter or in source-provenanced records.

## Reversal condition

Write a successor if the mechanical closure requires repeated special cases
that cannot be represented by the selected expansion and fact schemas, or if a
second standard demonstrates that the proposed adapter/core boundary is
materially wrong. A reversal must preserve the current Fortran evidence and
state which abstraction failed.

<!--
This body is immutable once the status is `accepted`. To change a decision,
write a new record that names this one in its Supersedes, Amends or Retracts
header and says what the old reasoning got wrong. Only the Status line of this
file may then be edited, to point at the successor.
-->
