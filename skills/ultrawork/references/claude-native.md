# Claude Native Agent Adapter

Use this adapter when Claude Code exposes native `Agent`/subagent or agent-team controls but not the ultracode Workflow JavaScript DSL.

## Mapping

- Keep the main Claude session as coordinator and final integrator.
- Use native agents for bounded read-heavy exploration, independent tests, or disjoint implementation slices.
- Derive effective width from actually available agent slots and the shared contract; do not reuse the Workflow cap formula.
- Give each writer the ownership contract from `write-isolation.md` before it starts.
- Wait at real dependency barriers, then publish the draft/ledger before beginning an expensive verification wave.
- Ask independent agents to refute findings or verify completed slices; batch related claims in one prompt when they share evidence.

Native agents do not imply Workflow schemas, deterministic JavaScript phases, a workflow journal, cached replay, or `resumeFromRunId`. Keep recoverable state in the requested artifact or coordinator ledger and describe those limits truthfully.

Use agent teams only when the host exposes them and peer-to-peer coordination materially helps. The coordinator still owns the final deliverable and unresolved-state ledger.

