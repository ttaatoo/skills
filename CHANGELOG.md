# Changelog

All notable changes to this marketplace are documented here.

The **train version** lives in `package.json` and is synced to every plugin / marketplace manifest on release. Formal entries below are produced by [Changesets](https://github.com/changesets/changesets) (and may be edited by hand).

## 0.1.0

### Major Changes

- Initial public train release of **ttaatoo-skills**.

### Marketplace

- Claude Code marketplace (`ttaatoo-skills`) with per-skill install and `all` bundle.
- Codex marketplace (`.agents/plugins/marketplace.json`) mirroring the same plugins.
- Install paths: Claude `/plugin`, Codex `plugin marketplace add`, and interactive `npx skills add`.

### Skills

- `effective-go` — idiomatic Go style and review.
- `go-naming` — Go naming form + semantics.
- `dave-cheney-go` — design trade-offs when rules are silent.
- `ultrawork` — maximum safe parallel agent work.

### Tooling

- Changesets + GitHub Actions: version PR → `vX.Y.Z` tag → GitHub Release.
- Train version sync (`scripts/sync-plugin-versions.js`) keeps all plugin manifests aligned.
- `scripts/validate.sh` / `npm run validate` for manifests, frontmatter, and version consistency.
