# D0012. The ImplIR v0 type set

Date: 2026-08-11
Status: accepted
Amends: D0007

## Context

The ImplIR sketch listed eleven types: `bool`, `int`, `status`, `node`,
`symbol`, `type`, `scope`, `value`, `list<T>`, `optional<T>`, and a `string`
that D0011 now rules out of the internals entirely.

ImplIR's defining constraint is that its complete grammar and semantics fit in
a prompt. Every type in the list costs prompt tokens and, more importantly,
gives a small model one more wrong choice to make. So the list needs a reason
per entry rather than a plausible-looking spread.

Two entries turn out not to have one.

`string` goes because D0011 removes it from every internal representation.
Names are interned, diagnostic codes and builtin operations are enums, and a
procedure identifier is an ID immediately after parsing. A model may write
`(proc check-C1234 ...)`; nothing downstream manipulates the spelling.

`value` goes because nothing uses it. Reading the whole builtin list —
`sym_exists`, `sym_type`, `sym_rank`, `sym_kind`, `resolve`, `type_equal`,
`type_numeric`, `node_kind`, `node_child`, `node_symbol`, `node_type`, `diag` —
not one produces or consumes a `value`, and no worked example mentions it. It
is speculative generality, and StandardIR's own rule is that a category is
added when a clause demonstrates it is necessary.

## Decision

Eight concrete types and two constructors:

```
bool  int  status  node  symbol  type  scope  name
list<T>  optional<T>
```

`name` replaces what `string` was doing and earns its place immediately:
`resolve(scope, name) -> optional<symbol>` needs it.

Target-language CHARACTER semantics are **not** an ImplIR type. Rules about
character entities reach them through `type` plus engine builtins such as
`type_is_character`, `char_length_known` and `char_length`. Putting a character
type into ImplIR would import target-language semantics into the synthesis
language, which is the failure `docs/self-hosting.md` §23 names: if ImplIR
starts becoming the formal definition of Fortran semantics, it is wrong. The
semantics belong in StandardIR and the target specification, where they carry
provenance.

## Rejected

**Keep `value` in case it is needed.** The argument for it is real — Fortran
constraints do talk about constant values, kind parameters and array bounds —
and integer constants are covered by `int`. A non-integer constant should
arrive together with the rule that needs it, so that the type has a citation
rather than an anticipation.

**Add `char_type`.** Rejected on the project's own criterion, above.

**Keep `string` for diagnostics.** Diagnostics are structured under D0011:
code, location, typed arguments. No string is needed to raise one.

## Reversal condition

`value` returns when a StandardIR rule requires a constant that `int` cannot
express, and the record that reinstates it cites that rule. The same standard
applies to any other addition: a type enters ImplIR with the rule that forced
it, or it does not enter.

If the type set grows past roughly a dozen entries, the constraint that
justifies ImplIR's existence — that its whole definition fits in a prompt — is
being eroded, and E4 should show it as a rising syntax-error or repair rate.
