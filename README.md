# Skills

Personal monorepo of agent skills ([Agent Skills](https://agentskills.io) / Claude Code / Codex). Each skill is markdown plus optional references — small, composable, and installable one-by-one or as a full bundle.

**Marketplace:** `ttaatoo-skills` · **Repo:** [ttaatoo/skills](https://github.com/ttaatoo/skills)

## Install

### Option A — Claude Code (native plugin, best update story)

```text
/plugin marketplace add ttaatoo/skills
/plugin install effective-go@ttaatoo-skills
```

| Want | Command |
|---|---|
| One skill | `/plugin install effective-go@ttaatoo-skills` |
| Another skill | `/plugin install go-naming@ttaatoo-skills` |
| Everything | `/plugin install all@ttaatoo-skills` |
| Activate | `/reload-plugins` if the install summary asks for it |

CLI equivalent:

```bash
claude plugin marketplace add ttaatoo/skills
claude plugin install effective-go@ttaatoo-skills
```

### Option B — `npx skills` (Claude + Codex + many other agents)

```bash
# one skill, global
npx skills add ttaatoo/skills --skill effective-go -g -y

# several
npx skills add ttaatoo/skills --skill effective-go --skill go-naming -g -y

# all skills, Claude + Codex
npx skills add ttaatoo/skills -g -a claude-code -a codex --all

# list what the repo exposes
npx skills add ttaatoo/skills --list
```

### Option C — Codex CLI marketplace

```bash
codex plugin marketplace add ttaatoo/skills
```

Then install `effective-go`, `go-naming`, `dave-cheney-go`, `ultrawork`, or `all` from the plugin browser (`/plugins`) or CLI.

Local test without pushing:

```text
# from a clone of this repo
/plugin marketplace add ./path/to/skills
/plugin install effective-go@ttaatoo-skills
```

## Update

After this repo ships a new skill version (version field bumped + pushed), users refresh as follows.

### Claude Code

```text
/plugin marketplace update ttaatoo-skills
/plugin update effective-go@ttaatoo-skills
```

Or use the `/plugin` UI to update installed plugins. Claude only pulls a new copy when the plugin **version string** changes — see [VERSIONING.md](VERSIONING.md).

### npx skills

```bash
npx skills update
npx skills update effective-go
```

### Codex

```bash
codex plugin marketplace update ttaatoo/skills
```

Then update/reinstall the plugin from `/plugins`.

## Available skills

| Plugin name | Version | Description |
|---|---|---|
| `effective-go` | 0.1.1 | Idiomatic Go style, correctness, maintainability |
| `go-naming` | 0.1.0 | Go naming (form + semantics) |
| `dave-cheney-go` | 0.1.0 | Design trade-offs when the rule book is silent |
| `ultrawork` | 0.1.0 | Maximum safe parallel agent work |
| `all` | 0.1.0 | Bundle of every skill above |

## Layout

```
.claude-plugin/
  marketplace.json      # Claude catalog (per-skill + all)
  plugin.json           # all-bundle plugin
.codex-plugin/
  plugin.json           # all-bundle for Codex
.agents/plugins/
  marketplace.json      # Codex catalog
skills/
  <skill-name>/
    SKILL.md
    .claude-plugin/plugin.json   # version + install unit
    .codex-plugin/plugin.json
    references/ | examples/ | agents/ | …
scripts/
  bump-version.sh       # bump skill/all versions in sync
  validate.sh           # manifest + frontmatter checks
```

A skill is a folder with `SKILL.md`. See [`skills/ultrawork`](skills/ultrawork) for a full multi-file example.

## SKILL.md format

```markdown
---
name: my-skill
description: <one dense sentence — when to use it>
---

# My Skill

...body...
```

- **`name`** — kebab-case identifier (must match the folder / plugin name).
- **`description`** — model **trigger**, not docs. Dense list of situations and keywords that should auto-invoke the skill.

## When to use supporting folders

| Folder | Use it for |
|---|---|
| `references/` | Longer `.md` docs the skill body links out to |
| `examples/` | Runnable samples (scripts, configs, fixtures) |
| `agents/` | Provider-specific agent configs (e.g. `openai.yaml`) |

## Authoring & releasing

1. Edit or add a skill under `skills/<name>/`.
2. Bump version so clients update: `scripts/bump-version.sh <name>` (or pass an explicit semver).
3. Validate: `scripts/validate.sh`.
4. Note the change in [CHANGELOG.md](CHANGELOG.md); push.

Full rules: **[VERSIONING.md](VERSIONING.md)**.

```bash
scripts/bump-version.sh --list          # current versions
scripts/bump-version.sh go-naming       # patch bump
scripts/bump-version.sh ultrawork 0.2.0
scripts/validate.sh
```

## Status

Marketplace + per-skill install/update is wired for Claude Code, Codex, and `npx skills`. Skills start at `0.1.0`.
