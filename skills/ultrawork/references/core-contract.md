# Shared Orchestration Contract

Ultrawork maximizes useful parallel progress while preserving one accountable coordinator, recoverable deliverables, and truthful completion status.

## Capacity

Compute capacity before every wave:

```text
effective_width = min(available_worker_slots, ready_independent_items, safe_resource_concurrency)
```

- Normalize `available_worker_slots` to spawned workers; subtract the coordinator if the host reports a total including it.
- Count only work whose dependencies are satisfied.
- Bound shared databases, ports, browsers, rate limits, generated outputs, and overlapping writes independently of the host ceiling.
- Replenish completed slots while independent ready work remains.
- For an explicit full-fleet request, widen read-only work with distinct lenses. Never create duplicate busywork for a trivial task.

## Coordinator ledger

The root/coordinator owns decomposition, scheduling, integration, and the final claim. Track each item with:

| Field | Meaning |
|---|---|
| `id` | Stable task or claim identifier |
| `depends_on` | Preconditions before dispatch |
| `state` | `ready`, `running`, `done`, `blocked`, `conflicting`, `interrupted`, `unverified` |
| `owner` | Exactly one accountable worker |
| `owned_paths` | Files or resources the worker may change |
| `forbidden_paths` | Shared or unrelated state it must not change |
| `artifact` | Result, patch, report section, or evidence |
| `verification` | Independent check and verdict |

After discovery, materialize the requested deliverable or a progress ledger with every claim marked `unverified`. Verification upgrades that artifact; it must not be the first point at which an artifact exists.

## Execution waves

1. Scout cheap facts inline when the work list is unknown.
2. Decompose by independent outcome, source, or ownership boundary.
3. Dispatch one bounded assignment per worker with expected output and verification criteria.
4. Land a draft or ledger at the first discovery boundary.
5. Verify findings adversarially and implementation slices independently.
6. Integrate centrally, run global gates, and synthesize for the user.

Use separate waves when a later step depends on all earlier results. Do not hide a real barrier merely to make the pipeline look concurrent.

## Verification

- Keep every discovered claim. Do not select verification candidates by unverified severity or top-N ranking.
- Batch related claims by source file, ownership boundary, or shared evidence into at most `effective_width` verifier groups.
- Ask verifiers to refute claims or demonstrate that changes fail their stated contract.
- Use one independent verdict by default. Escalate contested or ambiguous claims in another bounded batch.
- Preserve `confirmed`, `refuted`, and `unverified` entries in the final artifact.

## Completion contract

Report the adapter used, coverage, completed work, verification evidence, and every blocked, conflicting, interrupted, or unverified item. A partial run is a partial result, never a silent success.

