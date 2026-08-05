# Changelog

All notable changes to this marketplace are documented here.
Skill versions live in each skill's `.claude-plugin/plugin.json` (and the matching Codex manifest).

Format: keep entries under the skill or `all` they affect. Bump the corresponding plugin `version` when you ship.

## Unreleased

### effective-go 0.1.1

- Version bump to verify marketplace install → update path (content unchanged from 0.1.0).

## 0.1.0 — 2026-08-05

### Marketplace

- Initial Claude Code marketplace (`ttaatoo-skills`) with per-skill install and `all` bundle.
- Codex marketplace (`.agents/plugins/marketplace.json`) mirroring the same plugins.
- Install paths: Claude `/plugin`, Codex `plugin marketplace add`, and `npx skills add`.
- Tooling: `scripts/bump-version.sh`, `scripts/validate.sh`, [VERSIONING.md](VERSIONING.md).

### Skills (initial 0.1.0)

- `effective-go` — idiomatic Go style and review.
- `go-naming` — Go naming form + semantics.
- `dave-cheney-go` — design trade-offs when rules are silent.
- `ultrawork` — maximum safe parallel agent work.
