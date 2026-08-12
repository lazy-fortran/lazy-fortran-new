# D0028. Default decision principles and autonomous resolution

Date: 2026-08-12
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

## Context

The repository's decision ledger deliberately exposed D0024, D0026 and D0027
as a handoff queue. In practice, the user has now delegated ordinary design
choices and has stated the governing principles: keep the system simple, make
the generated compiler fast, preserve deterministic wiring and do not stop
when those principles determine the answer. The instructions need to make
that delegation durable rather than dependent on one conversation.

## Decision

Use the following default decision order:

1. preserve correctness, source provenance and the repository's explicit
   invariants.
2. prefer one authoritative representation and the smallest general
   mechanism.
3. prefer compile-time generation and specialized direct code over runtime
   interpretation, lookup and dispatch.
4. preserve the deterministic architecture: the LLM may fill local typed
   holes, but never owns wiring, ordering or composition.

When these principles and the available evidence determine a choice, the
agent should accept the proposed decision itself, record the selected option,
rejected alternatives and reversal condition, and continue implementation.
It should not wait for another planning model or ask the user merely because a
decision record was initially proposed.

The agent must stop and request direction only when requirements conflict,
the evidence cannot distinguish materially different choices, the action has
an irreversible external consequence beyond the delegated scope, or a new
authority is required. An unresolved technical problem is not by itself a
reason to remain stuck: make the smallest reversible progress, record the
boundary, and continue with the accepted parts.

## Rejected

Requiring a separate planning-model or user acceptance for every ordinary
representation choice is rejected because it serializes work that the
principles already determine. Leaving a proposed record open solely to avoid
responsibility is rejected because it makes the ledger a queue rather than a
working decision interface. Choosing runtime generic machinery for
convenience is rejected when the same contract can be specialized at
generation time.

## Reversal condition

Reverse this policy if autonomous decisions repeatedly violate the stated
invariants, produce materially worse measured performance than a plausible
alternative, or cause an irreversible scope or interface change that the
delegation did not cover.

<!--
This body is immutable once the status is `accepted`. To change a decision,
write a new record that names this one in its Supersedes, Amends or Retracts
header and says what the old reasoning got wrong. Only the Status line of this
file may then be edited, to point at the successor.

Rewriting the reasoning destroys the thing that makes a reversal condition
checkable later: what was actually believed at the time.
-->
