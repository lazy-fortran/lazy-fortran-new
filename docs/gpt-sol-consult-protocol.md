# Bounded GPT-Sol consultation protocol

GPT-Sol is a last-resort design and specification consultant. It is not a
default worker, reviewer, test oracle, or progress generator.

Route this through the installed `expert-escalation` skill, after
`bounded-exploration` where that skill's trigger applies. Ordinary debugging,
reading, experiments and `NO_PROGRESS` do not trigger a consultation or a
governance record.

## Trigger

Consult GPT-Sol only when either:

1. two materially distinct technical attempts for the same active task have
   failed under its verifier; or
2. the available evidence leaves a genuinely underdetermined interface or
   specification decision whose alternatives change the active path.

One failed command, an inconvenient implementation, missing documentation,
or a desire for another opinion is not a trigger.

## Request

The coordinator sends one bounded question containing:

- active task and exact definition of done;
- immutable fixture and source/provenance locator;
- component pins and contract revisions;
- expected versus actual observable;
- complete failure traces and verifier commands;
- the two rejected technical attempts, or the explicit competing options;
- constraints, including repository ownership and oracle policy.

Ask for a decision or a small set of falsifiable alternatives, not an
implementation dump. Store the consultation and its hash under the central
evidence path and link it from the task or decision log.

## Adoption

GPT-Sol advice is a proposal only. The coordinator must turn it into a new
fixture, independent oracle, or executable design comparison. Accept it only
after the active verifier passes and the decision record states what evidence
would reverse it. If the advice remains underdetermined, keep the task
BLOCKED and request the missing authority rather than guessing.
