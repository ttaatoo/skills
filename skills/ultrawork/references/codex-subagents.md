# Codex Subagent Adapter

Use this adapter when the host exposes Codex collaboration controls such as `spawn_agent`, `wait_agent`, `followup_task`, `send_message`, and `interrupt_agent` or their current equivalents.

## Coordinator loop

1. Normalize the host-reported capacity to available spawned-worker slots.
2. Build the dependency and write-ownership ledger before dispatch.
3. Spawn only concrete, bounded, independent assignments up to `effective_width`.
4. Keep recursive fan-out off by default; the root owns scheduling and integration.
5. Reuse a completed worker with `followup_task` for related work. Use `send_message` only to add context to an already running turn.
6. Wait in bounded intervals, surface progress at least once per minute, and replenish slots from the ready queue.
7. Interrupt work that is obsolete, conflicting, or outside scope; retain its state in the ledger.

## Prompt contract

Every worker receives the outcome, relevant context, owned and forbidden paths, dependency state, required evidence, and exact return shape. State that other agents share the workspace and that unrelated edits must be preserved.

Prefer read-only `explorer` or `reviewer` roles for discovery and verification. Use write-capable workers only for disjoint implementation slices. The root integrates shared files and runs global verification.

Codex subagent threads provide session-level orchestration, not the Claude Workflow JavaScript runtime. Do not promise schemas enforced by Workflow, `journal.jsonl`, cached script replay, durable resume IDs, or cross-session recovery.

