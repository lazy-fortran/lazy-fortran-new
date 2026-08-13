# D0037. Cross-clause prohibition normalization

Date: 2026-08-13
Status: accepted
<!-- proposed | accepted | superseded by D#### | amended by D#### | retracted -->

<!-- no optional decision headers -->

## Context

E0087 retained C734 as disputed because two deterministic scope readings were
possible for the sentence:

```
A derived type type-name shall not be DOUBLEPRECISION or the same as the name
of any intrinsic type defined in this document.
```

The canonical document independently repeats the construction in C752, C824
and C952: a subject "shall not be of type" one listed alternative "or" a
second listed alternative. These clauses are normative source witnesses, not
comparison grammars. They provide a bounded cross-clause test for whether the
two prohibited alternatives are inside the scope of `not`.

## Decision

For a constraint using the exact normative construction `shall not be X or Y`,
when independently recorded source clauses exhibit the same prohibition
construction, normalize the alternatives as one prohibited disjunction:

```
(not (or X Y))
```

Apply this bounded rule to C734. Its accepted predicate is therefore:

```
(not (or (eq type-name DOUBLEPRECISION)
        (intrinsic-type-name type-name)))
```

The cross-clause witness IDs, source phrases, source hash and selected
candidate are recorded by E0088. The rule does not generalize to arbitrary
English negation, and it does not authorize parser projection by itself.
Compiler behavior is a secondary check; the normative witness remains the
authority.

This is autonomous under D0028: the source is authoritative, the mechanism is
small and deterministic, and the resulting predicate can be specialized into
direct generated code.

## Rejected

The alternative `(or (not X) Y)` is rejected because it does not prohibit both
listed alternatives. Resolving C734 from gfortran or Flang behavior alone is
rejected because implementations are behavioral oracles, not the normative
source. Sending the sentence to a model is rejected because the cross-clause
source pattern supplies a smaller independently checkable mechanism.

## Reversal condition

Write a successor if an independently recorded normative clause using the same
construction requires the alternative scope, if the witness matching produces
false positives on a broader audited sample, or if source-linked mutation and
the independent oracle cannot distinguish the selected predicate. A later
semantic vocabulary may refine the fact names without changing this bounded
scope rule.

<!--
This body is immutable once the status is `accepted`. To change a decision,
write a new record that names this one in its Supersedes, Amends or Retracts
header and says what the old reasoning got wrong. Only the Status line of this
file may then be edited, to point at the successor.

Rewriting the reasoning destroys the thing that makes a reversal condition
checkable later: what was actually believed at the time.
-->
