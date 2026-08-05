---
name: ultrawork
description: Use when the user says "ultrawork" or "ultracode", explicitly requests parallel or delegated agents, asks to saturate concurrency, or asks for a substantial audit, research, migration, batch refactor, or multi-step implementation to run with maximum safe parallelism.
---

# Ultrawork

Maximize useful parallel progress without losing the deliverable or corrupting shared state. Tool capabilities, not the product name, determine the execution adapter.

## Select one adapter

1. Inspect the orchestration tools actually available in this session.
2. Read [the shared contract](references/core-contract.md) and [write isolation rules](references/write-isolation.md).
3. Select exactly one adapter:

| Observed capability | Required adapter |
|---|---|
| Workflow JavaScript DSL with `agent()`, phases, schemas, budget, and resume state | [Claude Workflow](references/claude-workflow.md); also read [the Workflow example](examples/claude-workflow.js) |
| Codex collaboration controls such as spawn, wait, follow-up, steer, and interrupt | [Codex subagents](references/codex-subagents.md) |
| Claude native `Agent`/subagent controls without the Workflow DSL | [Claude native agents](references/claude-native.md) |
| No multi-agent primitives | State the downgrade and execute solo; do not fabricate parallelism or durability |

If several adapters appear possible, choose the most capable fully available one. Never mix their tool semantics in one run.

## Execute

1. Announce the selected adapter, effective width, real dependency barriers, and any write-ownership limits.
2. Keep the root/coordinator responsible for decomposition, scheduling, integration, global verification, and synthesis.
3. Scout cheap facts inline, then dispatch bounded independent work at:

   ```text
   min(available worker slots, ready independent items, safe resource concurrency)
   ```

4. Materialize the requested deliverable or an `unverified` progress ledger after discovery, before expensive verification.
5. Batch related claims for adversarial verification. Escalate contested claims without dropping low-ranked findings.
6. Finish with confirmed, refuted, unverified, blocked, conflicting, and interrupted counts plus the evidence for completion.

Do not promise Workflow schemas, journals, cached replay, resume IDs, or cross-session recovery from a native-agent adapter. A partial run remains visibly partial.

