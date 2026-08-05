# Claude Workflow Adapter

Use this adapter only when the host exposes the ultracode Workflow JavaScript DSL: `agent()`, `phase()`, `parallel()` or `pipeline()`, `budget`, schemas, and workflow resume state.

If any required primitive is absent, return to `SKILL.md` and choose a native-agent adapter. Never emit Workflow JavaScript for a host that cannot execute it.

## Mapping

- Root/coordinator: the conversation that authors and invokes the Workflow script.
- Worker: one `agent()` call with a bounded prompt and structured schema.
- Wave: a named `phase()` matching `meta.phases` exactly.
- Barrier: `parallel()` only when the next action needs the complete prior set, such as drafting, cross-item grouping, or final reduction.
- Streaming item stages: `pipeline()` when each item can advance without waiting for peers.
- Recovery: persisted `scriptPath`, `resumeFromRunId`, and `journal.jsonl` supplied by the Workflow runtime.

## Script contract

- Read [the canonical Workflow example](../examples/claude-workflow.js) before authoring.
- Keep `meta` a pure literal and set every worker's phase explicitly.
- Pass cap, target, output path, timestamps, and other varying inputs through `args`; do not hard-code machine paths or infer a universal cap.
- Validate finder, verifier, and judge results with JSON Schema.
- Filter `null` results before reduction.
- Keep scripts deterministic: no `Date.now()`, `Math.random()`, or argument-free `new Date()`.
- Test `budget.total` before treating `budget.remaining()` as a finite stop condition.
- Draft through one writer agent after discovery. Re-render from the same findings plus verdicts after verification.
- Batch verifier and escalation calls so queued depth stays bounded by the host width.

Before diagnosing an unexpected resumed result, inspect the workflow journal and cached prefix. These guarantees belong to this adapter only.

