# Versioning & updates

## What gets a version

| Artifact | Where | When to bump |
|---|---|---|
| Single skill | `skills/<name>/.claude-plugin/plugin.json` **and** `skills/<name>/.codex-plugin/plugin.json` | Any shipped change to that skill's content |
| Same skill (catalog) | `.claude-plugin/marketplace.json` → matching `plugins[].version` | Keep in sync with the skill plugin.json |
| All-skills bundle | `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`, marketplace entry `all` | When the set of skills changes, or you want one-shot update for full installs |

Claude Code only refreshes an installed plugin when the resolved **version string changes**. Editing markdown without a version bump leaves existing installs on the old cached copy.

`npx skills` tracks git content differently; users still run `npx skills update` after you push.

## Semver for skills

Use `MAJOR.MINOR.PATCH` (start at `0.1.0`):

- **PATCH** — wording, references, bugfixes; same triggers/behavior.
- **MINOR** — new guidance, new references, expanded scope; still compatible.
- **MAJOR** — breaking change to how the skill should be used or what it assumes.

## Release a skill update

```bash
# 1. Edit the skill under skills/<name>/

# 2. Bump version (patch by default)
scripts/bump-version.sh effective-go          # 0.1.0 -> 0.1.1
scripts/bump-version.sh effective-go 0.2.0    # explicit

# 3. Validate
scripts/validate.sh

# 4. Note the change in CHANGELOG.md

# 5. Commit + push
git add -A && git commit -m "feat(effective-go): ..." && git push

# optional repo tag for humans / release notes
git tag v0.1.1 && git push --tags
```

If you maintain the `all` bundle version as a “release train”, also:

```bash
scripts/bump-version.sh all
```

## How users update

### Claude Code

```text
/plugin marketplace update ttaatoo-skills
/plugin update effective-go@ttaatoo-skills
```

Or update everything from that marketplace via the `/plugin` UI.

### Codex CLI

```bash
codex plugin marketplace update ttaatoo-skills
# then update/reinstall the plugin from /plugins or the CLI
```

### npx skills (cross-agent)

```bash
npx skills update
npx skills update effective-go
```

## Adding a new skill

1. Create `skills/<name>/SKILL.md` with `name` + `description` frontmatter.
2. Add `skills/<name>/.claude-plugin/plugin.json` and `.codex-plugin/plugin.json` (`version: "0.1.0"`, `"skills": ["."]` / `"./"`).
3. Register the plugin in `.claude-plugin/marketplace.json`.
4. Register it in `.agents/plugins/marketplace.json`.
5. Add the path to the `all` bundle `skills` arrays (Claude root plugin.json + marketplace `all` entry).
6. Run `scripts/validate.sh`.
7. Bump `all` if you want bundle installs to refresh.
