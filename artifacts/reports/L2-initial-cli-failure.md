# L2 initial integration failure

Status: corrected

The first central smoke attempt used the component revisions before the CLI
boundary fix. `ffc-lower-frontend-v0` produced the reviewed MIR, but
`fortback-mir-v0` passed its fixed-length Fortran input buffer, including
trailing blanks, to the SX parser. The parser rejected the otherwise valid
input with:

```text
mir-v0: SX atom is too long
```

The generic correction was to pass `input(:int(file_size))` at the CLI/module
boundary. It was committed in `fortback-new` as
`181715ac2fa04b0682db24564126dee882cac345`, with a CLI/QEMU regression test.
The corrected central replay is recorded in `R000439` and passes.
