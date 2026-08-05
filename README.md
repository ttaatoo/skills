# Skills

Personal monorepo of agent skills ([Agent Skills](https://agentskills.io) / Claude Code / Codex). Each skill is markdown plus optional references — small, composable, and installable one-by-one or as a full bundle.

**Marketplace:** `ttaatoo-skills` · **Repo:** [ttaatoo/skills](https://github.com/ttaatoo/skills) · **Train version:** see [Releases](https://github.com/ttaatoo/skills/releases)

Two install philosophies (same repo, pick one per skill):

| | **Claude / Codex plugin** | **`npx skills` (skills.sh)** |
|---|---|---|
| What you get | Managed, read-only copy | Editable files in your project |
| Updates | Marketplace / plugin update when train version changes | `npx skills update` when you want |
| Select skills | Discover list or install `all` | Interactive multi-select |
| Best for | Subscribe and stay current | Fork, tweak, own the files |

Installing the same skill both ways leaves you with two copies — pick one path.

## Install

### A — Claude Code plugin (subscribe, best auto-update)

```text
/plugin marketplace add ttaatoo/skills
```

Then either:

**Whole bundle**

```text
/plugin install all@ttaatoo-skills
```

**Pick skills** (Discover UI or one command each)

```text
/plugin install effective-go@ttaatoo-skills
/plugin install go-naming@ttaatoo-skills
```

| Want | Command |
|---|---|
| Everything | `/plugin install all@ttaatoo-skills` |
| One skill | `/plugin install effective-go@ttaatoo-skills` |
| Browse | `/plugin` → **Discover** → `ttaatoo-skills` |
| Activate | `/reload-plugins` if the install summary asks for it |

CLI:

```bash
claude plugin marketplace add ttaatoo/skills
claude plugin install all@ttaatoo-skills
# or: claude plugin install effective-go@ttaatoo-skills
```

### B — `npx skills` (interactive select — any agent)

Interactive installer (choose skills + agents):

```bash
npx skills@latest add ttaatoo/skills
```

Non-interactive examples:

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

### C — Codex CLI marketplace

```bash
codex plugin marketplace add ttaatoo/skills
```

Then install `effective-go`, `go-naming`, `dave-cheney-go`, `ultrawork`, or `all` from the plugin browser (`/plugins`) or CLI.

### Local test (clone, no push)

```text
/plugin marketplace add ./path/to/skills
/plugin install effective-go@ttaatoo-skills
```

## Update

After this repo ships a new **train version** (see [Releases](https://github.com/ttaatoo/skills/releases)):

### Claude Code

```text
/plugin marketplace update ttaatoo-skills
/plugin update all@ttaatoo-skills
# or per skill:
/plugin update effective-go@ttaatoo-skills
```

Claude only pulls a new copy when the plugin **version string** changes — see [VERSIONING.md](VERSIONING.md).

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

| Plugin name | Description |
|---|---|
| `effective-go` | Idiomatic Go style, correctness, maintainability |
| `go-naming` | Go naming (form + semantics) |
| `dave-cheney-go` | Design trade-offs when the rule book is silent |
| `ultrawork` | Maximum safe parallel agent work |
| `all` | Bundle of every skill above |

Versions follow the repo **train** (`package.json`); all plugins share the same number on each release.

## Layout

```
package.json                 # train version (Changesets)
.changeset/                  # pending release notes
.github/workflows/           # release + validate CI
.claude-plugin/
  marketplace.json           # Claude catalog (per-skill + all)
  plugin.json                # all-bundle plugin
.codex-plugin/
  plugin.json                # all-bundle for Codex
.agents/plugins/
  marketplace.json           # Codex catalog
skills/
  <skill-name>/
    SKILL.md
    .claude-plugin/plugin.json
    .codex-plugin/plugin.json
    references/ | examples/ | agents/ | …
scripts/
  sync-plugin-versions.js    # train → all manifests
  bump-version.sh            # local train bump + sync
  validate.sh                # manifest + frontmatter checks
  extract-changelog.js       # Release notes from CHANGELOG
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

Preferred (automatic tag + GitHub Release on `main`):

```bash
# edit skills/...
npx changeset                 # patch | minor | major + summary
npm run validate
git add -A && git commit && git push   # PR → merge
# CI: version PR → merge → tag vX.Y.Z → GitHub Release
```

Local train bump / hotfix:

```bash
scripts/bump-version.sh --list
scripts/bump-version.sh patch
# edit CHANGELOG.md, commit, tag, push --tags
```

Full rules: **[VERSIONING.md](VERSIONING.md)**.

## Status

Marketplace + per-skill install, Changesets train releases, and validate CI are wired for Claude Code, Codex, and `npx skills`.
