# Cross-repository protocol

`lazy-fortran-new` is the sole control plane. Component repositories contain
implementation, local tests and their permanent local rules; they do not own
cross-repository status or Goal Mode loops.

## Pinning

Each integration run records the component repository, immutable commit SHA,
clean/dirty state, relevant artifact hash, active contracts, fixture hash and
output hash.

## Change order

1. Modify and test the component repository in an isolated worktree.
2. Commit the component change.
3. Update the central pin record.
4. Run the central end-to-end command.
5. Store the trace manifest and oracle result under `artifacts/` or the
   ignored run cache, as appropriate.
6. Update `STATUS.md` and milestone evidence only after the complete slice
   passes.
7. Commit the central integration update.

## Failure rule

A component test passing does not complete a central milestone. A central
failure records the component revision, minimized fixture, expected and actual
observable, full stage trace, oracle result and owning repository.

## Compatibility rule

A component interface change requires a central contract revision, migration
fixture, old/new behavior record and central integration test update.
