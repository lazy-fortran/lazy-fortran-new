# D0007. ImplIR is residual, not a mandatory layer

Date: 2026-08-11
Status: accepted

## Context

The original architecture drew one path from StandardIR to the implementation:
every rule became ImplIR, and ImplIR became Fortran. That reads well and is
wasteful. A constraint of the form

```
require rank(x) = 0
```

fully determines its own checker. Routing it through a synthesis step means
paying for a model call, a verification cycle and a repair loop to obtain code
that a specializer could have emitted deterministically. It also inflates the
number the project most wants to report: if every rule passes through ImplIR,
the fraction of the compiler that is model-generated is 100 per cent by
construction, and the measurement means nothing.

There is a published precedent for the middle path. The Statix work specializes
declarative scope-resolution queries into a procedural intermediate query
language, reporting query resolution up to 7.7× faster and total type-checking
time reduced by roughly 38 to 48 per cent. Declarative specification and
procedural performance are not in conflict; specialization connects them.

## Decision

StandardIR is expressive enough that many semantic checks compile directly to
code. The pipeline forks:

```
                StandardIR
                /        \
     mechanically         unresolved
     constructive         problem
          │                   │
          ▼                   ▼
       Fortran              ImplIR → Fortran
```

ImplIR is the residual implementation language for cases where StandardIR
cannot be specialized mechanically. It is not the compiler's MIR, not the
language being compiled, and not the implementation language of the project.

Three paths exist and are tried in order: interpret the declarative rule,
specialize it into procedural Fortran, or synthesize ImplIR. Performance work
follows the same order — interpret first, verify semantics, profile,
specialize, benchmark — rather than writing procedural implementations up
front.

ImplIR stays deliberately too weak to implement the toolchain: no pointer
arithmetic, manual allocation, casts, exceptions, function pointers, classes,
inheritance, operator overloading, macros, threads or general I/O, and no
recursion initially. Generic traversal and resolution live in trusted Fortran
and are exposed as typed builtins.

**The fraction of rules requiring ImplIR becomes a headline metric**, tracked
against project maturity, and it should decrease. That number is only
meaningful because this decision makes it possible for it to be below one.

## Rejected

**ImplIR for every rule.** Uniform, simple to describe, and it destroys the
measurement and spends model budget on rules that need none.

**No ImplIR at all, specialize everything.** Attractive, and it assumes in
advance that every rule in a 688-page standard yields to mechanical
specialization. That is the hypothesis under test, not a premise.

**Interpret and never specialize.** Keeps the semantics authoritative and gives
up the performance goal, which is one of the project's three objectives.

## Consequences

E4 changes meaning. It was "does ImplIR reduce required model capability",
which presumed ImplIR was on the critical path for everything. It now measures
capability reduction on the residue only, and the residue's size is itself
reported.

`WHITEPAPER.md` §11 and §12, `DESIGN.md` §4, and `docs/glossary.md` are updated
so that ImplIR is not described as the path every rule takes.

## Reversal condition

If mechanical specialization turns out to cover only a small minority of rules
in practice, say under a quarter after the Core 0 rule set is formalized, then
ImplIR is effectively mandatory again and the architecture should say so
honestly rather than keeping a fork that never branches.
