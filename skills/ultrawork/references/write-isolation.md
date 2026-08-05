# Write Isolation

Parallel writes are safe only when ownership and shared resources are explicit before dispatch.

## Ownership rules

- Give each writer one disjoint set of `owned_paths` and an explicit `forbidden_paths` list.
- Tell every worker it is not alone in the workspace, must preserve unrelated WIP, and must not revert another worker's edits.
- Keep shared interfaces, registries, lockfiles, generated entrypoints, migrations, and release metadata under one owner.
- Assign integration and repository-wide verification to the root/coordinator.
- Use a worktree only when the host supports it and independent integration is cheaper than shared-workspace coordination.

## Resource limits

Treat these as capacity constraints even when files do not overlap:

| Resource | Safe treatment |
|---|---|
| Database/schema | One migration or schema owner at a time |
| Dev server/port | One lifecycle owner; readers may share the running instance |
| Browser/profile | One mutating controller per profile |
| Generated code | One generator owner; consumers wait for its artifact |
| External API quota | Bound workers below the provider limit |

## Dispatch contract

Every write assignment includes:

```text
Outcome:
Owned paths:
Forbidden paths:
Dependencies:
Required checks:
Return artifact:
```

If a worker discovers that it must touch a forbidden or already-owned path, it stops that slice and reports `conflicting`. The coordinator reassigns or serializes it; the worker does not negotiate ownership by editing first.

