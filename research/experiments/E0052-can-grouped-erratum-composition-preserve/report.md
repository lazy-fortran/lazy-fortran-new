# E0052. Grouped erratum composition

## Question

Can grouped erratum composition preserve optional reference punctuation for all
target validators?

## Method

The analysis command reruns E0049 and applies the same eight accepted errata to
the original StandardIR input. It performs an optional-group replacement before
the generic reference replacement. A source term such as `where-construct-name:`
therefore becomes one `optional(seq(ref name, token :))` expression. The command
generates ANTLR4, Bison and tree-sitter outputs and validates each with its
installed target tool.

## Result

The grouped candidate retains 522 syntax records and two optional grouping
witnesses. The tree-sitter generator loads the grammar far enough to expose
the unresolved `r_xyz` symbol, and its earlier malformed-sequence failure has
gone. ANTLR4 and Bison still reject it with the same unresolved-name boundary
as E0051. Each target format contains 502 definitions. The controlled removal
of one grouping witness changes the independent witness count as expected. No
model calls were made.

## Boundary

The structural composition defect is removed without resolving R401/R403 or
other unresolved terms. E0052 therefore remains a verification-failure result
for the complete parser input. It establishes the next boundary more cleanly:
all three target tools expose the remaining 103-name resolution residue, and
tree-sitter no longer fails earlier on malformed syntax. D0024 and D0026
remain unselected.
