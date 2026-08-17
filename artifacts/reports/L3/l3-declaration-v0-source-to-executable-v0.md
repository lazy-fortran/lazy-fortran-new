# L3 integer-declaration source-to-executable replay

Status: bootstrap replay `PASS`; committed clean replay pending.

The exact positive source is:

```fortran
program p
  integer :: x
end program p
```

The negative neighbour omits the entity name:

```fortran
program p
  integer ::
end program p
```

The replay command is:

```text
L3_EXPECTED_CENTRAL_COMMIT=<pinned-central> tests/e2e/run-l3-declaration.sh --fresh
```

It reuses the existing frontend-v0, MIR-v0 and backend observables. The
independent validator is `tests/e2e/validate_l3_declaration.py`; it checks the
exact source bytes, rejected diagnostic, no-negative-MIR control, stable MIR
and executable, ELF64/RISC-V identity and a second QEMU run. The slice does
not expose `x` as a typed AST or MIR declaration and does not claim general
declaration parsing.

The bootstrap replay accepted the positive, rejected the malformed neighbour,
returned runtime exit status zero, and recorded zero model calls and zero
semantic promotions. Regenerate these observations with the command above.
