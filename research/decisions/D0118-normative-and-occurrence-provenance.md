# D0118. Separate normative rule clause from source occurrence provenance

Date: 2026-08-16
Status: accepted

## Context

The current StandardIR replay derives every syntax record from a single
command-line clause and therefore emits `(clause 5)` for the complete source
set. That conflates two different facts. The J3/24-007 notation section says
that an R-number encodes the clause in which the rule is defined, while the
high-level syntax section reproduces rules whose numbered definitions belong
to later clauses. A repeated R1401, for example, has a normative clause
encoded by its rule number but also has a source occurrence in the high-level
syntax section. R1520 is an independent control: its occurrence is in clause
15 rather than the current global clause 5.

The source coordinates and the rule identity are therefore not enough unless
the producer distinguishes normative identity from occurrence location. A
deduplication transformation must also retain the occurrence it suppresses.

## Decision

StandardIR source provenance uses these separate facts:

* `clause` is the normative clause, derived by one generic parser from the
  rule identifier's documented numbering convention;
* `occurrence-clause`, when present, is the clause in which this occurrence is
  printed in the source document and is not inferred from the rule number;
* page, end-page, byte-start, byte-length and source hash identify the exact
  source occurrence;
* an occurrence ordinal or equivalent lineage identifies repeated appearances
  of the same numbered rule; and
* target transformations retain a relation to the retained occurrence when
  another occurrence is suppressed.

The generic rule-number parser handles the documented one- and two-digit
clause prefixes and rejects malformed identifiers. It does not contain a list
of Fortran rules. Source-page/section context supplies occurrence location;
the producer may not fill it with the normative clause merely because the
source context is unavailable. Existing fixture and library callers that
provide an explicit clause remain valid, but real PDF replay is not green
until the producer supplies the separated fields.

R401/R402/R403 remain compact assumed-syntax facts in authoritative
StandardIR. A target projection may expand their closure only as a derived
artifact carrying its source rule and derivation relation. Repeated numbered
occurrences remain source lineage, not duplicate canonical definitions.

## Rejected

* Hard-coding clause 5 for a complete source document.
* Replacing occurrence provenance with the rule-number clause.
* Removing repeated occurrences without a retained-occurrence relation.
* Expanding assumed syntax in the authoritative source record.
* Repairing any of these cases with a rule-number list or a production-specific
  exception.

## Reversal condition

Write a successor if the pinned source document demonstrates that the
documented rule-number convention is insufficient to derive normative clause,
or if a source occurrence can cross section boundaries in a way that requires
a richer occurrence-span type than the current contract can represent.

## Evidence

* J3/24-007, §4.1.1, “Syntax rules”, and §4.1.3, “Assumed syntax rules”:
  <https://j3-fortran.org/doc/year/24/24-007.pdf>.
* R000404: the clean replay whose header and 522 syntax records all carry the
  command-line clause `5`.
* R000431/R000432: the selected source-target witness and its independent
  review, which exposed the need to retain suppressed occurrences.
* D0116/D0117: typed source-target correspondence and relation-valued
  transformation evidence.
