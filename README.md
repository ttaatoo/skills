# Skills

A personal monorepo of [Claude Code](https://docs.claude.com/en/docs/claude-code) agent skills. Each skill is pure markdown — small, easy to adapt, and composable.

## Layout

```
skills/
  <skill-name>/
    SKILL.md          # the skill itself
    references/       # extra .md docs the SKILL.md links to
    examples/         # concrete sample files
    agents/           # provider-specific configs (e.g. openai.yaml)
```

A skill is just a folder with a `SKILL.md`. See [`skills/ultrawork`](skills/ultrawork) for a full, multi-file example.

## SKILL.md format

```markdown
---
name: my-skill
description: <one dense sentence — when to use it>
---

# My Skill

...body...
```

Frontmatter has two fields:

- **`name`** — the skill's kebab-case identifier.
- **`description`** — the model's **trigger**, not documentation. This is the text the model matches on to decide whether to auto-invoke the skill, so it should densely state *when to use it* (the signals, keywords, and situations that should fire it), not what the skill contains.

## When to use supporting folders

| Folder | Use it for |
|---|---|
| `references/` | Longer `.md` docs the SKILL.md body links out to. Keeps SKILL.md short while letting the model read detail on demand. |
| `examples/` | Concrete, runnable sample files (scripts, configs, fixtures). |
| `agents/` | Provider-specific agent definitions (e.g. `openai.yaml` for an OpenAI Codex subagent). |

## Adding a new skill

1. Create `skills/<name>/SKILL.md` with `name` and `description` frontmatter.
2. Write the body; link to `references/` docs for anything that would bloat the main file.
3. Sharpen the `description` first — it's what gets the skill invoked. Name the triggers, keywords, and situations explicitly.
4. Verify it loads: the skill appears under the available skills list in Claude Code.

## Status

Lean skills-only. No plugin manifest, versioning, or CI yet — that layer can be added later without changing the skills.
