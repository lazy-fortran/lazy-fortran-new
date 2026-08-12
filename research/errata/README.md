# Fixed source errata

The files in this directory are deterministic overlays for source or parser
exceptions that a pinned document requires. They are research data, not a
replacement for the PDF or for StandardIR.

Each document file records its source hash. Every entry records an identifier,
kind, source clause, rule, page, observed spelling, derived spelling or rule,
an exact source witness, and the run that established the entry. The `origin`
field records who produced the entry. The `decision_id` records the decision
that accepted its use. Those fields are separate. An LLM-produced entry can
be accepted by a user without becoming human-authored.

The accepted entry is applied after extraction by a generator. The generator
keeps the original source record and attaches the erratum identifier to the
derived record.

`source-repair` entries describe extraction or layout defects such as
punctuation absorbed into a reference name. `parser-exception` entries add a
bounded rule required by an inconsistency in the source presentation. Both
classes need a source witness and an independent negative check.

An erratum is accepted through the decision ledger. A model may propose an
erratum or repair, with `LLM` or `LLM_REPAIR` provenance, but it cannot change
the accepted overlay or the generated wiring. A later experiment may compare
such proposals with this fixed set.
