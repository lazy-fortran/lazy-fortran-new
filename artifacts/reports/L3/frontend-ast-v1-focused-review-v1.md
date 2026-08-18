# Focused review: typed frontend AST v1

Two independent medium-depth Luna reviews examined the frozen executable
revision `2a0c97576adc2fe3e64054cbae8a363a502f024d`, fortfront revision
`394f34da390fb7540da5676cbc4e6f89a84553c1`, the v1 schema and witness, the
canonical trace and the independent replay validator.

Both reviews pass:

- source-contract lineage and schema/output structural correspondence;
- independent oracle separation from fortfront implementation code;
- exact positive source, malformed `integer ::` negative and no-output control;
- path-independent trace replay and clean-checkout reproducibility;
- generated-record/handwritten-producer boundary for this exact witness;
- narrow scope and zero model calls or semantic promotions.

The promotion is bounded to one source spelling and one typed integer variable
declaration. It does not claim general declaration parsing, symbol resolution,
semantic analysis, MIR lowering, executable semantics or full M3.
