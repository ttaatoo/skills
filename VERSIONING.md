# Versioning & releases

This repo uses a **train version**: one semver for the whole marketplace. Claude, Codex, and the catalog all share that number so a release is one tag and one GitHub Release.

## Version source of truth

| Artifact | Role |
|---|---|
| `package.json` → `version` | **Train version** (Changesets bumps this) |
| `.claude-plugin/plugin.json` | `all` bundle; must match train |
| `skills/*/.claude-plugin/plugin.json` | Per-skill plugins; must match train |
| `.claude-plugin/marketplace.json` | Every `plugins[].version` + `metadata.version` = train |
| Matching `.codex-plugin/plugin.json` files | Same version as Claude manifests |
| `CHANGELOG.md` | Human notes; Changesets appends on version PR |
| git tag `vX.Y.Z` + GitHub Release | Created by CI after the version PR merges |

Claude Code only refreshes an installed plugin when the resolved **version string** changes. `npx skills` tracks git content; users still run `npx skills update` after you ship.

## Semver

Use `MAJOR.MINOR.PATCH` (train starts at `0.1.0`):

- **PATCH** — wording, references, bugfixes; same triggers/behavior.
- **MINOR** — new guidance, new skill, expanded scope; still compatible.
- **MAJOR** — breaking change to how skills are used or what they assume.

## Formal release (Changesets — preferred)

```bash
# 1. Edit skills under skills/<name>/

# 2. Record the change
npx changeset
#    → pick patch/minor/major for ttaatoo-skills
#    → write a short user-facing summary

# 3. Validate locally
npm run validate   # or scripts/validate.sh

# 4. Commit skill + .changeset/*.md, open PR, merge to main
```

Then CI:

1. **Release** workflow sees pending changesets → opens/updates **chore: version skills**.
2. That PR runs `changeset version` + `scripts/sync-plugin-versions.js` (writes train into all manifests) and updates `CHANGELOG.md`.
3. Merge the version PR → `changeset tag` pushes `vX.Y.Z`.
4. **GitHub Release** workflow creates a Release from the matching CHANGELOG section.

### Local train bump (hotfix / no changeset)

```bash
scripts/bump-version.sh              # patch
scripts/bump-version.sh minor
scripts/bump-version.sh 0.2.0
# edit CHANGELOG.md, commit, then:
git tag -a v0.2.0 -m "v0.2.0"
git push origin main --tags
```

## How users update

### Claude Code (native plugin — managed, read-only)

```text
/plugin marketplace update ttaatoo-skills
/plugin update effective-go@ttaatoo-skills
# or
/plugin update all@ttaatoo-skills
```

### npx skills (editable copies)

```bash
npx skills update
npx skills update effective-go
```

### Codex CLI

```bash
codex plugin marketplace update ttaatoo/skills
```

Then update/reinstall from `/plugins`.

## Install paths (which is interactive?)

| Path | Selects skills? | Updates |
|---|---|---|
| Claude `all@ttaatoo-skills` | No — whole bundle | Auto when train version changes |
| Claude Discover / per-plugin install | Yes — pick plugins one by one | Per installed plugin version |
| `npx skills add ttaatoo/skills` | Yes — multi-select skills + agents | `npx skills update` |

Do not install the same skill via both plugin and `npx skills` — you will get two copies.

## Adding a new skill

1. Create `skills/<name>/SKILL.md` with `name` + `description` frontmatter.
2. Add `skills/<name>/.claude-plugin/plugin.json` and `.codex-plugin/plugin.json` (version will be overwritten by train sync).
3. Register in `.claude-plugin/marketplace.json`.
4. Register in `.agents/plugins/marketplace.json` if you keep the Codex catalog.
5. Append the path to the `all` bundle `skills` arrays (root `.claude-plugin/plugin.json` + marketplace `all` if needed).
6. `node scripts/sync-plugin-versions.js` so the new manifests match train.
7. `npx changeset` (minor if new skill) + `npm run validate`.

## Tooling

```bash
npm run changeset              # create a changeset
npm run version                # changeset version + sync (CI)
npm run sync-versions          # sync train → manifests only
npm run validate               # manifests + frontmatter (+ claude if installed)
scripts/bump-version.sh --list
scripts/bump-version.sh patch
```
